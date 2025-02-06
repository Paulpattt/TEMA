import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @Binding var hideHeader: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(appData.posts.sorted(by: { $0.timestamp > $1.timestamp })) { post in
                        PostView(post: post)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true) // On masque la barre de navigation pour ne rien afficher
        }
    }
}

struct PostView: View {
    var post: Post
    
    var body: some View {
        Image(uiImage: post.image)
            .resizable()
            .scaledToFit()
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

#Preview {
    HomeView(hideHeader: .constant(false)).environmentObject(AppData())
}
