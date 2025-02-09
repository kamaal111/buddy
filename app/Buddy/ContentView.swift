//
//  ContentView.swift
//  Buddy
//
//  Created by Kamaal M Farah on 2/9/25.
//

import SwiftUI
import BuddyClient

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button(action: {
                let client = BuddyClient()
                Task {
                    let result = await client.health.ping()
                    print(result)
                }
            }) {
                Text("Action")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
