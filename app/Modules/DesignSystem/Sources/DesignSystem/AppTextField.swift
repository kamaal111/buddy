//
//  File.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import SwiftValidator

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

public enum AppTextFieldVariant {
    case text
    case decimals
    case numbers
    case secure

    #if canImport(UIKit)
    var keyboardType: UIKeyboardType {
        switch self {
        case .decimals: return .decimalPad
        case .numbers: return .numberPad
        case .text, .secure: return .default
        }
    }
    #endif
}

public struct AppTextField: View {
    @State private var showPassword = false

    @FocusState private var isFocused: Bool

    @Binding private var text: String
    @Binding private var errorResult: AppTextFieldErrorResult?

    public let title: String
    public let variant: AppTextFieldVariant
    public let validations: [any StringValidatableRule]

    public init(
        text: Binding<String>,
        errorResult: Binding<AppTextFieldErrorResult?>,
        title: String,
        variant: AppTextFieldVariant = .text,
        validations: [AppTextFieldValidationRules]
    ) {
        self._text = text
        self._errorResult = errorResult
        self.title = title
        self.variant = variant
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
        variant: AppTextFieldVariant = .text,
        validations: [AppTextFieldValidationRules]
    ) {
        self.init(
            text: text,
            errorResult: errorResult,
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            variant: variant,
            validations: validations
        )
    }

    public init(text: Binding<String>, title: String, variant: AppTextFieldVariant = .text) {
        self.init(
            text: text,
            errorResult: .constant(nil),
            title: title,
            variant: variant,
            validations: []
        )
    }

    public init(
        text: Binding<String>,
        localizedTitle: LocalizedStringResource,
        bundle: Bundle,
        variant: AppTextFieldVariant = .text
    ) {
        self.init(
            text: text,
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            variant: variant
        )
    }

    public var body: some View {
        FloatingFieldWrapper(text: text, title: title, error: textFieldError, field: {
            if variant == .secure {
                HStack {
                    JustStack {
                        if showPassword {
                            TextField("", text: $text)
                                .focused($isFocused)
                        } else {
                            SecureField("", text: $text)
                                .focused($isFocused)
                        }
                    }
                    .takeWidthEagerly(alignment: .leading)
                    Image(systemName: !showPassword ? "eye" : "eye.slash")
                        .foregroundColor(showError ? Color.red : Color.accentColor)
                        .onTapGesture { handleShowPassword() }
                }
            } else {
                #if canImport(UIKit)
                TextField("", text: $text)
                    .focused($isFocused)
                    .keyboardType(variant.keyboardType)
                #else
                TextField("", text: $text)
                    .focused($isFocused)
                #endif
            }
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

    private func handleShowPassword() {
        showPassword.toggle()
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

    private let text: String
    private let title: String
    private let error: (show: Bool, message: String?)
    private let field: () -> Field

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
