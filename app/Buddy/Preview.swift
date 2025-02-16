//
//  Preview.swift
//  Buddy
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import Authentication

extension View {
    func preview() -> some View {
        let authentication = Authentication()

        return self
            .authenticationEnvironment(authentication: authentication)
    }
}
