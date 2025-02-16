//
//  File.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import SwiftValidator

private let MACOS_LABEL_HORIZONTAL_PADDING: CGFloat = 8

public enum AppTextFieldValidationRules {
    case minimumLength(length: Int, message: String?)
    case isSameAs(value: String, message: String?)
    case email(message: String?)
}

public struct AppTextFieldErrorResult: Equatable {
    public let valid: Bool
    public let errorMessage: String?

    public init(valid: Bool, errorMessage: String?) {
        self.valid = valid
        self.errorMessage = errorMessage
    }
}

public struct AppTextField: View {
    @FocusState private var isFocused: Bool

    @Binding public var text: String
    @Binding var errorResult: AppTextFieldErrorResult?

    public let title: String
    public let textFieldType: TextFieldType
    public let validations: [any StringValidatableRule]

    public init(
        text: Binding<String>,
        errorResult: Binding<AppTextFieldErrorResult?>,
        title: String,
        textFieldType: TextFieldType = .text,
        validations: [AppTextFieldValidationRules]
    ) {
        self._text = text
        self._errorResult = errorResult
        self.title = title
        self.textFieldType = textFieldType
        self.validations = validations.map({ validation -> any StringValidatableRule in
            switch validation {
            case let .minimumLength(length, message):
                StringValidateMinimumLength(length: length, message: message)
            case let .isSameAs(value, message):
                StringIsTheSameValue(value: value, message: message)
            case let .email(message):
                StringIsEmail(message: message)
            }
        })
    }

    public init(
        text: Binding<String>,
        errorResult: Binding<AppTextFieldErrorResult?>,
        localizedTitle: LocalizedStringResource,
        bundle: Bundle,
        textFieldType: TextFieldType = .text,
        validations: [AppTextFieldValidationRules]
    ) {
        self.init(
            text: text,
            errorResult: errorResult,
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            textFieldType: textFieldType,
            validations: validations
        )
    }

    public init(text: Binding<String>, title: String, textFieldType: TextFieldType = .text) {
        self.init(
            text: text,
            errorResult: .constant(nil),
            title: title,
            textFieldType: textFieldType,
            validations: []
        )
    }

    public init(
        text: Binding<String>,
        localizedTitle: LocalizedStringResource,
        bundle: Bundle,
        textFieldType: TextFieldType = .text
    ) {
        self.init(
            text: text,
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            textFieldType: textFieldType
        )
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
        FloatingFieldWrapper(text: text, title: title, error: textFieldError, field: {
            #if canImport(UIKit)
            TextField("", text: $text)
                .focused($isFocused)
                .keyboardType(textFieldType.keyboardType)
            #else
            TextField("", text: $text)
                .focused($isFocused)
            #endif
        })
        .onChange(of: text) { oldValue, newValue in handleValueChange(value: newValue) }
    }

    private var validator: StringValidator {
        StringValidator(value: text, validators: validations)
    }

    private var textFieldError: (show: Bool, message: String?) {
        guard showError else { return (false, nil) }

        return (true, errorResult?.errorMessage)
    }

    private var showError: Bool {
        guard !validations.isEmpty else { return false }

        return !isFocused && !text.isEmpty && errorResult?.valid != true
    }

    private func handleValueChange(value: String) {
        setErrorResult(value: value)
    }

    private func setErrorResult(value: String) {
        let result = validator.result
        errorResult = AppTextFieldErrorResult(valid: result.valid, errorMessage: result.message)
    }
}

private struct FloatingFieldWrapper<Field: View>: View {
    @State private var textYOffset: CGFloat
    @State private var textScaleEffect: CGFloat

    let text: String
    let title: String
    let error: (show: Bool, message: String?)
    let field: () -> Field

    init(
        text: String,
        title: String,
        error: (show: Bool, message: String?),
        @ViewBuilder field: @escaping () -> Field
    ) {
        self.text = text
        self.title = title
        self.error = error
        self.field = field
        self.textYOffset = Self.nextTextYOffsetValue(text.isEmpty)
        self.textScaleEffect = Self.nextTextScaleEffectValue(text.isEmpty)
    }

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(textColor)
                    .offset(y: textYOffset)
                    .scaleEffect(textScaleEffect, anchor: .leading)
                    .padding(.horizontal, titleHorizontalPadding)
                field()
            }
            if error.show, let message = error.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    #if os(macOS)
                    .padding(.horizontal, MACOS_LABEL_HORIZONTAL_PADDING)
                    #endif
                    .takeWidthEagerly(alignment: .leading)
            }
        }
        .padding(.top, 12)
        .animation(.spring(response: 0.5), value: textYOffset)
        .onChange(of: text.isEmpty, handleOnTextIsEmptyChange)
    }

    private var textColor: Color {
        if text.isEmpty { .secondary } else { .accentColor }
    }

    private var titleHorizontalPadding: CGFloat {
        if text.isEmpty {
            return 12
        }

        return 8
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
    VStack(spacing: 24) {
        AppTextField(
            text: .constant("Yes"),
            errorResult: .constant(AppTextFieldErrorResult(valid: false, errorMessage: "Nooo")),
            title: "Task",
            validations: []
        )
        AppTextField(
            text: .constant(""),
            errorResult: .constant(AppTextFieldErrorResult(valid: false, errorMessage: "Nooo")),
            title: "Task",
            validations: []
        )
    }
        .padding(.all, .medium)
}
