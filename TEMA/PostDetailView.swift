import SwiftUI
import Kingfisher

struct PostDetailView: View {
    var posts: [Post]
    @Binding var selectedIndex: Int
    var onDismiss: () -> Void

    var body: some View {
        // La vue occupe tout l'espace disponible, mais sera placée sous le header et la tab bar.
        ZStack(alignment: .topLeading) {
            // Affichage des images en mode paging
            TabView(selection: $selectedIndex) {
                ForEach(0..<posts.count, id: \.self) { index in
                    if let url = URL(string: posts[index].imageUrl) {
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
                        .tag(index)
                        
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .edgesIgnoringSafeArea(.all)
            
            // Bouton de retour en haut à gauche
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        // Geste de glissement vers la droite pour revenir
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width > 100 {
                        onDismiss()
                    }
                }
        )
    }
}

#Preview {
    PostDetailView(posts: [], selectedIndex: .constant(0), onDismiss: {})
}
