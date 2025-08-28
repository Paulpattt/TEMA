import SwiftUI
import AuthenticationServices
import FirebaseAuth

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
    
    // (SignInWithAppleButton struct removed)
}


#Preview {
    WelcomeView().environmentObject(AppData())
}
