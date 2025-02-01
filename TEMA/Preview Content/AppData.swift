import SwiftUI
import FirebaseAuth

// Modèle utilisateur simplifié
struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String?
    // Vous pourrez ajouter d'autres propriétés, par exemple une URL de photo de profil.
}

class AppData: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    // Listener pour suivre l'état de l'authentification Firebase.
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // On écoute les changements d'état de Firebase Auth.
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    // Utilisateur connecté
                    self?.isLoggedIn = true
                    let displayName = firebaseUser.displayName ?? "Utilisateur"
                    self?.currentUser = User(id: firebaseUser.uid, name: displayName, email: firebaseUser.email)
                    print("Utilisateur connecté: \(firebaseUser.email ?? "inconnu")")
                } else {
                    // Aucun utilisateur connecté
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
    
    // Connexion via e-mail et mot de passe.
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
    
    // Inscription via e-mail et mot de passe.
    func signUpWithEmail(email: String, password: String, fullName: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Erreur lors de l'inscription : \(error.localizedDescription)")
                completion(error)
            } else if let firebaseUser = authResult?.user {
                // Mise à jour du displayName dans Firebase.
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
                // Cas imprévu : aucune erreur et aucun utilisateur retourné.
                completion(NSError(domain: "AppData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non créé"]))
            }
        }
    }
    
    // Méthode pour se déconnecter.
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("Déconnexion réussie")
        } catch {
            print("Erreur lors de la déconnexion : \(error.localizedDescription)")
        }
    }
    
    // Vous pourrez ajouter ici d'autres méthodes (par exemple, pour la connexion via Apple)
}
