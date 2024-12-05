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
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack() {
                
                HStack(alignment: .top) {
                    profileImageButton
                        .frame(alignment: .leading)
                    
                    Text("Freunde: \(viewModel.currentUser.friends.count)")
                        .frame(alignment: .top)
                    
                    Spacer()
                    
                }
                
                
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
            Task {
                let friendList: [Friend] = []
                FriendService.shared.fetchFriends(for: viewModel.currentUser.uid) { friends in
                        let friendList = friends
                        DispatchQueue.main.async {
                            viewModel.currentUser.friends = friendList
                        }
                }
            }
            viewModel.fetchProfileData(currentUserID: viewModel.currentUser.uid)
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
                settingsMenu
            }
        }
    }
}
extension ProfileView {
    
    private var settingsMenu: some View {
        Menu {
            pencilButton
            logoutButton
        } label: {
            Image(systemName: "gearshape")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
    
    private var logoutButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                AuthService.shared.logoutUser()
            }
        }, label: {
            Label(
                title: { Text("Ausloggen") },
                icon: { Image(systemName: "power") }
            )
        })
    }
    
    private var profileImageButton: some View {
        Button(action: {
            viewModel.showImagePicker.toggle()
        }) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
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
                viewModel.saveProfileDataWithCompressedImage(currentUserID: viewModel.currentUser.uid)
                if editBio {
                    editBio.toggle()
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
    }
    
    private var userInfoText: some View {
        VStack(alignment: .leading) {
            Text("\(viewModel.currentUser.displayName)")
                .font(.title2)
            Text("\(viewModel.currentUser.email)")
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
            Label(
                title: { 
                    Text(editBio ? "Nicht mehr editieren" : "Profil anpassen")
                        .foregroundStyle(editBio ? .red : .green)
                },
                icon: {
                    Image(systemName: editBio ? "pencil.slash" : "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .tint(editBio ? .green : .blue)
                }
            )
        })
    }
    
    private var userBioTextField: some View {
        TextField("Bio eingeben", text: $viewModel.bioTextInput)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.top, 100)
    }
}
