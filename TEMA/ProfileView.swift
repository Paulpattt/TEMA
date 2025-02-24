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
                                Button(action: {
                                    withAnimation {
                                        selectedIndex = index
                                    }
                                }) {
                                    if let url = URL(string: post.imageUrl) {
                                        KFImage(url)
                                            .placeholder {
                                                ProgressView()
                                                    .frame(width: UIScreen.main.bounds.width / 3,
                                                           height: UIScreen.main.bounds.width / 3)
                                            }
                                            .cancelOnDisappear(true)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: UIScreen.main.bounds.width / 3,
                                                   height: UIScreen.main.bounds.width / 3)
                                            .clipped()
                                    } else {
                                        Color.gray
                                            .frame(width: UIScreen.main.bounds.width / 3,
                                                   height: UIScreen.main.bounds.width / 3)
                                    }
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
                                .tag(i)
                            } else {
                                Color.gray
                                    .tag(i)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .transition(.move(edge: .bottom))
                    
                    // Bouton pour fermer la vue détail
                    Button(action: {
                        withAnimation {
                            selectedIndex = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                    }
                    .position(x: 40, y: 50)
                }
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
        // Présentation conditionnelle de EditProfilePictureView selon iOS version
        .sheet(isPresented: $showEditProfilePicture) {
            if #available(iOS 16.0, *) {
                EditProfilePictureView().environmentObject(appData)
            } else {
                // Fallback : ici, tu pourrais présenter une vue alternative ou un simple message
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
