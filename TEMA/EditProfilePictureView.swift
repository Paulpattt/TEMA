//
//  ProfileAvatarPickerView.swift
//  TEMA
//
//  Created by Paul Paturel on 14/02/2025.
//
import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ProfileAvatarPickerView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    // Liste des avatars personnalisés (mise à jour pour correspondre aux noms réels d'assets)
    private let avatarNames = [
        "avatar1", "avatar2", "avatar3", "avatar4", "avatar5",
        "avatar6", "avatar7", "avatar8", "avatar9", "avatar10",
        "avatar11", "avatar12", "avatar13", "avatar14", "avatar15",
        "avatar16", "avatar17", "avatar18", "avatar19", "avatar20",
        "avatar21", "avatar22", "avatar23", "avatar24", "avatar25",
        "avatar26", "avatar27", "avatar28", "avatar29", "avatar30",
        "avatar31", "avatar_02", "avatar33", "avatar34"
    ]
    
    // Couleurs disponibles pour les avatars (optionnel si vos images ont déjà leurs propres couleurs)
    private let avatarColors: [Color] = [
        .red, .blue, .green, .orange, .purple, 
        .pink, .yellow, .cyan, .indigo, .mint
    ]
    
    // États
    @State private var isLoading = true
    @State private var availableAvatars: [String] = []
    @State private var selectedAvatar: String? = "avatar_02" // Charizard préselectionné
    @State private var selectedColor: Color = .red
    @State private var currentlyUsedAvatar: String? = nil
    @State private var currentlyUsedColor: Color = .red
    @State private var errorMessage: String? = nil
    @State private var showColorPicker = false // Désactivé car nous utilisons des images en couleur
    
    // Configuration de la grille - modifiée pour avoir exactement 3 colonnes
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Contenu principal
            VStack {
                    if isLoading {
                        // Indicateur de chargement
                        ProgressView("Chargement des avatars disponibles...")
                        .padding()
                } else {
                        // Titre avec instructions
                        VStack(spacing: 16) {
                            // Message d'explication
                            Text("Choisissez votre avatar unique")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            Text("Chaque avatar ne peut être utilisé que par une seule personne.")
                                .font(.subheadline)
                        .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Sélecteur de couleur (affiché conditionnellement)
                        if showColorPicker {
                            VStack(alignment: .leading) {
                                Text("Couleur de l'avatar")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(avatarColors, id: \.self) { color in
                                            Circle()
                                                .fill(color)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .opacity(selectedColor == color ? 1 : 0)
                                                )
                                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                .onTapGesture {
                                                    selectedColor = color
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.bottom)
                            }
                        }
                        
                        // Grille d'avatars
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 25) { // Plus d'espace vertical entre les lignes
                                ForEach(avatarNames, id: \.self) { avatarName in
                                    AvatarCell(
                                        systemName: avatarName,
                                        color: selectedColor,
                                        isSelected: selectedAvatar == avatarName,
                                        isAvailable: availableAvatars.contains(avatarName) || currentlyUsedAvatar == avatarName,
                                        isCurrent: currentlyUsedAvatar == avatarName
                                    )
                                    .onTapGesture {
                                        // Sélectionner uniquement si disponible ou déjà utilisé par cet utilisateur
                                        if availableAvatars.contains(avatarName) || currentlyUsedAvatar == avatarName {
                                            selectedAvatar = avatarName
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 15)
                        }
                        
                        // Message d'erreur éventuel
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        // Bouton d'enregistrement
                        Button(action: saveSelectedAvatar) {
                            Text("Enregistrer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedAvatar != nil ? Color("TEMA_Red") : Color.gray)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .disabled(selectedAvatar == nil)
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Choisir un avatar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAvailableAvatars()
            }
        }
    }
    
    // Charge les avatars disponibles depuis Firestore
    private func loadAvailableAvatars() {
        isLoading = true
        errorMessage = nil
        
        // Lors des tests, permettre tous les avatars
        self.availableAvatars = self.avatarNames
        self.isLoading = false
        
        // Détecter l'avatar déjà utilisé
        if let currentUser = appData.currentUser, let profilePicture = currentUser.profilePicture {
            // Extraction du nom de l'avatar à partir de l'URL
            let parts = profilePicture.components(separatedBy: ":")
            if parts.count >= 2, let avatarName = parts.first,
               avatarNames.contains(avatarName) {
                currentlyUsedAvatar = avatarName
                selectedAvatar = avatarName // Pré-sélectionner l'avatar actuel
                
                // Extraire la couleur
                if let colorStr = parts.last,
                   let color = colorFromString(colorStr) {
                    currentlyUsedColor = color
                    selectedColor = color
                }
            }
        }
        
        /* Commenté pour le moment pour les tests
        let db = Firestore.firestore()
        
        // 2. Récupérer tous les avatars déjà utilisés
        db.collection("users")
            .whereField("profilePicture", isGreaterThan: "")
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = "Erreur: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                // Extraire les noms d'avatars déjà utilisés et leur couleur
                var usedAvatarCombinations: [String] = []
                if let documents = snapshot?.documents {
                    for doc in documents {
                        if let profilePicture = doc.data()["profilePicture"] as? String {
                            // Format attendu: "avatarName:colorName"
                            usedAvatarCombinations.append(profilePicture)
                        }
                    }
                }
                
                // Déterminer les avatars disponibles
                self.availableAvatars = self.avatarNames.filter { avatarName in
                    // Vérifier si chaque combinaison avatar+couleur n'est pas déjà utilisée
                    for combination in usedAvatarCombinations {
                        let parts = combination.components(separatedBy: ":")
                        if parts.count >= 1 && parts[0] == avatarName {
                            // Si c'est déjà l'avatar de l'utilisateur actuel, c'est disponible
                            if avatarName == self.currentlyUsedAvatar {
                                return true
                            }
                            return false
                        }
                    }
                    return true // Disponible si pas trouvé dans la liste
                }
                
                self.isLoading = false
            }
        */
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
    
    // Convertit une couleur en chaîne
    private func stringFromColor(_ color: Color) -> String {
        if color == .red { return "red" }
        else if color == .blue { return "blue" }
        else if color == .green { return "green" }
        else if color == .orange { return "orange" }
        else if color == .purple { return "purple" }
        else if color == .pink { return "pink" }
        else if color == .yellow { return "yellow" }
        else if color == .cyan { return "cyan" }
        else if color == .indigo { return "indigo" }
        else if color == .mint { return "mint" }
        else { return "red" } // Défaut
    }
    
    // Enregistre l'avatar sélectionné
    private func saveSelectedAvatar() {
        guard let selectedAvatar = selectedAvatar, let currentUser = appData.currentUser else {
            errorMessage = "Veuillez sélectionner un avatar"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Format: "nomAvatar:couleur" (ex: "avatar1:red")
        // Nous conservons le format avec la couleur pour la compatibilité, même si la couleur n'est pas utilisée pour les images
        let avatarUrl = "\(selectedAvatar):\(stringFromColor(selectedColor))"
        
        // Mise à jour du profil utilisateur dans Firestore
        appData.updateProfilePicture(url: avatarUrl)
        
        // Mettre à jour l'interface utilisateur
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.dismiss()
        }
    }
}

// Cellule pour afficher un avatar dans la grille
struct AvatarCell: View {
    let systemName: String
    let color: Color
    let isSelected: Bool
    let isAvailable: Bool
    let isCurrent: Bool
    
    // Pour le débogage
    @State private var imageExists: Bool = false
    @State private var imageName: String = ""
    
    // Dimensions de la cellule - réduites pour 3 par ligne
    private let cellWidth: CGFloat = 95
    private let cellHeight: CGFloat = 80
    private let imageWidth: CGFloat = 85
    private let imageHeight: CGFloat = 75
    
    var body: some View {
        ZStack {
            // Image de l'avatar (image réelle depuis Assets)
            if systemName.contains("avatar") {
                ZStack {
                    // Essaie de charger l'image
                    if let image = UIImage(named: systemName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: imageWidth, height: imageHeight)
                            .opacity(isAvailable ? 1.0 : 0.4)
                        
                        // Tick vert supprimé
                    } else {
                        // Afficher un texte de débogage si l'image n'existe pas
                        VStack {
                            Text(systemName)
                                .font(.caption2) // Réduit la taille du texte
                                .foregroundColor(.gray)
                            
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("Not found")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        .padding(2) // Réduit le padding
                        .frame(width: imageWidth, height: imageHeight)
                    }
                }
                .onAppear {
                    // Détecter si l'image existe
                    imageExists = UIImage(named: systemName) != nil
                    imageName = systemName
                }
            } else {
                // Fallback sur SF Symbol si l'image n'existe pas
                Rectangle()
                    .fill(color.opacity(0.15))
                    .frame(width: 70, height: 70) // Réduit les dimensions
                    .cornerRadius(8)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .padding(14) // Réduit le padding
                    .foregroundColor(color)
                    .frame(width: 70, height: 70) // Réduit les dimensions
                    .opacity(isAvailable ? 1.0 : 0.4)
            }
            
            // Bordure de sélection
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("TEMA_Red"), lineWidth: 3)
                    .frame(width: cellWidth, height: cellHeight)
            }
            
            // Indicateur "Actuel"
            if isCurrent {
                Text("Actuel")
                    .font(.caption2) // Réduit la taille du texte
                    .foregroundColor(.white)
                    .padding(.horizontal, 4) // Réduit le padding
                    .padding(.vertical, 1) // Réduit le padding
                    .background(Color.blue)
                    .cornerRadius(4)
                    .position(x: 35, y: 12) // Ajusté pour la nouvelle taille
            }
            
            // Indicateur "Non disponible" - on garde ce texte pour être sûr que c'est clair
            if !isAvailable {
                Text("Pris")
                    .font(.caption2) // Réduit la taille du texte
                    .foregroundColor(.white)
                    .padding(.horizontal, 4) // Réduit le padding
                    .padding(.vertical, 1) // Réduit le padding
                    .background(Color.red)
                    .cornerRadius(4)
                    .position(x: 35, y: 12) // Ajusté pour la nouvelle taille
            }
        }
        .frame(width: cellWidth, height: cellHeight)
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        ProfileAvatarPickerView().environmentObject(AppData())
    } else {
        // Fallback on earlier versions
    }
}

