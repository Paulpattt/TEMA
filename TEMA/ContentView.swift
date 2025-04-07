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
            
            // Optionnel : pour les autres dispositions (iPad, etc.)
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
        ZStack {
            // Background tap area to dismiss keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                // Swipe down gesture to dismiss keyboard
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            // Check if it's a downward swipe
                            if value.translation.height > 0 && abs(value.translation.width) < abs(value.translation.height) {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                )
            
            VStack(spacing: 0) {
                // Header conditionnel
                if !hideHeader {
                    GeometryReader { geometry in
                        HStack {
                            // Bouton TEMA : ramène à l'onglet Home
                            Button(action: {
                                selectedTab = 0
                            }) {
                                Image("LaunchLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                            }
                            .padding(.leading, 0)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            // Barre de recherche avec loupe cliquable
                            HStack(spacing: 8) {
                                // Loupe transformée en bouton
                                Button(action: {
                                    if !searchText.isEmpty {
                                        isSearchActive = true
                                    } else {
                                        focusSearchField()
                                    }
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 5)
                                
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
                            .contentShape(Rectangle())
                            .frame(width: geometry.size.width / 2, alignment: .trailing)
                            .padding(.vertical, 5)
                            .onTapGesture {
                                focusSearchField()
                            }
                        }
                        // On peut conserver un padding à droite pour équilibrer
                        .padding(.trailing, 16)
                        .frame(height: geometry.size.height)
                    }
                    .frame(height: 55)
                    .background(Color(UIColor.systemBackground))
                }
                
                // TabView en bas
                ZStack {
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
                    .padding(.bottom, -5)
                }
                // Cache la TabBar quand hideHeader est true
                .overlay(Color(UIColor.systemBackground).opacity(hideHeader ? 1 : 0))
            }
        }
        // Utiliser une approche plus standard pour la navigation
        .fullScreenCover(isPresented: $isSearchActive) {
            NavigationView {
                SearchView(searchQuery: searchText)
                    .environmentObject(appData)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            // Ajouter une transition pour un effet plus fluide
            .transition(.move(edge: .trailing))
            .animation(.easeInOut, value: isSearchActive)
        }
        .navigationBarHidden(true)
    }
    
    // Fonction pour mettre le focus sur le champ de recherche
    private func focusSearchField() {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        keyWindow?.endEditing(false)
        
        // Small delay to ensure the keyboard appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let textFields = keyWindow?.subviews.flatMap { $0.subviews.flatMap { $0.subviews } }.compactMap { $0 as? UITextField }
            textFields?.first?.becomeFirstResponder()
        }
    }
}

// Extension pour ajouter un placeholder au TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    ContentView().environmentObject(AppData())
}
