//
//  ChatRoom.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/8/25.
//

import Foundation

public struct ChatRoom: Hashable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let messagesCount: Int
    public let updatedAt: String
    public let messages: [ChatMessage]

    public func setMessages(_ messages: [ChatMessage]) -> ChatRoom {
        .init(id: id, title: title, messagesCount: messages.count, updatedAt: updatedAt, messages: messages)
    }
}
