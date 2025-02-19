//
//  SignUpScreen.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

struct SignUpScreen: View {
    @EnvironmentObject private var authentication: Authentication

    @State private var signingUp = false

    @Binding private var isShown: Bool

    init(isShown: Binding<Bool>) {
        self._isShown = isShown
    }

    init() {
        self.init(isShown: .constant(true))
    }

    var body: some View {
        FormBox(localizedTitle: "Sign Up", bundle: .module, minSize: ModuleConfig.screenMinSize) {
            SignUpFormContent(onSignUp: handleSignUp, onLoginPress: handleLoginPress)
        }
        .disabled(signingUp)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func handleLoginPress() {
        isShown = false
    }

    private func handleSignUp(_ payload: SignUpPayload) {
        Task {
            signingUp = true
            let result = await authentication.signUp(email: payload.email, password: payload.password)
            print("🐸🐸🐸 result", result)
            signingUp = false
        }
    }
}

#Preview {
    SignUpScreen()
        .preview()
}
