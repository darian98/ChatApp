//
//  Post.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 11.12.24.
//

import Foundation


struct Post: Identifiable {
    let id: String
    let senderID: String
    let title: String
    let message: String
    var comments: [Comment]
    var timestamp: Date
    var likes: Likes
}

struct Comment: Identifiable {
    var id: String
    let senderID: String
    let comment: String
    var timestamp: Date
    var likes: Likes
}

struct Likes {
    var likesCount: Int = 0
    var senderIDs: [String]
}


