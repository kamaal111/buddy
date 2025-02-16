//
//  LoginScreen.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

struct LoginScreen: View {
    @EnvironmentObject private var authentication: Authentication

    @State private var email = ""
    @State private var emailError: AppTextFieldErrorResult?
    @State private var password = ""
    @State private var passwordError: AppTextFieldErrorResult?

    @FocusState private var focusedTextfield: FocusFields?

    var body: some View {
        Form {
            AppTextField(
                text: $email,
                errorResult: $emailError,
                localizedTitle: "Email",
                bundle: .module,
                validations: [.email(message: NSLocalizedString("Not an valid email", comment: ""))]
            )
            .focused($focusedTextfield, equals: .email)
            AppTextField(
                text: $password,
                errorResult: $passwordError,
                localizedTitle: "Password",
                bundle: .module,
                validations: [
                    .minimumLength(
                        length: 5,
                        message: NSLocalizedString("Password must be atleast 5 characters", comment: "")
                    )
                ]
            )
            .focused($focusedTextfield, equals: .password)
        }
        .navigationTitle(Text("Login"))
        .frame(minWidth: AppConfig.screenMinSize.width, minHeight: AppConfig.screenMinSize.height)
    }
}

private enum FocusFields {
    case email
    case password
}

#Preview {
    NavigationStack {
        LoginScreen()
    }
    .preview()
}
