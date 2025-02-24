//
//  AuthenticationEnvironment.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

extension View {
    public func authenticationEnvironment(authentication: Authentication) -> some View {
        modifier(AuthenticationEnvironment(authentication: authentication))
    }
}

private struct AuthenticationEnvironment: ViewModifier {
    @StateObject private var authentication: Authentication

    init(authentication: Authentication) {
        self._authentication = StateObject(wrappedValue: authentication)
    }

    func body(content: Content) -> some View {
        JustStack {
            if authentication.initiallyValidatingToken {
                ProgressView()
            } else {
                if !authentication.isLoggedIn {
                    NavigationStack {
                        LoginScreen()
                    }
                } else {
                    content
                }
            }
        }
        .environmentObject(authentication)
    }
}
