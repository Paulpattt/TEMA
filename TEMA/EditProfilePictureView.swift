//
//  ProfileAvatarPickerView.swift
//  TEMA
//
//  Created by Paul Paturel on 14/02/2025.
//
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@available(iOS 16.0, *)
struct ProfileAvatarPickerView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    // Liste des avatars - maintenant dynamique
    @State private var avatarNames: [String] = []
    @State private var avatarUrls: [String: URL] = [:]
    
    // Couleurs disponibles pour les avatars
    private let avatarColors: [Color] = [
        .red, .blue, .green, .orange, .purple, 
        .pink, .yellow, .cyan, .indigo, .mint
    ]
    
    // États
    @State private var isLoading = true
    @State private var availableAvatars: [String] = []
    @State private var selectedAvatar: String? = nil
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
                                        isCurrent: currentlyUsedAvatar == avatarName,
                                        avatarUrls: $avatarUrls
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
    
    // Charge les avatars disponibles depuis Firebase Storage
    private func loadAvailableAvatars() {
        isLoading = true
        errorMessage = nil
        
        // Référence à Firebase Storage
        let storage = Storage.storage()
        let avatarsRef = storage.reference().child("Avatars")
        
        // Fonction pour obtenir la liste des avatars
        avatarsRef.listAll { result, error in
            if let error = error {
                print("Erreur lors de la lecture des avatars depuis Firebase: \(error)")
                // Fallback sur les avatars locaux si Firebase échoue
                self.loadLocalAvatars()
                return
            }
            
            guard let items = result?.items, !items.isEmpty else {
                print("Aucun avatar trouvé dans Firebase Storage")
                // Fallback sur les avatars locaux si aucun avatar trouvé
                self.loadLocalAvatars()
                return
            }
            
            print("Avatars trouvés dans Firebase Storage: \(items.count)")
            
            // Réinitialiser les listes
            self.avatarNames = []
            self.avatarUrls = [:]
            var loadedCount = 0
            
            // Pour chaque avatar, obtenir l'URL
            for item in items {
                let avatarName = item.name.replacingOccurrences(of: ".png", with: "")
                self.avatarNames.append(avatarName)
                
                // Obtenir l'URL téléchargeable
                item.downloadURL { url, error in
                    loadedCount += 1
                    
                    if let error = error {
                        print("Erreur lors de l'obtention de l'URL pour \(avatarName): \(error)")
                    } else if let url = url {
                        self.avatarUrls[avatarName] = url
                        print("URL obtenue pour \(avatarName): \(url)")
                    }
                    
                    // Si tous les avatars sont traités
                    if loadedCount == items.count {
                        DispatchQueue.main.async {
                            // Pour les tests, permettre tous les avatars
                            self.availableAvatars = self.avatarNames
                            
                            // Détecter l'avatar déjà utilisé
                            if let currentUser = self.appData.currentUser, let profilePicture = currentUser.profilePicture {
                                let parts = profilePicture.components(separatedBy: ":")
                                if parts.count >= 2, let avatarName = parts.first {
                                    self.currentlyUsedAvatar = avatarName
                                    self.selectedAvatar = avatarName
                                    
                                    // Extraire la couleur
                                    if let colorStr = parts.last,
                                       let color = self.colorFromString(colorStr) {
                                        self.currentlyUsedColor = color
                                        self.selectedColor = color
                                    }
                                }
                            }
                            
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    // Fonction de fallback pour charger les avatars locaux
    private func loadLocalAvatars() {
        if let bundlePath = Bundle.main.resourcePath {
            let avatarPath = (bundlePath as NSString).appendingPathComponent("AvatarsPokemons")
            
            do {
                // Vérifier si le dossier existe
                var isDirectory: ObjCBool = false
                let exists = FileManager.default.fileExists(atPath: avatarPath, isDirectory: &isDirectory)
                
                if exists && isDirectory.boolValue {
                    print("Dossier AvatarsPokemons trouvé à: \(avatarPath)")
                    
                    // Lire tous les fichiers PNG du dossier
                    let files = try FileManager.default.contentsOfDirectory(atPath: avatarPath)
                    let pngFiles = files.filter { $0.hasSuffix(".png") }
                    
                    // Extraire les noms sans extension
                    self.avatarNames = pngFiles.map { ($0 as NSString).deletingPathExtension }
                    
                    print("Avatars locaux trouvés: \(avatarNames.count)")
                    
                    // Pour les tests, permettre tous les avatars
                    self.availableAvatars = self.avatarNames
                    
                    // Détecter l'avatar déjà utilisé
                    if let currentUser = appData.currentUser, let profilePicture = currentUser.profilePicture {
                        let parts = profilePicture.components(separatedBy: ":")
                        if parts.count >= 2, let avatarName = parts.first {
                            currentlyUsedAvatar = avatarName
                            selectedAvatar = avatarName
                            
                            // Extraire la couleur
                            if let colorStr = parts.last,
                               let color = colorFromString(colorStr) {
                                currentlyUsedColor = color
                                selectedColor = color
                            }
                        }
                    }
                } else {
                    print("Dossier AvatarsPokemons non trouvé à: \(avatarPath)")
                    errorMessage = "Aucun avatar disponible"
                }
            } catch {
                print("Erreur lors du chargement des avatars locaux: \(error.localizedDescription)")
                errorMessage = "Erreur lors du chargement des avatars"
            }
        } else {
            print("Impossible d'accéder aux ressources du bundle")
            errorMessage = "Erreur d'accès au bundle"
        }
        
        self.isLoading = false
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
    
    // Pour stocker l'URL de l'avatar
    @Binding var avatarUrls: [String: URL]
    
    // État pour gérer l'image chargée
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    @State private var imageError = false
    
    // Dimensions de la cellule - réduites pour 3 par ligne
    private let cellWidth: CGFloat = 95
    private let cellHeight: CGFloat = 80
    private let imageWidth: CGFloat = 85
    private let imageHeight: CGFloat = 75
    
    // Fonction pour charger l'image depuis Firebase Storage
    private func loadImage() {
        isLoading = true
        imageError = false
        
        // Essayer d'abord depuis Firebase Storage
        if let url = avatarUrls[systemName] {
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data, let loadedImage = UIImage(data: data) {
                        self.image = loadedImage
                        self.isLoading = false
                    } else {
                        // Si le téléchargement échoue, essayer en local
                        self.loadLocalImage()
                    }
                }
            }.resume()
        } else {
            // Si pas d'URL, essayer en local
            loadLocalImage()
        }
    }
    
    // Fonction de fallback pour charger l'image locale
    private func loadLocalImage() {
        if let bundlePath = Bundle.main.resourcePath {
            let avatarPath = (bundlePath as NSString).appendingPathComponent("AvatarsPokemons")
            let imagePath = (avatarPath as NSString).appendingPathComponent("\(systemName).png")
            
            if let localImage = UIImage(contentsOfFile: imagePath) {
                self.image = localImage
            } else {
                self.imageError = true
            }
        } else {
            self.imageError = true
        }
        
        self.isLoading = false
    }
    
    var body: some View {
        ZStack {
            // Image de l'avatar (chargée dynamiquement)
            ZStack {
                if isLoading {
                    ProgressView()
                        .frame(width: imageWidth, height: imageHeight)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageWidth, height: imageHeight)
                        .opacity(isAvailable ? 1.0 : 0.4)
                } else {
                    // Afficher un texte de débogage si l'image n'existe pas
                    VStack {
                        Text(systemName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Not found")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    .padding(2)
                    .frame(width: imageWidth, height: imageHeight)
                }
            }
            .onAppear {
                // Charger l'image au chargement de la cellule
                loadImage()
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
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.blue)
                    .cornerRadius(4)
                    .position(x: 35, y: 12)
            }
            
            // Indicateur "Non disponible"
            if !isAvailable {
                Text("Pris")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.red)
                    .cornerRadius(4)
                    .position(x: 35, y: 12)
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

