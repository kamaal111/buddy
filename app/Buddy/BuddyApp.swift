//
//  BuddyApp.swift
//  Buddy
//
//  Created by Kamaal M Farah on 2/9/25.
//

import Chat
import SwiftUI
import Authentication

@main
struct BuddyApp: App {
    @State private var authentication = Authentication()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .chatEnvironment()
                .authenticationEnvironment(authentication: authentication)
        }
    }
}
