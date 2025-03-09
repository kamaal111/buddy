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
            Spacer()
            MessageTextField(message: $textFieldMessage, onSubmit: handleSubmit)
                .disabled(chat.selectedModel == nil)
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
    }

    private var availableModels: [LLMModel] {
        authentication.session?.availableModels ?? []
    }

    private func handleAppear() {
        guard !availableModels.isEmpty else { return }

        if let selectedModel = chat.selectedModel, availableModels.contains(selectedModel) {
            return
        }

        chat.selectedModel = availableModels.first
    }

    private func handleSubmit(_ message: String) async -> Bool {
        guard chat.selectedModel != nil else { return false }

        let error: SendMessageErrors
        let result = await chat.sendMessage(message)
        switch result {
        case let .failure(failure): error = failure
        case .success: return true
        }

        toast = .error(message: error.errorDescription ?? error.localizedDescription)
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
