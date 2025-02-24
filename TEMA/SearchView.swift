import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    var searchQuery: String
    @State private var results: [User] = []
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Text("Résultats pour : \(searchQuery)")
                .font(.headline)
                .padding()
            
            if results.isEmpty && !searchQuery.isEmpty {
                Text("Aucun résultat trouvé")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(results) { user in
                    NavigationLink(destination: UserProfileView(user: user)
                                    .environmentObject(appData)) {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.body)
                            if let email = user.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            searchUsers()
        }
        .navigationTitle("Recherche")
    }
    
    func searchUsers() {
        let lowerQuery = searchQuery.lowercased()
        let query = appData.db.collection("users")
            .whereField("searchName", isGreaterThanOrEqualTo: lowerQuery)
            .whereField("searchName", isLessThan: lowerQuery + "\u{f8ff}")
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Erreur de recherche : \(error.localizedDescription)")
                results = []
            } else {
                results = snapshot?.documents.compactMap { try? $0.data(as: User.self) } ?? []
            }
        }
    }
}

#Preview {
    NavigationView {
        SearchView(searchQuery: "paulpaturel")
            .environmentObject(AppData())
    }
}
