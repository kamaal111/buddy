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
        NavigationSplitView(sidebar: { Sidebar() }, detail: { MainDetailView() })
    }
}

#Preview {
    AppNavigation()
}
