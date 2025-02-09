//
//  BuddyHealthClient.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/9/25.
//

import OpenAPIRuntime

public struct BuddyHealthClient: Sendable {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    public func ping() async -> Result<PingResponse, BuddyHealthPingErrors> {
        let result: Operations.GetHealthPing.Output
        do {
            result = try await client.getHealthPing()
        } catch {
            return .failure(.internalServerError(context: error))
        }

        let data: Operations.GetHealthPing.Output.Ok.Body.JsonPayload
        switch result {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let jsonResponse):
                data = jsonResponse
            }
        case .undocumented(statusCode: let statusCode, let payload):
            return .failure(.undocumentedError(statusCode: statusCode, payload: payload))
        }

        return .success(PingResponse(details: data.details.rawValue))
    }
}

public struct PingResponse: Codable, Sendable {
    public let details: String
}

public enum BuddyHealthPingErrors: Error {
    case internalServerError(context: Error)
    case undocumentedError(statusCode: Int, payload: UndocumentedPayload)
}
