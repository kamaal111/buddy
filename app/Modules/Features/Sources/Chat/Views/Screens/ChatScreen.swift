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

    @State private var textFieldMessage = ""
    @State private var selectedModel: LLMModel?

    public init() { }

    public var body: some View {
        VStack {
            Spacer()
            MessageTextField(message: $textFieldMessage, onSubmit: handleSubmit)
            if selectedModel != nil {
                Picker("", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model.displayName)
                            .tag(model)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(.all, .medium)
        .frame(minWidth: ModuleConfig.screenMinSize.width, minHeight: ModuleConfig.screenMinSize.height)
        .onAppear {
            guard !availableModels.isEmpty else { return }

            selectedModel = availableModels.first
        }
    }

    private var availableModels: [LLMModel] {
        authentication.session?.availableModels ?? []
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
