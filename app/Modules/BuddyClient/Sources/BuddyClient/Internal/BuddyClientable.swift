//
//  BuddyClientable.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 3/8/25.
//

import Foundation

protocol BuddyClientable {
    var jsonEncoder: JSONEncoder { get }
    var jsonDecoder: JSONDecoder { get }
}

enum ClientRequestError: Error {
    case internalServerError(context: Error?)
    case clientError(data: Data, response: HTTPURLResponse)
    case decodingError(data: Data, error: Error)
    case unauthorized(data: Data)
    case badRequest(data: Data)
    case notFound(data: Data)
}

extension BuddyClientable {
    func makeGetRequest<T: Decodable>(
        url: URL,
        headers: [String: String] = [:]
    ) async -> Result<T, ClientRequestError> {
        await makeRequest(url: url, method: .get, payload: nil, headers: headers)
    }

    func makePostRequest<Response: Decodable, Payload: Encodable>(
        url: URL,
        payload: Payload,
        headers: [String: String] = [:]
    ) async -> Result<Response, ClientRequestError> {
        await makeRequest(url: url, method: .post, payload: try? jsonEncoder.encode(payload), headers: headers)
    }

    private func makeRequest<T: Decodable>(
        url: URL,
        method: BuddyClientMethods,
        payload: Data?,
        headers: [String: String]
    ) async -> Result<T, ClientRequestError> {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpBody = payload
        request.httpMethod = method.rawValue

        let output: (Data, URLResponse)
        do {
            output = try await URLSession.shared.data(for: request)
        } catch {
            return .failure(.internalServerError(context: error))
        }

        let (data, response) = output
        guard let httpResponse = response as? HTTPURLResponse
        else { return .failure(.internalServerError(context: nil)) }

        switch httpResponse.statusCode {
        case let statusCode where statusCode < 300: break
        case 401, 403: return .failure(.unauthorized(data: data))
        case 400, 422: return .failure(.badRequest(data: data))
        default: return .failure(.clientError(data: data, response: httpResponse))
        }

        let parsedData: T
        do {
            parsedData = try jsonDecoder.decode(T.self, from: data)
        } catch {
            return .failure(.decodingError(data: data, error: error))
        }

        return .success(parsedData)
    }
}

private enum BuddyClientMethods: String {
    case get = "GET"
    case post = "POST"
}
