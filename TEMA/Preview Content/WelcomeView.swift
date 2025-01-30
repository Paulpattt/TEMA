import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var appData: AppData
    @State private var isSigningUp = false
    @State private var isLoggingIn = false
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // ✅ HEADER AVEC "TEMA" MAIS SANS BARRE DE RECHERCHE
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

            // ✅ OPTION 1 : Connexion avec Apple
            if !isSigningUp && !isLoggingIn {
                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        handleSignIn(authResults)
                    case .failure(let error):
                        errorMessage = "Erreur : \(error.localizedDescription)"
                    }
                })
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)
                .padding(.horizontal)
            }

            // ✅ OPTION 2 : Connexion par téléphone (Affiché si Login activé)
            if isLoggingIn {
                VStack(spacing: 15) {
                    TextField("Numéro de téléphone", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    SecureField("Mot de passe", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button(action: login) {
                        Text("Se connecter")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }

            // ✅ OPTION 3 : Création de compte (Affiché si Signup activé)
            if isSigningUp {
                VStack(spacing: 15) {
                    TextField("Numéro de téléphone", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    SecureField("Mot de passe", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    SecureField("Confirmer le mot de passe", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Button(action: register) {
                        Text("Créer un compte")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }

            // ✅ Affichage des erreurs
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()

            // ✅ BOUTONS DE NAVIGATION ENTRE LES MODES
            if !isSigningUp && !isLoggingIn {
                Button(action: { isLoggingIn = true }) {
                    Text("Se connecter avec un numéro de téléphone")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)

                Button(action: { isSigningUp = true }) {
                    Text("Créer un compte")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
            } else {
                Button(action: { isSigningUp = false; isLoggingIn = false }) {
                    Text("Retour")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
        .padding()
    }

    // ✅ FONCTION CONNEXION
    func login() {
        let savedPhone = UserDefaults.standard.string(forKey: "userPhoneNumber")
        let savedPassword = UserDefaults.standard.string(forKey: "userPassword")

        guard phoneNumber == savedPhone, password == savedPassword else {
            errorMessage = "Numéro ou mot de passe incorrect"
            return
        }

        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        errorMessage = nil
        print("✅ Connexion réussie : \(phoneNumber)")
        appData.isLoggedIn = true
    }

    // ✅ FONCTION INSCRIPTION
    func register() {
        guard !phoneNumber.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas"
            return
        }

        UserDefaults.standard.set(phoneNumber, forKey: "userPhoneNumber")
        UserDefaults.standard.set(password, forKey: "userPassword")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")

        errorMessage = nil
        print("✅ Utilisateur enregistré avec succès : \(phoneNumber)")
        appData.isLoggedIn = true
    }

    // ✅ FONCTION APPLE SIGN-IN
    func handleSignIn(_ authResults: ASAuthorization) {
        guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else { return }

        let userIdentifier = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let username = "\(fullName?.givenName ?? "Utilisateur") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)

        UserDefaults.standard.set(userIdentifier, forKey: "AppleUserID")

        DispatchQueue.main.async {
            appData.updateUser(from: username)
            appData.isLoggedIn = true
        }
    }
}

#Preview {
    WelcomeView().environmentObject(AppData())
}
