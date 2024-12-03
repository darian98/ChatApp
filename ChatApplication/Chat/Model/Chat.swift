//
//  Chat.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 15.11.24.
//

import Foundation

struct Chat {
    let chatID: String
    let lastMessage: LastMessage
    let participantIDs: [String]
    let isTyping: [String]
    let timestamp: Date
    var messages: [ChatMessage]
}

struct LastMessage {
    let senderID: String
    let message: String
    let isAudio: Bool
    
    init?(from dictionary: [String: Any]) {
        guard let senderID = dictionary["senderID"] as? String,
              let message = dictionary["message"] as? String,
              let isAudio = dictionary["isAudio"] as? Bool
        else {
            return nil
        }
        self.senderID = senderID
        self.message = message
        self.isAudio = isAudio
    }
}
