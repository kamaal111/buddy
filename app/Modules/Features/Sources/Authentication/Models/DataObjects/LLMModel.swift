//
//  LLMModel.swift
//  Features
//
//  Created by Kamaal M Farah on 3/1/25.
//

public struct LLMModel: Hashable, Codable, Identifiable {
    public let provider: String
    public let key: String
    public let displayName: String
    public let description: String

    public var id: String { key }
}
