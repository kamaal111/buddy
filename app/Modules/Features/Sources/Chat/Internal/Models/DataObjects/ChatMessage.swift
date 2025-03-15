//
//  ChatMessage.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/9/25.
//

import Foundation

public struct ChatMessage: Hashable, Sendable {
    public let role: Role
    public let content: String
    public let date: Date
    public let llmProvider: String
    public let llmKey: String

    public var isFromUser: Bool { role == .user }

    public enum Role: String, Sendable {
        case user
        case assistant
    }
}
