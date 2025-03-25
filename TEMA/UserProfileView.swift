import SwiftUI
import Kingfisher

struct UserProfileView: View {
    @EnvironmentObject var appData: AppData
    let user: User
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    @State private var selectedIndex: Int? = nil
    @State private var isFullscreen = false
    
    // Filtre les posts de l'utilisateur
    var userPosts: [Post] {
        return appData.posts.filter { $0.authorId == user.id }
    }
    
    // Configuration de la grille (3 colonnes)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // En-tête du profil
                    HStack {
                        // Utiliser AvatarView au lieu de KFImage
                        AvatarView(
                            profileUrl: user.profilePicture,
                            size: 70,
                            defaultSymbol: "person.fill",
                            defaultColor: .gray
                        )
                        
                        Spacer()
                        
                        // Navigation link vers la vue des actions utilisateur
                        NavigationLink(destination: UserActionsView(user: user)) {
                            Text(user.name)
                                .font(.title)
                                .bold()
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .frame(height: 90)
                    
                    Divider()
                    
                    // Grille de photos
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(userPosts.sorted(by: { $0.timestamp > $1.timestamp }).enumerated()), id: \.offset) { index, post in
                            if let url = URL(string: post.imageUrl), selectedIndex != index || !isFullscreen {
                                KFImage(url)
                                    .placeholder {
                                        ProgressView()
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
            if isFullscreen, let selectedIdx = selectedIndex {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                TabView(selection: $selectedIndex) {
                    ForEach(Array(userPosts.sorted(by: { $0.timestamp > $1.timestamp }).enumerated()), id: \.offset) { index, post in
                        if let url = URL(string: post.imageUrl) {
                            KFImage(url)
                                .placeholder {
                                    ProgressView()
                                }
                                .cancelOnDisappear(true)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // Fermeture si glissement vertical
                            if abs(value.translation.height) > 100 && abs(value.translation.height) > abs(value.translation.width) {
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        UserProfileView(user: User(id: "preview", name: "Preview User", email: "preview@example.com"))
            .environmentObject(AppData())
    }
}
