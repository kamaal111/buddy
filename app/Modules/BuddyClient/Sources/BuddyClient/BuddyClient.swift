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
    public let llm: BuddyLLMClient

    private let state = BuddyClientState()

    private init() {
        let client = Client(serverURL: ModuleConfig.baseURL, transport: URLSessionTransport())
        self.health = BuddyHealthClient(client: client)
        self.authentication = BuddyAuthenticationClient(client: client, state: state)
        self.llm = BuddyLLMClient(state: state)
    }

    public static let shared = BuddyClient()
}
