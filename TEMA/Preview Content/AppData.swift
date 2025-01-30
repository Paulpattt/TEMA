import SwiftUI

// ✅ Modèle pour une publication (Post)
struct Post: Identifiable, Codable {
    var id: String
    var authorId: String
    var imageName: String
    var date: Date
}

// ✅ Modèle pour un utilisateur
struct User: Codable {
    var id: String
    var name: String
    var email: String?
    var phoneNumber: String?
    var profilePicture: String?
}

class AppData: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var posts: [Post] = [] // ✅ Ajout des posts de l'utilisateur

    init() {
        loadUser()
        loadPosts() // ✅ Charger les posts au démarrage
    }

    // ✅ Enregistre l'utilisateur dans UserDefaults
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        self.currentUser = user
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
    }

    // ✅ Charge l'utilisateur enregistré
    func loadUser() {
        if let savedUserData = UserDefaults.standard.data(forKey: "currentUser"),
           let savedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
            self.currentUser = savedUser
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false
        }
    }

    // ✅ Met à jour l'utilisateur actuel avec un nouveau nom
    func updateUser(from username: String) {
        if var user = self.currentUser {
            user.name = username
            saveUser(user) // ✅ Sauvegarde les données mises à jour
        } else {
            let newUser = User(id: UUID().uuidString, name: username, email: nil, phoneNumber: nil, profilePicture: nil)
            saveUser(newUser)
        }
    }

    // ✅ Déconnexion
    func logout() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        self.currentUser = nil
        self.isLoggedIn = false
    }

    // ✅ Charger des publications fictives (temporaire)
    func loadPosts() {
        self.posts = [
            Post(id: UUID().uuidString, authorId: "12345", imageName: "photo1", date: Date()),
            Post(id: UUID().uuidString, authorId: "67890", imageName: "photo2", date: Date()),
            Post(id: UUID().uuidString, authorId: "12345", imageName: "photo3", date: Date())
        ]
    }
}
