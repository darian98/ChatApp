//
//  SharePostList.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 19.12.24.
//

import Foundation
import SwiftUI

struct SharePostList: View {
    
    var currentUser: UserModel
    @ObservedObject var viewModel: PostsViewModel
    @StateObject private var imageLoader = AsyncImageLoader()
    
    
    var body: some View {
        
        VStack {
            List {
                ForEach(currentUser.friends) { friend in
                    HStack {
                        friendUserImage(for: friend)
                        friendName(for: friend)
                        Spacer()
                        
                        checkButton(for: friend)
                    }
                }
            }
            sharePostButton()
        }
        .onAppear {
            print("Current user name: \(currentUser.displayName)")
            print("Friends Count: \(currentUser.friends.count)")
        }
    }
}




extension SharePostList {
    private func friendName(for friend: Friend) -> some View {
        Group {
            if let postingUserName = viewModel.friendsNames[friend.friendID] {
                Text(postingUserName)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            } else {
                Text("Lade Benutzername...")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .task {
                        await viewModel.loadUserName(for: friend.friendID, userNameFor: .friendList)
                    }
            }
        }
    }
    
    private func friendUserImage(for friend: Friend) -> some View {
        Group {
            if let image = imageLoader.sharePostListImages[friend.friendID] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .shadow(radius: 2)
        
            } else {
                    Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .shadow(radius: 2)
            }
        }
        .task(id: friend.friendID) {
            await imageLoader.loadUserImage(for: friend.friendID, imagesFor: .sharePostList)
        }
    }
    private func checkButton(for friend: Friend) -> some View {
        Button {
            viewModel.updateFriendRowClicked(friendID: friend.friendID)
        } label: {
            Image(systemName: viewModel.isFriendRowClicked(friendID: friend.friendID) ? "checkmark": "")
        }
    }
    
    private func sharePostButton() -> some View {
        Button {
            print("")
        } label: {
            Text("Teilen")
                .background(.blue)
                .frame(maxWidth: .infinity)
                .padding()
        }

    }
    
}
