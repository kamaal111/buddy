//
//  LoginScreen.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

struct LoginScreen: View {
    @State private var signUpScreenIsShown = false

    var body: some View {
        FormBox(localizedTitle: "Sign In", bundle: .module, minSize: ModuleConfig.screenMinSize, content: {
            LoginFormContent(onLogin: handleLogin, onSignUpPress: handleSignUpPress)
        })
        .navigationDestination(isPresented: $signUpScreenIsShown) { SignUpScreen(isShown: $signUpScreenIsShown) }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: handleSignUpPress) {
                    Text("Sign Up")
                        .bold()
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func handleSignUpPress() {
        signUpScreenIsShown = true
    }

    private func handleLogin(_ payload: LoginPayload) { }
}

#Preview {
    LoginScreen()
        .preview()
}
