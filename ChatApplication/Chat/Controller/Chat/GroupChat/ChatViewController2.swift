    //
    //  ChatViewController.swift
    //  SomeUIKit
    //
    //  Created by Hanci, Darian on 12.11.24.
    //

    import Foundation
    import UIKit
    import FirebaseAuth
    import CryptoKit

    class ChatViewController2: UIViewController {
        // UI-Elemente
        let tableView = UITableView()
        let messageInputContainer = UIView()
        let messageTextField = UITextField()
        let voiceMailButton = UIButton(type: .custom)
        let sendButton = UIButton(type: .system)
        let typingIndicatorLabel = UILabel()
        var messageInputContainerBottomConstraint: NSLayoutConstraint!
        
        var messages: [ChatMessage] = []
        let currentUser: UserModel
        let usersToChatWith: [UserModel]
        let chatID: String
        var isRecording: Bool = false
        private var chatKey: SymmetricKey {
            //return ChatService.shared.generateChatKey(from: chatID)
            return loadOrCreateChatKey()
        }
        
        init(currentUser: UserModel, usersToChatWith: [UserModel], chatID: String) {
            self.currentUser = currentUser
            self.usersToChatWith = usersToChatWith
            self.chatID = chatID
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.addSubview(tableView)
            view.addSubview(messageInputContainer)
            addTapGestureRecognizerToView(action: #selector(dismissKeyBoard), delegate: self)
            setupUIWithStackView()
            configureUIBarButtonItems()
            //navigationItem.title = "\(userToChatWith.displayName)"
            
            //observeMessages()
            observeEncryptedMessages()
            observeTypingStatus2()
            AudioService.shared.configureAudioSession()
        }
        
         @objc func dismissKeyBoard() {
             view.endEditing(true)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            
            //ChatService.shared.deleteMessagesFromChat(chat: chat)
            
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            
//            if messages.isEmpty {
//                ChatService.shared.deleteChat(chatID: chatID)
//            }
        }
        func setupUIWithStackView() {
                view.backgroundColor = .systemBackground
                // Container für TypingIndicator und TableView
                let mainStackView = UIStackView()
                mainStackView.axis = .vertical
                mainStackView.spacing = 8
                mainStackView.translatesAutoresizingMaskIntoConstraints = false
                
                view.addSubview(mainStackView)
                
                // Füge TypingIndicatorLabel und TableView in die StackView ein
                mainStackView.addArrangedSubview(typingIndicatorLabel)
                mainStackView.addArrangedSubview(tableView)
                
                // Constraints für mainStackView
                NSLayoutConstraint.activate([
                    mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    mainStackView.bottomAnchor.constraint(equalTo: messageInputContainer.topAnchor)
                ])
                setupTypingIndicatorLabel()
                setupTableView()
                setupMessageInputContainer()
        }
        
        // MARK: - Aufnahmezustand umschalten
           private func toggleRecordingState() {
               isRecording.toggle()
               let imageName = isRecording ? "mic" : "mic.fill"
               voiceMailButton.setImage(UIImage(systemName: imageName), for: .normal)
               voiceMailButton.tintColor = isRecording ? .systemRed : .systemBlue
           }
        
        func configureUIBarButtonItems() {
            let deletingMessagesTimer   = UIBarButtonItem(title: "", image: UIImage(systemName: "timer"), target: self, action: #selector(deleteMessages))
            let addFriendButton         = UIBarButtonItem(title: "", image: UIImage(systemName: "person.fill.badge.plus"), target: self, action: #selector(addFriend))
            navigationItem.rightBarButtonItems  = [addFriendButton, deletingMessagesTimer]
        }
        
        private func setupTypingIndicatorLabel() {
            typingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
            typingIndicatorLabel.textColor = .gray
            typingIndicatorLabel.font = UIFont.italicSystemFont(ofSize: 18)
            typingIndicatorLabel.text = "" // Anfangs leer
            typingIndicatorLabel.textAlignment = .center
        }
        
        @objc func deleteMessages() {
            showDeleteMessagesTimerAlert(chatID: chatID)
        }
        
        @objc func startCall() {
            print("Start Call clicked!")
            let firstVoiceMail = messages.first { message in
                message.isAudio
            }
            guard let firstVoiceMailUnwrapped = firstVoiceMail else { return }
            AudioService.shared.playAudio(from: firstVoiceMailUnwrapped.message)
            //AudioService.shared.handleReceivedMessage(firstVoiceMailUnwrapped)
        }
        
        @objc func startVideoChat() {
            if usersToChatWith.count == 1 {
                let callID = generateCallID(user1: currentUser.uid, user2: usersToChatWith[0].uid)
                let videoCallVC = VideoCallViewController(currentUserID: currentUser.uid, remoteUserID: usersToChatWith[0].uid, callID: callID)
                videoCallVC.modalPresentationStyle = .fullScreen
                present(videoCallVC, animated: true)
            } else {
                print("Zu viele Teilnehmer, GruppenVideoChat noch nicht implementiert!")
            }
        }
        
        @objc func addFriend() {
            self.showAddFriendAlert(senderID: currentUser.uid, for: usersToChatWith)
        }
        
        // Erzeugt eine eindeutige ID, basierend auf den User-IDs der Teilnehmer
        private func generateCallID(user1: String, user2: String) -> String {
            let sortedIDs = [user1, user2].sorted()
            return sortedIDs.joined(separator: "_")
        }
        
        private func setupTableView() {
            //view.addSubview(tableView)
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "messageCell")
            tableView.dataSource = self
            tableView.delegate = self
        }
        
        private func setupMessageInputContainer() {
           // view.addSubview(messageInputContainer)
            messageInputContainer.translatesAutoresizingMaskIntoConstraints = false
            messageInputContainerBottomConstraint = messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            NSLayoutConstraint.activate([
                  messageInputContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
                  messageInputContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
                  messageInputContainerBottomConstraint,
                  messageInputContainer.heightAnchor.constraint(equalToConstant: 50)
              ])
            
            // Erstelle eine StackView für die Buttons
               let buttonStackView = UIStackView(arrangedSubviews: [voiceMailButton, sendButton])
               buttonStackView.axis = .horizontal
               buttonStackView.spacing = 8
               buttonStackView.alignment = .center
               buttonStackView.translatesAutoresizingMaskIntoConstraints = false
               messageInputContainer.addSubview(buttonStackView)

            // Nachrichtentextfeld
            messageInputContainer.addSubview(messageTextField)
            messageTextField.placeholder = "Schreibe eine Nachricht..."
            messageTextField.translatesAutoresizingMaskIntoConstraints = false
            messageTextField.delegate = self
            messageTextField.leftAnchor.constraint(equalTo: messageInputContainer.leftAnchor, constant: 8).isActive = true
            messageTextField.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor).isActive = true
            messageTextField.rightAnchor.constraint(equalTo: messageInputContainer.rightAnchor, constant: -114).isActive = true
            messageTextField.heightAnchor.constraint(equalTo: messageInputContainer.heightAnchor, multiplier: 0.8).isActive = true

            // Buttons in der StackView platzieren
            voiceMailButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            voiceMailButton.tintColor = .systemBlue // Optionale Anpassung der Farbe
            voiceMailButton.layer.cornerRadius = 20
            voiceMailButton.addTarget(self, action: #selector(sendVoiceMail), for: .touchUpInside)
            voiceMailButton.backgroundColor = .clear
            voiceMailButton.imageView?.contentMode = .scaleAspectFit
            
            NSLayoutConstraint.activate([
                    voiceMailButton.widthAnchor.constraint(equalToConstant: 50),
                    voiceMailButton.heightAnchor.constraint(equalToConstant: 50)
                ])
            
            sendButton.setTitle("Senden", for: .normal)
            sendButton.isEnabled =  true
            sendButton.isUserInteractionEnabled = true
            sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
            
               NSLayoutConstraint.activate([
                   buttonStackView.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
                   buttonStackView.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: -8)
               ])
        }
        
        private func configureTypingIndicatorLabel(typingUserIDs: [String]) {
            self.typingIndicatorLabel.isHidden = false
            self.typingIndicatorLabel.alpha     = 1
            
            var users: [UserModel] = []
            Task {
                for typingUserID in typingUserIDs {
                    guard let user = try await UserService.shared.fetchUser(byID: typingUserID) else { return }
                    users.append(user)
                }
                
                print("UserCount in configureTypingIndicator: \(users.count)")
                let displayNames = users
                    .filter { $0.uid != currentUser.uid }
                    .map    {  $0.displayName }
                print("DisplayNames in configureTypingIndicator: \(displayNames.count)")
                // Wenn keine anderen Benutzer schreiben, Label leeren und Methode beenden
                guard !displayNames.isEmpty else {
                    DispatchQueue.main.async {
                        self.typingIndicatorLabel.text = ""
                    }
                    print("Returning after checking displayNames !Empty")
                    return
                }
                print("DisplayNames in IndicatorLabel: \(displayNames.count)")
                let formattedString: String
                switch displayNames.count {
                case 1:
                    formattedString = "\(displayNames[0]) schreibt..."
                case 2:
                    formattedString = "\(displayNames[0]) and \(displayNames[1]) schreiben..."
                default:
                    let firstTwo = displayNames.prefix(2).joined(separator: ",")
                    print("FirstTWo:\(firstTwo)")
                    formattedString = "\(firstTwo) und andere schreiben..."
                }
                // Aktualisiere das Label im Main-Thread
                DispatchQueue.main.async {
                    self.typingIndicatorLabel.text = formattedString
                }
            }
        }
        
        private func getOtherUsersIDs()  -> [String] {
            var userIDs = [String]()
            for user in usersToChatWith {
                userIDs.append(user.uid)
            }
            return userIDs
        }
        
        private func observeTypingStatus2() {
            let otherUserIDS = getOtherUsersIDs()
            
            //MARK: Erinnerung, currentUser mit userToChatWith
            ChatService.shared.observeOtherUsersTyping2(chatID: chatID, otherUserIDs: otherUserIDS) { typingUsers in
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                    if typingUsers.isEmpty {
                        self.typingIndicatorLabel.isHidden = true
                        self.typingIndicatorLabel.alpha = 0
                        self.typingIndicatorLabel.text = ""
                    } else {
                        self.configureTypingIndicatorLabel(typingUserIDs: typingUsers)
                    }
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        @objc func sendVoiceMail() {
            voiceMailButtonClicked()
        }
        
        func voiceMailButtonClicked() {
            let otherUsersIDs = getOtherUsersIDs()
            
            toggleRecordingState()
            if isRecording {
                AudioService.shared.startRecording { result in
                    switch result {
                    case .failure(let error):
                        print("Error starting Recording after clicking voiceMailButton: \(error.localizedDescription)")
                    case .success():
                        print("Started recording....")
                    }
                }
            } else {
                AudioService.shared.stopRecording3(chatID: chatID, senderID: currentUser.uid, receiverIDs: otherUsersIDs, displayName: currentUser.displayName, key: chatKey) { result in
                    switch result {
                    case .failure(let error):
                        print("Error stopping Recording after clicking voiceMailButton: \(error.localizedDescription)")
                    case .success():
                        print("Stopped recording....")
                    }
                }
            }
        }
        
        // Funktion zum Laden oder Erstellen des SymmetricKeys
          private func loadOrCreateChatKey() -> SymmetricKey {
              if let loadedKey = ChatService.shared.loadSymmetricKeyFromKeychain(forKey: chatID) {
                  print("Key erfolgreich aus der Keychain geladen! -> \(loadedKey)<- ")
                  return loadedKey
              } else {
                  print("Kein Schlüssel in der Keychain gefunden, erstelle neuen.")
                  // Erstelle neuen SymmetricKey
                  let newKey = ChatService.shared.generateChatKey(from: chatID)
                  let success = ChatService.shared.saveSymmetricKeyToKeychain(key: newKey, forKey: chatID)
                  if success {
                      print("Neuer Schlüssel erfolgreich in der Keychain gespeichert.")
                      return newKey
                  } else {
                      fatalError("Failed to save symmetric key to Keychain.")
                  }
              }
          }
        
       
        @objc private func sendMessage() {
            let otherUserIDS = getOtherUsersIDs()
            guard let messageText = messageTextField.text, !messageText.isEmpty else { return }
            
            //ChatService.shared.sendMessage2(chatID: chatID, message: messageText, receiverIDs: otherUserIDS, senderID: currentUser.uid, displayName: currentUser.displayName)
            
            Task {
                ChatService.shared.sendMessage3(chatID: chatID, message: messageText, receiverIDs: otherUserIDS, senderID: currentUser.uid, displayName: currentUser.displayName, key: chatKey)
                ChatService.shared.getChat(withID: chatID) { chat in
                    if let chat = chat {
                        print("chat in viewWillAppear vom ChatViewController2 geladen: \(chat.chatID)")
                        if chat.deleteMessagesAfterSeconds > 0 {
                            ChatService.shared.deleteMessagesFromChat(chat: chat)
                        }
                    } else {
                        print("Chat konnte nicht geladen werden!")
                    }
                }
            }
            
            messageTextField.text = ""
        }
        
    //     Nachrichten-Listener
           private func observeEncryptedMessages() {
               ChatService.shared.observeEncryptedMessages(chatID: chatID, key: chatKey) { [weak self] newMessages in
                   guard let self = self else { return }
                   // Nachrichten im Array aktualisieren und Tabelle neu laden
                   DispatchQueue.main.async {
                       self.messages = newMessages
                       print("Messages-Count :\(self.messages.count)")
                       self.tableView.reloadData()
                       // Zum neuesten Nachricht scrollen
                       if self.messages.count > 0 {
                           let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                           self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                       }
                   }
               }
           }
        
        // Nachrichten-Listener
           private func observeMessages() {
               ChatService.shared.observeMessages2(chatID: chatID) { [weak self] newMessages in
                   guard let self = self else { return }
                   // Nachrichten im Array aktualisieren und Tabelle neu laden
                   DispatchQueue.main.async {
                       self.messages = newMessages
                       print("Messages-Count :\(self.messages.count)")
                       self.tableView.reloadData()
                       
                       // Zum neuesten Nachricht scrollen
                       if self.messages.count > 0 {
                           let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                           self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                       }
                   }
               }
           }
        
        private func deleteMessage(at indexPath: IndexPath) {
            
            let message = messages[indexPath.row]
            
            guard messageIsFromCurrentUser(message: message) else {
                print("Nutzer kann nur eigene Nachrichten löschen!")
                return
            }
            
            ChatService.shared.deleteMessage(chatID: chatID, messageID: message.messageID) { result in
                switch result {
                case .success:
                    print("Nachricht wurde erfolgreich in der FirestoreDB gelöscht")
                    DispatchQueue.main.async {
                        guard indexPath.row < self.messages.count else {
                            print("Index nicht mehr gültig.")
                            return
                        }
                        self.messages.remove(at: indexPath.row)
                        // Überprüfen, ob der Index nach dem Entfernen der Nachricht noch gültig ist
                        if indexPath.row < self.messages.count {
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        } else {
                        print("Nachricht konnte nicht gelöscht werden, Index ungültig.")
                        }
                    }
                case .failure(let error):
                    print("Message could not be deleted with error: \(error)")
                }
            }
            
        }
        
        func messageIsFromCurrentUser(message: ChatMessage) -> Bool {
            if message.senderID == self.currentUser.uid { return true } else {
                return false
            }
        }
        
        @objc func keyboardWillShow(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

            let keyboardHeight = keyboardFrame.height

            UIView.animate(withDuration: animationDuration) {
                //self.tableView.contentInset.bottom = keyboardHeight + self.messageInputContainer.frame.height
                //self.tableView.scrollIndicatorInsets.bottom = keyboardHeight + self.messageInputContainer.frame.height
                //self.messageInputContainer.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight * 0.76)
                self.messageInputContainerBottomConstraint.constant = -keyboardHeight * 0.75
                self.view.layoutIfNeeded()
            }
        }

        @objc func keyboardWillHide(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

            UIView.animate(withDuration: animationDuration) {
                //self.tableView.contentInset.bottom = 0
                //self.messageInputContainer.transform = .identity
                self.messageInputContainerBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    extension ChatViewController2: UITableViewDataSource, UITableViewDelegate {
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let message = messages[indexPath.row]
            if message.isAudio {
                AudioService.shared.playAudio(from: message.message)
            }
            print("ROW IN TABLEVIEW CLICKED!")
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return messages.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath)
            cell.isUserInteractionEnabled = true
            let message = messages[indexPath.row]
            
            if messageIsFromCurrentUser(message: message) {
                if message.isAudio {
                    cell.textLabel?.text = "Du: Sprachnotiz"
                    //vAudioService.shared.playAudio(from: message.message)
                } else {
                    cell.textLabel?.text = "Du: \(message.message)"
                }
                cell.textLabel?.textAlignment = .right
                cell.backgroundColor = .systemBlue
                cell.textLabel?.numberOfLines = 0
            } else {
                if message.isAudio {
                    cell.textLabel?.text = "\(message.displayName): Sprachnotiz"
                } else {
                    cell.textLabel?.text = "\(message.displayName): \(message.message)"
                }
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = .systemGray
                cell.textLabel?.numberOfLines = 0
            }
            return cell
        }
        
        // Konfiguration für Swipe-Aktionen
            func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
                let deleteAction = UIContextualAction(style: .destructive, title: "Löschen") { [weak self] _, _, completionHandler in
                    guard let self = self else { return }
                    self.deleteMessage(at: indexPath)
                    completionHandler(true)
                }
                return UISwipeActionsConfiguration(actions: [deleteAction])
            }
    }

    extension ChatViewController2: UITextFieldDelegate {
        func textFieldDidBeginEditing(_ textField: UITextField) {
            print("User is typing...")
            let currentUserID = currentUser.uid
            ChatService.shared.updateUserIsTyping(chatID: chatID, typingUserID: currentUserID, isTyping: true)
           }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            print("User stopped typing.")
            let currentUserID = currentUser.uid
            ChatService.shared.updateUserIsTyping(chatID: chatID, typingUserID: currentUserID, isTyping: false)
           }
    }

// MARK: - UIGestureRecognizerDelegate
extension ChatViewController2: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Prüfen, ob die berührte View der sendButton ist (oder eine andere View, die den Tap ignorieren soll)
        if let touchedView = touch.view, touchedView == sendButton {
            return false // Verhindert, dass der TapRecognizer den sendButton beeinflusst
        }
        return true // Erlaube Taps auf allen anderen Bereichen
    }
}
