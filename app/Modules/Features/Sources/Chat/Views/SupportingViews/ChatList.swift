//
//  ChatList.swift
//  Chat
//
//  Created by Kamaal M Farah on 3/15/25.
//

import SwiftUI
import DesignSystem

public struct ChatList: View {
    @EnvironmentObject private var chat: Chat

    @State private var showChatScreen = false

    public init() { }

    public var body: some View {
        VStack {
            if isIphone {
                Button(action: { showChatScreen = true }) {
                    HStack {
                        Image(systemName: "plus.message.fill")
                        Text("New Chat")
                    }
                    .bold()
                    .padding(.all, .extraExtraSmall)
                    .invisibleFill(alignment: .leading)
                }
                Divider()
            }
            ForEach(chat.rooms) { room in
                VStack {
                    Button(action: { handleSelectRoom(room) }) {
                        Text(room.title)
                            .bold()
                            .lineLimit(1)
                            .padding(.all, .extraExtraSmall)
                            .foregroundStyle(chat.selectingRoom ? Color.secondary : Color.accentColor)
                            .invisibleFill(alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .disabled(chat.selectingRoom)
                    .background(roomIsSelected(room) ? Color.gray.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    if isIphone, room != chat.rooms.last {
                        Divider()
                    }
                }
            }
        }
        #if canImport(UIKit)
        .applyIf(isIphone) { view in
            view
                .onChange(of: showChatScreen, { oldValue, newValue in
                    guard !showChatScreen else { return }

                    chat.unsetSelectedRoom()
                })
                .navigationDestination(isPresented: $showChatScreen) {
                    ChatScreen()
                        .navigationTitle(chat.selectedRoom?.title ?? "New Chat")
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
        #endif
    }

    private var isIphone: Bool {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }

    private func handleSelectRoom(_ room: ChatRoom) {
        Task {
            await chat.selectRoom(room)
            showChatScreen = true
        }
    }

    private func roomIsSelected(_ room: ChatRoom) -> Bool {
        room.id == chat.selectedRoomID
    }
}

#Preview {
    ChatList()
}
