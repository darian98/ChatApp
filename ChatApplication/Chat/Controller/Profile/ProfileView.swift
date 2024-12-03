//
//  ProfileView.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 02.12.24.
//
import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var editBio = false
    
    var currentUser: UserModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center) {
                profileImageButton
                
                VStack(alignment: .leading) {
                    userInfoText
                    
                    userBioText
                    
                    if editBio {
                        userBioTextField
                    }
                    
                    saveButton
                }
                Spacer().frame(height: 200)
            }
        }
        .onAppear {
            viewModel.fetchProfileData(currentUserID: currentUser.uid)
        }
        .padding()
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(profileViewModel: viewModel)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(viewModel.alertMessage)
                })
        .contentShape(Rectangle()) // Versichert, dass egal wo geklickt wird, die TapGesture erkannt wird!
        .gesture(
            TapGesture()
                .onEnded {
                    UIApplication.shared.endEditing() // Dismiss the keyboard
            }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                pencilButton
            }
        }
    }
}
extension ProfileView {
    private var profileImageButton: some View {
        Button(action: {
            viewModel.showImagePicker.toggle()
        }) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    Text("Wählen Sie\n ein Profilbild")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    private var saveButton: some View {
        Button("Speichern") {
            withAnimation(.spring()) {
                viewModel.saveProfileDataWithCompressedImage(currentUserID: currentUser.uid)
                editBio.toggle()
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        
    }
    
    private var userInfoText: some View {
        VStack(alignment: .leading) {
            Text("\(currentUser.displayName)")
                .font(.title2)
            Text("\(currentUser.email)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var userBioText: some View {
        VStack(alignment : .leading) {
            HStack {
                Text("Bio:")
            }.padding(.top)
            
            Text("\(viewModel.bio)")
                .padding(.top, 2)
                .font(.subheadline)
        }
    }
    
    private var pencilButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                editBio.toggle()
            }
        }, label: {
            Image(systemName: editBio ? "pencil.slash" : "pencil")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .tint(editBio ? .green : .blue)
        })
    }
    
    private var userBioTextField: some View {
        TextField("Bio eingeben", text: $viewModel.bioTextInput)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.top, 100)
    }
}
