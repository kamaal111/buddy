//
//  MessageBubble.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/9/25.
//

import SwiftUI
import MarkdownUI
import DesignSystem
import KamaalExtensions

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if !message.isFromUser {
                Markdown(message.content)
                    .padding(.all, .small)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(.small)
                    .takeWidthEagerly(alignment: .trailing)
            } else {
                Markdown(message.content)
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
    VStack {
        MessageBubble(message: .init(
            role: .assistant,
            content: "Hi, how are you?",
            date: Date(timeIntervalSince1970: 1742053012),
            llmProvider: "openai",
            llmKey: "gpt-4o-mini"
        ))
        MessageBubble(message: .init(
            role: .user,
            content: "Hello, I'm doing fine thank you, how about you?",
            date: Date(timeIntervalSince1970: 1742055012),
            llmProvider: "openai",
            llmKey: "gpt-4o-mini"
        ))
    }
}
