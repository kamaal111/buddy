//
//  BuddyAuthenticationClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/19/25.
//

import Foundation
import OpenAPIRuntime

public struct BuddyAuthenticationLoginResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiryTimestamp: Int
}

public struct BuddyAuthenticationSessionResponse: Codable, Sendable {
    public let user: User

    public struct User: Codable, Sendable {
        public let email: String
    }
}

public struct BuddyAuthenticationRefreshResponse: Codable, Sendable {
    public let accessToken: String
    public let expiryTimestamp: Int
}

public struct BuddyAuthenticationClient: Sendable {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    public func refresh(
        authorization: String,
        refreshToken: String
    ) async -> Result<BuddyAuthenticationRefreshResponse, BuddyAuthenticationRefreshErrors> {
        let output: Operations.RefreshAppApiV1AuthRefreshPost.Output
        do {
            output = try await client.refreshAppApiV1AuthRefreshPost(
                headers: .init(headers: .init(authorization: authorization)),
                body: .json(.init(refreshToken: refreshToken))
            )
        } catch {
            return .failure(.internalServerError(context: error))
        }

        switch output {
        case let .unprocessableContent(unprocessableResponse):
            switch unprocessableResponse.body {
            case let .json(unprocessableJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(unprocessableJSONResponse)
                return .failure(.unauthorized(response: encodedResponse))
            }
        case let .unauthorized(unauthorizedResponse):
            switch unauthorizedResponse.body {
            case let .json(unauthorizedJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(unauthorizedJSONResponse)
                return .failure(.unauthorized(response: encodedResponse))
            }
        case let .undocumented(statusCode, payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        case let .ok(response):
            switch response.body {
            case let .json(jsonResponse):
                return .success(.init(
                    accessToken: jsonResponse.accessToken,
                    expiryTimestamp: jsonResponse.expiryTimestamp
                ))
            }
        }
    }

    public func session(
        authorization: String
    ) async -> Result<BuddyAuthenticationSessionResponse, BuddyAuthenticationSessionErrors> {
        let output: Operations.SessionAppApiV1AuthSessionGet.Output
        do {
            output = try await client
                .sessionAppApiV1AuthSessionGet(headers: .init(headers: .init(authorization: authorization)))
        } catch {
            return .failure(.internalServerError(context: error))
        }

        switch output {
        case let .unprocessableContent(unprocessableResponse):
            switch unprocessableResponse.body {
            case let .json(unprocessableJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(unprocessableJSONResponse)
                return .failure(.unauthorized(response: encodedResponse))
            }
        case let .unauthorized(unauthorizedResponse):
            switch unauthorizedResponse.body {
            case let .json(unauthorizedJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(unauthorizedJSONResponse)
                return .failure(.unauthorized(response: encodedResponse))
            }
        case let .undocumented(statusCode, payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        case let .ok(response):
            switch response.body {
            case let .json(jsonResponse):
                return .success(.init(user: .init(email: jsonResponse.user.email)))
            }
        }
    }

    public func login(
        email: String,
        password: String
    ) async -> Result<BuddyAuthenticationLoginResponse, BuddyAuthenticationLoginErrors> {
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
                let encodedResponse = try? JSONEncoder().encode(unprocessableJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .unauthorized(unauthorizedResponse):
            switch unauthorizedResponse.body {
            case let .json(unauthorizedJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(unauthorizedJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .undocumented(statusCode, payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        case let .ok(response):
            switch response.body {
            case let .json(jsonResponse):
                return .success(BuddyAuthenticationLoginResponse(
                    accessToken: jsonResponse.accessToken,
                    refreshToken: jsonResponse.refreshToken,
                    expiryTimestamp: jsonResponse.expiryTimestamp
                ))
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
                let encodedResponse = try? JSONEncoder().encode(unprocessableJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .conflict(conflictResponse):
            switch conflictResponse.body {
            case let .json(conflictJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(conflictJSONResponse)
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
    case internalServerError(context: Error)
    case unauthorized(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}

public enum BuddyAuthenticationRefreshErrors: Error {
    case internalServerError(context: Error)
    case unauthorized(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}

public enum BuddyAuthenticationRegisterErrors: Error {
    case internalServerError(context: Error)
    case badRequest(response: Data?)
    case conflict(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}
