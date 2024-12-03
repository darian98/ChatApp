//
//  ChatViewController.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 12.11.24.
//

import Foundation
import UIKit
import FirebaseAuth

class ChatViewController: UIViewController {
    // UI-Elemente
    let tableView = UITableView()
    let messageInputContainer = UIView()
    let messageTextField = UITextField()
    let voiceMailButton = UIButton(type: .custom)
    let sendButton = UIButton(type: .system)
    let typingIndicatorLabel = UILabel()
    
    var messages: [ChatMessage] = []
    let currentUser: UserModel
    let userToChatWith: UserModel
    let chatID: String
    var isRecording: Bool = false
    
    init(currentUser: UserModel, userToChatWith: UserModel, chatID: String) {
        self.currentUser = currentUser
        self.userToChatWith = userToChatWith
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
        //addTapGestureRecognizerForKeyboardDismiss()
        addTapGestureRecognizerToView(action: #selector(dismissKeyBoard))
        //setupUI()
        setupUIWithStackView()
        configureUIBarButtonItems()
        navigationItem.title = "\(userToChatWith.displayName)"
        observeMessages()
        observeTypingStatus()
        AudioService.shared.configureAudioSession()
    }
    
//    func addTapGestureRecognizerForKeyboardDismiss() {
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyBoard))
//        view.addGestureRecognizer(tapGestureRecognizer)
//    }
    
     @objc func dismissKeyBoard() {
         view.endEditing(true)
    }
    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        //setupTableView()
//        setupMessageInputContainer()
//        setupTypingIndicatorLabel()
//    }
    
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
        let addFriendButton     = UIBarButtonItem(title: "", image: UIImage(systemName: "person.fill.badge.plus"), target: self, action: #selector(addFriend))
        let callButton          = UIBarButtonItem(title: "", image: UIImage(systemName: "phone.fill"), target: self, action: #selector(startCall))
        let videoChatButton     = UIBarButtonItem(title: "", image: UIImage(systemName: "video.fill"), target: self, action: #selector(startVideoChat))
        navigationItem.rightBarButtonItems = [addFriendButton, callButton, videoChatButton]
    }
    
    private func setupTypingIndicatorLabel() {
        typingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        typingIndicatorLabel.textColor = .gray
        typingIndicatorLabel.font = UIFont.italicSystemFont(ofSize: 18)
        typingIndicatorLabel.text = "" // Anfangs leer
        typingIndicatorLabel.textAlignment = .center
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
        let callID = generateCallID(user1: currentUser.uid, user2: userToChatWith.uid)
        let videoCallVC = VideoCallViewController(currentUserID: currentUser.uid, remoteUserID: userToChatWith.uid, callID: callID)
        videoCallVC.modalPresentationStyle = .fullScreen
        present(videoCallVC, animated: true)
    }
    
    @objc func addFriend() {
        FriendService.shared.alreadyFriends(from: currentUser.uid, to: userToChatWith.uid) { isAlreadyFriend in
            if isAlreadyFriend {
                self.showAlert(withTitle: "Bereits befreundet", message: "Ihr seid bereits befreundet! Füge neue Nutzer hinzu")
            } else {
                FriendService.shared.sendFriendRequest(from: self.currentUser.uid, to: self.userToChatWith.uid)
            }
        }
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
        NSLayoutConstraint.activate([
              messageInputContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
              messageInputContainer.rightAnchor.constraint(equalTo: view.rightAnchor),
              messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
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
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
           NSLayoutConstraint.activate([
               buttonStackView.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
               buttonStackView.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: -8)
           ])
    }
    
    func voiceMailButtonClicked() {
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
//            AudioService.shared.stopRecording(chatID: chatID, senderID: currentUser.uid, receiverID: userToChatWith.uid, displayName: currentUser.displayName) { result in
//                switch result {
//                case .failure(let error):
//                    print("Error stopping Recording after clicking voiceMailButton: \(error.localizedDescription)")
//                case .success():
//                    print("Stopped recording....")
//                }
//            }
        }
    }
    
    
    @objc func sendVoiceMail() {
        voiceMailButtonClicked()
    }
    
    @objc private func sendMessage() {
        guard let messageText = messageTextField.text, !messageText.isEmpty else { return }

        //ChatService.shared.sendMessage(chatID: chatID, message: messageText, receiverID: userToChatWith.uid, senderID: currentUser.uid, displayName: currentUser.displayName ?? "N/A")
        
        messageTextField.text = ""
    }
    
    
    private func observeTypingStatus() {
        //MARK: Erinnerung, currentUser mit userToChatWith 
//        ChatService.shared.observeOtherUserTyping(chatID: chatID, otherUserID: userToChatWith.uid) { isTyping in
//            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
//                if isTyping {
//                    self.typingIndicatorLabel.isHidden = false
//                    self.typingIndicatorLabel.text = "\(self.userToChatWith.displayName) schreibt..."
//                    self.typingIndicatorLabel.alpha = 1
//                } else {
//                    self.typingIndicatorLabel.isHidden = true
//                    self.typingIndicatorLabel.alpha = 0
//                    self.typingIndicatorLabel.text = ""
//                }
//                self.view.layoutIfNeeded()
//            }
//        }
    }
    // Nachrichten-Listener
       private func observeMessages() {
           ChatService.shared.observeMessages2(chatID: chatID) { [weak self] newMessages in
               guard let self = self else { return }
               // Nachrichten im Array aktualisieren und Tabelle neu laden
               
               self.messages = newMessages
               
               self.tableView.reloadData()
               
               // Zum neuesten Nachricht scrollen
               if self.messages.count > 0 {
                   let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                   self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
               }
           }
       }
    
    func messageIsFromCurrentUser(message: ChatMessage) -> Bool {
        if message.senderID == self.currentUser.uid { return true } else {
            return false
        }
    }
    
}
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
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
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("User is typing...")
        let currentUserID = currentUser.uid
        ChatService.shared.updateUserIsTyping(chatID: chatID, typingUserID: currentUserID, isTyping: true)
        //observeTypingStatus()
            
       }
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("User stopped typing.")
        let currentUserID = currentUser.uid
        ChatService.shared.updateUserIsTyping(chatID: chatID, typingUserID: currentUserID, isTyping: false)
        //observeTypingStatus()
       }
}
