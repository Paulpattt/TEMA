import SwiftUI

struct HomeView: View {
    struct Post {
        let username: String
        let imageName: String
        let description: String
    }

    let posts: [Post] = [
        Post(username: "Paul", imageName: "post1", description: "Un moment parfait."),
        Post(username: "Viola", imageName: "post2", description: "Vue magnifique !"),
        Post(username: "Mathieu", imageName: "post3", description: "Souvenirs incroyables.")
    ]

    @Binding var hideHeader: Bool
    @State private var headerOpacity: Double = 1.0
    @State private var headerOffset: CGFloat = 0
    @State private var previousOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            GeometryReader { proxy in
                Color.clear
                    .frame(height: 0) // Hack pour détecter le scroll
                    .onAppear {
                        previousOffset = proxy.frame(in: .global).minY
                    }
                  
            }

            VStack(spacing: 20) {
                ForEach(posts, id: \.imageName) { post in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)

                        Image(post.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .clipped()

                        Text(post.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 5)
                    }
                }
            }
            .padding(.horizontal, 0)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    HomeView(hideHeader: .constant(false))
}
