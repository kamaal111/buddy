//
//  Authentication.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import OSLog
import Foundation
import BuddyClient

public final class Authentication: @unchecked Sendable, ObservableObject {
    @Published private(set) var initiallyValidatingToken = true
    @Published private var session: LoggedInSession?

    private let client = BuddyClient.shared
    private let logger = Logger(subsystem: ModuleConfig.identifier, category: String(describing: Authentication.self))
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private var authorizationToken: AuthorizationToken?

    public init() {
        if let authorizationToken = getAuthorizationTokenFromKeychain() {
            setAuthorizationToken(authorizationToken)
            Task {
                _ = await loadSession()
                DispatchQueue.main.async { [weak self] in
                    self?.initiallyValidatingToken = false
                }
            }
        } else {
            self.initiallyValidatingToken = false
        }
    }

    var isLoggedIn: Bool {
        session != nil
    }

    func login(email: String, password: String) async -> Result<Void, AuthenticationLoginErrors> {
        assert(email.trimmingCharacters(in: .whitespacesAndNewlines).count == email.count)
        assert(!email.isEmpty)
        assert(!password.isEmpty)

        let result = await client.authentication.login(email: email, password: password)
            .mapError { error -> AuthenticationLoginErrors in
                logger.warning("Failed to log in user; error='\(error)'")
                switch error {
                case .internalServerError:
                    return .generalFailure(context: error)
                case .badRequest:
                    return .invalidCredentials(context: error)
                case let .undocumentedError(statusCode, payload):
                    assert(statusCode < 500, "Undocumented error found that could have been documented; statusCode='\(statusCode)'; payload='\(payload)'")
                    return .generalFailure(context: error)
                }
            }
        let response: BuddyAuthenticationLoginResponse
        switch result {
        case let .failure(failure): return .failure(failure)
        case let .success(sucess): response = sucess
        }

        let authorizationToken = AuthorizationToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiryTimestamp: response.expiryTimestamp
        )
        setAuthorizationToken(authorizationToken)

