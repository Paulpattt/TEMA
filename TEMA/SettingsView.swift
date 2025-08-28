import SwiftUI
import PassKit

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    // États pour gérer le changement de nom
    @State private var isChangingName = false
    @State private var newName = ""
    @State private var showNameChangeAlert = false
    @State private var nameChangeMessage = ""
    // État pour l'erreur du Pass Apple Wallet
    @State private var showPassKitError = false
    @State private var passKitErrorMessage = ""
    // État pour afficher/masquer la sheet du pass wallet
    @State private var showPassSheet = false
    @State private var walletPass: PKPass? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Section du profil
            VStack(alignment: .leading, spacing: 8) {
                Text("Profil")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Bouton pour changer le nom d'utilisateur
                Button(action: {
                    newName = appData.currentUser?.name ?? ""
                    isChangingName = true
                }) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.blue)
                        
                        Text("Changer le nom d'utilisateur")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Bouton pour accéder au tutoriel Instagram
                NavigationLink(destination: InstagramDataTutorialView()) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.purple)

                        Text("Comment télécharger mes données Instagram")
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Nouveau bouton pour Apple Wallet - Prépare le pass et ouvre la sheet
                Button(action: {
                    prepareAndShowPass()
                }) {
                    HStack {
                        Image(systemName: "wallet.pass")
                            .foregroundColor(.orange)
                        
                        Text("Ajouter ma carte TEMA")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            Spacer()

            Button(action: {
                appData.signOut()
            }) {
                Text("Se déconnecter")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .padding(.top, 20)
        // Titre et configuration par défaut de la barre
        .navigationTitle("Paramètres")
        .navigationBarTitleDisplayMode(.inline)
        // Affiche une alerte pour confirmer le changement de nom
        .alert("Résultat", isPresented: $showNameChangeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(nameChangeMessage)
        }
        // Affiche une alerte pour les erreurs PassKit
        .alert("Erreur Apple Wallet", isPresented: $showPassKitError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(passKitErrorMessage)
        }
        // Affiche une sheet pour changer le nom
        .sheet(isPresented: $isChangingName) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Changer votre nom d'utilisateur")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    TextField("Nouveau nom", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                        .autocapitalization(.words)
                    
                    Spacer()
                }
                .navigationBarTitle("Changer de nom", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Annuler") {
                        isChangingName = false
                    },
                    trailing: Button("Enregistrer") {
                        updateUserName()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                )
            }
        }
        // Affiche la sheet pour le pass avec possibilité de swipe down pour fermer
        .sheet(isPresented: $showPassSheet) {
            // Sheet fermée
        } content: {
            if let pass = walletPass {
                PassKitSheetView(pass: pass, isPresented: $showPassSheet)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    // Fonction pour préparer et afficher le pass
    private func prepareAndShowPass() {
        if let passURL = Bundle.main.url(forResource: "Paul", withExtension: "pkpass") {
            print("✅ Fichier .pkpass trouvé: \(passURL)")
            
            do {
                let passData = try Data(contentsOf: passURL)
                print("✅ Données du pass chargées: \(passData.count) octets")
                
                // Créer le pass et le stocker
                let pass = try PKPass(data: passData)
                print("✅ Pass créé avec succès")
                
                // Afficher dans notre sheet personnalisée
                walletPass = pass
                showPassSheet = true
                
            } catch {
                print("❌ Erreur: \(error)")
                passKitErrorMessage = "Erreur lors du chargement du pass: \(error.localizedDescription)"
                showPassKitError = true
            }
        } else {
            print("❌ Fichier Paul.pkpass non trouvé dans le bundle")
            
            // Afficher les fichiers disponibles dans le bundle pour déboguer
            if let resourcePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: resourcePath)
                    print("📁 Fichiers dans le bundle:")
                    for item in contents {
                        print("   - \(item)")
                    }
                } catch {
                    print("❌ Erreur lors de la lecture du contenu du bundle: \(error)")
                }
            }
            
            passKitErrorMessage = "Le fichier .pkpass n'a pas été trouvé dans l'application. Assurez-vous qu'il est correctement inclus dans le bundle."
            showPassKitError = true
        }
    }
    
    private func updateUserName() {
        // Vérification du format du nom
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            nameChangeMessage = "Le nom ne peut pas être vide"
            showNameChangeAlert = true
            return
        }
        
        // Séparation du nom complet en prénom et nom
        let nameComponents = trimmedName.split(separator: " ", maxSplits: 1)
        let firstName = String(nameComponents.first ?? "")
        let lastName = nameComponents.count > 1 ? String(nameComponents[1]) : ""
        
        // Mise à jour du nom de l'utilisateur avec un callback à un seul paramètre
        appData.updateUserName(firstName: firstName, lastName: lastName) { error in
            isChangingName = false
            
            if error == nil {
                nameChangeMessage = "Votre nom a été mis à jour avec succès"
            } else {
                nameChangeMessage = "Erreur lors de la mise à jour du nom: \(error?.localizedDescription ?? "Inconnue")"
            }
            
            showNameChangeAlert = true
        }
    }
}

