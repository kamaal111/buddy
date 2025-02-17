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
        FormBox(localizedTitle: "Sign Up", bundle: .module, minSize: AppConfig.screenMinSize) {
            Text("Hello sign up")
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    SignUpScreen()
}