        return await loadSession()
            .mapError { error -> AuthenticationLoginErrors in
                switch error {
                case .serverUnavailable:
                    return .generalFailure(context: error)
                case .unauthorized:
                    return .invalidCredentials(context: error)
                }
            }
    }

    func signUp(email: String, password: String) async -> Result<Void, AuthenticationSignUpErrors> {
        await client.authentication.register(email: email, password: password)
            .mapError { error -> AuthenticationSignUpErrors in
                logger.warning("Failed to sign up user; error='\(error)'")
                switch error {
                case .internalServerError:
                    return .generalFailure(context: error)
                case .badRequest:
                    return .invalidCredentials(context: error)
                case let .undocumentedError(statusCode, payload):
                    assert(
                        statusCode < 500,
                        "Undocumented error found that could have been documented; statusCode='\(statusCode)'; payload='\(payload)'"
                    )
                    return .generalFailure(context: error)
                case .conflict:
                    return .userAlreadyExists(context: error)
                }
            }
    }

    func withUpToDateAuthorizationToken<T>(
        _ callback: (_ authorizationToken: AuthorizationToken?) async -> T
    ) async -> T {
        guard let authorizationToken else {
            logger.error("Authorization token not set for some reason")
            assertionFailure()
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

    private func getAuthorizationTokenFromKeychain() -> AuthorizationToken? {
        guard let authorizationTokenData = try? Keychain.get(forKey: KeychainKeys.authorizationToken.key).get()
        else { return nil}

        do {
            return try jsonDecoder.decode(AuthorizationToken.self, from: authorizationTokenData)
        } catch {
            logger.error("Failed to decode authorization token; error='\(error)'")
            Task { await invalidateAuthorizationToken() }
            assertionFailure()
            return nil
        }
    }

    @MainActor
    private func setSession(_ session: LoggedInSession) {
        self.session = session
    }

    @MainActor
    private func invalidateAuthorizationToken() {
        Keychain.delete(forKey: KeychainKeys.authorizationToken.key)
        session = nil
        authorizationToken = nil
    }

    private func loadSession() async -> Result<Void, LoadSessionErorrs> {
        await withUpToDateAuthorizationToken { authorizationToken in
            guard let authorizationToken else {
                logger.error("Authorization token not retrieved for some reason")
                assertionFailure()
                return .failure(.unauthorized(context: nil))
            }

            let result = await client.authentication.session(authorization: authorizationToken.accessToken)
                .mapError { error -> LoadSessionErorrs in
                    switch error {
                    case .internalServerError:
                        return .serverUnavailable(context: error)
                    case .unauthorized:
                        Task { await invalidateAuthorizationToken() }
                        return .unauthorized(context: error)
                    case .undocumentedError(let statusCode, let payload):
                        assert(
                            statusCode < 500,
                            "Undocumented error found that could have been documented; statusCode='\(statusCode)'; payload='\(payload)'"
                        )
                        return .serverUnavailable(context: error)
                    }
                }
            let response: BuddyAuthenticationSessionResponse
            switch result {
            case let .failure(failure): return .failure(failure)
            case let .success(success): response = success
            }

            await setSession(.init(user: .init(email: response.user.email)))

            return .success(())
        }
    }

    private func refreshTokenIfExpired(
        authorizationToken: AuthorizationToken
    ) async -> Result<AuthorizationToken, LoadSessionErorrs> {
        let timeleft = authorizationToken.expiryTimestamp - Int(Date.now.timeIntervalSince1970)
        guard timeleft < 30 else { return .success(authorizationToken) }

        let result = await client.authentication.refresh(
            authorization: authorizationToken.accessToken,
            refreshToken: authorizationToken.refreshToken
        )
            .mapError { error -> LoadSessionErorrs in
                switch error {
                case .internalServerError:
                    return .serverUnavailable(context: error)
                case .unauthorized:
                    Task { await invalidateAuthorizationToken() }
                    return .unauthorized(context: error)
                case .undocumentedError(let statusCode, let payload):
                    assert(
                        statusCode < 500,
                        "Undocumented error found that could have been documented; statusCode='\(statusCode)'; payload='\(payload)'"
                    )
                    return .serverUnavailable(context: error)
                }
            }

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
        setAuthorizationToken(updatedAuthorizationToken)

        return .success(updatedAuthorizationToken)
    }

    private func setAuthorizationToken(_ authorizationToken: AuthorizationToken) {
        defer { self.authorizationToken = authorizationToken }

        let authorizationTokenData: Data
        do {
            authorizationTokenData = try jsonEncoder.encode(authorizationToken)
        } catch {
            logger.error("Failed to encode authorization token; error='\(error)'")
            assertionFailure()
            return
        }

        let keychainSetResult = Keychain.set(authorizationTokenData, forKey: KeychainKeys.authorizationToken.key)
        switch keychainSetResult {
        case let .failure(failure):
            logger.error("Failed to set authorization token in keychain; error='\(failure)'")
            assertionFailure()
        case .success: break
        }
    }
}

enum AuthenticationLoginErrors: Error {
    case invalidCredentials(context: Error)
    case generalFailure(context: Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return NSLocalizedString("Invalid credentials provided.", comment: "")
        case .generalFailure:
            return NSLocalizedString("Failed to log in.", comment: "")
        }
    }
}

enum AuthenticationSignUpErrors: Error {
    case userAlreadyExists(context: Error)
    case invalidCredentials(context: Error)
    case generalFailure(context: Error)

    var errorDescription: String? {
        switch self {
        case .userAlreadyExists:
            return NSLocalizedString("User with the same email already exists.", comment: "")
        case .invalidCredentials:
            return NSLocalizedString("Invalid credentials provided.", comment: "")
        case .generalFailure:
            return NSLocalizedString("Failed to sign up.", comment: "")
        }
    }
}

private enum LoadSessionErorrs: Error {
    case serverUnavailable(context: Error?)
    case unauthorized(context: Error?)

    var errorDescription: String? {
        switch self {
        case .serverUnavailable:
            return NSLocalizedString("Failed to load session.", comment: "")
        case .unauthorized:
            return NSLocalizedString("Session expired, please log in again.", comment: "")
        }
    }
}

private enum KeychainKeys: String {
    case authorizationToken

    var key: String {
        "\(ModuleConfig.identifier).Keychain.\(rawValue)"
    }
}
