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
    // Funktion zum Anzeigen des Alerts
      func showFriendRequestAlert(for request: FriendRequest) {
          let alert = UIAlertController(title: "Freundschaftsanfrage", message: "Möchtest du diese Freundschaftsanfrage annehmen?", preferredStyle: .alert)
          
          let acceptAction = UIAlertAction(title: "Annehmen", style: .default) { _ in
              // Freundschaftsanfrage annehmen
              FriendService.shared.respondToFriendRequest(requestID: request.id, accept: true)
              print("Anfrage angenommen: \(request.senderID)")
          }
          
          let rejectAction = UIAlertAction(title: "Ablehnen", style: .destructive) { _ in
              // Freundschaftsanfrage ablehnen
              FriendService.shared.respondToFriendRequest(requestID: request.id, accept: false)
              print("Anfrage abgelehnt: \(request.senderID)")
          }
          
          // Füge die Aktionen zum Alert hinzu
          alert.addAction(acceptAction)
          alert.addAction(rejectAction)
          
          // Präsentieren des Alerts
          self.present(alert, animated: true, completion: nil)
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
    
    func addTapGestureRecognizerToView(action: Selector, delegate: UIGestureRecognizerDelegate? = nil) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = delegate
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
}
