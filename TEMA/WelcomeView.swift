import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

struct WelcomeView: View {
    @EnvironmentObject var appData: AppData
    @State private var isSigningUp = false
    @State private var isLoggingIn = false

    // Pour l'authentification par email
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var fullName: String = ""
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // En-tête de l'app
            HStack {
                Text("TEMA")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal)
            .frame(height: 50)
            
            Spacer()
            
            // Affichage des boutons si aucune action n'est en cours
            if !isSigningUp && !isLoggingIn {
                Button(action: {
                    isLoggingIn = true
                    clearFields()
                }) {
                    Text("Se connecter")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    isSigningUp = true
                    clearFields()
                }) {
                    Text("Créer un compte")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Bouton "Sign in with Apple"
                SignInWithAppleButton()
                    .frame(height: 50)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            // Formulaire de connexion (par email)
            if isLoggingIn {
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Mot de passe", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: login) {
                        Text("Se connecter")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button("Annuler") {
                        isLoggingIn = false
                        clearFields()
                    }
                    .foregroundColor(.gray)
                }
                .padding()
            }
            
            // Formulaire d'inscription (par email)
            if isSigningUp {
                VStack(spacing: 15) {
                    TextField("Nom complet", text: $fullName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Mot de passe", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Confirmer le mot de passe", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: register) {
                        Text("Créer un compte")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button("Annuler") {
                        isSigningUp = false
                        clearFields()
                    }
                    .foregroundColor(.gray)
                }
                .padding()
            }
            
            // Message d'erreur éventuel
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Efface les champs
    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        errorMessage = nil
    }
    
    // Connexion via Firebase (email)
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        appData.signInWithEmail(email: email, password: password) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = nil
            }
        }
    }
    
    // Inscription via Firebase (email)
    func register() {
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas"
            return
        }
        
        appData.signUpWithEmail(email: email, password: password, fullName: fullName) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = nil
            }
        }
    }
    
    // MARK: - Bouton "Sign in with Apple" intégré dans WelcomeView
    struct SignInWithAppleButton: UIViewRepresentable {
        func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
            let button = ASAuthorizationAppleIDButton()
            button.cornerRadius = 10
            button.addTarget(context.coordinator,
                             action: #selector(Coordinator.didTapButton),
                             for: .touchUpInside)
            return button
        }
        
        func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
            // Pas de mise à jour nécessaire
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
        class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
            var currentNonce: String?
            
            @objc func didTapButton() {
                // Génère un nonce et prépare la demande d'authentification
                currentNonce = randomNonceString()
                guard let nonce = currentNonce else { return }
                
                let appleIDProvider = ASAuthorizationAppleIDProvider()
                let request = appleIDProvider.createRequest()
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
                
                let authController = ASAuthorizationController(authorizationRequests: [request])
                authController.delegate = self
                authController.presentationContextProvider = self
                authController.performRequests()
            }
            
            // Précise sur quelle fenêtre afficher le contrôle d'autorisation
            func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
                return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
            }
            
            // Quand l'authentification réussit
            func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    guard let nonce = currentNonce else {
                        fatalError("Le nonce est introuvable.")
                    }
                    guard let appleIDToken = appleIDCredential.identityToken,
                          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        print("Impossible de récupérer ou convertir le token d'identité.")
                        return
                    }
                    
                    // Création de la credential Firebase
                    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                              idToken: idTokenString,
                                                              rawNonce: nonce)
                    
                    // Authentifie avec Firebase
                    Auth.auth().signIn(with: credential) { authResult, error in
                        if let error = error {
                            print("Erreur d'authentification avec Firebase : \(error.localizedDescription)")
                            return
                        }
                        print("Connexion par Apple réussie !")
                        
                        // Récupère le nom complet (uniquement envoyé lors de la première connexion)
                        if let fullNameComponents = appleIDCredential.fullName {
                            let formatter = PersonNameComponentsFormatter()
                            let fullNameString = formatter.string(from: fullNameComponents)
                            
                            if let currentUser = Auth.auth().currentUser {
                                let changeRequest = currentUser.createProfileChangeRequest()
                                changeRequest.displayName = fullNameString
                                changeRequest.commitChanges { error in
                                    if let error = error {
                                        print("Erreur lors de la mise à jour du profil : \(error.localizedDescription)")
                                    } else {
                                        print("Profil mis à jour avec le nom : \(fullNameString)")
                                    }
                                }
                            }
                        } else {
                            print("Aucun nom complet reçu (connexion ultérieure)")
                        }
                    }
                }
            }
            
            func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
                print("Sign in with Apple a échoué : \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Fonctions utilitaires pour Sign in with Apple

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
            fatalError("Impossible de générer un nonce : \(errorCode)")
        }
        if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
        }
    }
    return result
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap { String(format: "%02x", $0) }.joined()
}

#Preview {
    WelcomeView().environmentObject(AppData())
}
