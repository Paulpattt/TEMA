import SwiftUI

struct SpiraleView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("SpiraleLogo") // Assurez-vous que le nom correspond bien à celui dans Assets.xcassets
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300) // Ajustez la taille si nécessaire
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            
            Spacer()
        }
        .ignoresSafeArea() // Cela permet d'éviter les marges non souhaitées
    }
}

#Preview {
    SpiraleView()
}
