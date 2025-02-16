//
//  Authentication.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import Foundation

public enum AuthenticationSignUpErrors: Error {
    case userAlreadyExists
    case invalidCredentials
    case generalFailure(context: Error)
}

final public class Authentication: @unchecked Sendable, ObservableObject {
    @Published private(set) var initiallyValidatingToken: Bool
    @Published private var session: [String: String]?

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

    func signUp(email: String, password: String) async -> Result<Void, AuthenticationSignUpErrors> {
        return .success(())
    }

    private func loadSession(authorizationToken: String) async { }
}

private enum KeychainKeys: String {
    case authorizationToken

    var key: String {
        "\(Bundle.main.bundleIdentifier!).Authentication.Keychain.\(rawValue)"
    }
}
