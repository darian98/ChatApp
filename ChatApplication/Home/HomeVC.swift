//
//  HomeVC.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 11.11.24.
//

import UIKit
import FirebaseAuth
import SwiftUI

class HomeVC: UITabBarController {
    var currentUser: UserModel
    var chats: [Chat] = []
    var friendRequestsForCurrentUser: [FriendRequest] = []
    var profileViewModel: ProfileViewModel
    
    init(currentUser: UserModel) {
        self.currentUser = currentUser
        self.profileViewModel = ProfileViewModel(currentUser: currentUser)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        fetchAndSetFriendRequests()
        listenForIncomingCalls()
        
        super.viewDidLoad()
        view.backgroundColor = .white
        configureTabBarViewControllers()
    }
    
    func configureTabBarViewControllers() {
        let userSearchVC = UserSearchViewController(currentUser: currentUser)
        let navUserSearchVC = UINavigationController(rootViewController: userSearchVC)
        navUserSearchVC.tabBarItem = UITabBarItem(title: "Suche", image: UIImage(systemName: "magnifyingglass"), tag: 0)
        
        let chatListVC = ChatListViewController()
        let navChatListVC = UINavigationController(rootViewController: chatListVC)
        navChatListVC.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "message"), tag: 1)
        
//        let callListVC = CallListVC()
//        let navCallListVC = UINavigationController(rootViewController: callListVC)
//        navCallListVC.tabBarItem = UITabBarItem(title: "Anrufe", image: UIImage(systemName: "phone"), tag: 2)
        
        let friendListVC = FriendListViewController()
        let navFriendListVC = UINavigationController(rootViewController: friendListVC)
        navFriendListVC.tabBarItem = UITabBarItem(title: "Freunde", image: UIImage(systemName: "person.3"), tag: 3)
        
        let profileView = ProfileView(viewModel: profileViewModel)
        let profileViewHostingController = UIHostingController(rootView: profileView)
        let navProfileViewHostingController = UINavigationController(rootViewController: profileViewHostingController)
        navProfileViewHostingController.tabBarItem = UITabBarItem(title: "Profil", image: UIImage(systemName: "person.circle"), tag: 4)
        
        viewControllers = [navUserSearchVC, navChatListVC, navFriendListVC, navProfileViewHostingController]
    }
    
    func fetchAndSetFriendRequests() {
        FriendService.shared.observeFriendRequests(for: currentUser.uid) { friendRequests in
            self.friendRequestsForCurrentUser = friendRequests
        }
    }
    func listenForIncomingCalls() {
        VideoCallService.shared.listenForIncomingCalls { [weak self] senderID, callID in
            guard let self = self else { return }
            // Weiterleitung zu IncomingCallViewController, wenn ein Anruf eingeht
            self.presentIncomingCallViewController(senderID: senderID, callID: callID)
        }
    }
    
    func presentIncomingCallViewController(senderID: String, callID: String) {
        let incomingCallVC = IncomingCallViewController()
        incomingCallVC.senderID = senderID
        incomingCallVC.callID   = callID
        incomingCallVC.delegate = self
        self.present(incomingCallVC, animated: true, completion: nil)
    }
    // Methode zum Abrufen der Chats des aktuellen Nutzers
    private func observeChats() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        print("currentuserid: \(currentUserID)")
        
        ChatService.shared.observeChatsForUser(withID: currentUserID) { chats in
            self.chats = chats
            print(chats.count)
        }
    }

}
extension HomeVC: IncomingCallDelegate {
    func didAcceptCall(callID: String, remoteUserID: String) {
        print("DidAccepptCall wurde ausgeführt!")
        self.dismiss(animated: true)
        let videocallVC = VideoCallViewController(currentUserID: Auth.auth().currentUser?.uid ?? "", remoteUserID: remoteUserID, callID: callID)
        navigationController?.pushViewController(videocallVC, animated: true)
    }
}


