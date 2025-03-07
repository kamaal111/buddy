//
//  SignUpFormContent.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/17/25.
//

import SwiftUI
import DesignSystem

struct SignUpFormContent: View {
    @FocusState private var focusedTextfield: SignUpFormContentFocusFields?

    @State private var email = ""
    @State private var emailError: AppTextFieldErrorResult?
    @State private var password = ""
    @State private var passwordError: AppTextFieldErrorResult?
    @State private var confirmPassword = ""
    @State private var confirmPasswordError: AppTextFieldErrorResult?

    let onSignUp: (_ payload: SignUpPayload) -> Void
    let onLoginPress: () -> Void

    var body: some View {
        JustStack {
            AppTextField(
                text: $email,
                errorResult: $emailError,
                localizedTitle: "Email",
                bundle: .module,
                validations: [.email(message: NSLocalizedString("Not an valid email", comment: ""))]
            )
            .focused($focusedTextfield, equals: .email)
            .onSubmit(handleSubmit)
            AppTextField(
                text: $password,
                errorResult: $passwordError,
                localizedTitle: "Password",
                bundle: .module,
                variant: .secure,
                validations: [
                    .minimumLength(
                        length: 8,
                        message: NSLocalizedString("Password must be atleast 8 characters", comment: "")
                    )
                ]
            )
            .focused($focusedTextfield, equals: .password)
            .onSubmit(handleSubmit)
            AppTextField(
                text: $confirmPassword,
                errorResult: $confirmPasswordError,
                localizedTitle: "Confirm Password",
                bundle: .module,
                variant: .secure,
                validations: [
                    .isSameAs(
                        value: password,
                        message: NSLocalizedString("Password must be the same as the password above", comment: "")
                    )
                ]
            )
            .focused($focusedTextfield, equals: .password)
            .onSubmit(handleSubmit)
            VStack {
                Button(action: handleSubmit) {
                    Text("Sign Up")
                        .bold()
                        .foregroundStyle(formIsValid ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!formIsValid)
            }
            .padding(.vertical, .small)
            Button(action: onLoginPress) {
                HStack {
                    Text("Already have an account?")
                    Text("Sign In")
                        .foregroundStyle(Color.accentColor)
                        .bold()
                        .underline()
                }
                .padding(.bottom, .small)
            }
            .buttonStyle(.plain)
        }
    }

    private var formIsValid: Bool {
        [emailError, passwordError, confirmPasswordError]
            .allSatisfy({ result in result?.valid == true })
    }

    private var signUpPayload: SignUpPayload {
        SignUpPayload(email: email, password: password, confirmPassword: confirmPassword)
    }

    private func handleSubmit() {
        guard formIsValid else { return }

        onSignUp(signUpPayload)
    }
}

private enum SignUpFormContentFocusFields {
    case email
    case password
    case confirmPassword
}

#Preview {
    SignUpFormContent(onSignUp: { _ in }, onLoginPress: { })
}
