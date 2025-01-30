import SwiftUI

struct SpiralView: View {
    var body: some View {
        VStack {
            Text("Spirale")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
        }
        .background(Color("Background").ignoresSafeArea())
    }
}

#Preview {
    SpiralView()
}
