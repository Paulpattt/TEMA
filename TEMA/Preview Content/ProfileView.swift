import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
    @State private var showSettings = false

    var body: some View {
        VStack {
            HStack {
                // ✅ Photo de profil
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)

                VStack(alignment: .leading) {
                    // ✅ Affichage du prénom (ou du nom complet) de l'utilisateur
                    Text(appData.currentUser?.name ?? "Utilisateur")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()

                // ✅ Bouton paramètres
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
            }
            .padding()

            Spacer()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ProfileView().environmentObject(AppData())
}
