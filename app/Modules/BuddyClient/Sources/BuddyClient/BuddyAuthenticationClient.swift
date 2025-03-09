//
//  BuddyAuthenticationClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/19/25.
//

import OSLog
import Foundation
import OpenAPIRuntime

public struct BuddyAuthenticationSessionResponse: Codable, Sendable {
    public let user: User
    public let availableModels: [AvailableModel]

    public struct User: Codable, Sendable {
        public let email: String
    }

    public struct AvailableModel: Codable, Sendable {
        public let provider: String
        public let key: String
        public let displayName: String
        public let description: String

        enum CodingKeys: String, CodingKey {
            case provider
            case key
            case displayName = "display_name"
            case description
        }
    }

    enum CodingKeys: String, CodingKey {
        case user
        case availableModels = "available_models"
    }
}

public final class BuddyAuthenticationClient: Sendable, BuddyAuthorizedClientable, BuddyClientable {
    let state: BuddyClientState
    let jsonDecoder = JSONDecoder()
    let jsonEncoder = JSONEncoder()

    private let baseURL = ModuleConfig.authBaseURL
    private let client: Client
    private let logger = Logger(
        subsystem: ModuleConfig.identifier,
        category: String(describing: BuddyAuthenticationClient.self)
    )

    init(client: Client, state: BuddyClientState) {
        self.client = client
        self.state = state
    }

    public var isAuthorized: Bool {
        state.authorizationToken != nil
    }

    public func session() async -> Result<BuddyAuthenticationSessionResponse, BuddyAuthenticationSessionErrors> {
        let url = baseURL.appending(path: "session")

        return await makeAuthorizedGetRequest(url: url)
            .mapError { error in
                switch error {
                case let .badRequest(data):
                    return .badRequest(data: data)
                case let .clientError(data, response):
                    return .undocumentedError(statusCode: response.statusCode, payload: data)
                case .decodingError:
                    return .internalServerError(context: error)
                case let .unauthorized(data):
                    state.invalidateAuthorizationToken()

                    return .unauthorized(response: data)
                case let .notFound(data):
                    return .undocumentedError(statusCode: 404, payload: data)
                case .internalServerError:
                    return .internalServerError(context: error)
                }
            }
    }

    public func login(email: String, password: String) async -> Result<Void, BuddyAuthenticationLoginErrors> {
        let output: Operations.LoginAppApiV1AuthLoginPost.Output
        do {
            output = try await client
                .loginAppApiV1AuthLoginPost(body: .urlEncodedForm(.init(email: email, password: password)))
        } catch {
            return .failure(.internalServerError(context: error))
        }

        switch output {
        case .unprocessableContent(let unprocessableResponse):
            switch unprocessableResponse.body {
            case let .json(unprocessableJSONResponse):
                let encodedResponse = try? jsonEncoder.encode(unprocessableJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .unauthorized(unauthorizedResponse):
            switch unauthorizedResponse.body {
            case let .json(unauthorizedJSONResponse):
                let encodedResponse = try? jsonEncoder.encode(unauthorizedJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .undocumented(statusCode, payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        case let .ok(response):
            switch response.body {
            case let .json(jsonResponse):
                state.setAuthorizationToken(AuthorizationToken(
                    accessToken: jsonResponse.accessToken,
                    refreshToken: jsonResponse.refreshToken,
                    expiryTimestamp: jsonResponse.expiryTimestamp)
                )

                return .success(())
            }
        }
    }

    public func register(email: String, password: String) async -> Result<Void, BuddyAuthenticationRegisterErrors> {
        let output: Operations.RegisterAppApiV1AuthRegisterPost.Output
        do {
            output = try await client
                .registerAppApiV1AuthRegisterPost(body: .urlEncodedForm(.init(email: email, password: password)))
        } catch {
            return .failure(.internalServerError(context: error))
        }

        switch output {
        case .unprocessableContent(let unprocessableResponse):
            switch unprocessableResponse.body {
            case let .json(unprocessableJSONResponse):
                let encodedResponse = try? jsonEncoder.encode(unprocessableJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .conflict(conflictResponse):
            switch conflictResponse.body {
            case let .json(conflictJSONResponse):
                let encodedResponse = try? jsonEncoder.encode(conflictJSONResponse)
                return .failure(.conflict(response: encodedResponse))
            }
        case let .undocumented(statusCode, payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        case let .created(response):
            switch response.body {
            case .json:
                return .success(())
            }
        }
    }
}

public enum BuddyAuthenticationLoginErrors: Error {
    case internalServerError(context: Error)
    case badRequest(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}

public enum BuddyAuthenticationSessionErrors: Error {
    case internalServerError(context: Error?)
    case unauthorized(response: Data?)
    case badRequest(data: Data)
    case undocumentedError(statusCode: Int, payload: Data)
}

public enum BuddyAuthenticationRegisterErrors: Error {
    case internalServerError(context: Error)
    case badRequest(response: Data?)
    case conflict(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}
