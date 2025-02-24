import SwiftUI
import Kingfisher

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
            KFImage(url)
                .placeholder {
                    ProgressView()
                        .frame(height: 200) // Hauteur du placeholder uniquement
                }
                .cancelOnDisappear(true)
                .resizable()
                .scaledToFit()                  // Conserve le ratio, s'adapte à la largeur
                .frame(width: UIScreen.main.bounds.width)
                .clipped()
        } else {
            Color.gray
                .frame(height: 200)
        }
    }
}

#Preview {
    HomeView(hideHeader: .constant(false)).environmentObject(AppData())
}
