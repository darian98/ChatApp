//
//  UIApplication+Extension.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 02.12.24.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        windows.first?.endEditing(true)
    }
}
