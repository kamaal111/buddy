//
//  ModuleConfig.swift
//  BuddyClient
//
//  Created by Kamaal M Farah on 2/24/25.
//

import Foundation

enum ModuleConfig {
    static let identifier = "\(Bundle.main.bundleIdentifier!).BuddyClient"
    static let baseURL = URL(string: "http://localhost:8000")!
    static let authBaseURL = baseURL.appending(path: "app-api/v1/auth")
}
