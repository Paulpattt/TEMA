//
//  AvatarView.swift
//  TEMA
//
//  Created by Paul Paturel on 14/02/2025.
//

import SwiftUI

/// Vue réutilisable pour afficher un avatar à partir d'un symbole système
struct AvatarView: View {
    // URL de profil au format "nomSymbole:couleur"
    let profileUrl: String?
    
    // Taille de l'avatar
    let size: CGFloat
    
    // Forme circulaire (true) ou carrée (false)
    let isCircular: Bool
    
    // Symbole par défaut si aucun n'est fourni
    let defaultSymbol: String
    
    // Couleur par défaut si aucune n'est fournie
    let defaultColor: Color
    
    // Initialisateur avec valeurs par défaut
    init(
        profileUrl: String?,
        size: CGFloat = 40,
        isCircular: Bool = false,
        defaultSymbol: String = "person.fill",
        defaultColor: Color = .gray
    ) {
        self.profileUrl = profileUrl
        self.size = size
        self.isCircular = isCircular
        self.defaultSymbol = defaultSymbol
        self.defaultColor = defaultColor
    }
    
    private var symbolName: String {
        guard let profileUrl = profileUrl, !profileUrl.isEmpty else {
            return defaultSymbol
        }
        
        let parts = profileUrl.components(separatedBy: ":")
        if parts.count >= 1 {
            return parts[0]
        }
        return defaultSymbol
    }
    
    private var symbolColor: Color {
        guard let profileUrl = profileUrl, !profileUrl.isEmpty else {
            return defaultColor
        }
        
        let parts = profileUrl.components(separatedBy: ":")
        if parts.count >= 2 {
            return colorFromString(parts[1]) ?? defaultColor
        }
        return defaultColor
    }
    
    var body: some View {
        Group {
            if isCircular {
                // Version circulaire
                ZStack {
                    // Avatar: image personnalisée ou SF Symbol
                    if symbolName.contains("avatar") || symbolName.contains("Pokemon") {
                        // Image personnalisée - avec vérification
                        ZStack {
                            if let bundlePath = Bundle.main.resourcePath,
                               let image = loadPokemonAvatar(named: symbolName) {
                                // L'image existe - format rectangulaire pour les Pokémon
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: size * 1.15, height: size) // Ratio largeur/hauteur de 1.15
                            } else {
                                // L'image n'existe pas - montrer un placeholder
                                VStack {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(size * 0.25)
                                        .foregroundColor(.gray)
                                    
                                    if size > 30 {
                                        Text(symbolName)
                                            .font(.system(size: size * 0.15))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(width: size * 1.15, height: size)
                            }
                        }
                    } else {
                        // SF Symbol - garder le fond circulaire
                        Circle()
                            .fill(symbolColor.opacity(0.15))
                            .frame(width: size, height: size)
                        
                        Image(systemName: symbolName)
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.2)
                            .foregroundColor(symbolColor)
                            .frame(width: size, height: size)
                    }
                }
                .clipShape(Circle())
            } else {
                // Version rectangulaire
                ZStack {
                    // Avatar: image personnalisée ou SF Symbol
                    if symbolName.contains("avatar") || symbolName.contains("Pokemon") {
                        // Image personnalisée - avec vérification
                        ZStack {
                            if let image = loadPokemonAvatar(named: symbolName) {
                                // L'image existe - format rectangulaire pour les Pokémon
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: size * 1.15, height: size) // Ratio largeur/hauteur de 1.15
                            } else {
                                // L'image n'existe pas - montrer un placeholder
                                VStack {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(size * 0.25)
                                        .foregroundColor(.gray)
                                    
                                    if size > 30 {
                                        Text(symbolName)
                                            .font(.system(size: size * 0.15))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(width: size * 1.15, height: size)
                            }
                        }
                    } else {
                        // SF Symbol - garder le fond rectangulaire
                        Rectangle()
                            .fill(symbolColor.opacity(0.15))
                            .frame(width: size, height: size)
                            .cornerRadius(size * 0.1)
                        
                        Image(systemName: symbolName)
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.2)
                            .foregroundColor(symbolColor)
                            .frame(width: size, height: size)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
            }
        }
    }
    
    // Fonction pour charger un avatar Pokémon depuis le bundle
    private func loadPokemonAvatar(named: String) -> UIImage? {
        // D'abord essayer avec UIImage(named:) standard
        if let image = UIImage(named: named) {
            return image
        }
        
        // Sinon, chercher dans le dossier AvatarsPokemons
        if let bundlePath = Bundle.main.resourcePath {
            let avatarPath = (bundlePath as NSString).appendingPathComponent("AvatarsPokemons")
            let imagePath = (avatarPath as NSString).appendingPathComponent("\(named).png")
            
            // Essayer de charger directement depuis le chemin
            if let image = UIImage(contentsOfFile: imagePath) {
                return image
            }
        }
        
        return nil
    }
    
    // Convertit une chaîne en couleur
    private func colorFromString(_ colorStr: String) -> Color? {
        switch colorStr {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "mint": return .mint
        default: return nil
        }
    }
}

// Prévisualisations
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Nouvelles images d'avatar Pokémon
            HStack(spacing: 10) {
                AvatarView(profileUrl: "avatar_02:red", size: 70)
                AvatarView(profileUrl: "avatar1:blue", size: 70)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewDisplayName("Avatars Pokémon")
            
            // Test format rectangulaire
            AvatarView(profileUrl: "avatar_02:red", size: 85, isCircular: false)
                .background(Color.gray.opacity(0.1))
                .previewDisplayName("Pokémon rectangulaire")
            
            // Différentes tailles en carré
            HStack(spacing: 10) {
                AvatarView(profileUrl: "person.fill:red", size: 30)
                AvatarView(profileUrl: "star.fill:blue", size: 50)
                AvatarView(profileUrl: "heart.fill:green", size: 70)
            }
            
            // Différentes tailles en cercle
            HStack(spacing: 10) {
                AvatarView(profileUrl: "person.fill:red", size: 30, isCircular: true)
                AvatarView(profileUrl: "star.fill:blue", size: 50, isCircular: true)
                AvatarView(profileUrl: "heart.fill:green", size: 70, isCircular: true)
            }
            
            // Cas par défaut
            AvatarView(profileUrl: nil, size: 50)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
