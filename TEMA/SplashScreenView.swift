//
//  SplashScreenView.swift
//  TEMA
//
//  Created by Paul Paturel on 07/04/2025.
//

import SwiftUI

struct SplashScreenView: View {
    // États pour contrôler l'opacité et la fin du splash
    @State private var logoIsVisible = true
    @State private var showContent = false // Pour savoir quand ContentView doit être interactive

    // Accès à AppData (sera injecté depuis TEMAApp)
    @EnvironmentObject var appData: AppData

    var body: some View {
        ZStack {
            // 1. Le contenu principal (ContentView) - initialement invisible
            // On l'ajoute au ZStack pour qu'il soit prêt sous le splash
            // Il deviendra visible quand le splash disparaîtra
            if showContent {
                 ContentView()
                    .environmentObject(appData) // Important: passer l'environnement
            }

            // 2. Le "faux" écran de lancement (qui correspond au storyboard)
            if logoIsVisible { // On affiche ce calque tant que logoIsVisible est true
                 ZStack {
                    // Fond blanc (correspond au storyboard)
                    Color(UIColor.systemBackground) // Utilise la couleur système (blanc en mode clair, noir en mode sombre)
                        .ignoresSafeArea()

                    // Logo TEMA (positionné comme dans le storyboard)
                    Image("LaunchLogo") // Assure-toi que l'asset existe bien
                        .resizable()
                        .scaledToFit()
                        // Ajuste le padding et la position pour correspondre exactement à ton storyboard
                        // Ces valeurs sont des estimations, ajuste-les si nécessaire
                        .padding(.horizontal, 60)
                        .frame(maxWidth: .infinity)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.33) // Environ 1/3 haut

                 }
                 .transition(.opacity.animation(.easeOut(duration: 0.6))) // Animation de fondu pour ce ZStack
                 .zIndex(1) // Assure que ce calque est au-dessus de ContentView au début
            }
        }
        .onAppear {
            // Démarrer l'animation de disparition après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Délai avant le début du fondu
                withAnimation {
                    logoIsVisible = false // Cela déclenche la disparition du calque splash
                }
                // Active ContentView après la fin de l'animation pour éviter les interactions prématurées
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + 0.6) { // Délai + durée de l'animation
                     showContent = true
                 }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        // Fournir un AppData factice pour la prévisualisation
        SplashScreenView().environmentObject(AppData())
    }
}
