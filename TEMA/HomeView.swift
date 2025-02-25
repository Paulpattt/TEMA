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
    @State private var textColor: Color = .primary
    @Environment(\.colorScheme) var colorScheme
    
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
                    .onAppear {
                        KingfisherManager.shared.retrieveImage(with: url) { result in
                            switch result {
                            case .success(let imageResult):
                                let uiImage = imageResult.image
                                let color = extractAndAdjustColor(from: uiImage)
                                textColor = Color(uiColor: color)
                            case .failure:
                                textColor = .primary
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
                        .foregroundColor(textColor)
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
    
    private func extractAndAdjustColor(from image: UIImage) -> UIColor {
        // Réduire la taille de l'image pour l'analyse
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = scaledImage?.cgImage else { return .label }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let context = CGContext(data: &rawData,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return .label }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Collecter les couleurs et leur fréquence
        var colorFrequency: [String: (color: UIColor, count: Int, saturation: CGFloat)] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = CGFloat(rawData[offset]) / 255.0
                let g = CGFloat(rawData[offset + 1]) / 255.0
                let b = CGFloat(rawData[offset + 2]) / 255.0
                
                let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                var alpha: CGFloat = 0
                
                color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                
                // Ignorer les couleurs trop sombres ou trop claires
                guard brightness > 0.1 && brightness < 0.9 else { continue }
                
                // Clé unique pour chaque couleur (arrondie pour regrouper les similaires)
                let key = "\(Int(hue * 30))-\(Int(saturation * 10))-\(Int(brightness * 10))"
                
                if let existing = colorFrequency[key] {
                    colorFrequency[key] = (color, existing.count + 1, saturation)
                } else {
                    colorFrequency[key] = (color, 1, saturation)
                }
            }
        }
        
        // Trouver la couleur dominante la plus vibrante
        let dominantColor = colorFrequency
            .sorted { $0.value.count > $1.value.count } // D'abord par fréquence
            .prefix(5) // Prendre les 5 plus fréquentes
            .max { $0.value.saturation < $1.value.saturation }? // Choisir la plus saturée
            .value.color ?? .label
        
        // Ajuster la luminosité pour le mode
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        dominantColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        if colorScheme == .dark {
            b = min(max(b * 1.3, 0.6), 0.8)
            s = min(s * 1.1, 0.9)
        } else {
            b = min(max(b * 0.7, 0.3), 0.5)
            s = min(s * 0.9, 0.8)
        }
        
        return UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(hideHeader: .constant(false))
            .environmentObject(AppData())
    }
}
