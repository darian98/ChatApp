//
//  LoginViewController.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 12.11.24.
//

import Foundation
import UIKit
import FirebaseAuth

enum AuthMode {
    case register, login
}

class LoginViewController: UIViewController {
    private let userNameTextField = UITextField()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let registerButton = UIButton()
    private let loginButton = UIButton()
    private var notRegisteredYetButton = UIButton()
    private var alreadyRegisteredButton = UIButton()
    private var loginButtonConstraints: [NSLayoutConstraint] = []
    private var registerButtonConstraints: [NSLayoutConstraint] = []
    private var userNameTextFieldConstraints: [NSLayoutConstraint] = []
    private var mode: AuthMode = .login {
           didSet {
               updateUI()
           }
       }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        configureUIElements()
        addTapGestureRecognizerToView(action: #selector(dismissKeyBoard))
        updateUI()
    }
        
     @objc func dismissKeyBoard() {
         view.endEditing(true)
    }
    
    @objc func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let displayName = userNameTextField.text else { return }
        
        AuthService.shared.registerUser(email: email, password: password, displayName: displayName) { result in
            switch result {
            case .success(let user):
                print("Registrierung erfolgreic USER_ID: \(user.uid)")
            case .failure(let error):
                print("Fehler bei Registrierung: \(error)")
                self.showAlert(withTitle: "Registrieren Fehlgeschlagen", message: error.localizedDescription)
            }
        }
    }
    @objc func handleLogin() {
        
        loginButton.isEnabled = false
        
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        AuthService.shared.loginUser(email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("Anmeldung erfolgreich USER_ID: \(user.uid)")
                print("DisplayName: \(user.displayName ?? "")")
                
                Task {
                    guard let currentUserModel = await self.getCurrentUser(user: user) else { return }
                    self.pushToChatListViewController(user: currentUserModel)
                }
            case .failure(let error):
                print("Fehler bei Anmeldung: \(error)")
                self.loginButton.isEnabled = true
                self.showAlert(withTitle: "Anmeldung Fehlgeschlagen", message: error.localizedDescription)
            }
        }
    }
    
    func pushToChatListViewController(user: UserModel) {
        let homeVC = HomeVC(currentUser: user)
        homeVC.navigationItem.hidesBackButton = true
        navigationController?.pushViewController(homeVC, animated: true)
    }
    
    
    @objc func toggleMode() {
        mode = (mode == .login) ? .register : .login
        print(mode)
    }
    
    func getCurrentUser(user: User) async -> UserModel? {
        do {
            guard let currentUser = try await UserService.shared.fetchUser(byID: user.uid) else { return nil }
            return currentUser
        } catch {
            print("User konnte nicht geladen werden mit Error: \(error)")
            return nil
        }
    }
    
    private func configureUIElements() {
            // Füge die Textfelder und Buttons zur Ansicht hinzu
            view.addSubview(emailTextField)
            view.addSubview(passwordTextField)
            view.addSubview(registerButton)
            view.addSubview(loginButton)
            
            emailTextField.placeholder = "E-Mail"
            passwordTextField.placeholder = "Passwort"
            passwordTextField.isSecureTextEntry = true
            
            registerButton.setTitle("Registrieren", for: .normal)
            registerButton.setTitleColor(.systemBlue, for: .normal)
            registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
            
            loginButton.setTitle("Anmelden", for: .normal)
            loginButton.setTitleColor(.systemBlue, for: .normal)
            loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
            
            emailTextField.translatesAutoresizingMaskIntoConstraints = false
            passwordTextField.translatesAutoresizingMaskIntoConstraints = false
            registerButton.translatesAutoresizingMaskIntoConstraints = false
            loginButton.translatesAutoresizingMaskIntoConstraints = false
            
            // Auto-Layout-Constraints für gemeinsame UI-Elemente
            NSLayoutConstraint.activate([
                emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                emailTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
                emailTextField.heightAnchor.constraint(equalToConstant: 40),
                
                passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
                passwordTextField.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            // Initial Constraints für den Login-Button und Register-Button, die später je nach Modus aktiviert oder deaktiviert werden
            loginButtonConstraints = [
                loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                loginButton.heightAnchor.constraint(equalToConstant: 50)
            ]
            
            registerButtonConstraints = [
                registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                registerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                registerButton.heightAnchor.constraint(equalToConstant: 50)
            ]
            
            userNameTextField.translatesAutoresizingMaskIntoConstraints = false
        }
    
    func configureNotRegisteredYetButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Noch nicht Registriert? Hier Account erstellen!", for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        button.setTitleColor(.systemBlue, for: .normal)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 8),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        return button
    }
    
    func configureSwitchToLoginButton()  -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Du hast schon einen Account? Hier Anmelden", for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        button.setTitleColor(.systemBlue, for: .normal)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.topAnchor.constraint(equalTo: userNameTextField.bottomAnchor, constant: 8),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        return button
    }
    
    
    private func updateUI() {
            // Entsprechend dem Modus die Constraints für den Login-Button und Register-Button setzen oder deaktivieren
            switch self.mode {
            case .login:
                self.notRegisteredYetButton = self.configureNotRegisteredYetButton()
                // Im Anmelden-Modus: Login-Button anzeigen, Register-Button verstecken
                self.emailTextField.placeholder = "E-Mail"
                self.passwordTextField.placeholder = "Passwort"
                self.loginButton.isHidden = false
                self.userNameTextField.isHidden = true
                self.registerButton.isHidden = true
                self.alreadyRegisteredButton.isHidden = true
                
                NSLayoutConstraint.deactivate(self.registerButtonConstraints)
                NSLayoutConstraint.activate(self.loginButtonConstraints)
                
            case .register:
                // Im Registrieren-Modus: Register-Button anzeigen, Login-Button verstecken
                self.emailTextField.placeholder = "E-Mail"
                self.passwordTextField.placeholder = "Passwort"
                self.userNameTextField.placeholder = "Benutzername"
                
                // Benutzername TextField anzeigen
                self.view.addSubview(self.userNameTextField)
                self.userNameTextField.isHidden = false
                self.registerButton.isHidden = false
                self.loginButton.isHidden = true
                self.notRegisteredYetButton.isHidden = true
                
                self.userNameTextFieldConstraints = [
                    self.userNameTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
                    self.userNameTextField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
                    self.userNameTextField.topAnchor.constraint(equalTo: self.passwordTextField.bottomAnchor, constant: 20),
                    self.userNameTextField.heightAnchor.constraint(equalToConstant: 40)
                ]
                self.alreadyRegisteredButton = self.configureSwitchToLoginButton()
                
                // Aktivierung der Register-Button Constraints
                NSLayoutConstraint.deactivate(self.loginButtonConstraints)
                NSLayoutConstraint.activate(self.registerButtonConstraints)
                NSLayoutConstraint.activate(self.userNameTextFieldConstraints)
            }
            self.view.layoutIfNeeded() // Layout aktualisieren
    }
}
