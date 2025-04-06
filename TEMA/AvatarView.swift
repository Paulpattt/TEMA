//
//  AvatarView.swift
//  TEMA
//
//  Created by Paul Paturel on 14/02/2025.
//

import SwiftUI

/// Vue réutilisable pour afficher un avatar à partir d'un symbole système
struct AvatarView: View {
    // URL de profil contient maintenant SEULEMENT le nom de l'asset (ex: "PokemonAvatar_0357_Avatar-35")
    let profileUrl: String?
    
    // Taille de l'avatar
    let size: CGFloat
    
    // Forme circulaire (true) ou carrée (false)
    let isCircular: Bool
    
    // Symbole par défaut si aucun n'est fourni ou si l'image n'est pas trouvée
    let defaultSymbol: String
    
    // Couleur par défaut pour le placeholder
    let defaultColor: Color
    
    // Initialisateur avec valeurs par défaut
    init(
        profileUrl: String?,
        size: CGFloat = 40,
        isCircular: Bool = false,
        defaultSymbol: String = "person.fill", // Placeholder si l'image n'est pas trouvée
        defaultColor: Color = .gray
    ) {
        self.profileUrl = profileUrl
        self.size = size
        self.isCircular = isCircular
        self.defaultSymbol = defaultSymbol
        self.defaultColor = defaultColor
    }
    
    var body: some View {
        // Essaie de charger l'image directement depuis les Assets
        if let assetName = profileUrl, let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit() // Utiliser scaledToFit pour ne pas déformer
                .frame(width: size, height: size) // Cadre carré initial
                .background(Color.clear) // Fond transparent
                .clipShape(shape) // Appliquer la forme (cercle ou rectangle arrondi)

        } else {
            // Placeholder si profileUrl est nil ou si l'image n'est pas trouvée dans les Assets
            placeholderView
        }
    }
    
    // Vue pour le placeholder
    private var placeholderView: some View {
        ZStack {
            shape.fill(defaultColor.opacity(0.15)) // Fond coloré léger
            
            Image(systemName: defaultSymbol)
                .resizable()
                .scaledToFit()
                .foregroundColor(defaultColor)
                .padding(size * 0.25) // Padding pour l'icône
        }
        .frame(width: size, height: size)
    }
    
    // Détermine la forme à utiliser pour le clip et l'overlay
    // Utiliser AnyShape pour effacer le type concret
    private var shape: AnyShape { // <<<< Retourner AnyShape explicitement
        if isCircular {
            return AnyShape(Circle()) // <<<< Wrapper dans AnyShape
        } else {
            return AnyShape(RoundedRectangle(cornerRadius: size * 0.1)) // <<<< Wrapper dans AnyShape
        }
    }
}

// Prévisualisations (à adapter si les noms d'assets ont changé)
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Utiliser des noms d'assets réels qui sont dans Assets.xcassets
            HStack(spacing: 10) {
                // Remplace "PokemonAvatar_0357_Avatar-35" par un nom d'asset valide si besoin
                AvatarView(profileUrl: "PokemonAvatar_0357_Avatar-35", size: 70, isCircular: true)
                AvatarView(profileUrl: "PokemonAvatar_0356_Avatar-36", size: 70, isCircular: true) // Autre exemple
                AvatarView(profileUrl: "asset_inexistant", size: 70, isCircular: true) // Test placeholder
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewDisplayName("Avatars Locaux (Cercle)")

            HStack(spacing: 10) {
                AvatarView(profileUrl: "PokemonAvatar_0357_Avatar-35", size: 70, isCircular: false)
                AvatarView(profileUrl: "PokemonAvatar_0356_Avatar-36", size: 70, isCircular: false)
                AvatarView(profileUrl: nil, size: 70, isCircular: false) // Test placeholder (nil)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewDisplayName("Avatars Locaux (Carré)")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
