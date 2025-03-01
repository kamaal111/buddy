//
//  LoggedInSession.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/23/25.
//

public struct LoggedInSession {
    public let user: User
    public let availableModels: [LLMModel]

    public struct User {
        public let email: String
    }
}
