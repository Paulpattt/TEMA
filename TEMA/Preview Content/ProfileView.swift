import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appData: AppData
    @State private var showSettings = false // État pour afficher la modal des paramètres

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                Spacer()

                Button(action: {
                    showSettings.toggle() // Ouvre les paramètres
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
            SettingsView() // Ouvre la vue des paramètres en modal
        }
    }
}

#Preview {
    ProfileView().environmentObject(AppData())
}
