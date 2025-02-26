import SwiftUI
import FirebaseAuth
import Firebase

@main
struct TEMAApp: App {
    @StateObject private var appData = AppData()

    init() {
        FirebaseApp.configure()
        // Vérifier la connexion dès l'initialisation
        if Auth.auth().currentUser != nil {
            appData.isLoggedIn = true
        } else {
            appData.isLoggedIn = false
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

