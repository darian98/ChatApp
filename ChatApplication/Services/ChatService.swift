//
//  ChatService.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 12.11.24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import CryptoKit
import Security


class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()
    
    func sendMessage2(chatID: String, message: String, receiverIDs: [String] ,senderID: String, displayName: String) {
        let randomID = UUID().uuidString
        
        let data: [String: Any] = [
            "messageID": randomID,
            "message": message,
            "receiverIDs": receiverIDs,
            "senderID": senderID,
            "displayName": displayName,
            "receiverReadMessage": false,
            "timestamp": Timestamp(),
            "isAudio": false
        ]
        db.collection("chats").document(chatID).collection("messages").addDocument(data: data) { error in
            if let error = error {
                print("Error adding message: \(error)")
            } else {
                print("Message added successfully to chat \(chatID)")
                let lastMessageData: [String: Any] = [
                    "senderID": senderID,
                    "message" : message
                ]
                // Update last message in chat document
                self.db.collection("chats").document(chatID).updateData([
                    "lastMessage": lastMessageData,
                    "timestamp": Timestamp()
                ]){ error in
                    if let error = error {
                        print("Fehler beim Aktualisieren der lastMessage: \(error.localizedDescription)")
                    } else {
                        print("lastMessage erfolgreich aktualisiert für Chat \(chatID)")
                    }
                }
            }
        }
    }
    
    func sendMessage3(chatID: String, message: String, receiverIDs: [String] ,senderID: String, displayName: String, key: SymmetricKey) {
        let randomID = UUID().uuidString
        
        guard let encryptedMessage = encryptMessage(message: message, key: key) else {
                print("Fehler: Nachricht konnte nicht verschlüsselt werden.")
                return
            }
        
        let data: [String: Any] = [
            "messageID": randomID,
            "message": encryptedMessage.base64EncodedString(),
            "receiverIDs": receiverIDs,
            "senderID": senderID,
            "displayName": displayName,
            "receiverReadMessage": false,
            "timestamp": Timestamp(),
            "isAudio": false
        ]
        db.collection("chats").document(chatID).collection("messages").document(randomID).setData(data){ error in
            if let error = error {
                print("Error adding message: \(error)")
            } else {
                print("Message added successfully to chat \(chatID)")
                let lastMessageData: [String: Any] = [
                    "senderID": senderID,
                    "message" : message,
                    "isAudio" : false
                ]
                // Update last message in chat document
                self.db.collection("chats").document(chatID).updateData([
                    "lastMessage": lastMessageData,
                    "timestamp": Timestamp()
                ]){ error in
                    if let error = error {
                        print("Fehler beim Aktualisieren der lastMessage: \(error.localizedDescription)")
                    } else {
                        print("lastMessage erfolgreich aktualisiert für Chat \(chatID)")
                    }
                }
            }
        }
    }
    
    func startChat2(currentUser: UserModel, with users: [UserModel], viewController: UIViewController) {
        var userIDs = [String]()
        let currentUserID = Auth.auth().currentUser?.uid ?? ""
        userIDs.append(currentUserID)
        
        for user in users {
            if currentUserID == user.uid {
                print("Chat mit sich selbst ist nicht erlaubt")
                return
            } else {
                userIDs.append(user.uid)
            }
        }
        
        let chatID = generateChatID2(userIDs: userIDs)
        
        // Prüfen, ob der Chat bereits existiert
        db.collection("chats").document(chatID).getDocument { document, error in
            if let document = document, document.exists {
                // Chat existiert bereits, öffne den Chat
                self.openChat2(currentUser: currentUser, usersToChatWith: users, chatID: chatID, viewController: viewController)
            } else {
                // Neuer Chat erstellen
                let chatData: [String: Any] = [
                    "chatID": chatID,
                    "lastMessage": "",
                    "participants": userIDs,
                    "isTyping": [],
                    "timestamp": Timestamp()
                ] 
                self.db.collection("chats").document(chatID).setData(chatData) { error in
                    if let error = error {
                        print("Fehler beim Erstellen des Chats: \(error)")
                    } else {
                        print("Neuer Chat erstellt mit ChatID: \(chatID)")
                        self.openChat2(currentUser: currentUser, usersToChatWith: users, chatID: chatID, viewController: viewController)
                    }
                }
            }
        }
    }
    
    // Erzeugt eine eindeutige ID, basierend auf den User-IDs der Teilnehmer
    private func generateChatID2(userIDs: [String]) -> String {
        let sortedIDs = userIDs.sorted()
        return sortedIDs.joined(separator: "_")
    }
    
    func openChat2(currentUser: UserModel, usersToChatWith: [UserModel], chatID: String, viewController: UIViewController) {
        print("Öffne Chat mit ID: \(chatID)")
        
        let chatVC = ChatViewController2(currentUser: currentUser, usersToChatWith: usersToChatWith, chatID: chatID)
        if let navigationController = viewController.navigationController {
                navigationController.pushViewController(chatVC, animated: true)
                updateMessageRead(chatID: chatID, currentUserID: currentUser.uid)
            } else {
                print("Fehler: Kein NavigationController gefunden.")
        }
    }
    
    func updateMessageRead(chatID: String, currentUserID: String) {
        // Nachrichten abrufen, bei denen der receiverID mit der currentUserID übereinstimmt
        db.collection("chats").document(chatID).collection("messages")
            .whereField("receiverID", isEqualTo: currentUserID) // Nur Nachrichten des aktuellen Benutzers abrufen
            .whereField("receiverReadMessage", isEqualTo: false) // Optional: Nur Nachrichten, die noch nicht gelesen wurden
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Fehler beim Abrufen der Nachrichten: \(error)")
                    return
                }
                
                // Jede Nachricht durchgehen und das 'receiverReadMessage'-Feld aktualisieren
                for document in snapshot?.documents ?? [] {
                    self.db.collection("chats").document(chatID).collection("messages").document(document.documentID)
                        .updateData([
                            "receiverReadMessage": true // Markiere als gelesen
                        ]) { error in
                            if let error = error {
                                print("Fehler beim Aktualisieren der Nachricht: \(error)")
                            } else {
                                print("Nachricht erfolgreich als gelesen markiert.")
                            }
                        }
                }
            }
    }
    func observeOtherUsersTyping2(chatID: String, otherUserIDs: [String], completion: @escaping ([String]) -> Void) {
        let docRef = db.collection("chats").document(chatID)
        
        // Firestore Snapshot Listener hinzufügen
        docRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Fehler beim Abrufen von Tipp-Status mit SnapshotListener: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                print("Snapshot oder Daten nicht vorhanden.")
                completion([])
                return
            }
            if let isTypingArray = data["isTyping"] as? [String] {
                    completion(isTypingArray)
            } else {
                print("Fehler: 'isTyping'-Array nicht gefunden.")
                completion([])
            }
        }
    }
    
    func updateUserIsTyping(chatID: String, typingUserID: String, isTyping: Bool) {
        let updateData: [String: Any]
        
        if isTyping {
            updateData = ["isTyping": FieldValue.arrayUnion([typingUserID])]
        } else {
            updateData = ["isTyping": FieldValue.arrayRemove([typingUserID])]
        }
        
        self.db.collection("chats").document(chatID).updateData(updateData) { error in
            if let error = error {
                print("Fehler beim Aktualisieren der isTyping Liste!")
            } else {
                print("UserID des tippenden Nutzers wurde erfolgreich \(isTyping ? "hinzugefügt" : "entfernt")")
            }
        }
    }
    
    // Nachrichten-Listener
    func observeEncryptedMessages(chatID: String, key: SymmetricKey, completion: @escaping ([ChatMessage]) -> Void) {
        db.collection("chats").document(chatID).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let messages = documents.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    guard let encryptedMessage = data["message"] as? String,
                          let encryptedData    = Data(base64Encoded: encryptedMessage),
                          let decryptedMessage  = self.decryptMessage(encryptedData: encryptedData, key: key),
                          let messageID = data["messageID"] as? String,
                          let displayName = data["displayName"] as? String,
                          let senderID = data["senderID"] as? String,
                          let receiverReadMessage = data["receiverReadMessage"] as? Bool,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let isAudio = data["isAudio"] as? Bool
                    else {
                        return nil
                    }

                    // Dynamisch prüfen, ob es ein Gruppenchat oder Einzelchat ist
                    let receiverID = data["receiverID"] as? String
                    let receiverIDs = data["receiverIDs"] as? [String]
                    
                    return ChatMessage(messageID: messageID, displayName: displayName, message: decryptedMessage, senderID: senderID, receiverID: receiverID, receiverIDs: receiverIDs, receiverReadMessage: receiverReadMessage, timestamp: timestamp.dateValue(), isAudio: isAudio)
                }
                completion(messages)
                
            }
    }
    
    // Nachrichten-Listener
    func observeMessages2(chatID: String, completion: @escaping ([ChatMessage]) -> Void) {
        db.collection("chats").document(chatID).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let messages = documents.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    guard let message = data["message"] as? String,
                          let messageID = data["messageID"] as? String,
                          let displayName = data["displayName"] as? String,
                          let senderID = data["senderID"] as? String,
                          let receiverReadMessage = data["receiverReadMessage"] as? Bool,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let isAudio = data["isAudio"] as? Bool
                    else {
                        return nil
                    }

                    // Dynamisch prüfen, ob es ein Gruppenchat oder Einzelchat ist
                    let receiverID = data["receiverID"] as? String
                    let receiverIDs = data["receiverIDs"] as? [String]
                    
                    return ChatMessage(messageID: messageID, displayName: displayName, message: message, senderID: senderID, receiverID: receiverID, receiverIDs: receiverIDs, receiverReadMessage: receiverReadMessage, timestamp: timestamp.dateValue(), isAudio: isAudio)
                }
                completion(messages)
                
            }
    }
    
    func deleteMessage(chatID: String, messageID: String, completion: @escaping (Result<Void, Error>) -> Void) {
           let messageRef = Firestore.firestore().collection("chats").document(chatID).collection("messages").document(messageID)
           
           messageRef.delete { error in
               if let error = error {
                   completion(.failure(error))
               } else {
                   completion(.success(()))
               }
           }
       }
    
    func deleteChat(chatID: String) {
        self.db.collection("chats").document(chatID).delete { deleteError in
        if let deleteError = deleteError {
        print("Fehler beim Löschen des Dokuments: \(deleteError)")
      } else {
        print("Dokument erfolgreich gelöscht: \(chatID)")
        }
       }
    }
    
    func observeChatsForUser2(withID userID: String, completion: @escaping ([Chat]) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: userID) // Filtert Chats, in denen der Benutzer beteiligt ist
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Fehler beim Abrufen der Chats: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Keine Dokumente gefunden")
                    return
                }
                
                print("DocumentCount in Chats: \(documents.count)")
                
                var chats: [Chat] = []
                
                for document in documents {
                    let data = document.data()
                    guard let chatID = data["chatID"] as? String,
                          let lastMessageData = data["lastMessage"] as? [String: Any], // Hole das Dictionary
                          let lastMessage = LastMessage(from: lastMessageData), // Erstelle ein LastMessage-Objekt
                          let participantsIDs = data["participants"] as? [String],
                          let isTyping = data["isTyping"] as? [String],
                          let timestamp = data["timestamp"] as? Timestamp else {
                          print("Fehler beim Verarbeiten eines Dokuments")
                        // Lösche das fehlerhafte Dokument
                        continue
                    }
                    print("Last Message for chat: \(chatID): \(lastMessage.message)")
                    let chat = Chat(
                        chatID: chatID,
                        lastMessage: lastMessage,
                        participantIDs: participantsIDs,
                        isTyping: isTyping,
                        timestamp: timestamp.dateValue(),
                        messages: []
                    )
                    chats.append(chat)
                    
                }
                completion(chats)
            }
    }
    
    func observeChatsForUser3(withID userID: String, getKeyForChat: @escaping (String) -> SymmetricKey?,  completion: @escaping ([Chat]) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: userID) // Filtert Chats, in denen der Benutzer beteiligt ist
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Fehler beim Abrufen der Chats: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Keine Dokumente gefunden")
                    return
                }
                
                print("DocumentCount in Chats: \(documents.count)")
                
                var chats: [Chat] = []
                
                for document in documents {
                    let data = document.data()
                    guard let chatID = data["chatID"] as? String,
                          let lastMessageData = data["lastMessage"] as? [String: Any], // Hole das Dictionary
                          let lastMessage = LastMessage(from: lastMessageData), // Erstelle ein LastMessage-Objekt
                          let participantsIDs = data["participants"] as? [String],
                          let isTyping = data["isTyping"] as? [String],
                          let timestamp = data["timestamp"] as? Timestamp,
                          let key = getKeyForChat(chatID) else {
                          print("Fehler beim Verarbeiten eines Dokuments")
                        // Lösche das fehlerhafte Dokument
                        continue
                    }
                    if let encryptedSenderID = lastMessageData["senderID"] as? String,
                    let encryptedMessage = lastMessageData["message"] as? String,
                    let encryptedMessageData = Data(base64Encoded: encryptedMessage) {
                        if let decryptedSenderID = self.decryptMessage(encryptedData: encryptedSenderID.data(using: .utf8)!, key: key),
                           let decryptedMessage  = self.decryptMessage(encryptedData: encryptedMessageData, key: key) {
                            // Erstelle das LastMessage-Objekt mit entschlüsselten Werten
                            let lastMessageDataDecrypted: [String: Any] = [
                            "senderID": decryptedSenderID,
                            "message": decryptedMessage
                            ]
                            
                            if let lastMessage = LastMessage(from: lastMessageDataDecrypted) {
                                let chat = Chat(
                                    chatID: chatID,
                                    lastMessage: lastMessage,
                                    participantIDs: participantsIDs,
                                    isTyping: isTyping,
                                    timestamp: timestamp.dateValue(),
                                    messages: []
                                )
                                chats.append(chat)
                            } else {
                                print("Fehler beim erstellen der LastMessage aus den entschlüsselten Daten!")
                            }
                        }
                    }
                }
                completion(chats)
            }
    }
    
    func encryptMessage(message: String, key: SymmetricKey) -> Data? {
        let data = message.data(using: .utf8)!
        do {
            let encryptedData = try AES.GCM.seal(data, using: key)
            return encryptedData.combined
        } catch {
            print("Fehler bei der Verschlüsselung: \(error)")
            return nil
        }
    }
    
    func decryptMessage(encryptedData: Data, key: SymmetricKey) -> String? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Fehler bei der Entschlüsselung: \(error)")
            return nil
        }
    }
    
    func generateChatKey(from chatID: String) -> SymmetricKey {
        let data = chatID.data(using: .utf8)!
        let key = SHA256.hash(data: data)  // SHA256, um die Daten auf eine 256-Bit Länge zu bringen
        return SymmetricKey(data: key)
    }
    
    func saveSymmetricKeyToKeychain(key: SymmetricKey, forKey keyIdentifier: String) -> Bool {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Keychain-Query
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keyIdentifier,
            kSecValueData: keyData
        ]
        
        // Lösche den alten Key, wenn er existiert
        SecItemDelete(query as CFDictionary)
        
        // Speichere den neuen Key in der Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    func loadSymmetricKeyFromKeychain(forKey keyIdentifier: String) -> SymmetricKey? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keyIdentifier,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        } else {
            return nil
        }
    }
    
    func deleteSymmetricKey(forKey keyIdentifier: String) -> Bool {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keyIdentifier
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess
        }

    

//    func sendLocalNotification(title: String, body: String) {
//        let content = UNMutableNotificationContent()
//        content.title = title
//        content.body = body
//        content.sound = .default
//        // Triggert die Benachrichtigung sofort
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        // Identifikator für die Benachrichtigung
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Fehler beim Senden der lokalen Benachrichtigung: \(error)")
//            }
//        }
//    }
}
