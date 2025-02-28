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
    public let availableModels: [AvailableModel]

    public struct User: Codable, Sendable {
        public let email: String
    }

    public struct AvailableModel: Codable, Sendable {
        public let provider: String
        public let key: String
    }

    enum CodingKeys: String, CodingKey {
        case user
        case availableModels = "available_models"
    }
}

public struct BuddyAuthenticationRefreshResponse: Codable, Sendable {
    public let accessToken: String
    public let expiryTimestamp: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiryTimestamp = "expiry_timestamp"
    }
}

public struct BuddyAuthenticationClient: Sendable {
    private let client: Client
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private let baseURL = ModuleConfig.baseURL
        .appending(path: "app-api/v1/auth")

    init(client: Client) {
        self.client = client
    }

    public func refresh(
        authorization: String,
        refreshToken: String
    ) async -> Result<BuddyAuthenticationRefreshResponse, BuddyAuthenticationRefreshErrors> {
        let payload = try! jsonEncoder.encode(BuddyAuthenticationRefreshPayload(refreshToken: refreshToken))

        let url = baseURL.appending(path: "refresh")
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = ["Authorization": "Bearer \(authorization)"]
        request.httpBody = payload
        request.httpMethod = "POST"
        let output: (Data, URLResponse)
        do {
            output = try await URLSession.shared.data(for: request)
        } catch {
            return .failure(.internalServerError(context: error))
        }

        let (data, response) = output
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode
        else { return .failure(.internalServerError(context: nil)) }

        switch statusCode {
        case 422, 401: return .failure(.unauthorized(response: data))
        case let statusCode where statusCode < 300: break
        default: return .failure(.undocumentedError(statusCode: statusCode, payload: data))
        }

        let refreshedToken: BuddyAuthenticationRefreshResponse
        do {
            refreshedToken = try jsonDecoder.decode(BuddyAuthenticationRefreshResponse.self, from: data)
        } catch {
            return .failure(.internalServerError(context: error))
        }

        return .success(refreshedToken)
    }

    public func session(
        authorization: String
    ) async -> Result<BuddyAuthenticationSessionResponse, BuddyAuthenticationSessionErrors> {
        let url = baseURL.appending(path: "session")
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = ["Authorization": "Bearer \(authorization)"]
        let output: (Data, URLResponse)
        do {
            output = try await URLSession.shared.data(for: request)
        } catch {
            return .failure(.internalServerError(context: error))
        }

        let (data, response) = output
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode
        else { return .failure(.internalServerError(context: nil)) }

        switch statusCode {
        case 422, 401: return .failure(.unauthorized(response: data))
        case let statusCode where statusCode < 300: break
        default: return .failure(.undocumentedError(statusCode: statusCode, payload: data))
        }

        let session: BuddyAuthenticationSessionResponse
        do {
            session = try jsonDecoder.decode(BuddyAuthenticationSessionResponse.self, from: data)
        } catch {
            return .failure(.internalServerError(context: error))
        }

        return .success(session)
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
    case internalServerError(context: Error?)
    case unauthorized(response: Data?)
    case undocumentedError(statusCode: Int, payload: Data)
}

public enum BuddyAuthenticationRefreshErrors: Error {
    case internalServerError(context: Error?)
    case unauthorized(response: Data?)
    case undocumentedError(statusCode: Int, payload: Data)
}

public enum BuddyAuthenticationRegisterErrors: Error {
    case internalServerError(context: Error)
    case badRequest(response: Data?)
    case conflict(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}

private struct BuddyAuthenticationRefreshPayload: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
