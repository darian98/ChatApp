//
//  FriendService.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 14.11.24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


class FriendService {
    
    static let shared = FriendService()
    private let db = Firestore.firestore()
    
    // Methode, um eine Freundschaftsanfrage zu senden
        func sendFriendRequest(from senderID: String, to recipientID: String) {
            let data: [String: Any] = [
                "senderID": senderID,
                "recipientID": recipientID,
                "status": "pending",
                "timestamp": Timestamp()
            ]
            db.collection("friendRequests").addDocument(data: data) { error in
                if let error = error {
                    print("Error sending friend request: \(error)")
                } else {
                    print("Friend request sent successfully")
                }
            }
        }
    
    func alreadyFriends(from senderID: String, to recipientID: String, completion: @escaping (Bool) -> Void) {
        fetchFriends(for: senderID) { friends in
            var isAlreadyFriend = false
            for friend in friends {
                if friend.friendID == recipientID {
                    isAlreadyFriend = true
                    break
                }
            }
            completion(isAlreadyFriend)
        }
    }

    
    
    // Methode, um Freundschaftsanfragen für den aktuellen Benutzer zu beobachten
        func observeFriendRequests(for userID: String, completion: @escaping ([FriendRequest]) -> Void) {
            db.collection("friendRequests")
                .whereField("recipientID", isEqualTo: userID)
                .whereField("status", isEqualTo: "pending")
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let requests = documents.compactMap { doc -> FriendRequest? in
                        let data = doc.data()
                        guard let senderID = data["senderID"] as? String,
                              let recipientID = data["recipientID"] as? String,
                              let timestamp = data["timestamp"] as? Timestamp,
                              let status = data["status"] as? String else { return nil }
                        return FriendRequest(id: doc.documentID, senderID: senderID, recipientID: recipientID, status: status, timestamp: timestamp.dateValue())
                    }
                    completion(requests)
                }
        }
    // Methode, um eine Freundschaftsanfrage zu akzeptieren oder abzulehnen
       func respondToFriendRequest(requestID: String, accept: Bool) {
           let newStatus = accept ? "accepted" : "rejected"
           db.collection("friendRequests").document(requestID).updateData(["status": newStatus]) { error in
               if let error = error {
                   print("Error updating friend request: \(error)")
               } else {
                   print("Friend request \(accept ? "accepted" : "rejected")")
                   if accept {
                       self.addFriend(requestID: requestID)
                       // Hier Freundschaftsdaten speichern (z.B. in einer neuen Collection "friends")
                   }
               }
           }
       }
    private func addFriend(requestID: String) {
        // Hole die Freundschaftsanfrage, um Sender- und Empfänger-ID zu bekommen
        db.collection("friendRequests").document(requestID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                guard let senderID = data?["senderID"] as? String,
                      let recipientID = data?["recipientID"] as? String else {
                    return
                }
                
                // Füge die Freundschaft für beide Benutzer als Unterkollektion hinzu
                // Für den Absender
                self.db.collection("users").document(senderID).collection("friends").addDocument(data: [
                    "friendID": recipientID,
                    "timestamp": Timestamp()
                ]) { error in
                    if let error = error {
                        print("Error adding friend to sender: \(error)")
                    } else {
                        print("Friend added to sender")
                    }
                }
                
                // Für den Empfänger
                self.db.collection("users").document(recipientID).collection("friends").addDocument(data: [
                    "friendID": senderID,
                    "timestamp": Timestamp()
                ]) { error in
                    if let error = error {
                        print("Error adding friend to recipient: \(error)")
                    } else {
                        print("Friend added to recipient")
                    }
                }
            } else {
                print("Friend request not found.")
            }
        }
    }
    func fetchFriends(for userID: String, completion: @escaping ([Friend]) -> Void) {
        db.collection("users").document(userID).collection("friends")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching friends: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let friends = documents.compactMap { doc -> Friend? in
                    let data = doc.data()
                    guard let friendID = data["friendID"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    return Friend(friendID: friendID, timestamp: timestamp.dateValue())
                }
                completion(friends)
            }
    }
}
