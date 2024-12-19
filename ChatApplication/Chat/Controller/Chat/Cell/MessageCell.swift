//
//  MessageCell.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 20.11.24.
//

import UIKit

class MessageCell: UITableViewCell {
    let messageLabel = UILabel()
    let messageImageView = UIImageView()
    private var imageHeightConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Konfiguriere das Label
        messageLabel.numberOfLines = 0
        contentView.addSubview(messageLabel)

        // Konfiguriere das ImageView
        messageImageView.contentMode = .scaleAspectFit
        messageImageView.clipsToBounds = true
        contentView.addSubview(messageImageView)

        // AutoLayout konfigurieren
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            messageImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            messageImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            messageLabel.topAnchor.constraint(equalTo: messageImageView.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        // Höhenbeschränkung für das Bild
        imageHeightConstraint = messageImageView.heightAnchor.constraint(equalToConstant: 200)
        imageHeightConstraint?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: ChatMessage, isFromCurrentUser: Bool) {
        // Text konfigurieren
        if message.isAudio {
            messageLabel.text = isFromCurrentUser
                ? "Du: Sprachnotiz \(message.receiverReadMessage ? "✓✓" : "✓")"
                : "\(message.displayName): Sprachnotiz"
            messageImageView.image = nil
        } else {
            messageLabel.text = isFromCurrentUser
                ? "Du: \(message.message) \(message.receiverReadMessage ? "✓✓" : "✓")"
                : "\(message.displayName): \(message.message)"
            
            if let image = message.image {
                messageImageView.image = image
                imageHeightConstraint?.constant = 200 // Bild sichtbar
            } else {
                messageImageView.image = nil
                imageHeightConstraint?.constant = 0 // Kein Platz für das Bild
            }
        }

        // Textausrichtung und Hintergrundfarbe
        messageLabel.textAlignment = isFromCurrentUser ? .right : .left
        backgroundColor = isFromCurrentUser ? .systemBlue : .systemGray
    }
}
