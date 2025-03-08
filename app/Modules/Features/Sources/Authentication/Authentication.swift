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
    @Published public private(set) var session: LoggedInSession?

    private let client = BuddyClient.shared
    private let logger = Logger(subsystem: ModuleConfig.identifier, category: String(describing: Authentication.self))
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

    public init() {
        if client.authentication.isAuthorized {
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
        switch result {
        case let .failure(failure): return .failure(failure)
        case .success: break
        }

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

    @MainActor
    private func setSession(_ session: LoggedInSession) {
        self.session = session
    }

    @MainActor
    private func unsetSession() {
        session = nil
    }

    private func loadSession() async -> Result<Void, LoadSessionErorrs> {
        let result = await client.authentication.session()
            .mapError { error -> LoadSessionErorrs in
                switch error {
                case .internalServerError:
                    return .serverUnavailable(context: error)
                case .unauthorized, .badRequest:
                    Task { await unsetSession() }
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

        let availableModels = response.availableModels.map({ availableModel in
            LLMModel(
                provider: availableModel.provider,
                key: availableModel.key,
                displayName: availableModel.displayName,
                description: availableModel.description
            )
        })
        await setSession(.init(user: .init(email: response.user.email), availableModels: availableModels))

        return .success(())
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
