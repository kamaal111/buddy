//
//  Sidebar.swift
//  Buddy
//
//  Created by Kamaal M Farah on 2/16/25.
//

import Chat
import SwiftUI
import DesignSystem

struct Sidebar: View {
    @EnvironmentObject private var chat: Chat

    let minWidth: CGFloat
    let idealWidth: CGFloat

    private init(minWidth: CGFloat, idealWidth: CGFloat) {
        self.minWidth = minWidth
        self.idealWidth = idealWidth
    }

    init () {
        self.init(minWidth: Self.DEFAULT_MIN_WIDTH, idealWidth: Self.DEFAULT_IDEAL_WIDTH)
    }

    var body: some View {
        List {
            Section("App") {
                Button(action: { chat.unsetSelectedRoom() }) {
                    Label(Screens.chat.title, systemImage: Screens.chat.imageName)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                Divider()
                ChatList()
            }
        }
        .navigationSplitViewColumnWidth(min: minWidth, ideal: idealWidth)
    }

    private static let DEFAULT_MIN_WIDTH: CGFloat = 140
    private static let DEFAULT_IDEAL_WIDTH: CGFloat = 160
}

#Preview {
    Sidebar()
        .preview()
}
