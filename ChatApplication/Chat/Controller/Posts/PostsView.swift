//
//  PostsView.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 11.12.24.
//

import Foundation
import SwiftUI

struct PostsView: View {
    @ObservedObject var viewModel: PostsViewModel
    var currentUser: UserModel
    @StateObject private var imageLoader = AsyncImageLoader()
    
    var body: some View {
        VStack {
                postsList
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.editMode.toggle()
                }) {
                Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.editMode, content: {
            CreatePostView(currentUser: currentUser)
        })
        .navigationTitle(viewModel.posts.isEmpty ? "Keine Posts vorhanden": "Posts")
    }
}

extension PostsView {
    private var postsList: some View {
        List {
            ForEach(viewModel.posts) { post in
                VStack {
                    HStack {
                        postingUserImage(for: post)
                        
                        if let postingUserName = viewModel.userNames[post.senderID] {
                            Text(postingUserName)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        } else {
                            Text("Lade Benutzername...")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .task {
                                    await viewModel.loadUserName(for: post.senderID)
                                }
                        }
                        Text(post.title)
                            .font(.subheadline)
                            .padding(.leading, 20)
                            .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    if let imageString  = post.imageString,
                       let imageData    = Data(base64Encoded: imageString),
                       let uiimage = UIImage(data: imageData)
                    {
                        Image(uiImage: uiimage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }
                    
                    Text(post.message)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                    
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.selectedPost = post
                                viewModel.showCommentSheet.toggle()
                                viewModel.listenForComments(for: post)
                            }
                        }, label: {
                            HStack {
                                Text("Kommentare anzeigen (\(post.comments.count))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Image(systemName: "bubble")
                                    .font(.caption)
                            }
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        })
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        VStack {
                            Button {
                                if !viewModel.postIDsLikedByCurrentUser.contains(post.id) {
                                    viewModel.addLikeToPost(post: post, senderID: currentUser.uid)
                                } else {
                                    viewModel.removeLikeFromPost(post: post, senderID: currentUser.uid)
                                }
                            } label: {
                                Image(systemName: viewModel.postIDsLikedByCurrentUser.contains(post.id) ? "heart.fill" : "heart")
                                    .foregroundStyle(viewModel.postIDsLikedByCurrentUser.contains(post.id) ? .red : .black)
                                    .font(.headline)
                            }
                            .onAppear {
                                viewModel.fetchIsPostLiked(postID: post.id, senderID: currentUser.uid)
                            }
                            
                            Text("\(String(post.likes.likesCount))")
                                .font(.caption2)
                                .padding(.top, 4)
                        }
                    }
            }
        }
            .sheet(isPresented: $viewModel.showCommentSheet, onDismiss: {
                print("Ondismiss getting triggered!")
                if let selectedPost = viewModel.selectedPost {
                       viewModel.stopListeningForComments(for: selectedPost)
                   }
            }, content: {
                if let selectedPost = viewModel.selectedPost {
                    commentSheet(for: selectedPost)
                        .presentationDetents([.height(UIScreen.main.bounds.size.height * 0.65)])
                        .presentationDragIndicator(.visible)
                }
            })
    }
  }
    
    private func commentSection(for post: Post) -> some View {
        ScrollView {
            ForEach(post.comments.sorted { $0.timestamp > $1.timestamp }) { comment in
                VStack {
                    HStack(alignment: .center) {
                        commenterUserImage(for: comment)
                        commentData(for: comment)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer().frame(width: 100)
                        HStack {
                            commentlikeButton(postID: post.id, commentID: comment.id, commentsLikes: comment.likes)
                            
                            commentLikesCountText(likesCount: comment.likes.likesCount)
                        }
                        .frame(width: 36)
                        .padding(.bottom, 6)
                        .padding(.trailing, 16)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .cornerRadius(8)
                    Divider().background(.white)
                }
            }
        }
    }
    
    private func postingUserImage(for post: Post) -> some View {
        Group {
            if let image = imageLoader.postingUserImages[post.senderID] {
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
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .shadow(radius: 2)
            }
        }
        .task(id: post.senderID) {
            await imageLoader.loadUserImage(for: post.senderID, imagesFor: .postingUser)
        }
    }
    
    private func commenterUserImage(for comment: Comment) -> some View {
        Group {
            if let image = imageLoader.commenterImages[comment.senderID] {
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
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .shadow(radius: 2)
            }
        }
        .task(id: comment.senderID) {
            await imageLoader.loadUserImage(for: comment.senderID, imagesFor: .commentingUser)
        }
    }
    
    private func commentData(for comment: Comment) -> some View {
        Group {
            if let commenterName = viewModel.userNames[comment.senderID] {
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(commenterName)")
                            .fontWeight(.bold)
                        Text(timestampDisplay(for: comment.timestamp))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    Text("\(comment.comment)")
                        .padding(.top, 4)
                }
                .padding(6)
            } else {
                Text("Lade Benutzername...")
                    .task {
                        await viewModel.loadUserName(for: comment.senderID)
                    }
            }
        }
        .font(.caption)
        .foregroundStyle(.white)
    }
    
    private func timestampDisplay(for date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 3600 { // Weniger als eine Stunde
            let minutes = Int(interval / 60) // Minuten genau berechnen
            if minutes < 1 {
                return "Gerade eben"
            }
            return "vor \(minutes) Minuten"
        } else if interval < 86400 { // Weniger als ein Tag
            let hours = Int(interval / 3600)
            return "vor \(hours) Std."
        } else if interval < 7 * 86400 { // Weniger als eine Woche
            let days = Int(interval / 86400)
            return "vor \(days) Tagen"
        } else { // Mehr als eine Woche
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func commentLikesCountText(likesCount: Int) -> some View {
        Text("\(likesCount)")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.leading, 4)
    }
    
    private func commentlikeButton(postID: String, commentID: String, commentsLikes: Likes) -> some View {
        Button {
            if ifCommentWasLikedByUser(commentsLikes: commentsLikes, userID: currentUser.uid) {
                viewModel.addLikeToComment(postID: postID, commentID: commentID, senderID: currentUser.uid)
            } else {
                viewModel.removeLikeFromComment(postID: postID, commentID: commentID, senderID: currentUser.uid)
            }
        } label: {
            Image(systemName: ifCommentWasLikedByUser(commentsLikes: commentsLikes, userID: currentUser.uid) ? "heart.fill": "heart")
                .foregroundStyle(ifCommentWasLikedByUser(commentsLikes: commentsLikes, userID: currentUser.uid) ? .red : .white)
                .font(.caption)
        }
    }
    
    private func ifCommentWasLikedByUser(commentsLikes: Likes, userID: String) -> Bool {
        return commentsLikes.senderIDs.contains(userID)
    }
    
    
    private func commentInputView(for post: Post) -> some View {
        HStack {
            TextField("Kommentar eingeben", text: $viewModel.commentText)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .foregroundStyle(.white)
                .cornerRadius(8)
            Button {
                Task {
                    do {
                        try await PostService.shared.addCommentToPost(postID: post.id, senderID: currentUser.uid, comment: viewModel.commentText)
                        viewModel.commentText = ""
                        print("PostID: \(post.id)")
                    } catch {
                        print("ERROR")
                    }
                }
            } label: {
                Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .disabled(viewModel.commentText.isEmpty)
        }
        .padding()
    }
    
    private func commentSheet(for post: Post) -> some View {
            VStack(alignment: .leading) {
                commentSection(for: post)
                commentInputView(for: post)
            }
                .background(Color.gray.opacity(0.5))
                .cornerRadius(16)
                .shadow(radius: 10)
    }
    
}
