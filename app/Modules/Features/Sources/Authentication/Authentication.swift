//
//  Authentication.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import OSLog
import Foundation
import BuddyClient

final public class Authentication: @unchecked Sendable, ObservableObject {
    @Published private(set) var initiallyValidatingToken: Bool
    @Published private var session: [String: String]?

    private let client = BuddyClient()
    private let logger = Logger(subsystem: ModuleConfig.identifier, category: String(describing: Authentication.self))

    public init() {
        if let authorizationToken = try? Keychain.get(forKey: KeychainKeys.authorizationToken.key).get() {
            self.initiallyValidatingToken = true
            Task { await loadSession(authorizationToken: authorizationToken) }
        } else {
            self.initiallyValidatingToken = false
        }
    }

    var isLoggedIn: Bool {
        session != nil
    }

    func login(email: String, password: String) async -> Result<Void, AuthenticationSignUpErrors> {
        let result = await client.authentication.login(email: email, password: password)
            .mapError { error -> AuthenticationSignUpErrors in
                logger.error("Failed to log in user; error='\(error)'")
                switch error {
                case .internalServerError:
                    return .generalFailure(context: error)
                case .badRequest:
                    return .invalidCredentials(context: error)
                case .undocumentedError:
                    return .generalFailure(context: error)
                }
            }
        let response: BuddyAuthenticationLoginResponse
        switch result {
        case let .failure(failure): return .failure(failure)
        case let .success(sucess): response = sucess
        }

        print("🐸🐸🐸 response", response)

        return .success(())
    }

    func signUp(email: String, password: String) async -> Result<Void, AuthenticationSignUpErrors> {
        await client.authentication.register(email: email, password: password)
            .mapError { error -> AuthenticationSignUpErrors in
                logger.error("Failed to sign up user; error='\(error)'")
                switch error {
                case .internalServerError:
                    return .generalFailure(context: error)
                case .badRequest:
                    return .invalidCredentials(context: error)
                case .undocumentedError:
                    return .generalFailure(context: error)
                case .conflict:
                    return .userAlreadyExists(context: error)
                }
            }
    }

    private func loadSession(authorizationToken: String) async { }
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

private enum KeychainKeys: String {
    case authorizationToken

    var key: String {
        "\(ModuleConfig.identifier).Keychain.\(rawValue)"
    }
}
