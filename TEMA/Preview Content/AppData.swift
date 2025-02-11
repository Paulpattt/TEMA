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
    var authMethod: String?       // Par exemple, "Apple" ou "Email"
}

// Modèle Post : on stocke l'URL de l'image (et non l'image elle-même)
struct Post: Identifiable, Codable {
    var id: String = UUID().uuidString
    var authorId: String
    var imageUrl: String // Utilise toujours "imageUrl" avec "u" minuscule
    var timestamp: Date
}

class AppData: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var posts: [Post] = []
    
    private var db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isLoggedIn = true
                    let displayName = firebaseUser.displayName ?? "Utilisateur"
                    self?.currentUser = User(id: firebaseUser.uid, name: displayName, email: firebaseUser.email, profilePicture: nil, authMethod: "unknown")
                    print("Utilisateur connecté : \(firebaseUser.email ?? "inconnu")")
                    self?.fetchPosts() // Recharge les posts dès la connexion
                } else {
                    self?.isLoggedIn = false
                    self?.currentUser = nil
                    self?.posts = [] // On vide les posts à la déconnexion
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
    
    // Upload d'une image pour un post dans Firebase Storage
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
}
