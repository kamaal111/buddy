//
//  ChatEnvironment.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/7/25.
//

import SwiftUI

extension View {
    public func chatEnvironment() -> some View {
        self
            .modifier(ChatEnvironment())
    }
}

private struct ChatEnvironment: ViewModifier {
    @State private var chat = Chat()

    func body(content: Content) -> some View {
        content
            .environment(chat)
    }
}
