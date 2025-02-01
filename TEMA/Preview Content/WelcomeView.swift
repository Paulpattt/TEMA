import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appData: AppData
    @State private var isSigningUp = false
    @State private var isLoggingIn = false
    
    // Pour l'authentification par e-mail
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
            
            // Si aucune action n'est en cours, proposer les boutons "Se connecter" et "Créer un compte"
            if !isSigningUp && !isLoggingIn {
                Button(action: {
                    isLoggingIn = true
                    clearFields()
                }) {
                    Text("Se connecter")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
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
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            // Formulaire de connexion
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
                            .background(Color.blue)
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
            
            // Formulaire d'inscription
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
                            .background(Color.green)
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
            
            // Affichage d'un message d'erreur s'il y a lieu
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Efface les champs de saisie
    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        errorMessage = nil
    }
    
    // Connexion via Firebase
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
                // La connexion est gérée par le listener Firebase dans AppData,
                // et ContentView bascule automatiquement vers MainAppView.
            }
        }
    }
    
    // Inscription via Firebase
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
                // Une fois inscrit, le listener Firebase mettra automatiquement à jour l'état de connexion,
                // et ContentView affichera MainAppView.
            }
        }
    }
}

#Preview {
    WelcomeView().environmentObject(AppData())
}
