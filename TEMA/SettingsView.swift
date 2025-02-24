import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            
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
        .padding()
        // Titre et configuration par défaut de la barre
        .navigationTitle("Paramètres")
        .navigationBarTitleDisplayMode(.inline)
        // Aucune personnalisation du bouton "Back" :
        // - Pas de .navigationBarBackButtonDisplayMode(.minimal)
        // - Pas de .navigationBarBackButtonHidden(true)
        // => Le bouton "Back" système, avec texte, est affiché et le swipe fonctionne.
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView().environmentObject(AppData())
        }
    }
}
