//
//  CreatePostView.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 16.12.24.
//

import Foundation
import SwiftUI

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var message: String = ""
    var currentUser: UserModel
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertText: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                postTitleTextField

                postMessageTextField
                
                HStack {
                    showImagePickerButton
                    chooseVideoButton
                }
                
                if let selectedImage {
                    HStack {
                        selectedImagePreview
                            .overlay(deleteSelectedImageButton, alignment: .topTrailing)
                    }
                }
                Spacer()
            }
            .navigationTitle("Post erstellen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        Task {
                            do {
                                try await PostService.shared.postToFirestoreDB(senderID: currentUser.uid, postTitle: title, postMessage: message, imageString: getSelectedImageBase64String())
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                alertText = error.localizedDescription
                                showAlert.toggle()
                                print(error)
                            }
                        }
                    }
                    .disabled(title.isEmpty || message.isEmpty)
                }
            }
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Fehler beim erstellen des Post"), message: Text(alertText))
            })
            // Sheet für den ImagePicker
            .sheet(isPresented: $showImagePicker, onDismiss: {
                    showImagePicker = false
            }) {
            ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    func removeSelectedImage() {
        selectedImage = nil
    }
    
    func getSelectedImageBase64String() -> String? {
        if let selectedImage {
            guard let compressedImageData = ImageHelper.compressImage(selectedImage, to: 900) else { return nil }
            let imageBase64String = compressedImageData.base64EncodedString()
            return imageBase64String
        }
        return ""
    }
}

extension CreatePostView {
    private var postTitleTextField: some View {
        TextField("Titel eingeben", text: $title)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
    
    private var postMessageTextField: some View {
        TextField("Nachricht eingeben", text: $message)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        
    }
    
    private var chooseVideoButton: some View {
        Button {
            print("Choose Video Logic.")
        } label: {
            Image(systemName: "video.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
    }
    
    private var showImagePickerButton: some View {
        Button {
            showImagePicker.toggle()
        } label: {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding()
                .clipShape(Circle())
        }
    }
    
    private var selectedImagePreview: some View {
            if let uiimage = selectedImage {
                Image(uiImage: uiimage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 206, height: 206)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        
    }
    
    private var deleteSelectedImageButton: some View {
        Button {
            withAnimation(.spring()) {
                removeSelectedImage()
            }
        } label: {
                Image(systemName: "xmark.circle")
                    .font(.title)
                    .foregroundStyle(.red)
                    .padding(.trailing, 12)
            }
    }
    
}
