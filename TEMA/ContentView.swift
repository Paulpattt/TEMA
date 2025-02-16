import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        if appData.isLoggedIn {
            MainAppView() // Affiche l'application principale si connecté
        } else {
            WelcomeView() // Affiche l'écran de connexion sinon
        }
    }
}

struct MainAppView: View {
    @State private var selectedTab: Int = 0
    @State private var hideHeader: Bool = false
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false  // Active la navigation vers SearchView
    @EnvironmentObject var appData: AppData

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
                VStack(spacing: 0) {
                HeaderView(searchText: $searchText, isSearchActive: $isSearchActive)
                
                TabView(selection: $selectedTab) {
                    HomeView(hideHeader: $hideHeader)
                        .tabItem { Image("homeIcon") }
                        .tag(0)
                    
                    SpiraleView()
                        .tabItem { Image("spiraleIcon") }
                        .tag(1)
                    
                    CreatePostView()
                        .tabItem {
                            VStack {
                                Image("createpostIcon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                            }
                        }
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
            // NavigationLink invisible déclenché lorsque isSearchActive est true
            .background(
                NavigationLink(
                    destination: SearchView(searchQuery: searchText)
                        .environmentObject(appData),
                    isActive: $isSearchActive,
                    label: { EmptyView() }
                )
            )
            .navigationBarHidden(true)
        }
    }
}

import SwiftUI

struct HeaderView: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool

    var body: some View {
        GeometryReader { geometry in
            HStack {
                // Titre "TEMA" à gauche
                Text("TEMA")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color("TEMA_Red"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Conteneur de recherche
                HStack(spacing: 8) {
                    // Icône de loupe toujours visible, avec offset ajusté vers la droite
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)
                        .offset(x: 0)  // Offset modifié pour rapprocher l'icône de la barre
                    
                    // Champ de recherche sans placeholder
                    TextField("", text: $searchText, onCommit: {
                        if !searchText.isEmpty {
                            isSearchActive = true
                        }
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
                    .frame(height: 34)  // Hauteur fixée pour le TextField
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.gray)
                            .offset(y: -5),  // Ajustez cette valeur pour relever la ligne
                        alignment: .bottom
                    )
                }
                // Conteneur plus large, ici 1/2 de la largeur du header
                .frame(width: geometry.size.width / 2, alignment: .trailing)
            }
            .padding(.horizontal)
            .frame(height: geometry.size.height)
        }
        .frame(height: 50)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    HeaderView(searchText: .constant(""), isSearchActive: .constant(false))
}
#Preview {
    ContentView().environmentObject(AppData())
}
