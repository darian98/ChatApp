//
//  UserModel.swift
//  SomeUIKit
//
//  Created by Hanci, Darian on 14.11.24.
//

import Foundation
// Benutzer-Modell zur Darstellung in der Liste
struct UserModel {
    let uid: String
    let displayName: String
    let email: String
    var friends: [Friend] = []
    var bio: String
    var profileImage: String?
}
