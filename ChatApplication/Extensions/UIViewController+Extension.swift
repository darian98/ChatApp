//
//  UIViewController+Extension.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 14.11.24.
//

import Foundation
import UIKit


extension UIViewController {
    func showAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    func showAddFriendAlert(senderID: String, for chatParticipiants: [UserModel]) {
        
        var notAlreadyFriendList    = [UserModel]()
        var alreadyFriendsList      = [UserModel]()
        let dispatchGroup = DispatchGroup()
        
        print("ChatPartCount:\(chatParticipiants.count)")
        
        for user in chatParticipiants {
            dispatchGroup.enter()
            FriendService.shared.alreadyFriends(from: senderID, to: user.uid) { isAlreadyFriend in
                if !isAlreadyFriend {
                    notAlreadyFriendList.append(user)
                } else {
                    alreadyFriendsList.append(user)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
        print("AlreadyFriends count: \(alreadyFriendsList.count)")
        print("Not Friend count: \(notAlreadyFriendList.count)")
        if chatParticipiants.count == 1 && alreadyFriendsList.count == 1 {
                let alert = UIAlertController(title: "Bereits befreundet.", message: "Du und \(alreadyFriendsList[0].displayName) seid bereits Freunde!", preferredStyle: .alert)
            let rejectAction = UIAlertAction(title: "OK", style: .cancel) { _ in }
                alert.addAction(rejectAction)
                self.present(alert, animated: true, completion: nil)
                return
        }
            
        if !notAlreadyFriendList.isEmpty {
            let onlyOneParticipiantNotFriend = notAlreadyFriendList.count ==  1
            let alert = UIAlertController(title: "Freund hinzufügen", message: "\(onlyOneParticipiantNotFriend ?  "Möchtest du folgenden Nutzer als Freund hinzufügen? " : "Wen willst du als Freund hinzufügen? ")", preferredStyle: .actionSheet)
            for notFriendUser in notAlreadyFriendList {
            let addNotFriendUserButton = UIAlertAction(title: "\(notFriendUser.displayName)", style: .default) { _ in
            FriendService.shared.sendFriendRequest(from: senderID, to: notFriendUser.uid)
            }
            alert.addAction(addNotFriendUserButton)
            }
                
            let rejectAction = UIAlertAction(title: "Abbrechen", style: .destructive) { _ in }
            alert.addAction(rejectAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
    
    func showOnFriendClickedAlert(userID: String, friendID: String, viewController: UIViewController) {
        let alertController = UIAlertController(title: "", message: "Wähle deine Aktion", preferredStyle: .actionSheet)
        
        let deleteFriendAction  = UIAlertAction(title: "Freund löschen", style: .destructive) { _ in
            Task {
                FriendService.shared.deleteFriend(userID: userID, friendID: friendID) { deletedSuccessfull in
                    if deletedSuccessfull {
                        print("Freund wurde erfolgreich entfernt.")
                    } else {
                        print("Fehler beim Löschen des Freundes.")
                    }
                }
            }
        }
        let sendMessageAction   = UIAlertAction(title: "Nachricht senden", style: .default) { _ in
            Task {
                guard let currentUser = try await UserService.shared.fetchUser(byID: userID) else { return}
                guard let friendUser = try await UserService.shared.fetchUser(byID: friendID) else { return }
                ChatService.shared.startChat2(currentUser: currentUser, with: [friendUser], viewController: viewController)
            }
        }
        let cancelButton        = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        alertController.addAction(deleteFriendAction)
        alertController.addAction(sendMessageAction)
        alertController.addAction(cancelButton)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func showDeleteMessagesTimerAlert(chatID: String) {
        let alertController = UIAlertController(title: "Selbstzerstörende Nachrichten", message: "Gib die Anzahl der Sekunden ein, nach denen Nachrichten gelöscht werden sollen.", preferredStyle: .alert)
            // Füge ein Textfeld für die Eingabe hinzu
            alertController.addTextField { textField in
                textField.placeholder = "Sekunden eingeben"
                textField.keyboardType = .numberPad // Nur Zahlen erlauben
            }
            // Füge den "Abbrechen"-Button hinzu
            let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
            
            // Füge den "OK"-Button hinzu, um die Eingabe zu verarbeiten
            let okAction = UIAlertAction(title: "Timer setzen", style: .default) { [weak alertController] _ in
                guard let textField = alertController?.textFields?.first,
                      let secondsText = textField.text,
                      let seconds = Int(secondsText), seconds > 0 else {
                          print("Ungültige Eingabe")
                          return
                }
                // Deine Logik zum Löschen der Nachrichten nach der angegebenen Zeit
                ChatService.shared.deleteMessagesAfterSeconds(chatID: chatID, delayInSeconds: seconds)
                ChatService.shared.updateDeleteMessagesAfterSecondsForChat(chatID: chatID, seconds: seconds)
                
            }
            // Füge die Aktionen hinzu
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            // Zeige den AlertController an
            self.present(alertController, animated: true, completion: nil)
    }
    
    
    func addTapGestureRecognizerToView(action: Selector, delegate: UIGestureRecognizerDelegate? = nil) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = delegate
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
}
