//
//  AppTabView.swift
//  Buddy
//
//  Created by Kamaal M Farah on 3/15/25.
//

import Chat
import SwiftUI

struct AppTabView: View {
    var body: some View {
        TabView {
            ChatTabScreen()
                .tabItem {
                    Label(Screens.chat.title, systemImage: Screens.chat.imageName)
                }
        }
    }
}

#Preview {
    AppTabView()
}