// Vue wrapper pour PKAddPassesViewController avec swipe pour fermer
struct PassKitSheetView: UIViewControllerRepresentable {
    let pass: PKPass
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Créer le conteneur qui va héberger le PKAddPassesViewController
        let containerViewController = PassContainerViewController()
        containerViewController.pass = pass
        containerViewController.dismissHandler = {
            self.isPresented = false
        }
        return containerViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas besoin de mise à jour
    }
    
    // Classe pour gérer le conteneur du pass avec swipe down
    class PassContainerViewController: UIViewController {
        var pass: PKPass?
        var passViewController: PKAddPassesViewController?
        var dismissHandler: (() -> Void)?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            guard let pass = pass else { return }
            
            // Créer le PKAddPassesViewController
            if PKAddPassesViewController.canAddPasses() {
                passViewController = PKAddPassesViewController(pass: pass)
                passViewController?.delegate = self
                
                // Ajouter le geste de swipe
                let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
                view.addGestureRecognizer(swipeGesture)
                
                // Présenter le pass en tant que view controller enfant
                if let passVC = passViewController {
                    addChild(passVC)
                    view.addSubview(passVC.view)
                    passVC.view.frame = view.bounds
                    passVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    passVC.didMove(toParent: self)
                }
            }
        }
        
        @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: view)
            let velocity = gesture.velocity(in: view)
            
            switch gesture.state {
            case .changed:
                // Déplacer la vue vers le bas en fonction du geste
                if translation.y > 0 {
                    passViewController?.view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                }
                
            case .ended, .cancelled:
                // Si le swipe est assez rapide ou assez long vers le bas, fermer
                if translation.y > 150 || velocity.y > 500 {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.passViewController?.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                    }, completion: { _ in
                        self.dismissHandler?()
                    })
                } else {
                    // Sinon, revenir à la position normale
                    UIView.animate(withDuration: 0.3) {
                        self.passViewController?.view.transform = .identity
                    }
                }
                
            default:
                break
            }
        }
    }
}

// Conformer à PKAddPassesViewControllerDelegate
extension PassKitSheetView.PassContainerViewController: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        // Apple Wallet a terminé l'ajout du pass
        dismissHandler?()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView().environmentObject(AppData())
        }
    }
}

struct InstagramDataTutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("🔐 Étape 1 — Connectez-vous à Instagram")
                        .font(.headline)
                    Text("1. Allez sur https://www.instagram.com\n2. Connectez-vous à votre compte.")

                    Text("⚙️ Étape 2 — Accédez aux paramètres")
                        .font(.headline)
                    Text("1. Cliquez sur votre photo de profil en haut à droite.\n2. Cliquez sur Paramètres > Votre activité > Télécharger vos informations\n(ou accédez directement à https://www.instagram.com/download/request/)")

                    Text("📧 Étape 3 — Demandez vos données")
                        .font(.headline)
                    Text("1. Entrez l’adresse e-mail à laquelle vous souhaitez recevoir le lien de téléchargement.\n2. Choisissez le format :\n   • HTML (lisible facilement dans un navigateur)\n   • JSON (plus adapté pour les développeurs ou pour une intégration dans d’autres outils)\n3. Cliquez sur Suivant, entrez votre mot de passe, puis Demander un téléchargement.")
                }

                Group {
                    Text("🕐 Étape 4 — Attendez l’e-mail")
                        .font(.headline)
                    Text("Instagram vous enverra un lien de téléchargement par e-mail (cela peut prendre quelques minutes à quelques heures).")

                    Text("📂 Étape 5 — Téléchargez le fichier ZIP")
                        .font(.headline)
                    Text("1. Une fois l’e-mail reçu, cliquez sur Télécharger les informations.\n2. Vous serez redirigé vers Instagram, connectez-vous de nouveau si nécessaire.\n3. Le fichier ZIP contiendra :\n   • Vos publications\n   • Vos messages\n   • Vos commentaires\n   • Vos likes\n   • Vos stories archivées\n   • Et plus encore…")
                }
            }
            .padding()
        }
        .navigationTitle("Télécharger mes données")
        .navigationBarTitleDisplayMode(.inline)
    }
}
