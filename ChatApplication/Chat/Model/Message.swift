//
//  Message.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 12.11.24.
//

import Foundation

struct ChatMessage {
    let messageID: String
    let displayName: String
    let message: String
    let senderID: String
    let receiverID: String?
    let receiverIDs: [String]?
    let receiverReadMessage: Bool
    let timestamp: Date
    let isAudio: Bool
}
