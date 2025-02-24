//
//  EditProfilePictureView.swift
//  TEMA
//
//  Created by Paul Paturel on 14/02/2025.
//
import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct EditProfilePictureView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .padding()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Choisir une nouvelle photo")
                }
                .padding()
                .onChange(of: selectedItem) { newItem in
                    if let newItem = newItem {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImage = image
                                print("Nouvelle image sélectionnée")
                            } else {
                                print("❌ Erreur lors du chargement de l'image")
                            }
                        }
                    }
                }
                
                Button("Enregistrer") {
                    print("Bouton Enregistrer cliqué")
                    guard let image = selectedImage, let currentUser = appData.currentUser else {
                        print("❌ Erreur : aucune image sélectionnée ou utilisateur non connecté")
                        return
                    }
                    appData.uploadProfileImage(image, forUser: currentUser) { result in
                        switch result {
                        case .success(let url):
                            print("Photo de profil mise à jour, URL : \(url.absoluteString)")
                            dismiss()
                        case .failure(let error):
                            print("❌ Erreur lors de l'upload de la photo de profil : \(error.localizedDescription)")
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Modifier la photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        EditProfilePictureView().environmentObject(AppData())
    } else {
        // Fallback on earlier versions
    }
}
