import SwiftUI
import Kingfisher
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @Binding var hideHeader: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 30) {
                ForEach(appData.posts.sorted(by: { $0.timestamp > $1.timestamp })) { post in
                    PostView(post: post)
                        .background(Color.clear)
                }
            }
            .padding(.vertical)
        }
        .background(Color.clear)
    }
}

struct PostView: View {
    var post: Post
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
            
            // Conteneur pour le nom (toujours affiché)
            ZStack(alignment: .leading) {
                if let user = author {
                    NavigationLink(destination: UserProfileView(user: user)) {
                        Text(user.name)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(textColor)
                    }
                } else {
                    Text("Chargement...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .onAppear {
                            loadAuthor()
                        }
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 6)
            .padding(.top, 2)
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
                if let fetchedUser = fetchedUser {
                    DispatchQueue.main.async {
                        self.author = fetchedUser
                    }
                } else {
                    print("Impossible de charger l'auteur pour le post: \(post.id)")
                }
            }
        }
    }
    
    private func extractAndAdjustColor(from image: UIImage) -> UIColor {
        // Réduire la taille de l'image pour l'analyse
        let size = CGSize(width: 100, height: 100) // Augmenté pour plus de précision
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
        
        // Score pour chaque couleur en fonction de sa vivacité et son unicité
        var colorScores: [UIColor: (score: Double, saturation: CGFloat, brightness: CGFloat)] = [:]
        
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
                
                // Ignorer les couleurs grisâtres, trop sombres ou trop claires
                guard saturation > 0.2 && brightness > 0.2 && brightness < 0.95 else { continue }
                
                // Calcul du score: on privilégie les couleurs saturées et de luminosité moyenne
                let saturationScore = saturation * 2.0 // On donne plus d'importance à la saturation
                let brightnessScore = 1.0 - abs(brightness - 0.6) * 2.0 // Optimum à 0.6 de luminosité
                
                // Bonus pour les couleurs spécifiques (oranges pour les flammes, bleus pour la mer)
                var thematicBonus: Double = 0.0
                
                // Orange/Rouge (flammes) - hue entre 0.0 et 0.1 ou 0.95-1.0
                if (hue < 0.1 || hue > 0.95) && saturation > 0.5 {
                    thematicBonus += 1.0
                }
                
                // Bleu (mer/ciel) - hue entre 0.5 et 0.7
                if hue > 0.5 && hue < 0.7 && saturation > 0.5 {
                    thematicBonus += 0.7
                }
                
                let score = saturationScore + brightnessScore + thematicBonus
                
                // On arrondit les couleurs similaires
                let roundedColor = UIColor(hue: round(hue * 20) / 20,
                                         saturation: round(saturation * 10) / 10,
                                         brightness: round(brightness * 10) / 10,
                                         alpha: 1.0)
                
                if let existing = colorScores[roundedColor] {
                    colorScores[roundedColor] = (existing.score + score, max(existing.saturation, saturation), existing.brightness)
                } else {
                    colorScores[roundedColor] = (score, saturation, brightness)
                }
            }
        }
        
        // Trouver la couleur avec le meilleur score
        let bestColor = colorScores.max { $0.value.score < $1.value.score }?.key ?? .label
        
        // Ajuster la vivacité de la couleur
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        bestColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // Augmenter la saturation pour des couleurs plus vives
        s = min(s * 1.8, 1.0) // Augmente encore plus la saturation
        
        if colorScheme == .dark {
            // En mode sombre, on garde une luminosité élevée
            b = min(max(b, 0.8), 0.95)
        } else {
            // En mode clair, luminosité moyenne-basse pour contraste
            b = min(max(b * 0.7, 0.5), 0.7)
        }
        
        // Créer une couleur plus vibrante
        let vibrantColor = UIColor(hue: h,
                                 saturation: s,
                                 brightness: b,
                                 alpha: 1.0)
        
        return vibrantColor
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(hideHeader: .constant(false))
            .environmentObject(AppData())
    }
}
