//
//  PostService.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 11.12.24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class PostService {
    static let shared = PostService()
    private let db = Firestore.firestore()
    
    func postToFirestoreDB(senderID: String, postTitle: String, postMessage: String) {
        let data: [String: Any] = [
            "senderID": senderID,
            "title": postTitle,
            "message": postMessage,
            "timestamp": Timestamp(),
            "likes": [
                "likesCount": 0,
                "senderIDs": []
            ]
        ]
        db.collection("posts").addDocument(data: data) { error in
            if let error = error {
                print("Error uploading Post to FireStore: \(error)")
            } else {
                print("Post uploaded to Firestore successfully!")
            }
        }
    }
    
    func addCommentToPost(postID: String, senderID: String, comment: String) async throws {
        let commentData: [String: Any] = [
            "senderID": senderID,
            "comment": comment,
            "timestamp": Timestamp(),
            "likes": [
                "likesCount": 0,
                "senderIDs": []
            ]
        ]
        try await db.collection("posts").document(postID).collection("comments").addDocument(data: commentData)
    }
    
    func addOrRemoveLikeFromPost(postID: String, senderID: String) async throws {
        let postRef = db.collection("posts").document(postID)
        do {
            let postDocument = try await postRef.getDocument()
            guard let data = postDocument.data(),
                    let likesData = data["likes"] as? [String: Any],
                    let senderIDs = likesData["senderIDs"] as? [String] else {
                throw NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve likes data"])
            }
            
            // MARK: Prüfen, ob der Nutzer den Post schon geliket hat
            if senderIDs.contains(senderID) {
                // MARK: Like wieder vom Post entfernen
                try await postRef.updateData([
                    "likes.likesCount": FieldValue.increment(Int64(-1)),
                    "likes.senderIDs": FieldValue.arrayRemove([senderID])
                ])
            } else {
                // MARK: Post liken
                try await postRef.updateData([
                    "likes.likesCount": FieldValue.increment(Int64(1)),
                    "likes.senderIDs": FieldValue.arrayUnion([senderID])
                ])
                print("Like added to post successfully!")
            }
        } catch {
            print("Error adding like to post: \(error)")
            throw error
        }
    }
    
    func isPostLikedByUser(postID: String, senderID: String) async throws -> Bool {
        let postRef = db.collection("posts").document(postID)
        let postDoc = try await postRef.getDocument()
        guard let data = postDoc.data(),
              let likesData = data["likes"] as? [String: Any],
              let senderIDs = likesData["senderIDs"] as? [String] else {
            return false
        }
        return senderIDs.contains(senderID)
    }
    
    func isCommentLikedByUser(postID: String, commentID: String, senderID: String) async throws -> Bool {
        let commentForPostRef = db.collection("posts").document(postID).collection("comments").document(commentID)
        let commentDoc = try await commentForPostRef.getDocument()
        guard let data = commentDoc.data(),
              let likesData = data["likes"] as? [String: Any],
              let senderIDs = likesData["senderIDs"] as? [String] else {
            return false
        }
        return senderIDs.contains(senderID)
    }

    
    func addOrRemoveLikeFromComment(postID: String, commentID: String, senderID: String) async throws {
        let commentForPostRef = db.collection("posts").document(postID).collection("comments").document(commentID)
        do {
            let commentDoc = try await commentForPostRef.getDocument()
            guard let data = commentDoc.data(),
                  let likesData = data["likes"] as? [String: Any],
                  let senderIDs = likesData["senderIDs"] as? [String] else {
                throw NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve likes data"])
            }
            // MARK: Prüfen, ob der Nutzer den Post schon geliket hat
            if senderIDs.contains(senderID) {
                // MARK: Like wieder vom Post entfernen
                
                let updatedSenderIDs = senderIDs.filter { $0 != senderID }
                
                try await commentForPostRef.updateData([
                    "likes.senderIDs": FieldValue.arrayRemove([senderID]),
                    "likes.likesCount": updatedSenderIDs.count
                    
                ])
            } else {
                // MARK: Post liken
                let updatedSenderIDs = senderIDs + [senderID]
                
                try await commentForPostRef.updateData([
                    "likes.senderIDs": FieldValue.arrayUnion([senderID]),
                    "likes.likesCount": FieldValue.increment(Int64(1))
            
                ])
                print("Like added to post successfully!")
            }
        } catch {
            print("Error adding like to comment: \(error)")
        }
    }
    
    
    func listenForCommentsUpdates(forPostID postID: String, completion: @escaping (Result<[Comment], Error>) -> Void) -> ListenerRegistration {
        return db.collection("posts").document(postID).collection("comments").addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.failure(NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                return
            }
            
            let comments = snapshot.documents.compactMap { commentDoc -> Comment? in
                let commentData = commentDoc.data()
                guard let senderID = commentData["senderID"] as? String,
                      let comment = commentData["comment"] as? String,
                      let commentTimeStamp = commentData["timestamp"] as? Timestamp,
                      let commentLikesData = commentData["likes"] as? [String: Any],
                      let commentLikesCount = commentLikesData["likesCount"] as? Int,
                      let commentLikeSenderIDS = commentLikesData["senderIDs"] as? [String] else {
                    return nil
                }
                let commentLikes = Likes(likesCount: commentLikesCount, senderIDs: commentLikeSenderIDS)
                
                return Comment(
                    id: commentDoc.documentID,
                    senderID: senderID,
                    comment: comment,
                    timestamp: commentTimeStamp.dateValue(),
                    likes: commentLikes
                )
            }
            completion(.success(comments))
        }
    }

    func listenForPostsUpdates(completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection("posts").addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.failure(NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                return
            }
            
            Task {
                var posts: [Post] = []
                for document in snapshot.documents {
                    let data = document.data()
                    guard let senderID  = data["senderID"] as? String,
                          let title     = data["title"] as? String,
                          let message   = data["message"] as? String,
                          let timeStamp = data["timestamp"] as? Timestamp,
                          let postLikesData = data["likes"] as? [String: Any],
                          let postLikeCount = postLikesData["likesCount"] as? Int,
                          let postLikeSenderIDS = postLikesData["senderIDs"] as? [String] else {
                        continue
                    }
                    let postLikes = Likes(likesCount: postLikeCount, senderIDs: postLikeSenderIDS)
                    
                    // Kommentare abrufen
                    let commentsSnapshot = try? await self.db.collection("posts").document(document.documentID).collection("comments").getDocuments()
                    let comments = commentsSnapshot?.documents.compactMap { commentDoc -> Comment? in
                        let commentData = commentDoc.data()
                        guard let senderID = commentData["senderID"] as? String,
                              let comment = commentData["comment"] as? String,
                              let commentTimeStamp = commentData["timestamp"] as? Timestamp,
                              let commentLikesData = commentData["likes"] as? [String: Any],
                              let commentLikesCount = commentLikesData["likesCount"] as? Int,
                              let commentLikeSenderIDS = commentLikesData["senderIDs"] as? [String] else {
                            return nil
                        }
                        let commentLikes = Likes(likesCount: commentLikesCount, senderIDs: commentLikeSenderIDS)
                        return Comment(
                            id: commentDoc.documentID,
                            senderID: senderID,
                            comment: comment,
                            timestamp: commentTimeStamp.dateValue(),
                            likes: commentLikes
                        )
                    } ?? []
                    
                    // Post erstellen
                    let post = Post(
                        id: document.documentID,
                        senderID: senderID,
                        title: title,
                        message: message,
                        comments: comments,
                        timestamp: timeStamp.dateValue(),
                        likes: postLikes
                    )
                    posts.append(post)
                }
                completion(.success(posts))
            }
        }
    }
}
