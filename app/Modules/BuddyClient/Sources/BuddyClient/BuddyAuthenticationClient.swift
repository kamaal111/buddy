//
//  BuddyAuthenticationClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/19/25.
//

import Foundation
import OpenAPIRuntime

public struct BuddyAuthenticationClient {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    public func register(email: String, password: String) async -> Result<Void, BuddyAuthenticationRegisterErrors> {
        let output: Operations.RegisterAppApiV1AuthRegisterPost.Output
        do {
            output = try await client.registerAppApiV1AuthRegisterPost(
                body: .urlEncodedForm(.init(email: email, password: password))
            )
        } catch {
            return .failure(.internalServerError(context: error))
        }

        switch output {
        case .unprocessableContent(let unprocessableResponse):
            switch unprocessableResponse.body {
            case let .json(unprocessableJSONResponse):
                let encodedResponse = try? JSONEncoder().encode(unprocessableJSONResponse)
                return .failure(.badRequest(response: encodedResponse))
            }
        case let .undocumented(statusCode, payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        case let .created(response):
            switch response.body {
            case .json:
                return .success(())
            }
        }
    }
}

public enum BuddyAuthenticationRegisterErrors: Error {
    case internalServerError(context: Error)
    case badRequest(response: Data?)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}
