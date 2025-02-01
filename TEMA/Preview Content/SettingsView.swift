import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        VStack {
            Text("Paramètres")
                .font(.largeTitle)
                .bold()
                .padding()

            Spacer()

            Button(action: {
                // Appel de la méthode signOut d'AppData pour déconnecter via Firebase
                appData.signOut()
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
    SettingsView().environmentObject(AppData())
}
