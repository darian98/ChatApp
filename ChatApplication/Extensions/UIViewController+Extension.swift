//
//  UIViewController+Extension.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 14.11.24.
//

import Foundation
import UIKit


enum UpdatedTimerState {
    case failed
    case active(seconds: Int)
    case inactive
}

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
                ChatService.shared.startChat(currentUser: currentUser, with: [friendUser], viewController: viewController)
            }
        }
        let cancelButton        = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        alertController.addAction(sendMessageAction)
        alertController.addAction(deleteFriendAction)
        alertController.addAction(cancelButton)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    func showActiveDeleteMessagesTimerAlert(seconds: Int, chatID: String, completion: @escaping (UpdatedTimerState) -> Void) {
        let alertController = UIAlertController(title: "Selbstzerstörende Nachrichten aktiv", message: self.configureTimerMessage(seconds: seconds), preferredStyle: .alert)
        
        let deleteTimerAction = UIAlertAction(title: "Timer löschen", style: .destructive) { _ in
            ChatService.shared.updateDeleteMessagesAfterSecondsForChat(chatID: chatID, seconds: 0) { success in
                DispatchQueue.main.async {
                    if success {
                        print("Timer zum Löschen der Nachrichten erfolgreich auf 0 gesetzt!")
                        completion(.inactive)
                    } else {
                        print("Fehler beim Löschen (auf 0 Setzen) des Timers!")
                        completion(.failed)
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        alertController.addAction(deleteTimerAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showDeleteMessagesTimerAlert(chatID: String, completion: @escaping (UpdatedTimerState) -> Void) {
        let alertController = UIAlertController(title: "Selbstzerstörende Nachrichten", message: "Nach wie vielen Sekunden sollen die Nachrichten zerstört werden?", preferredStyle: .alert)
            // Füge ein Textfeld für die Eingabe hinzu
            alertController.addTextField { textField in
                textField.placeholder = "Sekunden eingeben"
                textField.keyboardType = .numberPad // Nur Zahlen erlauben
            }
            // Füge den "Abbrechen"-Button hinzu
            let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
            
            let okAction = UIAlertAction(title: "Timer setzen", style: .default) { [weak alertController] _ in
                guard let textField = alertController?.textFields?.first,
                      let secondsText = textField.text,
                      let seconds = Int(secondsText), seconds > 0 else {
                          print("Ungültige Eingabe")
                          return
                }
                
                // Deine Logik zum Löschen der Nachrichten nach der angegebenen Zeit
                ChatService.shared.deleteMessagesAfterSeconds(chatID: chatID, delayInSeconds: seconds)
                ChatService.shared.updateDeleteMessagesAfterSecondsForChat(chatID: chatID, seconds: seconds) { success in
                    DispatchQueue.main.async {
                        if success {
                            print("Timer zum Löschen der Nachrichten erfolgreich geupdated!")
                            completion(.active(seconds: seconds))
                        } else {
                            print("Fehler beim Updaten des Timers!")
                            completion(.failed)
                        }
                    }
                }
                
            }
            
        let deleteTimerAction = UIAlertAction(title: "Timer löschen", style: .destructive) { _ in
            ChatService.shared.updateDeleteMessagesAfterSecondsForChat(chatID: chatID, seconds: 0) { success in
                DispatchQueue.main.async {
                    if success {
                        print("Timer zum Löschen der Nachrichten erfolgreich auf 0 gesetzt!")
                        completion(.inactive)
                    } else {
                        print("Fehler beim Löschen (auf 0 Setzen) des Timers!")
                        completion(.failed)
                    }
                }
            }
        }
        
            // Füge die Aktionen hinzu
            alertController.addAction(okAction)
            //alertController.addAction(deleteTimerAction)
            alertController.addAction(cancelAction)
            // Zeige den AlertController an
            self.present(alertController, animated: true, completion: nil)
    }
    
    func presentAlertWithActions(
            title: String?,
            message: String?,
            action1Title: String,
            action1Handler: @escaping () -> Void,
            action2Title: String,
            action2Handler: @escaping () -> Void
        ) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            
            let action1 = UIAlertAction(title: action1Title, style: .default) { _ in
                action1Handler()
            }
            let action2 = UIAlertAction(title: action2Title, style: .default) { _ in
                action2Handler()
            }
            
            alert.addAction(action1)
            alert.addAction(action2)
            
            self.present(alert, animated: true, completion: nil)
        }
    
    
    func addTapGestureRecognizerToView(action: Selector, delegate: UIGestureRecognizerDelegate? = nil) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = delegate
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func configureTimerMessage(seconds: Int) -> String {
        var hours = 0
        var minutes = 0
        var seconds1 = 0
        
        minutes = seconds / 60       // Ganzzahldivision
        seconds1 = seconds % 60
        
        var andMinutes = 0
        var andSeconds = 0
        
        hours = minutes / 60
        print("Stunden: ")
        andMinutes = minutes % 60
        andSeconds = seconds1
        
        let hourOrHours = "\(hours == 1 ? "Stunde" : "Stunden")"
        let minuteOrMinutes = "\(andMinutes == 1 ? "Minute" : "Minuten")"
        let secondOrSeconds = "\(andSeconds == 1 ? "Sekunde" : "Sekunden")"
        
        let hoursText = "\(hours > 0 ? "\(hours) \(hourOrHours)," : "")"
        let minuteText = "\(minutes > 0 ? "\(String(andMinutes)) \(minuteOrMinutes)" : "")"
        let andSecondsText =  "\(minutes > 0 ? "und \(seconds1) \(secondOrSeconds)" : "\(seconds1) \(secondOrSeconds)")"
        
        
        let components = [hoursText, minuteText, andSecondsText].filter { !$0.isEmpty }
        let combinedText = components.joined(separator: " ")
        
        let hoursMinutesAndSecondsText = "Der Timer wurde auf \(combinedText) gesetzt!"
        
        return hoursMinutesAndSecondsText
    }
    
}
