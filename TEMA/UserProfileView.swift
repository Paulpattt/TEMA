import SwiftUI

struct UserProfileView: View {
    var user: User
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss

    // Filtre les posts de cet utilisateur
    var userPosts: [Post] {
        return appData.posts.filter { $0.authorId == user.id }
    }
    
    // Grille à 3 colonnes
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                // En-tête du profil
                HStack {
                    if let profilePictureURL = user.profilePicture,
                       !profilePictureURL.isEmpty,
                       let url = URL(string: profilePictureURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.title)
                            .bold()
                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Grille des posts
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(userPosts) { post in
                        if let url = URL(string: post.imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray
                                        .frame(width: UIScreen.main.bounds.width / 3,
                                               height: UIScreen.main.bounds.width / 3)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: UIScreen.main.bounds.width / 3,
                                               height: UIScreen.main.bounds.width / 3)
                                        .clipped()
                                case .failure:
                                    Color.red
                                        .frame(width: UIScreen.main.bounds.width / 3,
                                               height: UIScreen.main.bounds.width / 3)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Color.gray
                                .frame(width: UIScreen.main.bounds.width / 3,
                                       height: UIScreen.main.bounds.width / 3)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        // On masque le bouton "Back" système, donc plus de swipe
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Bouton perso en haut à gauche
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                // Couleur dynamique (noir en clair, blanc en sombre)
                .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    NavigationView {
        UserProfileView(
            user: User(
                id: "1",
                name: "Paul Paturel",
                email: "paul@example.com",
                profilePicture: "",
                authMethod: "Email"
            )
        )
        .environmentObject(AppData())
    }
}
