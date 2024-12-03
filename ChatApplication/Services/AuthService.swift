//
//  AuthService.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 12.11.24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    
    
    func registerUser(email: String, password: String, displayName: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } else if let user = authResult?.user {
               // user.displayName = displayName
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    } else {
                        print("User mit dem Nutzernamen \(user.displayName ?? "N/A") erfolgreich angelegt.")
                        DispatchQueue.main.async {
                            completion(.success(user))
                        }
                    }
                }
                let userData: [String: Any] = [
                            "uid": user.uid,
                            "displayName": displayName,
                            "email": user.email,
                            "bio": "",
                            "profileImage": "",
                            "friends": []
                        ]
                Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                           if let error = error {
                               print(error)
                           } else {
                               print("User added successfully to FireStore-Collection")
                           }
                       }
            }
        }
    }
    // Registrierung mit E-Mail und Passwort
    func registerUser2(email: String, password: String, displayName: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                if let _ = try await UserService.shared.fetchUser(byDisplayName: displayName) {
                    print("User existiert bereits, wähle einen anderen Namen")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Display name already in use"])))
                    }
                }
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    } else if let user = authResult?.user {
                       // user.displayName = displayName
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = displayName
                        changeRequest.commitChanges { error in
                            if let error = error {
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                            } else {
                                print("User mit dem Nutzernamen \(user.displayName ?? "N/A") erfolgreich angelegt.")
                                DispatchQueue.main.async {
                                    completion(.success(user))
                                }
                            }
                        }
                        let userData: [String: Any] = [
                                    "uid": user.uid,
                                    "displayName": displayName,
                                    "email": user.email,
                                    "bio": "",
                                    "profileImage": "",
                                    "friends": []
                                ]
                        Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                                   if let error = error {
                                       print(error)
                                   } else {
                                       print("User added successfully to FireStore-Collection")
                                   }
                               }
                    }
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getCurrentUserID() -> String {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return "" }
        return currentUserID
    }
    
    // Anmeldung mit E-Mail / UserName und Passwort
    func loginUser3(emailOrUserName: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                var userMail = ""
                if let user = try await UserService.shared.fetchUser(byDisplayName: emailOrUserName) {
                    userMail = user.email
                    Auth.auth().signIn(withEmail: userMail, password: password) { authResult, error in
                        if let error = error {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        } else if let user = authResult?.user {
                            DispatchQueue.main.async {
                                completion(.success(user))
                            }
                        }
                    }
                } else {
                    Auth.auth().signIn(withEmail: emailOrUserName, password: password) { authResult, error in
                        if let error = error {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        } else if let user = authResult?.user {
                            DispatchQueue.main.async {
                                completion(.success(user))
                            }
                        }
                    }
                }
            } catch {
                print("Error while logging user in: \(error)")
            }
        
        }
    }
    
    // Anmeldung mit E-Mail und Passwort
    func loginUser2(displayName: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                var userMail = ""
                if let user = try await UserService.shared.fetchUser(byDisplayName: displayName) {
                    userMail = user.email
                    Auth.auth().signIn(withEmail: userMail, password: password) { authResult, error in
                        if let error = error {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        } else if let user = authResult?.user {
                            DispatchQueue.main.async {
                                completion(.success(user))
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Es gibt keinen User mit diesem Username"])))
                    }
                }
            } catch {
                print("Error while logging user in: \(error)")
            }
        
        }
    }
    
    // Anmeldung mit E-Mail und Passwort
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }
    
    func logoutUser() {
           let firebaseAuth = Auth.auth()
           do {
               try firebaseAuth.signOut()
                let loginVC = LoginViewController()
                let navigationController = UINavigationController(rootViewController: loginVC)
                if let window = UIApplication.shared.windows.first {
                window.rootViewController = navigationController
                window.makeKeyAndVisible()
                }
           } catch let signOutError as NSError {
               print("Fehler beim Ausloggen: \(signOutError.localizedDescription)")
           }
       }
}
