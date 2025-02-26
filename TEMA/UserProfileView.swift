import SwiftUI
import Kingfisher

struct UserProfileView: View {
    @EnvironmentObject var appData: AppData
    let user: User
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    @State private var selectedIndex: Int? = nil
    @State private var isFullscreen = false
    
    // Filtre les posts de l'utilisateur
    var userPosts: [Post] {
        return appData.posts.filter { $0.authorId == user.id }
    }
    
    // Configuration de la grille (3 colonnes)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Couleur du nom
    @State private var nameColor: Color = .primary
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // En-tête du profil
                    HStack {
                        if let profilePictureURL = user.profilePicture,
                           !profilePictureURL.isEmpty,
                           let url = URL(string: profilePictureURL) {
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
                                .onAppear {
                                    extractColor(from: url)
                                }
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(user.name)
                            .font(.title)
                            .bold()
                            .foregroundColor(nameColor)
                    }
                    .padding()
                    .frame(height: 75)
                    
                    Divider()
                    
                    // Grille de photos
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(userPosts.sorted(by: { $0.timestamp > $1.timestamp }).enumerated()), id: \.offset) { index, post in
                            if let url = URL(string: post.imageUrl), selectedIndex != index || !isFullscreen {
                                KFImage(url)
                                    .placeholder {
                                        ProgressView()
                                    }
                                    .cancelOnDisappear(true)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: UIScreen.main.bounds.width / 3,
                                        height: UIScreen.main.bounds.width / 3
                                    )
                                    .clipped()
                                    .matchedGeometryEffect(id: "image-\(index)", in: animation)
                                    .onTapGesture {
                                        selectedIndex = index
                                        withAnimation(.spring()) {
                                            isFullscreen = true
                                        }
                                    }
                            } else {
                                Color.clear
                                    .frame(
                                        width: UIScreen.main.bounds.width / 3,
                                        height: UIScreen.main.bounds.width / 3
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .opacity(isFullscreen ? 0 : 1)
            
            // Vue plein écran
            if isFullscreen, let selectedIdx = selectedIndex {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                TabView(selection: $selectedIndex) {
                    ForEach(Array(userPosts.sorted(by: { $0.timestamp > $1.timestamp }).enumerated()), id: \.offset) { index, post in
                        if let url = URL(string: post.imageUrl) {
                            KFImage(url)
                                .placeholder {
                                    ProgressView()
                                }
                                .cancelOnDisappear(true)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // Fermeture si glissement vertical
                            if abs(value.translation.height) > 100 && abs(value.translation.height) > abs(value.translation.width) {
                                withAnimation(.spring()) {
                                    isFullscreen = false
                                }
                            }
                        }
                )
                
                // Bouton de fermeture
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                isFullscreen = false
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .foregroundColor(.primary)
                                .padding(12)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func extractColor(from url: URL) {
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let imageResult):
                let uiImage = imageResult.image
                let color = extractAndAdjustColor(from: uiImage)
                DispatchQueue.main.async {
                    self.nameColor = Color(uiColor: color)
                }
            case .failure:
                self.nameColor = .primary
            }
        }
    }
    
    private func extractAndAdjustColor(from image: UIImage) -> UIColor {
        let size = CGSize(width: 100, height: 100)
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
                
                guard saturation > 0.2 && brightness > 0.2 && brightness < 0.95 else { continue }
                
                let saturationScore = saturation * 2.0
                let brightnessScore = 1.0 - abs(brightness - 0.6) * 2.0
                
                var thematicBonus: Double = 0.0
                
                if (hue < 0.1 || hue > 0.95) && saturation > 0.5 {
                    thematicBonus += 1.0
                }
                
                if hue > 0.5 && hue < 0.7 && saturation > 0.5 {
                    thematicBonus += 0.7
                }
                
                let score = saturationScore + brightnessScore + thematicBonus
                
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
        
        let bestColor = colorScores.max { $0.value.score < $1.value.score }?.key ?? .label
        
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        bestColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        s = min(s * 1.8, 1.0)
        
        if colorScheme == .dark {
            b = min(max(b, 0.8), 0.95)
        } else {
            b = min(max(b * 0.7, 0.5), 0.7)
        }
        
        return UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
    }
}

#Preview {
    NavigationView {
        UserProfileView(user: User(id: "preview", name: "Preview User", email: "preview@example.com"))
            .environmentObject(AppData())
    }
}
