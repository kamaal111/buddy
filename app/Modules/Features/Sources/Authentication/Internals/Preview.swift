//
//  Preview.swift
//  Authentication
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

extension View {
    func preview() -> some View {
        let authentication = Authentication()

        return self
            .authenticationEnvironment(authentication: authentication)
    }
}
