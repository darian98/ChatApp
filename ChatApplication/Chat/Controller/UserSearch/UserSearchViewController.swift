    //
    //  UserSearchViewController.swift
    //  SomeUIKit
    //
    //  Created by Hanci, Darian on 13.11.24.
    //

    import Foundation
    import UIKit
    import FirebaseFirestore
    import FirebaseAuth
    import SwiftUI

    class UserSearchViewController: UIViewController {
        private let searchBar = UISearchBar()
        private let tableView = UITableView()
        private var users: [UserModel] = []
        private var filteredUsers: [UserModel] = []
        private let db = Firestore.firestore()
        var currentUser: UserModel
        
        init(currentUser: UserModel) {
            self.currentUser = currentUser
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchAllUsers()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .white
            setupSearchBar()
            setupTableView()
            addTapGestureRecognizerToView(action: #selector(dismissKeyboard))
            navigationItem.title = "Alle Nutzer"
        }
        
        @objc private func dismissKeyboard() {
                if let presentedVC = self.presentedViewController, presentedVC is UIAlertController {
                    presentedVC.dismiss(animated: true, completion: nil)
                    return
                }
                searchBar.endEditing(true) // Tastatur ausblenden
        }
        
        private func setupSearchBar() {
            searchBar.placeholder = "Suche nach Benutzername oder E-Mail"
            searchBar.delegate = self
            navigationItem.titleView = searchBar
        }
        
        private func setupTableView() {
            tableView.dataSource = self
            tableView.delegate = self
            //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            tableView.register(UserSearchListCell.self, forCellReuseIdentifier: "UserSearchListCell")
            tableView.frame = view.bounds
            view.addSubview(tableView)
        }
        
        private func fetchAllUsers() {
            Task {
                do {
                    let users = try await UserService.shared.fetchAllUsers()
                    self.users = users
                    print("User-Count: \(users.count)")
                    //self.filteredUsers = users
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Fehler beim Abrufen der Benutzer: \(error.localizedDescription)")
                }
            }
        }
        
        // Funktion zum Starten eines Chats
        private func startChat(with user: UserModel) {
            ChatService.shared.startChat(currentUser: currentUser, with: [user], viewController: self)
            print("Chat starten mit Benutzer: \(user.displayName)")

        }
        
        private func showUserProfile(with user: UserModel) {
            let userProfileViewModel = UserProfileViewModel(user: user)
            let userprofileView = UserProfileView(viewModel: userProfileViewModel)
            let userProfileViewHostingController = UIHostingController(rootView: userprofileView)
            present(userProfileViewHostingController, animated: true)
        }
        
        
        private func filterUsers(for searchText: String) {
            if searchText.isEmpty {
                filteredUsers = []
            } else {
                filteredUsers = users.filter { user in
                    user.uid != currentUser.uid &&
                    (user.displayName.lowercased().contains(searchText.lowercased()) ||
                    user.email.lowercased().contains(searchText.lowercased()))
                }
            }
            tableView.reloadData()
        }
    }

extension UserSearchViewController:  UITableViewDataSource, UITableViewDelegate {
    // UITableViewDataSource - Tabellenansicht für die Benutzerliste
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("FilteredUsersCount: \(filteredUsers.count)")
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserSearchListCell", for: indexPath) as? UserSearchListCell else { return UITableViewCell() }
        //let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let user = filteredUsers[indexPath.row]
        cell.configure(userName: user.displayName, email: user.email, base64ImageString: user.profileImage)
        //cell.textLabel?.text = user.displayName + " (" + user.email + ")"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 86  // Beispielhöhe, anpassbar
    }
    
    // UITableViewDelegate - Aktion bei Auswahl eines Benutzers
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = filteredUsers[indexPath.row]
        
        self.presentAlertWithActions(title: "Aktion auswählen", message: "Wählen Sie die Aktion, die Sie ausführen wollen", action1Title: "Nachricht an \(selectedUser.displayName)", action1Handler: {
            self.startChat(with: selectedUser)
        }, action2Title: "Profil von \(selectedUser.displayName) anzeigen") {
            self.showUserProfile(with: selectedUser)
        }
    }
}

extension UserSearchViewController: UISearchBarDelegate {
    // UISearchBarDelegate - Suchfunktionalität
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterUsers(for: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
}
