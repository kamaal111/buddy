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
                VStack(alignment: .trailing, spacing: 4) {
                    Markdown(message.content)
                        .padding(.all, .small)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(.small)
                    dateRecievedView
                        .padding(.trailing, .extraSmall)
                }
                .takeWidthEagerly(alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Markdown(message.content)
                        .padding(.all, .small)
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .cornerRadius(.small)
                    dateRecievedView
                        .padding(.leading, .extraSmall)
                }
                .takeWidthEagerly(alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, .extraSmall)
    }

    private var dateRecievedView: some View {
        Text(Self.dateFormatter.string(from: message.date))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
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
    .frame(height: 200)
}
