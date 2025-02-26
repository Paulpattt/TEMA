import SwiftUI
import Kingfisher

struct SearchView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    
    @State var searchQuery: String
    @State private var searchResults: [User] = []
    @State private var isSearching: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Barre de recherche
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
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
                        NavigationLink(destination: UserProfileView(user: user)) {
                            HStack(spacing: 15) {
                                // Photo de profil
                                if let profilePicture = user.profilePicture, 
                                   !profilePicture.isEmpty,
                                   let url = URL(string: profilePicture) {
                                    KFImage(url)
                                        .placeholder {
                                            ProgressView()
                                        }
                                        .cancelOnDisappear(true)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                }
                                
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
        .navigationBarHidden(true)
        .onAppear {
            if !searchQuery.isEmpty {
                performSearch()
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
