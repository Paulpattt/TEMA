import SwiftUI

struct SpiraleView: View {
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack {
            Spacer()
            Image("SpiraleLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotationAngle += 360
                    }
                }
            Spacer()
        }
    }
}

struct SpiraleView_Previews: PreviewProvider {
    static var previews: some View {
        SpiraleView()
    }
}
