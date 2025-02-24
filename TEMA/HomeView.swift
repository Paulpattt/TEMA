import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @Binding var hideHeader: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Trie par timestamp décroissant
                    ForEach(appData.posts.sorted(by: { $0.timestamp > $1.timestamp })) { post in
                        PostView(post: post)
                    }
                }
                // On retire le padding horizontal pour occuper toute la largeur
                .padding(.vertical)
            }
            .navigationBarHidden(true)
        }
    }
}

struct PostView: View {
    var post: Post
    
    var body: some View {
        if let url = URL(string: post.imageUrl) {
            AsyncImage(url: url, transaction: Transaction(animation: .easeIn)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()        // L'image s'ajuste pour occuper toute la largeur sans être coupée
                        //.cornerRadius(0)      // Pas de coins arrondis
                        //.shadow(radius: 0)      // Pas d'ombre
                        .frame(maxWidth: .infinity)
                case .failure(let error):
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Erreur : \(error.localizedDescription)")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                @unknown default:
                    EmptyView()
                }
            }
            .onAppear {
                print("Chargement de l'image depuis URL: \(url.absoluteString)")
            }
        } else {
            Color.gray
                .frame(height: 200)
        }
    }
}

#Preview {
    HomeView(hideHeader: .constant(false)).environmentObject(AppData())
}
