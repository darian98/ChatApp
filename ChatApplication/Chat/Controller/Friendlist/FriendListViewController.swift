import UIKit
import FirebaseAuth

class FriendListViewController: UIViewController {
    var userID: String = Auth.auth().currentUser?.uid ?? "" // Aktuelle Benutzer-ID
    var friendRequests: [FriendRequest] = [] // Liste der Freundschaftsanfragen
    var friends: [Friend] = [] // Liste der Freunde
    var tableView: UITableView!
    var userCache: [String: String] = [:] // Cache für Usernamen (userID -> displayName)

    override func viewDidLoad() {
        super.viewDidLoad()
        // View Controller Setup
        view.backgroundColor = .white
        title = "Freunde"

        // UITableView Setup
        configureTableView()
        
        configureTabBarItems()
        // Freunde laden
        fetchFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFriendRequests()
    }
    
    func configureTabBarItems() {
        let groupChatImage = UIImage(systemName: "person.3")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: groupChatImage, style: .plain, target: self, action: #selector(onGroupChatButtonClicked))
    }
    
    func configureTableView() {
        // UITableView Setup
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FriendCell")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
    }
    
    func presentConfigGroupChatVC() async {
        do {
            guard let currentUser = try await UserService.shared.fetchUser(byID: userID) else { return }
            let configGroupChat = ConfigureGroupChatVC(currentUser: currentUser)
            configGroupChat.delegate = self
            let navConfigGroupChat = UINavigationController(rootViewController: configGroupChat)
            self.present(navConfigGroupChat, animated: true)
        } catch {
            print("Error fetching current user: \(error)")
            return
        }
    }
    
    @objc func onGroupChatButtonClicked() {
        Task {
            await presentConfigGroupChatVC()
        }
    }
    
    func prefetchUserNames(for userIDs: [String]) {
           let uniqueIDs = Set(userIDs) // Doppelte vermeiden
           let idsToFetch = uniqueIDs.filter { self.userCache[$0] == nil } // Nur nicht gecachte IDs laden
           
           for id in idsToFetch {
               Task {
                   if let user = try? await UserService.shared.fetchUser(byID: id) {
                       self.userCache[id] = user.displayName
                       print(user.displayName)
                   }
                   DispatchQueue.main.async {
                       self.tableView.reloadData() // Aktualisiere die Ansicht
                   }
               }
           }
       }

    // Freundschaftsanfragen laden
    func fetchFriendRequests() {
        FriendService.shared.observeFriendRequests(for: userID) { requests in
            self.friendRequests = requests
            let requestIDs = self.friendRequests.map { $0.senderID }
            self.prefetchUserNames(for: requestIDs)
            self.tableView.reloadData()
        }
    }
    
    // Freunde laden
    func fetchFriends() {
        FriendService.shared.fetchFriends(for: userID) { friends in
            self.friends = friends
            let friendIDs = friends.map { $0.friendID }
            self.prefetchUserNames(for: friendIDs)
            self.tableView.reloadData()
        }
    }
    
    // Methode zum Aktualisieren der internen Liste und der Firebase-Datenbank nach der Antwort auf die Anfrage
    func handleFriendRequestResponse(requestID: String, accept: Bool) {
        FriendService.shared.respondToFriendRequest(requestID: requestID, accept: accept)
        // Nach der Antwort die Liste der Freundschaftsanfragen aktualisieren
        fetchFriendRequests()
        if accept { fetchFriends() }
    }
}

// MARK: - UITableViewDataSource
extension FriendListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Zwei Abschnitte: Freundschaftsanfragen und Freunde
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return friendRequests.count // Freundschaftsanfragen
        } else {
            return friends.count // Freunde
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath)
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if indexPath.section == 0 { // Freundschaftsanfragen
            let friendRequest = friendRequests[indexPath.row]
            cell.textLabel?.text = "\(userCache[friendRequest.senderID] ?? "Username wird geladen...")"
            //cell.textLabel?.text = "Anfrage von \(friendRequest.senderID)"
            
            // Hinzufügen von Buttons zum Annehmen und Ablehnen
            let acceptButton = UIButton(type: .system)
            acceptButton.setTitle("Annehmen", for: .normal)
            acceptButton.tag = indexPath.row
            acceptButton.addTarget(self, action: #selector(acceptRequest(_:)), for: .touchUpInside)
            
            
            let rejectButton = UIButton(type: .system)
            rejectButton.setTitle("Ablehnen", for: .normal)
            rejectButton.tag = indexPath.row
            rejectButton.addTarget(self, action: #selector(rejectRequest(_:)), for: .touchUpInside)
            
                acceptButton.translatesAutoresizingMaskIntoConstraints = false
                rejectButton.translatesAutoresizingMaskIntoConstraints = false
                
                cell.contentView.addSubview(acceptButton)
                cell.contentView.addSubview(rejectButton)
                
                NSLayoutConstraint.activate([
                                acceptButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -120),
                                acceptButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                                acceptButton.widthAnchor.constraint(equalToConstant: 80),
                                acceptButton.heightAnchor.constraint(equalToConstant: 30),
                                
                                rejectButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -20),
                                rejectButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                                rejectButton.widthAnchor.constraint(equalToConstant: 80),
                                rejectButton.heightAnchor.constraint(equalToConstant: 30)
                            ])
            
        } else { // Freunde
            let friend = friends[indexPath.row]
            cell.textLabel?.text = "\(userCache[friend.friendID] ?? "Username wird geladen...")"
        }
        return cell
    }

    // Methode für Annahme einer Anfrage
       @objc func acceptRequest(_ sender: UIButton) {
           let request = friendRequests[sender.tag]
           handleFriendRequestResponse(requestID: request.id, accept: true)
       }
       
       // Methode für Ablehnung einer Anfrage
       @objc func rejectRequest(_ sender: UIButton) {
           let request = friendRequests[sender.tag]
           handleFriendRequestResponse(requestID: request.id, accept: false)
       }
}

// MARK: - UITableViewDelegate
extension FriendListViewController: UITableViewDelegate {
    // Optional: Header für Abschnitte
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Freundschaftsanfragen"
        } else {
            return "Freunde"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let friend = friends[indexPath.row]
        
        if indexPath.section != 0 {
            self.showOnFriendClickedAlert(userID: userID, friendID: friend.friendID, viewController: self)
        }
    }
    
}
extension FriendListViewController: ConfigureGroupChatDelegate {
    func didStartGroupChat(with users: [UserModel], from configureGroupChatVC: ConfigureGroupChatVC) {
        if users.isEmpty {
            print("Keine Benutzer für den Gruppenchat ausgewählt")
        } else {
            ChatService.shared.startChat(currentUser: configureGroupChatVC.currentUser, with: users, viewController: self)
        }
    }
}
