//
//  MessageCell.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 20.11.24.
//

import UIKit

class MessageCell: UITableViewCell {
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white // Passe die Farbe des Symbols an
        return imageView
    }()
    
    // Initialisierer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(messageLabel)
        contentView.addSubview(statusImageView)
        
        // Constraints für Layout
        NSLayoutConstraint.activate([
            // Nachrichtentext-Label
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            // Wenn der Text rechts ausgerichtet ist
            messageLabel.trailingAnchor.constraint(equalTo: statusImageView.leadingAnchor, constant: -5),
            
            // Status-Bild
            statusImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            statusImageView.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            statusImageView.widthAnchor.constraint(equalToConstant: 20),
            statusImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Maximale Breite des Labels
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
