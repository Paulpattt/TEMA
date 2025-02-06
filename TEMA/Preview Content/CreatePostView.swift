import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @EnvironmentObject var appData: AppData
    @State private var isPhotoPickerPresented = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            // Fond adaptatif (clair/sombre)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Si une image est sélectionnée, on l'affiche avec un bouton pour publier le post
            if let image = selectedImage {
                VStack {
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            } else {
                // Affiche uniquement le "+" au centre de la vue
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
              let currentUser = appData.currentUser else { return }
        // Création d'un nouveau post avec l'identifiant de l'utilisateur connecté
        let newPost = Post(authorId: currentUser.id, image: image)
        appData.addPost(newPost)
        selectedImage = nil // Réinitialise l'image après publication
        print("Post publié par \(currentUser.name)")
    }
}

#Preview {
    CreatePostView().environmentObject(AppData())
}
