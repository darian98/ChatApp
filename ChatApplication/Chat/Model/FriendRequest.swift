//
//  FriendRequest.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 14.11.24.
//

import Foundation
// Model für Freundschaftsanfragen
struct FriendRequest {
    let id: String
    let senderID: String
    let recipientID: String
    let status: String
    let timestamp: Date
}
