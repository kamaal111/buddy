//
//  MessageTextField.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem
import KamaalExtensions

struct MessageTextField: View {
    @State private var isDisabled = false

    @Binding var message: String

    let onSubmit: (_ message: String) async -> Bool

    var body: some View {
        HStack {
            AppTextField(text: $message, localizedTitle: "Message Buddy", bundle: .module)
                .takeWidthEagerly(alignment: .leading)
            Button(action: handleSubmit) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(submitIsDisabled ? Color.secondary : Color.accentColor)
            }
            .padding(.bottom, -12)
            .disabled(submitIsDisabled)
        }
        .onSubmit(handleSubmit)
        .disabled(isDisabled)
    }

    private var submitIsDisabled: Bool {
        message.trimmingByWhitespacesAndNewLines.isEmpty
    }

    private func handleSubmit() {
        guard !submitIsDisabled else { return }

        Task {
            isDisabled = true
            let clear = await onSubmit(message.trimmingByWhitespacesAndNewLines)
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
