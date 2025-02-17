//
//  FormBox.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/17/25.
//

import SwiftUI

public struct FormBox<Content: View>: View {
    private let title: String
    private let minSize: CGSize

    @ViewBuilder private let content: () -> Content

    public init(title: String, minSize: CGSize, content: @escaping () -> Content) {
        self.title = title
        self.minSize = minSize
        self.content = content
    }

    public init(
        localizedTitle: LocalizedStringResource,
        bundle: Bundle,
        minSize: CGSize,
        content: @escaping () -> Content
    ) {
        self.init(
            title: NSLocalizedString(localizedTitle.key, bundle: bundle, comment: ""),
            minSize: minSize,
            content: content
        )
    }

    public var body: some View {
        JustStack {
            #if os(macOS)
            VStack {
                GroupBox {
                    VStack {
                        Text(title)
                            .font(.title2)
                            .takeWidthEagerly(alignment: .leading)
                        content()
                    }
                    .padding(.vertical, .large)
                    .padding(.horizontal, .medium)
                }
                .frame(width: minSize.width / 1.1)
            }
            .padding(.horizontal, .medium)
            .frame(minWidth: minSize.width + AppSizes.medium, minHeight: minSize.height + AppSizes.medium)
            #else
            Form {
                content()
            }
            #endif
        }
        .navigationTitle(Text(title))
    }
}

#Preview {
    FormBox(title: "FormBox", minSize: .init(width: 200, height: 200)) {
        Text("Gello")
    }
}
