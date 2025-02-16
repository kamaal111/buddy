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
        if withNavigation {
            #if os(macOS)
            NavigationSplitView(sidebar: { Sidebar() }, detail: { MainDetailView() })
            #else
            TabView(selection: $selectedTab) {
                Tab(Screens.chat.title, systemImage: Screens.chat.imageName, value: .chat) {
                    MainDetailView()
                }
            }
            #endif
        } else {
            MainDetailView()
        }
    }

    private var withNavigation: Bool {
        Screens.allCases.count > 1
    }
}

#Preview {
    AppNavigation()
}
