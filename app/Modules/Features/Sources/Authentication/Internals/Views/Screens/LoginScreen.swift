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

    @State private var signUpScreenIsShown = false
    @State private var toast: Toast?

    var body: some View {
        FormBox(localizedTitle: "Sign In", bundle: .module, minSize: ModuleConfig.screenMinSize, content: {
            LoginFormContent(onLogin: handleLogin, onSignUpPress: handleSignUpPress)
        })
        .navigationDestination(isPresented: $signUpScreenIsShown) {
            SignUpScreen(isShown: $signUpScreenIsShown, toast: $toast)
                .toastView(toast: $toast)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: handleSignUpPress) {
                    Text("Sign Up")
                        .bold()
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .toastView(toast: $toast)
    }

    private func handleSignUpPress() {
        signUpScreenIsShown = true
    }

    private func handleLogin(_ payload: LoginPayload) {
        Task {
            let result = await authentication.login(email: payload.email, password: payload.password)
            switch result {
            case let .failure(failure):
                toast = .error(message: failure.errorDescription ?? failure.localizedDescription)
            case .success: break
            }
        }
    }
}

#Preview {
    LoginScreen()
        .preview()
}
