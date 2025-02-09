//
//  BuddyClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/9/25.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public struct BuddyClient: Sendable {
    public let health: BuddyHealthClient

    private let client: Client

    public init() {
        self.client = Client(
            serverURL: URL(string: "http://localhost:8080")!,
            transport: URLSessionTransport()
        )
        self.health = BuddyHealthClient(client: self.client)
    }
}
