//
//  ChatListViewController.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 12.11.24.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import CryptoKit

class ChatListViewController: UIViewController {
    // UI-Elemente
    let tableView = UITableView()
    var chats: [Chat] = []  // Eine Liste von Chats, die der aktuelle Benutzer hat
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        observeChats()
        navigationItem.title = "Offene Chats"
    }
    
    // TableView einrichten
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.register(ChatListCell.self, forCellReuseIdentifier: "ChatListCell")
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chatCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // Automatische Höhenanpassung
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    func getKeyForChat(chatID: String) -> SymmetricKey? {
        guard let storedKey = ChatService.shared.loadSymmetricKeyFromKeychain(forKey: chatID) else { return nil }
        return storedKey
       }
    
    // Methode zum Abrufen der Chats des aktuellen Nutzers
    private func observeChats() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        print("currentuserid: \(currentUserID)")
        print("observeChats wird ausgeführt...")
                
        ChatService.shared.observeChatsForUser(withID: currentUserID) { chats in
            print("observechats completion...")
            DispatchQueue.main.async {
                self.chats = chats
                self.tableView.reloadData()
                print("Chats-Count: \(chats.count)")
            }
        }
    }

    func navigateToChat(chat: Chat) {
        guard let currentUser = Auth.auth().currentUser else { return }
        Task {
            guard let currentUserModel = try await UserService.shared.fetchUser(byID: currentUser.uid) else { return }
            let usersToChatWithIDs = chat.participantIDs.filter { ids in
                currentUserModel.uid != ids
            }
            var chatParticipiants = [UserModel]()
            
            for userID in usersToChatWithIDs {
                guard let userToChatWith = try await UserService.shared.fetchUser(byID: userID) else { return }
                chatParticipiants.append(userToChatWith)
            }
            ChatService.shared.startChat(currentUser: currentUserModel, with: chatParticipiants, viewController: self)
        }
    }
}

// MARK: - UITableViewDataSource und UITableViewDelegate
extension ChatListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {	
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as? ChatListCell else { return UITableViewCell()}
        let chat = chats[indexPath.row]
        
        Task {
            await cell.configure(with: chat)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80  // Beispielhöhe, anpassbar
    }
    
    // Wenn auf einen Chat geklickt wird, öffne den Chat
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.row]
        //for messages in chat
        navigateToChat(chat: chat)
    }
    
}






