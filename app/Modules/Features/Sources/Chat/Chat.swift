//
//  Chat.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import OSLog
import Foundation
import BuddyClient
import KamaalUtils
import Authentication
import KamaalExtensions

public final class Chat: @unchecked Sendable, ObservableObject{
    @Published public private(set) var rooms: [ChatRoom] = []
    @Published public private(set) var selectedRoomID: UUID?
    @Published public private(set) var selectingRoom = false
    @Published var selectedModel: LLMModel? {
        didSet { Task { await selectedModelDidSet() } }
    }
    @Published private(set) var selectingRoomError: ListChatMessagesErrors?

    private let client = BuddyClient.shared
    private let logger = Logger(subsystem: ModuleConfig.identifier, category: String(describing: Chat.self))

    @UserDefaultsObject(key: "selectedModel")
    private var storedSelectedModel: LLMModel?

    public init() {
        selectedModel = storedSelectedModel
        Task {
            do {
                try await listRooms().get()
            } catch {
                logger.error("Failed to list rooms; error='\(error)'")
            }
        }
    }

    var selectedRoom: ChatRoom? {
        guard let selectedRoomID else { return nil }

        return rooms.find(by: \.id, is: selectedRoomID)
    }

    public func selectRoom(_ room: ChatRoom) async {
        await selectRoom(room, fetchMessages: true)
    }

    @MainActor
    public func unsetSelectedRoom() {
        selectedRoomID = nil
    }

    func sendMessage(_ message: String) async -> Result<Void, SendMessageErrors> {
        guard let selectedModel else {
            assertionFailure("Should have a a model selected before sending a message")
            return .failure(.general(context: nil))
        }

        let userMessageDate = Date.now
        let result = await client.llm.sendMessage(payload: .init(
            roomID: selectedRoom?.id,
            llmProvider: selectedModel.provider,
            llmKey: selectedModel.key,
            message: message
        ))
            .mapError { error -> SendMessageErrors in
                switch error {
                case .internalServerError, .undocumentedError: return .general(context: error)
                case .unauthorized, .badRequest: return .unauthorized
                }
            }
        let response: SendMessageResponse
        switch result {
        case let .failure(failure):
            logger.error("Failed to send message; error='\(failure)'")
            return .failure(failure)
        case let .success(success): response = success
        }

        let newMessages = [
            ChatMessage(
                role: .user,
                content: message,
                date: userMessageDate.toIsoString(),
                llmProvider: selectedModel.provider,
                llmKey: selectedModel.key
            ),
            ChatMessage(
                role: .assistant,
                content: response.content,
                date: response.date,
                llmProvider: response.llmProvider,
                llmKey: response.llmKey
            ),
        ]

        if let selectedRoom {
            let messages = selectedRoom.messages.concat(newMessages)
            await setMessagesOnRoom(selectedRoom, messages: messages)

            return .success(())
        }

        let newRoom = ChatRoom(
            id: response.roomID,
            title: response.title,
            messagesCount: 2,
            updatedAt: response.updatedAt,
            messages: newMessages
        )
        let newRooms = rooms
            .prepended(newRoom)
        await setRooms(newRooms)
        await selectRoom(newRoom, fetchMessages: false)

        return .success(())
    }

    func listRooms() async -> Result<Void, ListRoomsErrors> {
        let result = await client.llm.listChatRooms()
            .map({ response -> [ChatRoom] in
                response.data
                    .map { room in
                        ChatRoom(
                            id: room.roomID,
                            title: room.title,
                            messagesCount: room.messagesCount,
                            updatedAt: room.updatedAt,
                            messages: []
                        )
                    }
            })
            .mapError { error -> ListRoomsErrors in
                switch error {
                case .unauthorized: return .unauthorized
                default: return .general(context: error)
                }
            }
        switch result {
        case let .failure(failure): return .failure(failure)
        case let .success(success): await setRooms(success)
        }

        return .success(())
    }

