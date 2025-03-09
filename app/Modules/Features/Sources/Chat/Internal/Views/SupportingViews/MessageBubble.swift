//
//  MessageBubble.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/9/25.
//

import SwiftUI
import DesignSystem
import KamaalExtensions

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if !message.isFromUser {
                Text(message.content)
                    .padding(.all, .small)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(.small)
                    .takeWidthEagerly(alignment: .trailing)
            } else {
                Text(message.content)
                    .padding(.all, .small)
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .cornerRadius(.small)
                    .takeWidthEagerly(alignment: .leading)
             }
         }
         .padding(.horizontal)
         .padding(.vertical, .extraSmall)
    }
}

#Preview {
    MessageBubble(message: .init(
        role: .user,
        content: "Hello",
        date: Date.now.toIsoString(),
        llmProvider: "openai",
        llmKey: "gpt-4o-mini"
    ))
}
