//
//  ConfigureGroupChatVC.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 25.11.24.
//

import Foundation
import UIKit

protocol ConfigureGroupChatDelegate: AnyObject {
    func didStartGroupChat(with users: [UserModel], from configureGroupChatVC: ConfigureGroupChatVC)
}


class ConfigureGroupChatVC: UIViewController {
    weak var delegate: ConfigureGroupChatDelegate?
    let searchField             = UISearchBar()
    let tableView               = UITableView()
    let startGroupChatButton    = UIButton()
    let currentUser: UserModel
    
    private var users: [UserModel] = []
    private var filteredUsers: [UserModel] = []
    
    private var usersForGroupChat: [UserModel] = []
    
    init(currentUser: UserModel) {
        self.currentUser = currentUser
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSearchBar()
        setupTableView()
        addTapGestureRecognizerToView(action: #selector(dismissKeyboard))
        setupStartGroupChatButton()
        fetchAllUsers()
    }
    
    @objc func dismissKeyboard() {
        searchField.endEditing(true)
    }
    
    private func setupSearchBar() {
        searchField.placeholder = "Suche nach Username oder E-Mail"
        searchField.delegate = self
        navigationItem.titleView = searchField
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.frame = view.bounds
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
                    tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80) // Platz für den Button
                ])
    }
    
    
    private func setupStartGroupChatButton() {
            startGroupChatButton.setTitle("Gruppenchat starten", for: .normal)
            startGroupChatButton.backgroundColor = .systemBlue
            startGroupChatButton.setTitleColor(.white, for: .normal)
            startGroupChatButton.layer.cornerRadius = 10
            startGroupChatButton.addTarget(self, action: #selector(didTapStartGroupChatButton), for: .touchUpInside)
            startGroupChatButton.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(startGroupChatButton)
            
            NSLayoutConstraint.activate([
                startGroupChatButton.heightAnchor.constraint(equalToConstant: 50),
                startGroupChatButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                startGroupChatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                startGroupChatButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        }
    
    private func fetchAllUsers() {
        Task {
            do {
                let users = try await UserService.shared.fetchAllUsers()
                self.users = users
                self.filteredUsers = users
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Fehler beim Abrufen der Benutzer: \(error.localizedDescription)")
            }
        }
    }
    private func filterUsers(for searchText: String) {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                user.displayName.lowercased().contains(searchText.lowercased()) ||
                user.email.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
    
    func addUserToGroupChatList(user: UserModel) -> Bool {
        if currentUser.uid == user.uid { return false }
        
        let filteredUsers = self.usersForGroupChat.filter { userInGroupChatList in
            user.uid == userInGroupChatList.uid
        }
        if filteredUsers.isEmpty {
            self.usersForGroupChat.append(user)
            return true
        }
        return false
    }
    
    @objc func didTapStartGroupChatButton() {
        dismiss(animated: true) {
            self.delegate?.didStartGroupChat(with: self.usersForGroupChat, from: self)
        }
    }
    
    // Funktion zum Starten eines Chats
    private func startChat2(with users: [UserModel]) {
        ChatService.shared.startChat(currentUser: currentUser, with: users, viewController: self)
        print("\(currentUser.displayName) startet Chat mit folgenden Benutzern: ")
        for user in users {
            print("\(user.displayName)")
        }
    }
}

extension ConfigureGroupChatVC: UITableViewDelegate, UITableViewDataSource {
    // UITableViewDataSource - Tabellenansicht für die Benutzerliste
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return filteredUsers.count // Nutzer gefiltert, allgemein
        } else {
            return usersForGroupChat.count // Nutzer, die der Gruppenchatliste hinzugefügt wurden.
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.section == 0 {
            let user = filteredUsers[indexPath.row]
            cell.textLabel?.text = user.displayName + " (" + user.email + ")"
        } else {
            let user = usersForGroupChat[indexPath.row]
            cell.textLabel?.text = user.displayName
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Alle Nutzer"
        } else {
            return "Nutzer beteiligt am Gruppenchat"
        }
    }
    
    // UITableViewDelegate - Aktion bei Auswahl eines Benutzers
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let selectedUser = filteredUsers[indexPath.row]
            let userAdded = addUserToGroupChatList(user: selectedUser)
            if userAdded {
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
                print("User: \(selectedUser.displayName) wurde zur GruppenChat-Liste hinzugefügt!")
            }
        } else {
            print("...")
        }
    }
}

extension ConfigureGroupChatVC: UISearchBarDelegate {
    // UISearchBarDelegate - Suchfunktionalität
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterUsers(for: searchText)
    }
}

