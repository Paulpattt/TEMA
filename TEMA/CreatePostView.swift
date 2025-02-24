import SwiftUI
import PhotosUI
import FirebaseStorage

@available(iOS 16.0, *)
struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appData: AppData
    @State private var isPhotoPickerPresented = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        ZStack {
            // Fond adaptatif (clair/sombre)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if let image = selectedImage {
                // Vue de prévisualisation avec l'image et le bouton Publier
                VStack {
                    // On ajoute un espace pour éviter que le bouton "x" chevauche l'image
                    Spacer().frame(height: 60)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .padding()
                    
                    Button(action: publishPost) {
                        Text("Publier")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    Spacer()
                }
                // Superposition d'un bouton "x" positionné en haut à gauche avec plus de padding pour le décoller de l'image
                .overlay(
                    Button(action: {
                        // Réinitialise selectedImage pour revenir à l'écran initial
                        selectedImage = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.primary)
                            .padding(20)
                    },
                    alignment: .topLeading
                )
            } else {
                // Vue initiale avec le "+"
                Button(action: {
                    isPhotoPickerPresented = true
                }) {
                    Text("+")
                        .font(.system(size: 150, weight: .light))
                        .foregroundColor(.red)
                }
            }
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedItem)
        .onChange(of: selectedItem) { newItem in
            if let newItem = newItem {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedImage = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    func publishPost() {
        guard let image = selectedImage,
              let currentUser = appData.currentUser else {
            print("❌ Erreur : image ou utilisateur introuvable")
            return
        }
        print("Début de l'upload de l'image...")
        appData.uploadImage(image) { result in
            switch result {
            case .success(let imageURL):
                let newPost = Post(authorId: currentUser.id, imageUrl: imageURL, timestamp: Date())
                appData.addPostToFirestore(newPost)
                selectedImage = nil
                print("✅ Post publié avec succès ! URL : \(imageURL)")
                dismiss()
            case .failure(let error):
                print("❌ Erreur lors de l'upload : \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        CreatePostView().environmentObject(AppData())
    } else {
        EmptyView()
    }
}
