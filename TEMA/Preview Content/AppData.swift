import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Modèle utilisateur simplifié
struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String?
    var profilePicture: String?  // URL de la photo de profil
    var authMethod: String?       // "Apple" ou "Email"
}

// Modèle Post (inchangé)
struct Post: Identifiable, Codable {
    var id: String = UUID().uuidString
    var authorId: String
    var imageUrl: String
    var timestamp: Date
}

class AppData: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var posts: [Post] = []
    
    var db = Firestore.firestore() // Exposé pour y accéder depuis d'autres fichiers
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isLoggedIn = true
                    let displayName = firebaseUser.displayName ?? "Utilisateur"
                    // On crée un utilisateur (profilePicture est initialisé à nil, il sera mis à jour ensuite)
                    self?.currentUser = User(id: firebaseUser.uid, name: displayName, email: firebaseUser.email, profilePicture: nil, authMethod: "unknown")
                    print("Utilisateur connecté : \(firebaseUser.email ?? "inconnu")")
                    
                    // Récupère le document utilisateur dans Firestore pour mettre à jour profilePicture
                    self?.db.collection("users").document(firebaseUser.uid).getDocument { document, error in
                        if let error = error {
                            print("Erreur lors de la récupération du document utilisateur : \(error.localizedDescription)")
                        } else if let document = document, document.exists {
                            let data = document.data() ?? [:]
                            let profilePicture = data["profilePicture"] as? String ?? ""
                            self?.currentUser?.profilePicture = profilePicture
                            print("Photo de profil récupérée : \(profilePicture)")
                        } else {
                            print("Aucun document utilisateur trouvé pour l'UID \(firebaseUser.uid)")
                        }
                    }
                    
                    self?.fetchPosts()
                } else {
                    self?.isLoggedIn = false
                    self?.currentUser = nil
                    self?.posts = []
                    print("Aucun utilisateur connecté")
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // Connexion par email
    func signInWithEmail(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Erreur lors de la connexion : \(error.localizedDescription)")
                completion(error)
            } else {
                print("Connexion réussie")
                completion(nil)
            }
        }
    }
    
    // Inscription par email
    func signUpWithEmail(email: String, password: String, fullName: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Erreur lors de l'inscription : \(error.localizedDescription)")
                completion(error)
            } else if let firebaseUser = authResult?.user {
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Erreur lors de la mise à jour du profil : \(error.localizedDescription)")
                        completion(error)
                    } else {
                        print("Inscription réussie et profil mis à jour")
                        completion(nil)
                    }
                }
            } else {
                completion(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non créé"]))
            }
        }
    }
    
    // Déconnexion
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
            self.currentUser = nil
            self.posts = []
            print("Déconnexion réussie")
        } catch {
            print("Erreur lors de la déconnexion : \(error.localizedDescription)")
        }
    }
    
    // Upload d'une image pour un post (inchangé)
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l’image"])))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("posts/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            imageRef.downloadURL { result in
                switch result {
                case .success(let url):
                    completion(.success(url.absoluteString))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Ajoute un post dans Firestore
    func addPostToFirestore(_ post: Post) {
        do {
            _ = try db.collection("posts").addDocument(from: post) { error in
                if let error = error {
                    print("❌ Erreur lors de l'ajout du post dans Firestore : \(error.localizedDescription)")
                } else {
                    print("✅ Post sauvegardé dans Firestore")
                }
            }
        } catch {
            print("❌ Erreur de codage du post : \(error.localizedDescription)")
        }
    }
    
    // Charge les posts depuis Firestore
    func fetchPosts() {
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Erreur lors du chargement des posts : \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self?.posts = documents.compactMap { try? $0.data(as: Post.self) }
                print("Nombre de posts chargés : \(self?.posts.count ?? 0)")
            }
    }
    
    // Upload d'une image pour la photo de profil et mise à jour dans Firestore
    func uploadProfileImage(_ image: UIImage, forUser user: User, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_pictures/\(user.id).png")
        guard let data = image.pngData() else {
            completion(.failure(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur de conversion de l'image"])))
            return
        }
        
        storageRef.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { result in
                switch result {
                case .success(let url):
                    self.updateProfilePicture(url: url.absoluteString)
                    completion(.success(url))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Met à jour le champ "profilePicture" du document utilisateur dans Firestore
    func updateProfilePicture(url: String) {
        guard let userId = currentUser?.id else { return }
        db.collection("users").document(userId).updateData(["profilePicture": url]) { error in
            if let error = error {
                print("❌ Erreur lors de la mise à jour de la photo de profil : \(error.localizedDescription)")
            } else {
                print("✅ Photo de profil mise à jour")
                DispatchQueue.main.async {
                    self.currentUser?.profilePicture = url
                }
            }
        }
    }
    
    // Sauvegarde ou mise à jour du document utilisateur dans Firestore
    func saveUserToFirestore(_ user: User, completion: ((Error?) -> Void)? = nil) {
        let userDocRef = db.collection("users").document(user.id)
        userDocRef.getDocument { document, error in
            var existingProfilePicture = ""
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                existingProfilePicture = data["profilePicture"] as? String ?? ""
            }
            let newUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                profilePicture: existingProfilePicture, // On conserve la pp existante
                authMethod: user.authMethod
            )
            userDocRef.setData([
                "name": newUser.name,
                "email": newUser.email ?? "",
                "profilePicture": newUser.profilePicture ?? "",
                "authMethod": newUser.authMethod ?? ""
            ], merge: true) { error in
                if let error = error {
                    print("❌ Erreur lors de la sauvegarde de l'utilisateur dans Firestore : \(error.localizedDescription)")
                } else {
                    print("✅ Utilisateur enregistré dans Firestore")
                }
                completion?(error)
            }
            DispatchQueue.main.async {
                self.currentUser = newUser
            }
        }
    }
}
