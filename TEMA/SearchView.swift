import SwiftUI
import Kingfisher

struct SearchView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    @State var searchQuery: String
    @State private var searchResults: [User] = []
    @State private var isSearching: Bool = false
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    // Bouton retour simple
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color("TEMA_Red"))
                            .padding(8)
                    }
                    
                    TextField("Rechercher", text: $searchQuery, onCommit: {
                        performSearch()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    
                    Button(action: {
                        performSearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Aucun utilisateur trouvé")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Essayez un autre terme de recherche")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 100)
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(searchResults) { user in
                            NavigationLink(destination: 
                                UserProfileView(user: user)
                                    .navigationBarTitle(user.name, displayMode: .inline)
                            ) {
                                HStack(spacing: 15) {
                                    // Utiliser AvatarView au lieu de KFImage
                                    AvatarView(
                                        profileUrl: user.profilePicture,
                                        size: 50,
                                        isCircular: true,
                                        defaultSymbol: "person.crop.circle",
                                        defaultColor: .gray
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(user.name)
                                            .font(.headline)
                                        
                                        if user.id == appData.currentUser?.id {
                                            Text("Votre compte")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .offset(x: offset) // Appliquer le décalage horizontal
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Permettre le drag seulement vers la droite (pour revenir)
                        if value.translation.width > 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        // Si le drag est suffisamment long, on ferme la vue
                        if value.translation.width > geometry.size.width * 0.3 {
                            dismiss()
                        } else {
                            // Sinon on revient à la position initiale avec animation
                            withAnimation {
                                offset = 0
                            }
                        }
                    }
            )
            // Ajouter un indicateur visuel pour le swipe
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.01))
                    .frame(width: 20)
                    .onTapGesture {} // Pour capturer les taps
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.width > 0 {
                                    offset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                if value.translation.width > geometry.size.width * 0.3 {
                                    dismiss()
                                } else {
                                    withAnimation {
                                        offset = 0
                                    }
                                }
                            }
                    ),
                alignment: .leading
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            if !searchQuery.isEmpty {
                performSearch()
            }
        }
        .onChange(of: searchQuery) { newValue in
            if newValue.isEmpty {
                searchResults = []
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        appData.searchUsers(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}

#Preview {
    NavigationView {
        SearchView(searchQuery: "test")
            .environmentObject(AppData())
    }
}
