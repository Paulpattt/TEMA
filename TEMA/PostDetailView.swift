import SwiftUI
import Kingfisher

struct PostDetailView: View {
    var posts: [Post]
    @Binding var selectedIndex: Int
    var onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Fond adaptatif au mode (clair/sombre)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // TabView en mode vertical
            TabView(selection: $selectedIndex) {
                ForEach(0..<posts.count, id: \.self) { index in
                    if let url = URL(string: posts[index].imageUrl) {
                        ZStack(alignment: .topLeading) {
                            // Image plein écran
                            KFImage(url)
                                .placeholder {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                .cancelOnDisappear(true)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .tag(index)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            // Rotation pour défilement vertical
            .rotationEffect(.degrees(-90))
            .frame(
                width: UIScreen.main.bounds.height,
                height: UIScreen.main.bounds.width
            )
            .rotationEffect(.degrees(90), anchor: .topLeading)
            .offset(x: UIScreen.main.bounds.width)
            .ignoresSafeArea()
            
            // Bouton de retour avec fond adaptatif
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title)
                    .foregroundColor(.primary)
                    .padding(12)
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        // Geste de balayage vers le bas pour fermer
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        onDismiss()
                    }
                }
        )
    }
}

#Preview {
    PostDetailView(posts: [], selectedIndex: .constant(0), onDismiss: {})
}