    @MainActor
    func unsetSelectingRoomError() {
        setSelectingRoomError(nil)
    }

    @MainActor
    private func setSelectingRoomError(_ error: ListChatMessagesErrors?) {
        selectingRoomError = error
    }

    private func withSelectingRoom<T>(_ callback: () async -> T) async -> T {
        await setSelectingRoom(true)
        let result = await callback()
        await setSelectingRoom(false)

        return result
    }

    @MainActor
    private func setSelectingRoom(_ state: Bool) {
        selectingRoom = state
    }

    private func selectRoom(_ room: ChatRoom, fetchMessages: Bool) async {
        guard room.id != selectedRoomID else { return }

        await withSelectingRoom {
            if fetchMessages {
                await fetchRoomMessages(room)
            }

            await setSelectedRoom(room)
        }
    }

    private func fetchRoomMessages(_ room: ChatRoom) async {
        let result = await client.llm.listChatMessages(roomID: room.id)
            .mapError { error -> ListChatMessagesErrors in
                switch error {
                case .internalServerError, .undocumentedError: return .general(context: error)
                case .unauthorized: return .unauthorized
                case .notFound: return .notFound
                }
            }
            .map { response -> [ChatMessage] in
                response.data
                    .compactMap { data -> ChatMessage? in
                        guard let role = ChatMessage.Role(rawValue: data.role.rawValue) else { return nil }

                        return ChatMessage(
                            role: role,
                            content: data.content,
                            date: data.date,
                            llmProvider: data.llmProvider,
                            llmKey: data.llmKey
                        )
                    }
            }
        let messages: [ChatMessage]
        switch result {
        case let .failure(failure):
            logger.error("Failed to fetch messages; error='\(failure)'")
            await setSelectingRoomError(failure)
            return
        case let .success(success): messages = success
        }

        await setMessagesOnRoom(room, messages: messages)
    }

    @MainActor
    private func setMessagesOnRoom(_ room: ChatRoom, messages: [ChatMessage]) {
        guard let index = rooms.findIndex(by: \.id, is: room.id) else {
            logger.warning("Failed to find room with id '\(room.id)' in rooms")
            assertionFailure()
            return
        }

        rooms[index] = room.setMessages(messages)
    }

    @MainActor
    private func setSelectedRoom(_ room: ChatRoom) {
        selectedRoomID = room.id
    }

    @MainActor
    private func selectedModelDidSet() {
        guard let selectedModel else { return }
        guard storedSelectedModel != selectedModel else { return }

        storedSelectedModel = selectedModel
    }

    @MainActor
    private func setRooms(_ rooms: [ChatRoom]) {
        self.rooms = rooms
    }
}

enum ListChatMessagesErrors: Error, Equatable {
    case notFound
    case unauthorized
    case general(context: Error?)

    static func == (lhs: ListChatMessagesErrors, rhs: ListChatMessagesErrors) -> Bool {
        switch lhs {
        case .notFound:
            return rhs == .notFound
        case .unauthorized:
            return rhs == .unauthorized
        case let .general(lhsContext):
            if case let .general(rhsContext) = rhs {
                return lhsContext?.localizedDescription == rhsContext?.localizedDescription
            }

            return false
        }
    }

    var errorDescription: String {
        switch self {
        case .general: NSLocalizedString("Failed to get messages.", comment: "")
        case .notFound: NSLocalizedString("Room not found.", comment: "")
        case .unauthorized: NSLocalizedString("Unauthorized.", comment: "")
        }
    }
}

enum SendMessageErrors: Error {
    case unauthorized
    case general(context: Error?)

    var errorDescription: String {
        switch self {
        case .unauthorized:
            return NSLocalizedString("Unauthorized.", comment: "")
        case .general:
            return NSLocalizedString("Failed to send message.", comment: "")
        }
    }
}

enum ListRoomsErrors: Error {
    case unauthorized
    case general(context: Error?)
}
