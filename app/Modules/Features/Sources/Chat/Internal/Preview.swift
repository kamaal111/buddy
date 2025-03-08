//
//  Preview.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import Authentication

extension View {
    func preview() -> some View {
        let authentication = Authentication()

        return self
            .chatEnvironment()
            .authenticationEnvironment(authentication: authentication)
    }
}
