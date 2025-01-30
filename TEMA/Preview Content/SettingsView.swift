import SwiftUI

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true

    var body: some View {
        VStack {
            Text("Paramètres")
                .font(.largeTitle)
                .bold()
                .padding()

            Spacer()

            Button(action: {
                // Déconnexion : On réinitialise la session
                isLoggedIn = false
                UserDefaults.standard.removeObject(forKey: "AppleUserID") // Supprime l'identifiant Apple stocké
            }) {
                Text("Se déconnecter")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .padding(.bottom, 50)
            .padding(.horizontal, 20)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
