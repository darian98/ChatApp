//
//  UserProfileView.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 10.12.24.
//

import Foundation
import SwiftUI

struct UserProfileView: View {
   @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                profileImage
                    .frame(alignment: .center)
                
                VStack(alignment: .leading, spacing: 16) {
                    userInfo
                    userBio
                    userFriends
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                closeButton
            }
        }
        .onAppear {
            loadFriendsData()
            viewModel.fetchProfileData(currentUserID: viewModel.user.uid)
        }
    }
    
    private func loadFriendsData() {
        Task {
            let friendList: [Friend] = []
            FriendService.shared.fetchFriends(for: viewModel.user.uid) { friends in
                    print("FriendsCount: \(friends.count)")
                    let friendList = friends
                    DispatchQueue.main.async {
                        viewModel.user.friends = friendList
                        viewModel.loadFriendNames()
                    }
            }
        }
    }
    
}

extension UserProfileView {
    private var profileImage: some View {
        VStack {
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    Text("Wählen Sie\n ein Profilbild")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.user.displayName)
                .font(.title2)
            Text(viewModel.user.email)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var userBio: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bio")
                .font(.headline)
            Text(viewModel.user.bio.isEmpty ? "Keine Bio verfügbar." : viewModel.user.bio)
                .font(.subheadline)
        }
        .padding(.top)
    }
    
    private var userFriends: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.showFriendList.toggle()
                }
            }, label: {
                HStack {
                    Text("Freunde (\(viewModel.user.friends.count))")
                        .font(.headline)
                    if !viewModel.user.friends.isEmpty {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(viewModel.showFriendList ? 90 : 0 )) // Dreieck drehen
                            .frame(width: 10, height: 10) // Größe anpassen
                    }
                }
            })
            
            if viewModel.user.friends.isEmpty {
                Text("Keine Freunde gefunden.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else if viewModel.showFriendList {
                ScrollView {
                    ForEach(viewModel.user.friends) { friend in
                        HStack {
                            Text(viewModel.friendNames[friend.friendID] ?? "Lade...")
                                .font(.subheadline)
                            Spacer()
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.top)
            }
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func showFriendName(friendID: String) async -> String {
            do {
                if let friendUser = try await UserService.shared.fetchUser(byID: friendID) {
                    return friendUser.displayName
                } else {
                    return "Kein DisplayName für Nutzer"
                }
            } catch {
                print("Error while fetching Friends DisplayName: \(error)")
                return "Kein DisplayName für Nutzer"
            }
    }
    
    
    private var closeButton: some View {
        Button(action: {
            // Aktion, um die Ansicht zu schließen
        }) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

