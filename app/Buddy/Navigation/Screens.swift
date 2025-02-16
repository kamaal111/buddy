//
//  Screens.swift
//  Buddy
//
//  Created by Kamaal M Farah on 2/16/25.
//

import Foundation

enum Screens: Equatable, Hashable, Identifiable, CaseIterable {
    case chat

    var id: Screens { self }

    var imageName: String {
        switch self {
        case .chat: "message.fill"
        }
    }

    var imageIsFromSystem: Bool {
        switch self {
        case .chat: true
        }
    }

    var title: String {
        switch self {
        case .chat: NSLocalizedString("Chat", comment: "")
        }
    }
}
