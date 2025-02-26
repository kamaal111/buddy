//
//  ChatScreen.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

public struct ChatScreen: View {
    @State private var textFieldMessage = ""

    public init() { }

    public var body: some View {
        VStack {
            Spacer()
            MessageTextField(message: $textFieldMessage, onSubmit: handleSubmit)
        }
        .padding(.all, .medium)
        .frame(minWidth: AppConfig.screenMinSize.width, minHeight: AppConfig.screenMinSize.height)
    }

    private func handleSubmit(_ message: String) -> Bool {
        print("message", message)
        return true
    }
}

#Preview {
    ChatScreen()
        .preview()
}
