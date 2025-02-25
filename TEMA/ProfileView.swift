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
                                    .frame(width: 80, height: 80)
                            }
                            .cancelOnDisappear(true)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 80, height: 80)
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
                                            
                                            // iOS16+ symbol, attention
                                            Button {
                                                // Action "Ajuster l’aperçu"
                                            } label: {
                                                Label("Ajuster l’aperçu", systemImage: "rectangle.and.pencil.and.ellipsis")
                                            }
                                            
                                            Button {
                                                // Action "Archiver"
                                            } label: {
                                                Label("Archiver", systemImage: "archivebox")
                                            }
                                            
                                            Button {
                                                // Supprimer le post
                                                appData.deletePost(post)
                                            } label: {
                                                Label("Supprimer", systemImage: "trash")
                                            }
                                        }
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
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
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
                                    case .failure(_):
                                        // On affiche rien au lieu d'un message d'erreur
                                        EmptyView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
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
                                    
                                    // iOS16+ symbol, attention
                                    Button {
                                        // Action "Ajuster l’aperçu"
                                    } label: {
                                        Label("Ajuster l’aperçu", systemImage: "rectangle.and.pencil.and.ellipsis")
                                    }
                                    
                                    Button {
                                        // Supprimer le post
                                        appData.deletePost(post)
                                        withAnimation {
                                            selectedIndex = nil
                                        }
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                                .tag(i)
                            } else {
                                Color.gray.tag(i)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .transition(.move(edge: .bottom))
                    
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
