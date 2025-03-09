//
//  BuddyAuthorizedClientable.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 3/1/25.
//

import Foundation
import KamaalExtensions

protocol BuddyAuthorizedClientable: BuddyClientable {
    var state: BuddyClientState { get }
    var jsonEncoder: JSONEncoder { get }
    var jsonDecoder: JSONDecoder { get }
}

extension BuddyAuthorizedClientable {
    func makeAuthorizedGetRequest<T: Decodable>(
        url: URL,
        headers: [String: String] = [:]
    ) async -> Result<T, ClientRequestError> {
        await withUpToDateAuthorizationHeaders { authorizedHeaders in
            await makeGetRequest(url: url, headers: (authorizedHeaders ?? [:]).merged(with: headers))
        }
    }

    func makeAuthorizedPostRequest<Response: Decodable, Payload: Encodable>(
        url: URL,
        payload: Payload,
        headers: [String: String] = [:]
    ) async -> Result<Response, ClientRequestError> {
        await withUpToDateAuthorizationHeaders { authorizedHeaders in
            await makePostRequest(
                url: url,
                payload: payload,
                headers:  (authorizedHeaders ?? [:]).merged(with: headers)
            )
        }
    }

    func withUpToDateAuthorizationHeaders<T>(_ callback: (_ headers: [String: String]?) async -> T) async -> T {
        await withUpToDateAuthorizationToken { authorizationToken in
            guard let authorizationToken = state.authorizationToken else { return await callback(nil) }

            return await callback(makeAuthorizedHeaders(authorizationToken: authorizationToken))
        }
    }

    func withUpToDateAuthorizationToken<T>(
        _ callback: (_ authorizationToken: AuthorizationToken?) async -> T
    ) async -> T {
        guard let authorizationToken = state.authorizationToken else {
            assertionFailure("Authorization token not set for some reason")
            return await callback(nil)
        }

        let updatedAuthorizationToken: AuthorizationToken
        do {
            updatedAuthorizationToken = try await refreshTokenIfExpired(authorizationToken: authorizationToken).get()
        } catch {
            return await callback(authorizationToken)
        }

        return await callback(updatedAuthorizationToken)
    }

    private func makeAuthorizedHeaders(authorizationToken: AuthorizationToken) -> [String: String] {
        [
            "Authorization": "Bearer \(authorizationToken.accessToken)",
            "Content-Type": "application/json"
        ]
    }

    private func refreshTokenIfExpired(
        authorizationToken: AuthorizationToken
    ) async -> Result<AuthorizationToken, BuddyAuthenticationRefreshErrors> {
        let timeleft = authorizationToken.expiryTimestamp - Int(Date.now.timeIntervalSince1970)
        guard timeleft < 30 else { return .success(authorizationToken) }

        let result = await refresh()

        let response: BuddyAuthenticationRefreshResponse
        switch result {
        case let .failure(failure):
            return .failure(failure)
        case let .success(success): response = success
        }

        let updatedAuthorizationToken = AuthorizationToken(
            accessToken: response.accessToken,
            refreshToken: authorizationToken.refreshToken,
            expiryTimestamp: response.expiryTimestamp
        )
        state.setAuthorizationToken(updatedAuthorizationToken)

        return .success(updatedAuthorizationToken)
    }

    private func refresh() async -> Result<BuddyAuthenticationRefreshResponse, BuddyAuthenticationRefreshErrors> {
        guard let authorizationToken = state.authorizationToken else { return .failure(.unauthorized(response: nil)) }

        let url = ModuleConfig.authBaseURL.appending(path: "refresh")
        let payload = BuddyAuthenticationRefreshPayload(refreshToken: authorizationToken.refreshToken)
        let headers = makeAuthorizedHeaders(authorizationToken: authorizationToken)

        return await makePostRequest(url: url, payload: payload, headers: headers)
            .mapError { error in
                switch error {
                case let .unauthorized(data):
                    return .unauthorized(response: data)
                case let .badRequest(data):
                    return .unauthorized(response: data)
                case let .clientError(data, response):
                    return .undocumentedError(statusCode: response.statusCode, payload: data)
                case let .notFound(data):
                    return .undocumentedError(statusCode: 404, payload: data)
                case .decodingError, .internalServerError:
                    return .internalServerError(context: error)
                }
            }
    }
}

private struct BuddyAuthenticationRefreshResponse: Codable, Sendable {
    let accessToken: String
    let expiryTimestamp: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiryTimestamp = "expiry_timestamp"
    }
}

private enum BuddyAuthenticationRefreshErrors: Error {
    case internalServerError(context: Error?)
    case unauthorized(response: Data?)
    case undocumentedError(statusCode: Int, payload: Data)
}

private struct BuddyAuthenticationRefreshPayload: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}
