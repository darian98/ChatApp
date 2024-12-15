//
//  PostsView.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 11.12.24.
//

import Foundation
import SwiftUI


struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var message: String = ""
    var currentUser: UserModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Titel eingeben", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Nachricht eingeben", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Spacer()
            }
            .navigationTitle("Post erstellen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        PostService.shared.postToFirestoreDB(senderID: currentUser.uid, postTitle: title, postMessage: message)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || message.isEmpty)
                }
            }
        }
    }
}

struct PostsView: View {
    @ObservedObject var viewModel: PostsViewModel
    var currentUser: UserModel
    
    var body: some View {
        VStack {
                postsList
        }
        .onAppear {
            //viewModel.fetchPosts()
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
                    if let postingUserName = viewModel.userNames[post.senderID] {
                        Text(postingUserName)
                            .font(.headline)
                    } else {
                        Text("Lade Benutzername...")
                            .font(.headline)
                            .foregroundStyle(.gray)
                            .task {
                                await viewModel.loadUserName(for: post.senderID)
                            }
                    }
                    Text(post.title)
                        .font(.title3)
                    Text(post.message)
                        .font(.subheadline)
                    
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
                            commentlikeButtonBeta(postID: post.id, commentID: comment.id, commentsLikes: comment.likes)
                            
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
    
    private func commenterUserImage(for comment: Comment) -> some View {
        Group {
            if let userImageString = viewModel.userProfileImages[comment.senderID] {
                if let imageData     = Data(base64Encoded: userImageString),
                   let image            = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        .shadow(radius: 2)
                        
                }
            } else {
                    Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    .shadow(radius: 2)
                    .task {
                        await viewModel.loadUserImages(for: comment.senderID)
                    }
            }
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
    
    private func commentlikeButton(postID: String, commentID: String) -> some View {
        Button {
            if !viewModel.commentIDsLikedByCurrentUser.contains(commentID) {
                viewModel.addLikeToComment(postID: postID, commentID: commentID, senderID: currentUser.uid)
            } else {
                viewModel.removeLikeFromComment(postID: postID, commentID: commentID, senderID: currentUser.uid)
            }
        } label: {
            Image(systemName: viewModel.commentIDsLikedByCurrentUser.contains(commentID) ? "heart.fill": "heart")
                .font(.caption)
        }
        .onAppear {
            viewModel.fetchIsCommentLiked(postID: postID, commentID: commentID, senderID: currentUser.uid)
        }
    }
    
    private func commentlikeButtonBeta(postID: String, commentID: String, commentsLikes: Likes) -> some View {
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
        .onAppear {
            //viewModel.fetchIsCommentLiked(postID: postID, commentID: commentID, senderID: currentUser.uid)
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
                    //viewModel.fetchPosts()
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
