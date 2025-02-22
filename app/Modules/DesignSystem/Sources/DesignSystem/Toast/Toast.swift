//
//  Toast.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

@usableFromInline
let TOAST_DEFAULT_DURATION: Double = 3

@usableFromInline
let TOAST_DEFAULT_WIDTH: CGFloat = .infinity

public struct Toast: Equatable {
    public let style: ToastStyle
    public let message: String
    public let duration: Double
    public let width: CGFloat

    init(
        style: ToastStyle,
        message: String,
        duration: Double = TOAST_DEFAULT_DURATION,
        width: CGFloat = TOAST_DEFAULT_WIDTH
    ) {
        self.style = style
        self.message = message
        self.duration = duration
        self.width = width
    }

    public static func error(
        message: String,
        duration: Double = TOAST_DEFAULT_DURATION,
        width: CGFloat = TOAST_DEFAULT_WIDTH
    ) -> Self {
        .init(style: .error, message: message, duration: duration, width: width)
    }

    public static func success(
        message: String,
        duration: Double = TOAST_DEFAULT_DURATION,
        width: CGFloat = TOAST_DEFAULT_WIDTH
    ) -> Self {
        .init(style: .success, message: message, duration: duration, width: width)
    }
}

public enum ToastStyle {
    case error
    case warning
    case success
    case info

    public var color: Color {
        switch self {
        case .error: .red
        case .warning: .orange
        case .info: .blue
        case .success: .green
        }
    }

    public var imageSystemName: String {
        switch self {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        }
    }
}
