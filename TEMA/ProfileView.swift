import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
    
    @State private var showEditProfilePicture = false
    @State private var selectedIndex: Int? = nil  // Pour la vue de détail des posts
    
    // Filtre les posts de l'utilisateur courant
    var profilePosts: [Post] {
        if let currentId = appData.currentUser?.id {
            return appData.posts.filter { $0.authorId == currentId }
        }
        return []
    }
    
    // Configuration de la grille (3 colonnes)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête du profil
            HStack {
                // Bouton pour modifier la photo de profil (à gauche)
                Button(action: {
                    showEditProfilePicture = true
                }) {
                    if let profilePictureURL = appData.currentUser?.profilePicture,
                       !profilePictureURL.isEmpty,
                       let url = URL(string: profilePictureURL) {
                        KFImage(url)
                            .placeholder {
                                ProgressView()
                                    .frame(width: 92, height: 92)
                            }
                            .cancelOnDisappear(true)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 92)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 92, height: 92)
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Circle())
                
                Spacer()
                
                // Le nom de l'utilisateur ouvre SettingsView via NavigationLink
                NavigationLink(destination: SettingsView().environmentObject(appData)) {
                    Text(appData.currentUser?.name ?? "Utilisateur")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .frame(height: 75)
            
            Divider()
            
            // ZStack pour la grille et la vue de détail
            ZStack {
                // Grille (visible si aucun post n'est sélectionné)
                if selectedIndex == nil {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(Array(profilePosts.enumerated()), id: \.offset) { index, post in
                                if let url = URL(string: post.imageUrl) {
                                    KFImage(url)
                                        .placeholder {
                                            ProgressView()
                                                .frame(
                                                    width: UIScreen.main.bounds.width / 3,
                                                    height: UIScreen.main.bounds.width / 3
                                                )
                                        }
                                        .cancelOnDisappear(true)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(
                                            width: UIScreen.main.bounds.width / 3,
                                            height: UIScreen.main.bounds.width / 3
                                        )
                                        .clipped()
                                        // Ajout du menu contextuel sur la grille
                                        .contextMenu {
                                            Button {
                                                // Action "Statistiques"
                                            } label: {
                                                Label("Statistiques", systemImage: "chart.bar.fill")
                                            }
                                            
                                            Button {
                                                // Action "Épingler au profil"
                                            } label: {
                                                Label("Épingler au profil", systemImage: "pin.fill")
                                            }
                                            
                                            Button {
                                                // Action "Partager"
                                            } label: {
                                                Label("Partager", systemImage: "square.and.arrow.up")
                                            }
                                            
                                            Button {
                                                // Action "Ajuster l’aperçu"
                                            } label: {
                                                Label("Ajuster l’aperçu", systemImage: "rectangle.and.pencil.and_ellipsis")
                                            }
                                            
                                            Button {
                                                // Action "Archiver"
                                            } label: {
                                                Label("Archiver", systemImage: "archivebox")
                                            }
                                            
                                            // Nouveau bouton pour supprimer la photo
                                            Button {
                                                // Ici, appelle ta fonction de suppression.
                                                // Par exemple, si tu as une méthode dans ton appData :
                                                appData.deletePost(post)
                                            } label: {
                                                Label("Supprimer", systemImage: "trash")
                                            }
                                        }
                                        // Tap pour ouvrir la vue détaillée du post
                                        .onTapGesture {
                                            withAnimation {
                                                selectedIndex = index
                                            }
                                        }
                                } else {
                                    Color.gray
                                        .frame(
                                            width: UIScreen.main.bounds.width / 3,
                                            height: UIScreen.main.bounds.width / 3
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .transition(.opacity)
                }
                
                // Vue de détail (carrousel) si un post est sélectionné
                if let index = selectedIndex {
                    // Fond semi-transparent
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    // Carrousel en plein écran
                    TabView(selection: Binding(
                        get: { index },
                        set: { newValue in
                            selectedIndex = newValue
                        }
                    )) {
                        ForEach(Array(profilePosts.enumerated()), id: \.offset) { i, post in
                            if let url = URL(string: post.imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    case .failure(let error):
                                        VStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundColor(.red)
                                            Text("Erreur : \(error.localizedDescription)")
                                                .font(.caption)
                                                .multilineTextAlignment(.center)
                                        }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                // Menu contextuel sur la vue détaillée
                                .contextMenu {
                                    Button {
                                        // Action "Statistiques"
                                    } label: {
                                        Label("Statistiques", systemImage: "chart.bar.fill")
                                    }
                                    
                                    Button {
                                        // Action "Épingler au profil"
                                    } label: {
                                        Label("Épingler au profil", systemImage: "pin.fill")
                                    }
                                    
                                    Button {
                                        // Action "Partager"
                                    } label: {
                                        Label("Partager", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button {
                                        // Action "Ajuster l’aperçu"
                                    } label: {
                                        Label("Ajuster l’aperçu", systemImage: "rectangle.and.pencil.and_ellipsis")
                                    }
                                    
                                    Button {
                                        // Action "Archiver"
                                    } label: {
                                        Label("Archiver", systemImage: "archivebox")
                                    }
                                    
                                    // Nouveau bouton pour supprimer la photo
                                    Button {
                                        // Ici, appelle ta fonction de suppression.
                                        // Par exemple, si tu as une méthode dans ton appData :
                                        appData.deletePost(post)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                                .tag(i)
                            } else {
                                Color.gray
                                    .tag(i)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .transition(.move(edge: .bottom))
                    
                    // Bouton pour fermer la vue détaillée
                    Button(action: {
                        withAnimation {
                            selectedIndex = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .position(x: 40, y: 50)
                }
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditProfilePicture) {
            if #available(iOS 16.0, *) {
                EditProfilePictureView().environmentObject(appData)
            } else {
                Text("La modification de la photo n'est pas disponible sur cette version")
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView().environmentObject(AppData())
    }
}
