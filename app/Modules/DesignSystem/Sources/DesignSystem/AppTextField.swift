//
//  File.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

public struct AppTextField: View {
    @Binding public var text: String

    public let title: String
    public let textFieldType: TextFieldType

    public init(text: Binding<String>, title: String, textFieldType: TextFieldType = .text) {
        self._text = text
        self.title = title
        self.textFieldType = textFieldType
    }

    public enum TextFieldType {
        case text
        case decimals
        case numbers

        #if canImport(UIKit)
        var keyboardType: UIKeyboardType {
            switch self {
            case .decimals: return .decimalPad
            case .numbers: return .numberPad
            case .text: return .default
            }
        }
        #endif
    }

    public var body: some View {
        FloatingFieldWrapper(text: text, title: title, field: {
            #if canImport(UIKit)
            TextField("", text: $text)
                .keyboardType(textFieldType.keyboardType)
            #else
            TextField(title, text: $text)
            #endif
        })
    }
}

private struct FloatingFieldWrapper<Field: View>: View {
    @State private var textYOffset: CGFloat
    @State private var textScaleEffect: CGFloat

    let text: String
    let title: String
    let field: () -> Field

    init(text: String, title: String, @ViewBuilder field: @escaping () -> Field) {
        self.text = text
        self.title = title
        self.field = field
        self.textYOffset = Self.nextTextYOffsetValue(text.isEmpty)
        self.textScaleEffect = Self.nextTextScaleEffectValue(text.isEmpty)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .foregroundColor(textColor)
                .offset(y: textYOffset)
                .scaleEffect(textScaleEffect, anchor: .leading)
                .padding(.horizontal, titleHorizontalPadding)
            field()
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.5), value: textYOffset)
        .onChange(of: text.isEmpty, handleOnTextIsEmptyChange)
    }

    private var textColor: Color {
        if text.isEmpty { .secondary } else { .accentColor }
    }

    private var titleHorizontalPadding: CGFloat {
        if text.isEmpty { 4 } else { 0 }
    }

    private func handleOnTextIsEmptyChange(_ oldValue: Bool, _ newValue: Bool) {
        textYOffset = Self.nextTextYOffsetValue(newValue)
        textScaleEffect = Self.nextTextScaleEffectValue(newValue)
    }

    private static func nextTextYOffsetValue(_ textIsEmpty: Bool) -> CGFloat {
        if textIsEmpty { 0 } else { -25 }
    }

    private static func nextTextScaleEffectValue(_ textIsEmpty: Bool) -> CGFloat {
        if textIsEmpty { 1 } else { 0.75 }
    }
}

#Preview {
    AppTextField(text: .constant("Yes"), title: "Task")
        .padding(.all, .medium)
}
