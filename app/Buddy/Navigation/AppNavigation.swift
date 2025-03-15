//
//  AppNavigation.swift
//  Buddy
//
//  Created by Kamaal M Farah on 2/16/25.
//

import SwiftUI

struct AppNavigation: View {
    @State private var selectedTab: Screens = .chat

    var body: some View {
        if withSidebar {
            NavigationSplitView(sidebar: { Sidebar() }, detail: { MainDetailView() })
        } else {
            AppTabView()
        }
    }

    private var withSidebar: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
}

#Preview {
    AppNavigation()
}
