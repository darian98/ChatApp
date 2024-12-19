//
//  PostsViewModel.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 11.12.24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

enum UserNameFor {
    case posts, friendList
}

class PostsViewModel: ObservableObject {
    @Published var currentUser: UserModel
    @Published var posts: [Post] = []
    @Published var editMode: Bool = false
    @Published var commentMode: Bool = false
    @Published var commentText: String = ""

    @Published var showCommentSheet: Bool = false
    @Published var selectedPost: Post? = nil
    
    @Published var userNames: [String: String] = [:]
    @Published var postIDsLikedByCurrentUser: [String] = []
    @Published var commentIDsLikedByCurrentUser: [String] = []
    
    @Published var isProcessingLikeForPost: Bool = false
    @Published var isProcessingLikeForComment: Bool = false
    
    @Published var showShareListSheet: Bool = false
    @Published var friendsNames: [String: String] = [:]
    @Published var friendRowIsChecked: [String: Bool] = [:]
    
    private var commentListeners: [String: ListenerRegistration] = [:]
    
    init(currentUser: UserModel) {
        self.currentUser = currentUser
        listenForPosts()
    }
    // MARK: Function to add listener for new posts
    func listenForPosts() {
        PostService.shared.listenForPostsUpdates { [weak self] result in
            switch result {
            case .success(let posts):
                DispatchQueue.main.async {
                    self?.posts = posts
                }
            case .failure(let error):
                print("Error listening for posts updates: \(error)")
            }
        }
    }
    
    // MARK: Function to add listener for any new comments in a specific post
    func listenForComments(for post: Post) {
        
        stopListeningForComments(for: post)
        
        let listener = PostService.shared.listenForCommentsUpdates(forPostID: post.id) { [weak self] result in
            switch result {
            case .success(let updatedComments):
                DispatchQueue.main.async {
                    if let index = self?.posts.firstIndex(where: { $0.id == post.id }) {
                        self?.posts[index].comments = updatedComments
                        if self?.selectedPost?.id == post.id {
                            self?.selectedPost?.comments = updatedComments
                        }
                    }
                }
            case .failure(let error):
                print("Error listening for comments: \(error)")
            }
        }
        commentListeners[post.id] = listener
    }
    
    // MARK: Falls vorhanden, wird der Listener für die Kommentare eines bestimmten Post entfernt.
    func stopListeningForComments(for post: Post) {
            // Entferne Listener für den Post, falls vorhanden
        if let listener = commentListeners[post.id] {
            print("Listener found for post \(post.id), removing it.")
            listener.remove()
            commentListeners[post.id] = nil
        } else {
            print("No listener found for post: \(post.id)")
        }
    }
    
    // MARK: Alle Listener werden entfernt
    func stopAllCommentListeners() {
            commentListeners.values.forEach { $0.remove() }
            commentListeners.removeAll()
        }
    
    
    // MARK: Checking if the post is liked by the current user, if so, adding it to the local list with the IDs of the liked posts
    func fetchIsPostLiked(postID: String, senderID: String) {
        Task {
            let postLiked = await isPostLikedByCurrentUser(postID: postID, senderID: senderID)
            if postLiked {
                DispatchQueue.main.async {
                    self.postIDsLikedByCurrentUser.append(postID)
                }
            }
        }
    }
    // MARK: Fetching if the post is liked by the currentUser from FireStore asynchronously
    func isPostLikedByCurrentUser(postID: String, senderID: String) async -> Bool {
        do {
            let isPostLiked = try await PostService.shared.isPostLikedByUser(postID: postID, senderID: senderID)
            return isPostLiked
        } catch {
            print("Error fetching isPostLiked for post: \(error)")
        }
        return false
    }
    
    // MARK: Checking if the comment is liked by the current user, if so, adding it to the local list with the IDs of the liked comments
    func fetchIsCommentLiked(postID: String, commentID: String, senderID: String) {
        Task {
            let isLiked = await isCommentLikedByCurrentUser(postID: postID, commentID: commentID, senderID: senderID)
            if isLiked {
                DispatchQueue.main.async {
                    self.commentIDsLikedByCurrentUser.append(commentID)
                }
            }
        }
    }
    
