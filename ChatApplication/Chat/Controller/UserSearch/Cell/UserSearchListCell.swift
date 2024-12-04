//
//  UserSearchListCell.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 03.12.24.
//

import Foundation
import UIKit


class UserSearchListCell: UITableViewCell {
    
    let profileImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 31 // Halb des geplanten Width/Height für Kreisform
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.lightGray.cgColor
            return imageView
        }()
    
    // MARK: - UI-Elemente
    let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemBlue
        label.numberOfLines = 1
        return label
    }()
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
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
    
    
    private func setupViews() {
            contentView.addSubview(profileImageView)
            contentView.addSubview(userNameLabel)
            contentView.addSubview(emailLabel)
        
        // Auto Layout aktivieren
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            userNameLabel.translatesAutoresizingMaskIntoConstraints = false
            emailLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                // Constraints für das Profilbild
                profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                profileImageView.widthAnchor.constraint(equalToConstant: 62), // 2 * 28
                profileImageView.heightAnchor.constraint(equalToConstant: 62),
                
                // Constraints für das Benutzername-Label
                userNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
                userNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
                userNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                
                // Constraints für das E-Mail-Label
                emailLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 4),
                emailLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
                emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                emailLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
            ])
        }
    
    // MARK: - Konfiguration
       func configure(userName: String, email: String, base64ImageString: String?) {
           userNameLabel.text = userName
           emailLabel.text = email
           
           if let base64String = base64ImageString,
              let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) {
               profileImageView.image = image
           } else {
               profileImageView.image = UIImage(systemName: "person.circle") // Platzhalterbild
           }
       }
    
    
}
