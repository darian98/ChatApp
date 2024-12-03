//
//  UserService.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 15.11.24.
//

import Foundation
import FirebaseFirestore

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    // MARK: Alle User fetchen...
    func fetchAllUsers() async throws -> [UserModel] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let uid = data["uid"] as? String,
                  let displayName = data["displayName"] as? String,
                  let email = data["email"] as? String,
                  let bio   = data["bio"] as? String,
                  let profileImage = data["profileImage"] as? String?
            else {
                return nil
            }
            return UserModel(uid: uid, displayName: displayName, email: email, bio: bio, profileImage: profileImage)
        }
    }
    // MARK: User über die ID fetchen...
    func fetchUser(byID uid: String) async throws -> UserModel? {
        let document = try await db.collection("users").document(uid).getDocument()
        guard let data = document.data(),
              let displayName = data["displayName"] as? String,
              let email = data["email"] as? String,
              let bio   = data["bio"] as? String,
              let profileImage = data["profileImage"] as? String?
        else {
            return nil
        }
        return UserModel(uid: uid, displayName: displayName, email: email, bio: bio, profileImage: profileImage)
    }
    
    // MARK: User über den DisplayName fetchen...
    func fetchUser(byDisplayName displayName: String) async throws -> UserModel? {
        let query = db.collection("users").whereField("displayName", isEqualTo: displayName)
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil // Kein Benutzer mit diesem Display-Namen gefunden
        }
        
        let data = document.data()
        guard let uid = data["uid"] as? String,
              let email = data["email"] as? String,
              let bio   = data["bio"] as? String,
              let profileImage = data["profileImage"] as? String?
        else {
            return nil
        }
        return UserModel(uid: uid, displayName: displayName, email: email, bio: bio, profileImage: profileImage)
    }
}
