//
//  BuddyClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/9/25.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public final class BuddyClient: Sendable {
    public let health: BuddyHealthClient
    public let authentication: BuddyAuthenticationClient

    private init() {
        let client = Client(serverURL: URL(string: "http://localhost:8000")!, transport: URLSessionTransport())
        self.health = BuddyHealthClient(client: client)
        self.authentication = BuddyAuthenticationClient(client: client)
    }

    public static let shared = BuddyClient()
}
