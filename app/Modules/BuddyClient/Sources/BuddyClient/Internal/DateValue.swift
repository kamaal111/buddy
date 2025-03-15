//
//  DateValue.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 3/15/25.
//

import Foundation

public protocol DateValueCodableStrategy {
    associatedtype RawValue: Codable

    static func decode(_ value: RawValue) throws -> Date
    static func encode(_ date: Date) -> RawValue
}

public struct ISO8601Strategy: DateValueCodableStrategy {
    public typealias RawValue = String

    public static func decode(_ value: String) throws -> Date {
        let formatter = makeFormatter()
        guard let date = formatter.date(from: value) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid date format: \(value)"))
        }

        return date
    }

    public static func encode(_ date: Date) -> String {
        let formatter = makeFormatter()

        return formatter.string(from: date)
    }

    private static func makeFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return formatter
    }
}

@propertyWrapper
public struct DateValue<Formatter: DateValueCodableStrategy>: Codable {
    public var wrappedValue: Date

    private let value: Formatter.RawValue

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
        self.value = Formatter.encode(wrappedValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Formatter.RawValue.self)
        self.wrappedValue = try Formatter.decode(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Formatter.encode(wrappedValue))
    }
}
