import SwiftUI
import Kingfisher
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @Binding var hideHeader: Bool
    
    // Variable d'état globale pour contrôler l'affichage des infos sur tous les posts
    @State private var globalShowUserInfo: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Trie par timestamp décroissant
                    ForEach(appData.posts.sorted(by: { $0.timestamp > $1.timestamp })) { post in
                        // Chaque PostView reçoit le binding global
                        PostView(post: post, showUserInfo: $globalShowUserInfo)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

struct PostView: View {
    var post: Post
    // Binding partagé pour afficher ou non les infos sur tous les posts
    @Binding var showUserInfo: Bool
    @EnvironmentObject var appData: AppData
    // Couleur dynamique du texte (calculée selon la luminosité de la zone haute de l'image)
    @State private var dynamicColor: Color = .white
    // Propriétés pour stocker les informations de l'auteur
    @State private var author: User? = nil
    
    var body: some View {
        ZStack {
            // Affichage de l'image du post
            if let url = URL(string: post.imageUrl) {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                            .frame(height: 200)
                    }
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFit() // L'image garde ses proportions et occupe toute la largeur
                    .frame(width: UIScreen.main.bounds.width)
                    .clipped()
                    // Dès que l'image est chargée, on calcule la couleur du texte
                    .onAppear {
                        KingfisherManager.shared.retrieveImage(with: url, options: nil) { result in
                            switch result {
                            case .success(let value):
                                let uiImage = value.image
                                // Analyse du haut 20% de l'image
                                let rect = CGRect(x: 0, y: 0, width: uiImage.size.width, height: uiImage.size.height * 0.2)
                                if let avgColor = uiImage.averageColor(in: rect) {
                                    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                                    avgColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                                    let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            dynamicColor = luminance > 0.5 ? .black : .white
                                        }
                                    }
                                }
                            case .failure(let error):
                                print("Erreur lors de la récupération de l'image: \(error.localizedDescription)")
                            }
                        }
                    }
            } else {
                Color.gray
                    .frame(height: 200)
            }
            
            // Affichage des infos de l'auteur (photo de profil en haut à gauche et nom en haut à droite)
            if showUserInfo, let user = author {
                VStack {
                    HStack {
                        // Photo de profil
                        if let profileURL = URL(string: user.profilePicture ?? "") {
                            KFImage(profileURL)
                                .placeholder {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(.gray)
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // Nom de l'auteur
                        Text(user.name)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(dynamicColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    Spacer()
                }
            }
        }
        // Un simple tap sur n'importe quelle image bascule globalement l'affichage des infos
        .onTapGesture {
            withAnimation {
                showUserInfo.toggle()
            }
        }
        // Chargement de l'auteur pour ce post
        .onAppear {
            loadAuthor()
        }
    }
    
    // Fonction pour charger l'auteur du post
    private func loadAuthor() {
        // Si le post appartient à l'utilisateur courant, utiliser directement appData.currentUser
        if let currentUser = appData.currentUser, currentUser.id == post.authorId {
            author = currentUser
        } else {
            // Sinon, récupérer l'utilisateur via la méthode getUser (qui peut utiliser un cache)
            appData.getUser(for: post.authorId) { fetchedUser in
                DispatchQueue.main.async {
                    self.author = fetchedUser
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(hideHeader: .constant(false))
            .environmentObject(AppData())
    }
}
