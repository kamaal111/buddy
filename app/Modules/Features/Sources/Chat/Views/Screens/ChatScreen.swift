//
//  ChatScreen.swift
//  Chat
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI
import DesignSystem
import Authentication

public struct ChatScreen: View {
    @EnvironmentObject private var authentication: Authentication
    @EnvironmentObject private var chat: Chat

    @State private var textFieldMessage = ""
    @State private var toast: Toast?

    public init() { }

    public var body: some View {
        VStack {
            ScrollView {
                ForEach(chat.selectedRoom?.messages ?? [], id: \.self) { message in
                    MessageBubble(message: message)
                }
            }
            .takeSizeEagerly(alignment: .top)
            MessageTextField(message: $textFieldMessage, onSubmit: handleSubmit)
                .disabled(messageFieldIsDisabled)
            if chat.selectedModel != nil {
                Picker("", selection: $chat.selectedModel) {
                    ForEach(availableModels) { model in
                        Text(model.displayName)
                            .tag(model)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(.all, .medium)
        .frame(minWidth: ModuleConfig.screenMinSize.width, minHeight: ModuleConfig.screenMinSize.height)
        .onAppear(perform: handleAppear)
        .toastView(toast: $toast)
        .onChange(of: chat.selectingRoomError, handleSelectingRoomErrorChange)
    }

    private var messageFieldIsDisabled: Bool {
        chat.selectedModel == nil || chat.selectingRoom
    }

    private var availableModels: [LLMModel] {
        authentication.session?.availableModels ?? []
    }

    private func handleSelectingRoomErrorChange(_ oldValue: ListChatMessagesErrors?, _ newValue: ListChatMessagesErrors?) {
        guard let error = newValue else { return }

        switch error {
        case .unauthorized: authentication.unsetSession()
        default: break
        }

        toast = .error(message: error.errorDescription)
        chat.unsetSelectingRoomError()
    }

    private func handleAppear() {
        guard !availableModels.isEmpty else { return }

        if let selectedModel = chat.selectedModel, availableModels.contains(selectedModel) {
            return
        }

        chat.selectedModel = availableModels.first
    }

    private func handleSubmit(_ message: String) async -> Bool {
        guard !messageFieldIsDisabled else { return false }

        let error: SendMessageErrors
        let result = await chat.sendMessage(message)
        switch result {
        case let .failure(failure): error = failure
        case .success: return true
        }

        toast = .error(message: error.errorDescription)
        switch error {
        case .unauthorized: authentication.unsetSession()
        case .general: break
        }

        return false
    }
}

#Preview {
    ChatScreen()
        .preview()
}
