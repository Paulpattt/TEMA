import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appData: AppData

    // États pour la navigation et la recherche
    @State private var selectedTab: Int = 0
    @State private var hideHeader: Bool = false
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false

    init() {
        // Configuration personnalisée de la TabBar pour que l'onglet sélectionné soit rouge
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        if let temaRed = UIColor(named: "TEMA_Red") {
            appearance.stackedLayoutAppearance.selected.iconColor = temaRed
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: temaRed]
            
            // Optionnel : pour les autres dispositions sur iPad, etc.
            appearance.inlineLayoutAppearance.selected.iconColor = temaRed
            appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: temaRed]
            appearance.compactInlineLayoutAppearance.selected.iconColor = temaRed
            appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: temaRed]
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        if appData.isLoggedIn {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    mainContent
                }
                .tint(Color(UIColor.label))  // Applique la couleur dynamique (noir/blanc) aux éléments de la barre de navigation
            } else {
                NavigationView {
                    mainContent
                }
                .tint(Color(UIColor.label))
            }
        } else {
            WelcomeView()
        }
    }
    
    // Le contenu principal de l'app : header + TabView
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header : titre "TEMA" et barre de recherche
            GeometryReader { geometry in
                HStack {
                    // Bouton TEMA : ramène à l'onglet Home
                    Button(action: {
                        selectedTab = 0
                    }) {
                        Text("TEMA")
                            .font(.largeTitle)
                            .bold()
                            // Ici, on peut définir la couleur souhaitée pour ce bouton (ici on le laisse en rouge ou en couleur personnalisée)
                            .foregroundColor(Color("TEMA_Red"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Barre de recherche
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                        
                        TextField("", text: $searchText, onCommit: {
                            if !searchText.isEmpty {
                                isSearchActive = true
                            }
                        })
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.primary)
                        .frame(height: 34)
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(.gray)
                                .offset(y: -5),
                            alignment: .bottom
                        )
                    }
                    .frame(width: geometry.size.width / 2, alignment: .trailing)
                }
                .padding(.horizontal)
                .frame(height: geometry.size.height)
            }
            .frame(height: 50)
            .background(Color(UIColor.systemBackground))
            
            // TabView en bas
            TabView(selection: $selectedTab) {
                HomeView(hideHeader: $hideHeader)
                    .tabItem { Image("homeIcon") }
                    .tag(0)
                
                SpiraleView()
                    .tabItem { Image("spiraleIcon") }
                    .tag(1)
                
                if #available(iOS 16.0, *) {
                    CreatePostView()
                        .tabItem {
                            Image("createpostIcon")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        }
                        .tag(2)
                }
                
                ChessView()
                    .tabItem { Image("chessIcon") }
                    .tag(3)
                
                ProfileView()
                    .tabItem { Image("profileIcon") }
                    .tag(4)
            }
            // Pas d'appel à .tint ici car la TabBar est personnalisée via UITabBarAppearance
        }
        .background(
            // NavigationLink invisible pour lancer SearchView
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

#Preview {
    ContentView().environmentObject(AppData())
}
