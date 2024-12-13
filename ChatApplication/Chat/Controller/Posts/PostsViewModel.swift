//
//  PostsViewModel.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 11.12.24.
//

import Foundation
import SwiftUI


class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var editMode: Bool = false
    @Published var commentMode: Bool = false
    @Published var commentText: String = ""
    @Published var userNames: [String: String] = [:]
    
    @Published var commentVisibility: [String: Bool] = [:]
    @Published var showCommentSheet: Bool = false
    @Published var selectedPost: Post? = nil
    
    @Published var postIDsLikedByCurrentUser: [String] = []
    @Published var commentIDsLikedByCurrentUser: [String] = []
    
    init() {
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
        PostService.shared.listenForCommentsUpdates(forPostID: post.id) { [weak self] result in
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
    
    func addLikeToPost(post: Post, senderID: String) {
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromPost(postID: post.id, senderID: senderID)
                DispatchQueue.main.async {
                    self.postIDsLikedByCurrentUser.append(post.id)
                    print("ADDING - PostIDSLikedByUserCount: \(self.postIDsLikedByCurrentUser.count)")
                }
            } catch {
                print("Failed to add like: \(error)")
            }
        }
    }
    
    func removeLikeFromPost(post: Post, senderID: String) {
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
        }
    }
    
    func addLikeToComment(postID: String, commentID: String, senderID: String) {
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromComment(postID: postID, commentID: commentID, senderID: senderID)
                DispatchQueue.main.async {
                    self.commentIDsLikedByCurrentUser.append(commentID)
                }
            } catch {
                print("Error adding like to Comment: \(error)")
            }
        }
    }
    func removeLikeFromComment(postID: String, commentID: String, senderID: String) {
        Task {
            do {
                try await PostService.shared.addOrRemoveLikeFromComment(postID: postID, commentID: commentID, senderID: senderID)
                DispatchQueue.main.async {
                    self.commentIDsLikedByCurrentUser.removeAll { $0 == commentID }
                }
            } catch {
                print("Error removing like from Comment: \(error)")
            }
        }
    }
    
    
    
    
     func loadUserName(for senderID: String) async {
        guard userNames[senderID] == nil else { return } // Vermeide doppelte Anfragen
        do {
            guard let user = try await UserService.shared.fetchUser(byID: senderID) else { return }
            DispatchQueue.main.async {
                self.userNames[senderID] = user.displayName
            }
        } catch {
            print("Fehler beim Laden des Benutzernamens für \(senderID): \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.userNames[senderID] = "Fehler beim Laden"
            }
        }
    }
    
    func toggleComments(for postID: String) {
        if let isVisible = commentVisibility[postID] {
            commentVisibility[postID] = !isVisible
        } else {
            commentVisibility[postID] = true
        }
    }

    func isCommentVisible(for postID: String) -> Bool {
        return commentVisibility[postID] ?? false
    }
    
}
