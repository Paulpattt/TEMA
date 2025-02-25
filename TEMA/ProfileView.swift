import SwiftUI
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
    @Namespace private var animation  // Namespace pour l'animation
    
    @State private var showEditProfilePicture = false
    @State private var selectedIndex: Int? = nil  // Pour la vue de détail des posts
    @State private var isFullscreen = false
    
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
        ZStack {
            // Vue principale (grille)
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
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .frame(height: 75)
                
                Divider()
                
                // Grille de photos
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(profilePosts.enumerated()), id: \.offset) { index, post in
                            if let url = URL(string: post.imageUrl), selectedIndex != index || !isFullscreen {
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
                                    .matchedGeometryEffect(id: "image-\(index)", in: animation)
                                    .onTapGesture {
                                        selectedIndex = index
                                        withAnimation(.spring()) {
                                            isFullscreen = true
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
                                            // Action "Ajuster l'aperçu"
                                        } label: {
                                            Label("Ajuster l'aperçu", systemImage: "rectangle.and.pencil.and.ellipsis")
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
                            } else {
                                Color.clear
                                    .frame(
                                        width: UIScreen.main.bounds.width / 3,
                                        height: UIScreen.main.bounds.width / 3
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .opacity(isFullscreen ? 0 : 1)
            
            // Vue plein écran
            if isFullscreen, let selectedIdx = selectedIndex, selectedIdx < profilePosts.count {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                // Image agrandie
                KFImage(URL(string: profilePosts[selectedIdx].imageUrl)!)
                    .placeholder {
                        ProgressView()
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .matchedGeometryEffect(id: "image-\(selectedIdx)", in: animation)
                    .gesture(
                        // Geste de balayage vertical pour naviguer entre les images
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                if abs(value.translation.height) > 100 {
                                    if value.translation.height > 0 && selectedIdx > 0 {
                                        // Swipe vers le bas -> image précédente
                                        selectedIndex = selectedIdx - 1
                                    } else if value.translation.height < 0 && selectedIdx < profilePosts.count - 1 {
                                        // Swipe vers le haut -> image suivante
                                        selectedIndex = selectedIdx + 1
                                    }
                                } else if abs(value.translation.width) > 100 {
                                    // Swipe horizontal -> fermeture
                                    withAnimation(.spring()) {
                                        isFullscreen = false
                                    }
                                }
                            }
                    )
                
                // Bouton de fermeture
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                isFullscreen = false
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .foregroundColor(.primary)
                                .padding(12)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
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
