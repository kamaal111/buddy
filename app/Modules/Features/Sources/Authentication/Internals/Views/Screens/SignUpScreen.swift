//
//  SignUpScreen.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

struct SignUpScreen: View {
    @Binding private var isShown: Bool

    init(isShown: Binding<Bool>) {
        self._isShown = isShown
    }

    init() {
        self.init(isShown: .constant(true))
    }

    var body: some View {
        Text("Sign Up Hello, World!")
            .frame(
                minWidth: AppConfig.screenMinSize.width + AppSizes.medium,
                minHeight: AppConfig.screenMinSize.height + AppSizes.medium
            )
    }
}

#Preview {
    SignUpScreen()
}
