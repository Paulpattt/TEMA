import SwiftUI
import AuthenticationServices

@main
struct TEMAApp: App {
    @StateObject private var appData = AppData()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
                    .environmentObject(appData) // Injection de AppData
            } else {
                WelcomeView()
                    .environmentObject(appData) // Injection pour WelcomeView aussi
            }
        }
    }
}

// Gestionnaire d'authentification avec Apple
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    static let shared = AppleSignInCoordinator()

    func handleAppleSignIn(appData: AppData) {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()

        // Stocker appData pour mise à jour après authentification
        self.appData = appData
    }

    private var appData: AppData?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let username = "\(fullName?.givenName ?? "Utilisateur") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)

            // Sauvegarde dans UserDefaults
            UserDefaults.standard.set(userIdentifier, forKey: "AppleUserID")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")

            // Mise à jour des données utilisateur via AppData
            DispatchQueue.main.async {
                self.appData?.updateUser(from: username)
                self.appData?.isLoggedIn = true
            }

            print("✅ Connexion Apple réussie: \(userIdentifier)")
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Erreur lors de l'authentification Apple: \(error.localizedDescription)")
    }
}
