//
//  MessageTextField.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem

struct MessageTextField: View {
    @State private var isDisabled = false

    @Binding var message: String

    let onSubmit: (_ message: String) async -> Bool

    var body: some View {
        AppTextField(text: $message, localizedTitle: "Message Buddy", bundle: .module)
            .onSubmit(handleSubmit)
            .disabled(isDisabled)
    }

    private func handleSubmit() {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            isDisabled = true
            let clear = await onSubmit(message)
            isDisabled = false
            guard clear else { return }

            self.message = ""
        }
    }
}

#Preview {
    MessageTextField(message: .constant(""), onSubmit: { _ in true })
    MessageTextField(message: .constant("Hello"), onSubmit: { _ in true })
}
