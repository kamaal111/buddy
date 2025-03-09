//
//  BuddyLLMClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 3/7/25.
//

import Foundation

public struct ListChatRoomResponse: Codable {
    public let data: [ChatRoom]

    public struct ChatRoom: Codable {
        public let roomID: UUID
        public let title: String
        public let messagesCount: Int
        public let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case roomID = "room_id"
            case title
            case messagesCount = "messages_count"
            case updatedAt = "updated_at"
        }
    }
}

public struct SendMessageResponse: Codable {
    public let role: Role
    public let content: String
    public let llmProvider: String
    public let llmKey: String
    public let date: String
    public let roomID: UUID
    public let title: String

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case llmProvider = "llm_provider"
        case llmKey = "llm_key"
        case date
        case roomID = "room_id"
        case title
    }

    public enum Role: String, Codable {
        case user
        case assistant
    }
}

public final class BuddyLLMClient: Sendable, BuddyAuthorizedClientable, BuddyClientable {
    let state: BuddyClientState
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    private let baseURL = ModuleConfig.apiBaseURL.appending(path: "llm")

    init(state: BuddyClientState) {
        self.state = state
    }

    public func sendMessage(
        payload: BuddyLLMClientSendMessagePayload
    ) async -> Result<SendMessageResponse, BuddyLLMClientSendMessageErrors> {
        let url = baseURL.appending(path: "chats")

        return await makeAuthorizedPostRequest(url: url, payload: payload)
            .mapError { error -> BuddyLLMClientSendMessageErrors in
                switch error {
                case .internalServerError: return .internalServerError(context: error)
                case .decodingError: return .internalServerError(context: error)
                case let .badRequest(data): return .badRequest(response: data)
                case let .unauthorized(data): return .unauthorized(response: data)
                case let .clientError(_, response):
                    assert(response.statusCode >= 300)
                    return .internalServerError(context: error)
                }

            }
    }

    public func listChatRooms() async -> Result<ListChatRoomResponse, BuddyLLMClientListChatRoomsErrors> {
        let url = baseURL.appending(path: "chats")

        return await makeAuthorizedGetRequest(url: url)
            .mapError { error -> BuddyLLMClientListChatRoomsErrors in
                switch error {
                case .internalServerError: return .internalServerError(context: error)
                case .decodingError: return .internalServerError(context: error)
                case let .badRequest(data): return .badRequest(response: data)
                case let .unauthorized(data): return .unauthorized(response: data)
                case let .clientError(_, response):
                    assert(response.statusCode >= 300)
                    return .internalServerError(context: error)
                }
            }
    }
}

public struct BuddyLLMClientSendMessagePayload: Encodable {
    public let roomID: String?
    public let llmProvider: String
    public let llmKey: String
    public let message: String

    public init(roomID: String?, llmProvider: String, llmKey: String, message: String) {
        self.roomID = roomID
        self.llmProvider = llmProvider
        self.llmKey = llmKey
        self.message = message
    }

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case llmProvider = "llm_provider"
        case llmKey = "llm_key"
        case message
    }
}

public enum BuddyLLMClientSendMessageErrors: Error {
    case internalServerError(context: Error?)
    case undocumentedError(statusCode: Int, payload: Data)
    case unauthorized(response: Data?)
    case badRequest(response: Data?)
}

public enum BuddyLLMClientListChatRoomsErrors: Error {
    case internalServerError(context: Error?)
    case unauthorized(response: Data?)
    case badRequest(response: Data?)
    case undocumentedError(statusCode: Int, payload: Data)
}
