//
//  LoginFormContent.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/17/25.
//

import SwiftUI
import DesignSystem

struct LoginFormContent: View {
    @FocusState private var focusedTextfield: LoginFormContentFocusFields?

    @State private var email = ""
    @State private var emailError: AppTextFieldErrorResult?
    @State private var password = ""
    @State private var passwordError: AppTextFieldErrorResult?

    let onLogin: (_ payload: LoginPayload) -> Void
    let onSignUpPress: () -> Void

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
            VStack {
                Button(action: handleSubmit) {
                    Text("Continue")
                        .bold()
                        .foregroundStyle(formIsValid ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!formIsValid)
            }
            #if os(macOS)
            .padding(.vertical, .small)
            #endif
            Button(action: onSignUpPress) {
                HStack {
                    Text("Don't have an account yet?")
                    Text("Sign Up")
                        .foregroundStyle(Color.accentColor)
                        .bold()
                        .underline()
                }
                #if os(macOS)
                .padding(.bottom, .small)
                #endif
            }
            .buttonStyle(.plain)
        }
    }

    private var loginPayload: LoginPayload {
        LoginPayload(email: email, password: password)
    }

    private var formIsValid: Bool {
        [emailError, passwordError]
            .allSatisfy({ result in result?.valid == true })
    }

    private func handleSubmit() {
        guard formIsValid else { return }

        onLogin(loginPayload)
    }
}

private enum LoginFormContentFocusFields {
    case email
    case password
}

#Preview {
    LoginFormContent(onLogin: { _ in }, onSignUpPress: { })
        .preview()
}
