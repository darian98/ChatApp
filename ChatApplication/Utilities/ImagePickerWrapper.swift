//
//  ImagePickerWrapper.swift
//  ChatApplication
//
//  Created by Hanci, Darian on 18.12.24.
//

import Foundation
import SwiftUI

struct ImagePickerWrapper: View {
    var onImageSelected: (UIImage?) -> Void
    
    @State private var selectedImage: UIImage? = nil
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ImagePicker(selectedImage: Binding(get: {
            selectedImage
        }, set: { newImage in
            selectedImage = newImage
            onImageSelected(newImage)
            presentationMode.wrappedValue.dismiss()
        }))
    }
}

