//
//  AsyncImageLoader.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 17.12.24.
//

import Foundation
import SwiftUI

enum ImagesFor {
    case commentingUser, postingUser, sharePostList
}

class AsyncImageLoader: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var commenterImages: [String: UIImage] = [:]
    @Published var postingUserImages: [String: UIImage] = [:]
    @Published var sharePostListImages: [String: UIImage] = [:]
    //@Published var imagesFor: ImagesFor? = nil

    /// Lädt das Profilbild basierend auf der Sender-ID
    func loadUserImage(for senderID: String, imagesFor: ImagesFor) async {
        do {
            // Nutzer aus dem Backend abrufen
            guard let user = try await UserService.shared.fetchUser(byID: senderID),
                  let base64String = user.profileImage else {
                print("Fehler: Benutzer oder Profilbild ist nicht verfügbar.")
                return
            }
            // Base64-String dekodieren und in ein Bild umwandeln
            await loadImage(senderID: senderID, fromBase64: base64String, imagesFor: imagesFor)
        } catch {
            print("Fehler beim Abrufen des Benutzers für \(senderID): \(error.localizedDescription)")
        }
    }

    /// Dekodiert den Base64-String und lädt das Bild
    private func loadImage(senderID: String, fromBase64 base64String: String, imagesFor: ImagesFor) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                if let data = Data(base64Encoded: base64String),
                   let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                        if imagesFor == .commentingUser {
                            self.commenterImages[senderID] = uiImage
                        } else if imagesFor == .postingUser {
                            self.postingUserImages[senderID] = uiImage
                        } else if imagesFor == .sharePostList {
                            self.sharePostListImages[senderID] = uiImage
                        }
                        continuation.resume()
                    }
                } else {
                    print("Fehler: Ungültiger Base64-String.")
                    continuation.resume()
                }
            }
        }
    }
}
