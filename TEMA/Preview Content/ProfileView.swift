import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
    @State private var showSettings = false
    @State private var showEditProfilePicture = false

    var body: some View {
        NavigationView {
            VStack {
                // En-tête du profil
                HStack {
                    // Bouton pour changer la photo de profil
                    Button(action: {
                        print("Clic sur la photo de profil – ouverture de la modale")
                        showEditProfilePicture = true
                    }) {
                        if let profilePictureURL = appData.currentUser?.profilePicture,
                           !profilePictureURL.isEmpty,
                           let url = URL(string: profilePictureURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(width: 80, height: 80)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                case .failure(_):
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
                    }
                    .contentShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(firstName())
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    // Bouton engrenage pour accéder aux réglages
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
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(appData)
            }
            .sheet(isPresented: $showEditProfilePicture) {
                EditProfilePictureView().environmentObject(appData)
            }
        }
    }
    
    private func firstName() -> String {
        guard let fullName = appData.currentUser?.name, !fullName.isEmpty else {
            return "Utilisateur"
        }
        return fullName.split(separator: " ").first.map { String($0) } ?? "Utilisateur"
    }
}

#Preview {
    ProfileView().environmentObject(AppData())
}
