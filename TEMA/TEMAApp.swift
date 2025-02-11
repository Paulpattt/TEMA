import SwiftUI
import Firebase

@main
struct TEMAApp: App {
    @StateObject private var appData = AppData()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}
