//
//  MessageTextField.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem
import KamaalExtensions

private let LINE_HEIGHT: CGFloat = 17
private let MAX_FIELD_HEIGHT: CGFloat = LINE_HEIGHT * 10
private let FIELD_PADDING: CGFloat = 4

private let SUBMIT_SHORTCUT = KeyboardShortcutConfiguration(key: .return, modifiers: .command)
private let REGISTERED_SHORTCUTS = [
    SUBMIT_SHORTCUT
]

struct MessageTextField: View {
    @State private var isDisabled = false

    @FocusState private var isFocused: Bool

    @Binding var message: String

    let onSubmit: (_ message: String) async -> Bool

    var body: some View {
        KeyboardShortcutView(shortcuts: REGISTERED_SHORTCUTS, onEmit: handleShortcut) {
            HStack(alignment: .bottom) {
                TextEditor(text: $message)
                    .font(.system(size: LINE_HEIGHT, weight: .light))
                    .frame(minHeight: LINE_HEIGHT, maxHeight: textFieldMaxHeight + FIELD_PADDING)
                    .focused($isFocused)
                    .cornerRadius(.extraSmall)
                Button(action: handleSubmit) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(submitIsDisabled ? Color.secondary : Color.accentColor)
                }
                .disabled(submitIsDisabled)
            }
        }
        .disabled(isDisabled)
    }

    private var submitIsDisabled: Bool {
        message.trimmingByWhitespacesAndNewLines.isEmpty
    }

    private var textFieldMaxHeight: CGFloat {
        let lines = message.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        guard !lines.isEmpty else { return LINE_HEIGHT }

        let lineHeight = CGFloat(lines.count) * LINE_HEIGHT
        guard lineHeight < MAX_FIELD_HEIGHT else { return MAX_FIELD_HEIGHT }
        guard lineHeight > LINE_HEIGHT else { return LINE_HEIGHT }

        return lineHeight
    }

    private func handleShortcut(_ shortcut: KeyboardShortcutConfiguration) {
        guard isFocused else { return }

        if shortcut == SUBMIT_SHORTCUT {
            handleSubmit()
        }
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
