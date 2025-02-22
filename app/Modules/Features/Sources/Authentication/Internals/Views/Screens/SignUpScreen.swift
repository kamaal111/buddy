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
    @Binding private var toast: Toast?

    init(isShown: Binding<Bool>, toast: Binding<Toast?>) {
        self._isShown = isShown
        self._toast = toast
    }

    init() {
        self.init(isShown: .constant(true), toast: .constant(nil))
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
        navigateToBack()
    }

    private func navigateToBack() {
        isShown = false
    }

    private func handleSignUp(_ payload: SignUpPayload) {
        Task { await signUp(payload) }
    }

    private func signUp(_ payload: SignUpPayload) async {
        signingUp = true
        defer { signingUp = false }

        let result = await authentication.signUp(email: payload.email, password: payload.password)
        switch result {
        case let .failure(failure):
            toast = .error(message: failure.errorDescription ?? failure.localizedDescription)
        case .success:
            toast = .success(message: NSLocalizedString("Successfully created a account.", comment: ""))
            navigateToBack()
        }
    }
}

#Preview {
    SignUpScreen()
        .preview()
}
