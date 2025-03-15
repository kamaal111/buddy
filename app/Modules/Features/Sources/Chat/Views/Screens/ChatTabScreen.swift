//
//  ChatTabScreen.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/15/25.
//

import SwiftUI

public struct ChatTabScreen: View {
    public init() { }

    public var body: some View {
        NavigationStack {
            Form {
                ChatList()
            }
            .navigationTitle("Chat")
        }
    }
}

#Preview {
    ChatTabScreen()
}
