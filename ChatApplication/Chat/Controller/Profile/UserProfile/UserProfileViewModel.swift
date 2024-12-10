//
//  UserProfileViewModel.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 10.12.24.
//

import Foundation
import SwiftUI


class UserProfileViewModel: ObservableObject {
    
    @Published var user: UserModel
    @Published var profileImage: UIImage?
    @Published var bio: String = ""
    
    
    @Published var showFriendList: Bool = false
    @Published var friendNames: [String: String] = [:] // Speichert die Namen der Freunde
    @Published var isLoading = true
    
    init(user: UserModel) {
        self.user = user
    }
    
    
    func fetchProfileData(currentUserID: String) {
         Task {
             if let currentUserFetched = try? await UserService.shared.fetchUser(byID: currentUserID),
             let base64ImageString = currentUserFetched.profileImage,
             let imageData = Data(base64Encoded: base64ImageString),
             let image     = UIImage(data: imageData) {
             let bio = currentUserFetched.bio
                     DispatchQueue.main.async {
                         self.profileImage = image
                         self.bio = bio
                     }
                 }
             }
     }
    
     func showFriendName(friendID: String) async -> String {
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
    
     func loadFriendNames() {
           Task {
               for friend in user.friends {
                   let name = await showFriendName(friendID: friend.friendID)
                   DispatchQueue.main.async {
                       self.friendNames[friend.friendID] = name // Speichert den geladenen Namen
                       if self.friendNames.count == self.user.friends.count {
                           self.isLoading = false // Alle Namen wurden geladen
                       }
                   }
               }
           }
       }
    
}
