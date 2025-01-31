import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcomeScreen") private var hasSeenWelcomeScreen: Bool = false
    @EnvironmentObject var appData: AppData  // Accès aux données utilisateur

    var body: some View {
        if !hasSeenWelcomeScreen {
            WelcomeView() // Affiche la page de bienvenue au premier lancement
        } else if !appData.isLoggedIn {
            WelcomeView() // Redirige vers WelcomeView si l'utilisateur n'est pas connecté
        } else {
            MainAppView() // Affiche l'application normale si l'utilisateur est connecté
        }
    }
}

struct MainAppView: View {
    @State private var selectedTab: Int = 0
    @State private var hideHeader: Bool = false
    @EnvironmentObject var appData: AppData

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        VStack(spacing: 0) {
            if !hideHeader {
                HStack {
                    Button(action: {
                        selectedTab = 0 // Revient à l'onglet HomeView
                    }) {
                        Text("TEMA")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(Color("TEMA_Red"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)

                        TextField("", text: .constant(""))
                            .foregroundColor(.primary)
                            .frame(height: 20)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.primary),
                                alignment: .bottom
                            )
                    }
                    .frame(width: 150)
                }
                .padding(.horizontal)
                .frame(height: 50)
                .background(Color(UIColor.systemBackground))
            }

            TabView(selection: $selectedTab) {
                HomeView(hideHeader: $hideHeader)
                    .tabItem { Image("homeIcon") }
                    .tag(0)

                SpiraleView()
                    .tabItem { Image("spiraleIcon") }
                    .tag(1)

                CreatePostView()
                    .tabItem { Image("createpostIcon") }
                    .tag(2)

                ChessView()
                    .tabItem { Image("chessIcon") }
                    .tag(3)

                ProfileView()
                    .tabItem { Image("profileIcon") }
                    .tag(4)
            }
            .accentColor(Color("TEMA_Red"))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppData()) // Ajoute AppData pour éviter les erreurs d’environnement
}
