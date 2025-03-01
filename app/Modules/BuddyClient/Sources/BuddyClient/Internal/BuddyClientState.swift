//
//  BuddyClientState.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 3/1/25.
//

import OSLog
import Foundation

struct AuthorizationToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiryTimestamp: Int
}

final class BuddyClientState: @unchecked Sendable {
    private(set) var authorizationToken: AuthorizationToken?

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let logger = Logger(subsystem: ModuleConfig.identifier, category: String(describing: BuddyClientState.self))

    init() {
        if let authorizationTokenData = try? Keychain.get(forKey: KeychainKeys.authorizationToken.key).get(),
           let authorizationToken = try? jsonDecoder.decode(AuthorizationToken.self, from: authorizationTokenData) {
            self.authorizationToken = authorizationToken
        }
    }

    func invalidateAuthorizationToken() {
        defer { self.authorizationToken = nil }

        Keychain.delete(forKey: KeychainKeys.authorizationToken.key)
    }

    func setAuthorizationToken(_ authorizationToken: AuthorizationToken) {
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

private enum KeychainKeys: String {
    case authorizationToken

    var key: String {
        "\(ModuleConfig.identifier).BuddyClientState.Keychain.\(rawValue)"
    }
}
