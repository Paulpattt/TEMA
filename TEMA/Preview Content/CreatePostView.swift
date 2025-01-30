import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @State private var isPhotoPickerPresented = false // État pour ouvrir la photothèque
    @State private var selectedItem: PhotosPickerItem? = nil // Gère la sélection de l'image
    @State private var selectedImage: UIImage? = nil // Stocke l'image sélectionnée
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea() // Fond adaptatif clair/sombre
            
            Button(action: {
                isPhotoPickerPresented = true
            }) {
                Text("+")
                    .font(.system(size: 150, weight: .light))
                    .foregroundColor(.red)
            }
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedItem)
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newItem = newValue {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedImage = UIImage(data: data) // Charge l'image sélectionnée
                    }
                }
            }
        }
    }
}

#Preview {
    CreatePostView()
}
