//
//  KeyboardShortcutView.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 3/15/25.
//

import SwiftUI

public struct KeyboardShortcutView<Content: View>: View {
    let shortcuts: [KeyboardShortcutConfiguration]
    let content: Content
    let onEmit: (_ shortcut: KeyboardShortcutConfiguration) -> Void

    public init(
        shortcuts: [KeyboardShortcutConfiguration],
        onEmit: @escaping (_ shortcut: KeyboardShortcutConfiguration) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.shortcuts = shortcuts
        self.content = content()
        self.onEmit = onEmit
    }

    public var body: some View {
        ZStack {
            ForEach(shortcuts) { shortcut in
                Button(action: { self.onEmit(shortcut) }) { EmptyView() }
                    .keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
                    .buttonStyle(.borderless)
            }
            content
        }
    }
}

public struct KeyboardShortcutConfiguration: Hashable, Identifiable, Sendable {
    public let modifiers: EventModifiers
    private let keyCharacter: Character

    public init(key: KeyEquivalent, modifiers: EventModifiers = []) {
        self.init(key: key.character, modifers: modifiers)
    }

    private init(key: Character, modifers: EventModifiers = []) {
        self.keyCharacter = key
        self.modifiers = modifers
    }

    public var key: KeyEquivalent { KeyEquivalent(keyCharacter) }

    public var id: KeyboardShortcutConfiguration { self }
}

extension EventModifiers: @retroactive Hashable { }
