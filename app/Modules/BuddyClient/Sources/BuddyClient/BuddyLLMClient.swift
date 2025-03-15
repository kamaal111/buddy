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
        @DateValue<ISO8601Strategy> public private(set) var updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case roomID = "room_id"
            case title
            case messagesCount = "messages_count"
            case updatedAt = "updated_at"
        }
    }
}

public struct ListChatMessagesResponse: Codable {
    public let data: [ChatMessage]

    public struct ChatMessage: Codable {
        public let role: BuddyClientLLMMessageRole
        public let llmProvider: String
        public let llmKey: String
        public let content: String
        @DateValue<ISO8601Strategy> public private(set) var date: Date

        enum CodingKeys: String, CodingKey {
            case role
            case llmProvider = "llm_provider"
            case llmKey = "llm_key"
            case content
            case date
        }
    }
}

public struct SendMessageResponse: Codable {
    public let role: BuddyClientLLMMessageRole
    public let content: String
    public let llmProvider: String
    public let llmKey: String
    @DateValue<ISO8601Strategy> public private(set) var date: Date
    public let roomID: UUID
    public let title: String
    @DateValue<ISO8601Strategy> public private(set) var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case llmProvider = "llm_provider"
        case llmKey = "llm_key"
        case date
        case roomID = "room_id"
        case title
        case updatedAt = "updated_at"
    }
}

public enum BuddyClientLLMMessageRole: String, Codable {
    case user
    case assistant
}

public final class BuddyLLMClient: Sendable, BuddyAuthorizedClientable, BuddyClientable {
    let state: BuddyClientState
    let jsonDecoder: JSONDecoder
    let jsonEncoder = JSONEncoder()

    private let baseURL = ModuleConfig.apiBaseURL.appending(path: "llm")

    init(state: BuddyClientState) {
        self.state = state

        self.jsonDecoder = JSONDecoder()
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
                case let .notFound(data): return .undocumentedError(statusCode: 404, payload: data)
                case let .clientError(data, response):
                    assert(response.statusCode >= 300)
                    return .undocumentedError(statusCode: response.statusCode, payload: data)
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
                case let .notFound(data): return .undocumentedError(statusCode: 404, payload: data)
                case let .clientError(data, response):
                    assert(response.statusCode >= 300)
                    return .undocumentedError(statusCode: response.statusCode, payload: data)
                }
            }
    }

    public func listChatMessages(
        roomID: UUID
    ) async -> Result<ListChatMessagesResponse, BuddyLLMClientListMessagesErrors> {
        let url = baseURL.appending(path: "chats").appending(path: roomID.uuidString)

        return await makeAuthorizedGetRequest(url: url)
            .mapError { error -> BuddyLLMClientListMessagesErrors in
                switch error {
                case .internalServerError: return .internalServerError(context: error)
                case .decodingError: return .internalServerError(context: error)
                case let .notFound(data): return .notFound(response: data)
                case let .unauthorized(data): return .unauthorized(response: data)
                case let .badRequest(data): return .undocumentedError(statusCode: 400, payload: data)
                case let .clientError(data, response):
                    assert(response.statusCode >= 300)
                    return .undocumentedError(statusCode: response.statusCode, payload: data)
                }
            }
    }
}

public struct BuddyLLMClientSendMessagePayload: Encodable {
    public let roomID: UUID?
    public let llmProvider: String
    public let llmKey: String
    public let message: String

    public init(roomID: UUID?, llmProvider: String, llmKey: String, message: String) {
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

public enum BuddyLLMClientListMessagesErrors: Error {
    case internalServerError(context: Error?)
    case undocumentedError(statusCode: Int, payload: Data)
    case unauthorized(response: Data?)
    case notFound(response: Data?)
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
