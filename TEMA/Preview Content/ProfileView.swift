import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            VStack {
                // En-tête du profil
                HStack {
                    // Image de profil par défaut (ou personnalisée si tu en as une)
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        // Affiche uniquement le prénom
                        Text(firstName())
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    // Bouton pour accéder aux réglages
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                Divider()
                
                // Affichage des posts de l'utilisateur
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(appData.posts.filter { $0.authorId == appData.currentUser?.id }) { post in
                            PostView(post: post)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true) // Masque la barre de navigation pour ne pas afficher "Profil"
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    /// Extrait le prénom du nom complet de l'utilisateur
    private func firstName() -> String {
        guard let fullName = appData.currentUser?.name, !fullName.isEmpty else {
            return "Utilisateur"
        }
        return fullName.split(separator: " ").first.map { String($0) } ?? "Utilisateur"
    }
}

// Vue pour afficher un post individuel
struct UserPostView: View {
    var post: Post
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: post.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .shadow(radius: 5)
            } placeholder: {
                ProgressView() // Affiche un indicateur de chargement en attendant l'image
            }
        }
    }
    
    #Preview {
        ProfileView().environmentObject(AppData())
    }
}
