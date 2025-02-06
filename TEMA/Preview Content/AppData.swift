import SwiftUI
import FirebaseAuth

// Modèle utilisateur simplifié
struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String?
    // Tu pourras ajouter d'autres propriétés (photo de profil, etc.)
}

// Modèle Post : ici, on stocke l'image en mémoire pour simplifier
struct Post: Identifiable {
    var id = UUID().uuidString
    var authorId: String
    var image: UIImage
    var timestamp: Date = Date()
}

class AppData: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    // Liste des posts publiés
    @Published var posts: [Post] = []
    
    // Listener Firebase pour suivre l'état de connexion
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    self?.isLoggedIn = true
                    let displayName = firebaseUser.displayName ?? "Utilisateur"
                    self?.currentUser = User(id: firebaseUser.uid, name: displayName, email: firebaseUser.email)
                    print("Utilisateur connecté : \(firebaseUser.email ?? "inconnu")")
                } else {
                    self?.isLoggedIn = false
                    self?.currentUser = nil
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
    
    // Connexion via e-mail
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
    
    // Inscription via e-mail
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
            print("Déconnexion réussie")
        } catch {
            print("Erreur lors de la déconnexion : \(error.localizedDescription)")
        }
    }
    
    // Ajoute un nouveau post
    func addPost(_ post: Post) {
        posts.append(post)
    }
}
