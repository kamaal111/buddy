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
}
