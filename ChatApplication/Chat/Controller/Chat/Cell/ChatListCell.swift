//
//  ChatListCell.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 27.11.24.
//
import FirebaseAuth
import UIKit

class ChatListCell: UITableViewCell {
    
    let profileImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 28 // Halb des geplanten Width/Height für Kreisform
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.lightGray.cgColor
            return imageView
        }()
    
    // MARK: - UI-Elemente
    let participantsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.numberOfLines = 1
        return label
    }()
    
    let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    // MARK: - Initialisierung
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // UI-Komponenten hinzufügen
    private func setupViews() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(participantsLabel)
        contentView.addSubview(lastMessageLabel)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false
        lastMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 56), //
            profileImageView.heightAnchor.constraint(equalToConstant: 56),
            
            participantsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            participantsLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            participantsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            lastMessageLabel.topAnchor.constraint(equalTo: participantsLabel.bottomAnchor, constant: 5),
            lastMessageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            lastMessageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - Daten konfigurieren
    func configure(with chat: Chat) async {
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        // Namen der Teilnehmer laden
        let participantNames: [String] = await withTaskGroup(of: String?.self, body: { group -> [String] in
            var names = [String]()
            for participantID in chat.participantIDs {
                if participantID != currentUserID {
                    group.addTask {
                        if let user = try? await UserService.shared.fetchUser(byID: participantID) {
                            return user.displayName
                        }
                        return nil
                    }
                }
            }
            for await name in group {
                if let name = name {
                    names.append(name)
                }
            }
            return names
        })
        
        // DisplayName des letzten Absenders laden
            var lastMessageSenderName = ""
            if let sender = try? await UserService.shared.fetchUser(byID: chat.lastMessage.senderID) {
                if sender.uid == currentUserID {
                    lastMessageSenderName = "Du"
                } else {
                    lastMessageSenderName = sender.displayName
                }
            }
        
        // UI aktualisieren
        DispatchQueue.main.async {
            self.participantsLabel.text = participantNames.joined(separator: ", ")
            
            if !chat.lastMessage.message.isEmpty {
                if chat.lastMessage.isAudio {
                    self.lastMessageLabel.text = "\(lastMessageSenderName): Sprachnotiz"
                } else {
                    self.lastMessageLabel.text = "\(lastMessageSenderName): \(chat.lastMessage.message)"
                }
            } else {
                self.lastMessageLabel.text = ""
            }
        }
        
        if participantNames.count == 1, let singleParticipantID = chat.participantIDs.first(where: { $0 != currentUserID }) {
            if let user = try? await UserService.shared.fetchUser(byID: singleParticipantID),
               let base64ImageString = user.profileImage {
                    if let imageData     = Data(base64Encoded: base64ImageString),
                       let image            = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.profileImageView.image = image
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.profileImageView.image = UIImage(systemName: "person.circle") // Platzhalterbild
                        }
                    }
                }
        } else {
            DispatchQueue.main.async {
                            self.profileImageView.image = UIImage(systemName: "person.2.circle") // Platzhalterbild
            }
        }
    }
}


