//
//  AuthorizationToken.swift
//  Features
//
//  Created by Kamaal M Farah on 2/23/25.
//

public struct AuthorizationToken: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiryTimestamp: Int
}
