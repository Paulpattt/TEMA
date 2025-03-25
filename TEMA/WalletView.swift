import SwiftUI
import PassKit

struct WalletView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showPassKitError = false
    @State private var errorMessage = ""
    
    // États pour stocker les données du pass
    @State private var passLoaded = false
    @State private var passTitle = "Carte TEMA"
    @State private var passSubtitle = "MEMBRE"
    @State private var passValue = "TEMA"
    @State private var bgColor = Color("TEMA_Red")
    @State private var fgColor = Color.white
    @State private var pass: PKPass? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // En-tête et titre
            Text("Carte TEMA")
                .font(.system(size: 36, weight: .bold))
                .padding(.top, 10)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            // Prévisualisation améliorée du pass
            VStack(spacing: 0) {
                // Pass card avec apparence Apple Wallet
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(bgColor)
                        .frame(height: 220)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading) {
                        // Apple Wallet header
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            Text("WALLET")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        // Pass content
                        VStack(alignment: .leading, spacing: 4) {
                            Text(passSubtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                            Text(passValue)
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(height: 220)
                }
                
                // Add the shaded bottom area with barcode indication 
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 30)
                    .padding(.horizontal, 20)
                    .padding(.top, -15)
                    .offset(y: -8)
            }
            .padding(.horizontal)
            
            Text("Ajoutez votre carte TEMA à Apple Wallet pour un accès rapide.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
                .padding(.top, 20)
            
            Spacer()
            
            // Bouton pour ajouter au Wallet
            Button(action: addToWallet) {
                HStack {
                    Image(systemName: "plus.rectangle")
                        .font(.title3)
                    Text("Ajouter à Apple Wallet")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 30)
                .background(bgColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .navigationTitle("Apple Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erreur", isPresented: $showPassKitError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadPassPreview()
        }
    }
    
    private func loadPassPreview() {
        // Charger le fichier .pkpass depuis le bundle de l'application
        if let passURL = Bundle.main.url(forResource: "Paul", withExtension: "pkpass") {
            do {
                let passData = try Data(contentsOf: passURL)
                let loadedPass = try PKPass(data: passData)
                self.pass = loadedPass
                
                // Utiliser les couleurs du pass TEMA
                self.bgColor = Color.red
                self.fgColor = Color.white
                
                // Mettre à jour le titre si disponible
                self.passTitle = loadedPass.organizationName ?? "Carte TEMA"
                
                passLoaded = true
                print("✅ Pass chargé avec succès pour la prévisualisation")
                
            } catch {
                print("❌ Erreur lors du chargement du pass pour la prévisualisation: \(error)")
            }
        } else {
            print("❌ Fichier Paul.pkpass non trouvé pour la prévisualisation")
        }
    }
    
    private func addToWallet() {
        if let currentPass = self.pass {
            // Utiliser le pass déjà chargé
            if PKAddPassesViewController.canAddPasses() {
                let passViewController = PKAddPassesViewController(pass: currentPass)
                
                // Présenter le contrôleur
                if let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                   let rootViewController = window.rootViewController {
                    rootViewController.present(passViewController!, animated: true)
                }
            } else {
                errorMessage = "Impossible d'ajouter des passes sur cet appareil"
                showPassKitError = true
            }
            return
        }
        
        // Fallback si le pass n'est pas déjà chargé
        if let passURL = Bundle.main.url(forResource: "Paul", withExtension: "pkpass") {
            print("✅ Fichier .pkpass trouvé: \(passURL)")
            
            do {
                let passData = try Data(contentsOf: passURL)
                print("✅ Données du pass chargées: \(passData.count) octets")
                
                // Créer et présenter le pass
                let pass = try PKPass(data: passData)
                print("✅ Pass créé avec succès")
                
                if PKAddPassesViewController.canAddPasses() {
                    let passViewController = PKAddPassesViewController(pass: pass)
                    
                    // Présenter le contrôleur
                    if let windowScene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                       let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                       let rootViewController = window.rootViewController {
                        rootViewController.present(passViewController!, animated: true)
                    }
                } else {
                    // Fallback si PKAddPassesViewController n'est pas disponible
                    errorMessage = "Impossible d'ajouter des passes sur cet appareil"
                    showPassKitError = true
                }
            } catch {
                print("❌ Erreur: \(error)")
                errorMessage = "Erreur lors du chargement du pass: \(error.localizedDescription)"
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
            
            errorMessage = "Le fichier .pkpass n'a pas été trouvé dans l'application. Assurez-vous qu'il est correctement inclus dans le bundle."
            showPassKitError = true
        }
    }
}

#Preview {
    NavigationView {
        WalletView()
    }
} 