import SwiftUI
import Kingfisher
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @Binding var hideHeader: Bool
    @State private var showUserNames: Bool = true // Pour contrôler l'affichage des noms
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 50) {
                    ForEach(appData.posts.sorted(by: { $0.timestamp > $1.timestamp })) { post in
                        PostView(post: post, showName: showUserNames)
                            .background(Color.clear)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showUserNames.toggle()
                                }
                            }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.clear)
            .navigationBarHidden(true)
        }
    }
}

struct PostView: View {
    var post: Post
    var showName: Bool
    @EnvironmentObject var appData: AppData
    @State private var author: User? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let url = URL(string: post.imageUrl) {
                KFImage(url)
                    .placeholder {
                        ProgressView()
                            .frame(height: 200)
                    }
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.width)
                    .contextMenu {
                        if appData.currentUser?.id == post.authorId {
                            Button(role: .destructive) {
                                appData.deletePost(post)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
            } else {
                Color.clear
                    .frame(height: 200)
            }
            
            // Conteneur de hauteur fixe pour le nom
            ZStack(alignment: .leading) {
                if showName, let user = author {
                    Text(user.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 6)
            .padding(.top, 4)
        }
        .onAppear {
            loadAuthor()
        }
    }
    
    private func loadAuthor() {
        if let currentUser = appData.currentUser, currentUser.id == post.authorId {
            author = currentUser
        } else {
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
