//
//  Keychain.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import Security
import Foundation

enum KeychainSetErrors: Error {
    case generalError(status: OSStatus)
}

enum KeychainGetErrors: Error {
    case generalError(status: OSStatus)
}

enum KeychainDeleteErrors: Error {
    case generalError(status: OSStatus)
}

struct Keychain {
    private init() { }

    static func set(_ data: Data, forKey key: String) -> Result<Void, KeychainSetErrors> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ] as CFDictionary
        let status = SecItemAdd(query, nil)
        guard status != errSecDuplicateItem else { return update(data, forKey: key) }
        guard status == errSecSuccess else { return .failure(.generalError(status: status)) }

        return .success(())
    }

    static func get(forKey key: String) -> Result<Data?, KeychainGetErrors> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        guard status == errSecSuccess else { return .failure(.generalError(status: status)) }
        guard let data = dataTypeRef as? Data else { return .success(nil) }

        return .success(data)
    }

    @discardableResult
    static func delete(forKey key: String) -> Result<Void, KeychainDeleteErrors> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ] as CFDictionary
        let status = SecItemDelete(query)
        guard status == errSecSuccess else { return .failure(.generalError(status: status)) }

        return .success(())
    }

    private static func update(_ data: Data, forKey key: String) -> Result<Void, KeychainSetErrors> {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ] as CFDictionary
        let attributes = [kSecValueData as String: data] as CFDictionary
        let status = SecItemUpdate(query, attributes)
        guard status == errSecSuccess else { return .failure(.generalError(status: status)) }

        return .success(())
    }
}
