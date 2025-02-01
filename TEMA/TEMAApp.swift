import SwiftUI
import Firebase

@main
struct TEMAApp: App {
    @StateObject private var appData = AppData()
    
    init() {
        // Configuration de Firebase dès le démarrage de l'application.
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}
