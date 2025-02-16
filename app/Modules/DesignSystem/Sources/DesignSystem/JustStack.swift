//
//  JustStack.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

public struct JustStack<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        self.content
    }
}

#Preview {
    JustStack {
        Text("1")
        Text("2")
        Text("3")
        Text("4")
        Text("5")
    }
}
