//
//  Chat.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import OSLog
import Foundation
import BuddyClient

public final class Chat: @unchecked Sendable, ObservableObject{
    @Published public private(set) var rooms: [ChatRoom] = []

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
}

enum ListRoomsErrors: Error {
    case unauthorized
    case general(context: Error?)
}
