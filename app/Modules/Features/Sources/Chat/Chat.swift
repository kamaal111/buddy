//
//  Chat.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import OSLog
import Foundation
import BuddyClient
import Authentication
import KamaalExtensions

public final class Chat: @unchecked Sendable, ObservableObject{
    @Published public private(set) var rooms: [ChatRoom] = []
    @Published var selectedModel: LLMModel?
    @Published private(set) var selectedRoomID: UUID?

    private let client = BuddyClient.shared
    private let logger = Logger(subsystem: ModuleConfig.identifier, category: String(describing: Chat.self))

    public init() {
        Task {
            do {
                try await listRooms().get()
            } catch {
                logger.error("Failed to list rooms; error='\(error)'")
            }
        }
    }

    func sendMessage(_ message: String) async -> Result<Void, SendMessageErrors> {
        guard let selectedModel else {
            assertionFailure("Should have a a model selected before sending a message")
            return .failure(.general(context: nil))
        }

        let result = await client.llm.sendMessage(payload: .init(
            roomID: nil,
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

        let newRoom = ChatRoom(
            id: response.roomID,
            title: response.title,
            messagesCount: 2,
            updatedAt: response.date
        )
        let newRooms = rooms
            .prepended(newRoom)
        await setRooms(newRooms)
        await setSelectedRoomID(newRoom.id)

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
                            updatedAt: room.updatedAt
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
    private func setRooms(_ rooms: [ChatRoom]) {
        self.rooms = rooms
    }

    @MainActor
    private func setSelectedRoomID(_ roomID: UUID) {
        self.selectedRoomID = roomID
    }
}

enum SendMessageErrors: Error {
    case unauthorized
    case general(context: Error?)

    var errorDescription: String? {
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