    // MARK: Fetching if the comment is liked by the currentUser from FireStore asynchronously
    func isCommentLikedByCurrentUser(postID: String, commentID: String, senderID: String) async -> Bool {
            do {
                let isCommentLiked = try await PostService.shared.isCommentLikedByUser(postID: postID, commentID: commentID, senderID: senderID)
                
                return isCommentLiked
            } catch {
                print("Error fetching isComemntLikedByUser for post: \(error)")
            }
            return false
    }
    
    // MARK: Adding like to a specific post
    @MainActor
    func addLikeToPost(post: Post, senderID: String) {
        guard !isProcessingLikeForPost else { return }
        isProcessingLikeForPost = true
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromPost(postID: post.id, senderID: senderID)
                self.postIDsLikedByCurrentUser.append(post.id)
                print("ADDING - PostIDSLikedByUserCount: \(self.postIDsLikedByCurrentUser.count)")
            } catch {
                print("Failed to add like: \(error)")
            }
            isProcessingLikeForPost = false
        }
    }
    
    // MARK: Removing like from a specific post
    func removeLikeFromPost(post: Post, senderID: String) {
        guard !isProcessingLikeForPost else { return }
        isProcessingLikeForPost = true
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromPost(postID: post.id, senderID: senderID)
                DispatchQueue.main.async {
                    self.postIDsLikedByCurrentUser.removeAll { $0 == post.id }
                    print("REMOVING - PostIDSLikedByUserCount: \(self.postIDsLikedByCurrentUser.count)")
                }
            } catch {
                print("Failed to add like: \(error)")
            }
            DispatchQueue.main.async {
                self.isProcessingLikeForPost = false
            }
        }
    }
    
    // MARK: Adding like to a specific comment
    func addLikeToComment(postID: String, commentID: String, senderID: String) {
        guard !isProcessingLikeForComment else { return }
        isProcessingLikeForComment = true
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromComment(postID: postID, commentID: commentID, senderID: senderID)
                DispatchQueue.main.async {
                    self.commentIDsLikedByCurrentUser.append(commentID)
                }
            } catch {
                print("Error adding like to Comment: \(error)")
            }
            DispatchQueue.main.async {
                self.isProcessingLikeForComment = false
            }
        }
    }
    
    // MARK: Removing like from a specific post
    func removeLikeFromComment(postID: String, commentID: String, senderID: String) {
        guard !isProcessingLikeForComment else { return }
        isProcessingLikeForComment = true
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromComment(postID: postID, commentID: commentID, senderID: senderID)
                DispatchQueue.main.async {
                    self.commentIDsLikedByCurrentUser.removeAll { $0 == commentID }
                }
            } catch {
                print("Error removing like from Comment: \(error)")
            }
            DispatchQueue.main.async {
                self.isProcessingLikeForComment = false
            }
        }
    }
   
    // MARK: Loading user names for comment senders
    @MainActor
    func loadUserName(for senderID: String, userNameFor: UserNameFor) async {
        if userNameFor == .posts {
            guard userNames[senderID] == nil else { return }
        } else if userNameFor == .friendList {
            guard friendsNames[senderID] == nil else { return}
        }
        // Vermeide doppelte Anfragen
        do {
            guard let user = try await UserService.shared.fetchUser(byID: senderID) else { return }
            if userNameFor == .posts {
                self.userNames[senderID] = user.displayName
            } else if userNameFor == .friendList {
                self.friendsNames[senderID] = user.displayName
            }
        } catch {
            print("Fehler beim Laden des Benutzernamens für \(senderID): \(error.localizedDescription)")
            if userNameFor == .posts {
                self.userNames[senderID] = "Fehler beim Laden"
            } else if userNameFor == .friendList {
                self.friendsNames[senderID] = "Fehler beim Laden"
            }
        }
    }
    //MARK: NOT USED YET
    func loadAllUserNames(friendIDs: [String]) async {
            for friendID in friendIDs {
                if self.friendsNames[friendID] == nil {
                    await loadUserName(for: friendID, userNameFor: .friendList)
                }
            }
        }
    
    func updateFriendRowClicked(friendID: String) {
        if friendRowIsChecked[friendID] == nil {
            friendRowIsChecked[friendID] = true
        } else {
            if let rowIsChecked = friendRowIsChecked[friendID] {
                if rowIsChecked {
                    friendRowIsChecked[friendID] = false
                } else {
                    friendRowIsChecked[friendID] = true
                }
            }
        }
    }
    
    func isFriendRowClicked(friendID: String) -> Bool {
        return friendRowIsChecked[friendID] ?? false
    }
    
    
}
