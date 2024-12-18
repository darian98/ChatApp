//
//  ImageHelper.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 18.12.24.
//

import Foundation
import UIKit

enum ImageHelper {
    
    static func compressImage(_ image: UIImage, to maxSizeInKB: Int) -> Data? {
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
    
    
}
