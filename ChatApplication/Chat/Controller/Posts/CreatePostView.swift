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

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Titel eingeben", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Nachricht eingeben", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

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
                        PostService.shared.postToFirestoreDB(senderID: currentUser.uid, postTitle: title, postMessage: message)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || message.isEmpty)
                }
            }
        }
    }
}
