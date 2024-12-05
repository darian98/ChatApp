//
//  ProfileViewModel.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 02.12.24.
//

import Foundation
import SwiftUI
import FirebaseFirestore


class ProfileViewModel: ObservableObject {
    
    @Published var showImagePicker = false
    @Published var alertTitle = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var selectedImage: UIImage?
    @Published var bioTextInput: String = ""
    @Published var bio: String = ""
    
    @Published var currentUser: UserModel
    
    
    init(currentUser: UserModel) {
        self.currentUser = currentUser
    }
    
    
    
    func saveProfileData(currentUserID: String) {
        let uid = currentUserID
        var data: [String: Any] = ["bio": bio]
        
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64Image = imageData.base64EncodedString()
            data["profileImage"] = base64Image
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Fehler beim Speichern: \(error.localizedDescription)")
                self.alertTitle = "Fehler"
                self.alertMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                self.showAlert.toggle()
            } else {
                print("Profil erfolgreich aktualisiert.")
                self.alertTitle = "Es hat geklappt!"
                self.alertMessage = "Profil erfolgreich aktualisiert."
                self.showAlert.toggle()
            }
        }
    }
    
    func saveProfileDataWithCompressedImage(currentUserID: String) {
        let uid = currentUserID
        if !bioTextInput.isEmpty {
            self.bio = self.bioTextInput
            self.bioTextInput = ""
        }
        var data: [String: Any] = ["bio": bio]
        
        if let image = selectedImage {
            if let compressedImageData = compressImage(image, to: 900) {
                let base64Image = compressedImageData.base64EncodedString()
                data["profileImage"] = base64Image
            } else {
                print("CompressedImageData ging nicht)")
            }
        } else {
            print("Selected image konnte nicht unwrapped werden")
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                print("Fehler beim Speichern: \(error.localizedDescription)")
                self.alertTitle = "Fehler"
                self.alertMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                self.showAlert.toggle()
            } else {
                print("Profil erfolgreich aktualisiert.")
                self.alertTitle = "Es hat geklappt!"
                self.alertMessage = "Profil erfolgreich aktualisiert."
                self.showAlert.toggle()
            }
        }
    }

    func compressImage(_ image: UIImage, to maxSizeInKB: Int) -> Data? {
        var compression: CGFloat = 1.0
        let maxSizeInBytes = maxSizeInKB * 1024
        guard var imageData = image.jpegData(compressionQuality: compression) else { return nil }
        
        while imageData.count > maxSizeInBytes && compression > 0.1 {
            compression -= 0.1
            if let compressedData = image.jpegData(compressionQuality: compression) {
                imageData = compressedData
            }
        }
        
        return imageData
    }
    
   func fetchProfileData(currentUserID: String) {
        Task {
            if let currentUserFetched = try? await UserService.shared.fetchUser(byID: currentUserID),
            let base64ImageString = currentUserFetched.profileImage,
            let imageData = Data(base64Encoded: base64ImageString),
            let image     = UIImage(data: imageData) {
            let bio = currentUserFetched.bio
                    DispatchQueue.main.async {
                        self.selectedImage = image
                        self.bio = bio
                    }
                }
            }
    }
    
}
