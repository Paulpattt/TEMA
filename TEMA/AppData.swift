import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Modèles

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String?
    var profilePicture: String?  // URL de la photo de profil
    var authMethod: String?      // "Apple" ou "Email"
}

struct Post: Identifiable, Codable {
    var id: String = UUID().uuidString
    var authorId: String
    var imageUrl: String
    var timestamp: Date
}

// MARK: - AppData

class AppData: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var userCache: [String: User] = [:]
    @Published var posts: [Post] = []
    
    func getUser(for id: String, completion: @escaping (User?) -> Void) {
            if let cachedUser = userCache[id] {
                completion(cachedUser)
            } else {
                let db = Firestore.firestore()
                db.collection("users").document(id).getDocument { document, error in
                    if let document = document, document.exists, let data = document.data() {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            let fetchedUser = try JSONDecoder().decode(User.self, from: jsonData)
                            DispatchQueue.main.async {
                                self.userCache[id] = fetchedUser
                            }
                            completion(fetchedUser)
                        } catch {
                            print("Erreur de décodage: \(error.localizedDescription)")
                            completion(nil)
                        }
                    } else {
                        print("Erreur lors du chargement de l'utilisateur: \(error?.localizedDescription ?? "Document inexistant")")
                        completion(nil)
                    }
                }
            }
        }
    var db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isLoggedIn = true
                    let displayName = firebaseUser.displayName ?? "Utilisateur"
                    // Création initiale de l'utilisateur
                    self?.currentUser = User(id: firebaseUser.uid,
                                             name: displayName,
                                             email: firebaseUser.email,
                                             profilePicture: nil,
                                             authMethod: "unknown")
                    print("Utilisateur connecté : \(firebaseUser.email ?? "inconnu")")
                    
                    // Récupération du document utilisateur dans Firestore
                    self?.db.collection("users").document(firebaseUser.uid).getDocument { document, error in
                        if let error = error {
                            print("Erreur lors de la récupération du document utilisateur : \(error.localizedDescription)")
                        } else if let document = document, document.exists {
                            let data = document.data() ?? [:]
                            let profilePicture = data["profilePicture"] as? String ?? ""
                            let name = data["name"] as? String ?? displayName
                            self?.currentUser?.profilePicture = profilePicture
                            self?.currentUser?.name = name
                            print("Données utilisateur récupérées. Photo de profil : \(profilePicture)")
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
    
    // MARK: - Authentification
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                print("Erreur lors de la connexion : \(error.localizedDescription)")
                completion(error)
            } else {
                print("Connexion réussie")
                completion(nil)
            }
        }
    }
    
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
                        // Sauvegarder l'utilisateur dans Firestore après inscription
                        let newUser = User(id: firebaseUser.uid,
                                           name: fullName,
                                           email: firebaseUser.email,
                                           profilePicture: "",
                                           authMethod: "Email")
                        self.saveUserToFirestore(newUser)
                        completion(nil)
                    }
                }
            } else {
                completion(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non créé"]))
            }
        }
    }
    
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
    
    // MARK: - Supprimer un post
    func deletePost(_ post: Post) {
        guard !post.id.isEmpty else {
            print("Impossible de supprimer, post.id est vide.")
            return
        }
        
        db.collection("posts").document(post.id).delete { [weak self] error in
            if let error = error {
                print("Erreur lors de la suppression du post Firestore : \(error.localizedDescription)")
            } else {
                print("Post supprimé de Firestore : \(post.id)")
                
                // Retirer du tableau local
                DispatchQueue.main.async {
                    self?.posts.removeAll { $0.id == post.id }
                }
                
                // Supprimer l'image dans Storage
                if !post.imageUrl.isEmpty {
                    let storageRef = Storage.storage().reference(forURL: post.imageUrl)
                    storageRef.delete { storageError in
                        if let storageError = storageError {
                            print("Erreur lors de la suppression de l'image : \(storageError.localizedDescription)")
                        } else {
                            print("Image supprimée du Storage.")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Mise à jour du profil
    func updateUserName(firstName: String, lastName: String, completion: @escaping (Error?) -> Void) {
        guard let userId = currentUser?.id else { return }
        let fullName = "\(firstName) \(lastName)"
        db.collection("users").document(userId).updateData([
            "name": fullName,
            "searchName": fullName.lowercased()
        ]) { error in
            if let error = error {
                print("Erreur lors de la mise à jour du nom : \(error.localizedDescription)")
            } else {
                print("Nom mis à jour avec succès")
                DispatchQueue.main.async {
                    self.currentUser?.name = fullName
                }
            }
            completion(error)
        }
    }
    
    // MARK: - Upload d'image
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l’image"])))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("posts/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { _, error in
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
    
    // MARK: - Créer / Mettre à jour un post dans Firestore
    func addPostToFirestore(_ post: Post) {
        do {
            // IMPORTANT : On force Firestore à utiliser post.id comme ID du document
            try db.collection("posts").document(post.id).setData(from: post) { error in
                if let error = error {
                    print("Erreur lors de l'ajout du post dans Firestore : \(error.localizedDescription)")
                } else {
                    print("Post sauvegardé dans Firestore avec l'ID : \(post.id)")
                }
            }
        } catch {
            print("Erreur de codage du post : \(error.localizedDescription)")
        }
    }
    
    // MARK: - Récupérer les posts
    func fetchPosts() {
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Erreur lors du chargement des posts : \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self?.posts = documents.compactMap { try? $0.data(as: Post.self) }
                print("Nombre de posts chargés : \(self?.posts.count ?? 0)")
            }
    }
    
    // MARK: - Photo de profil
    func uploadProfileImage(_ image: UIImage, forUser user: User, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_pictures/\(user.id).png")
        guard let data = image.pngData() else {
            completion(.failure(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur de conversion de l'image"])))
            return
        }
        
        storageRef.putData(data, metadata: nil) { _, error in
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
    
    func updateProfilePicture(url: String) {
        guard let userId = currentUser?.id else { return }
        db.collection("users").document(userId).updateData(["profilePicture": url]) { error in
            if let error = error {
                print("Erreur lors de la mise à jour de la photo de profil : \(error.localizedDescription)")
            } else {
                print("Photo de profil mise à jour")
                DispatchQueue.main.async {
                    self.currentUser?.profilePicture = url
                }
            }
        }
    }
    
    func saveUserToFirestore(_ user: User, completion: ((Error?) -> Void)? = nil) {
        let userDocRef = db.collection("users").document(user.id)
        let searchName = user.name.lowercased()
        userDocRef.setData([
            "name": user.name,
            "email": user.email ?? "",
            "profilePicture": user.profilePicture ?? "",
            "authMethod": user.authMethod ?? "",
            "searchName": searchName
        ], merge: true) { error in
            if let error = error {
                print("Erreur lors de la sauvegarde de l'utilisateur dans Firestore : \(error.localizedDescription)")
            } else {
                print("Utilisateur enregistré dans Firestore")
            }
            completion?(error)
        }
        DispatchQueue.main.async {
            self.currentUser = user
        }
    }
}
