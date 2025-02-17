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
        FormBox(localizedTitle: "Sign in", bundle: .module, minSize: AppConfig.screenMinSize, content: {
            LoginFormContent(onSignIn: handleSignIn, onSignUpPress: handleSignUpPress)
        })
        .navigationDestination(isPresented: $signUpScreenIsShown) { SignUpScreen(isShown: $signUpScreenIsShown) }
    }

    private func handleSignUpPress() {
        signUpScreenIsShown = true
    }

    private func handleSignIn(_ payload: SignInPayload) { }
}

#Preview {
    LoginScreen()
        .preview()
}
