//
//  View+extensions.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

extension View {
    public func takeSizeEagerly(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }

    public func takeWidthEagerly(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
    }

    @ViewBuilder
    public func applyIf(_ condition: Bool, transformation: (_ view: Self) -> some View) -> some View {
        if condition { transformation(self) } else { self }
    }

    public func bindToFrameSize(_ size: Binding<CGSize>) -> some View {
        modifier(BindToFrameSize(size: size))
    }

    public func foregroundColor(light lightModeColor: Color, dark darkModeColor: Color) -> some View {
        modifier(AdaptiveForegroundColorModifier(lightModeColor: lightModeColor, darkModeColor: darkModeColor))
    }
}

private struct BindToFrameSize: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content.overlay(GeometryReader(content: overlay(for:)))
    }

    func overlay(for geometry: GeometryProxy) -> some View {
        let size = geometry.size
        if self.size.width != size.width || self.size.height != size.height {
            DispatchQueue.main.async {
                self.size = geometry.size
            }
        }
        return Text("")
    }
}

private struct AdaptiveForegroundColorModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var lightModeColor: Color
    var darkModeColor: Color

    func body(content: Content) -> some View {
        content.foregroundColor(resolvedColor)
    }

    private var resolvedColor: Color {
        switch self.colorScheme {
        case .light: lightModeColor
        case .dark: darkModeColor
        @unknown default: lightModeColor
        }
    }
}
