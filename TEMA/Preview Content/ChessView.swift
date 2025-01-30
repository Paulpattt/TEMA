import SwiftUI

struct ChessView: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 100) // Abaisse légèrement l’échiquier

            GeometryReader { geometry in
                Image("ChessBoard")
                    .resizable()
                    .scaledToFit() // Garde les proportions sans couper l’image
                    .frame(width: geometry.size.width) // Ne dépasse pas l’écran
                    .clipped() // Évite tout débordement
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarTitle("Échecs", displayMode: .inline)
    }
}

#Preview {
    ChessView()
}
