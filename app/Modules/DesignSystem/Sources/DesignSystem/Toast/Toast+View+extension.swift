//
//  Toast+View+extension.swift
//  DesignSystem
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

extension View {
    public func toastView(toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

private struct ToastModifier: ViewModifier {
    @State private var workItem: DispatchWorkItem?

    @Binding var toast: Toast?

    init(toast: Binding<Toast?>) {
        self._toast = toast
    }

    func body(content: Content) -> some View {
        content
            .takeSizeEagerly()
            .overlay(
                ZStack {
                    mainToastView
                        .offset(y: 32)
                }.animation(.spring, value: toast)
            )
            .onChange(of: toast, showToast)
    }

    @ViewBuilder
    private var mainToastView: some View {
        if let toast = toast {
            VStack {
                ToastView(style: toast.style, message: toast.message, width: toast.width) {
                    dismissToast()
                }
                Spacer()
            }
            .transition(.move(edge: .top))
        }
    }

    private func showToast(_ oldValue: Toast?, _ newValue: Toast?) {
        guard let toast else { return }

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
        #endif
        guard toast.duration > 0 else { return }

        workItem?.cancel()
        let task = DispatchWorkItem { dismissToast() }

        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }

    private func dismissToast() {
        withAnimation { toast = nil }

        workItem?.cancel()
        workItem = nil
    }
}

#Preview {
    @Previewable @State var toast: Toast?

    VStack {
        Button(action: { toast = .init(style: .success, message: "Wooooow!") }) {
            Text("Show Toast")
        }
    }
    .toastView(toast: $toast)
    .frame(width: 500, height: 500)
}
