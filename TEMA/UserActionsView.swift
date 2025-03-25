import SwiftUI
import MessageUI

struct UserActionsView: View {
    let user: User
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    @State private var showMessageComposer = false
    @State private var showAlertShare = false
    @State private var showAlertReport = false
    @State private var isFollowing = false // À connecter à une vraie logique de suivi
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Profil
            VStack(alignment: .leading, spacing: 8) {
                Text("Profil de \(user.name)")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Statut de suivi
                Button(action: {
                    toggleFollow()
                }) {
                    HStack {
                        Image(systemName: isFollowing ? "person.badge.minus" : "person.badge.plus")
                            .foregroundColor(isFollowing ? .red : .blue)
                        
                        Text(isFollowing ? "Ne plus suivre" : "Suivre \(user.name)")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Envoyer un message
                Button(action: {
                    showMessageComposer = true
                }) {
                    HStack {
                        Image(systemName: "message")
                            .foregroundColor(.green)
                        
                        Text("Envoyer un message")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Partager le profil
                Button(action: {
                    showAlertShare = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        
                        Text("Partager ce profil")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Section signalement
                Text("Action")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                Button(action: {
                    showAlertReport = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        
                        Text("Signaler ce profil")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Si c'est notre propre profil, afficher un message (ne devrait pas arriver normalement)
                if user.id == appData.currentUser?.id {
                    Text("Remarque: C'est votre profil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle("Actions")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Partager le profil", isPresented: $showAlertShare) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Cette fonctionnalité sera bientôt disponible.")
        }
        .alert("Signaler \(user.name)", isPresented: $showAlertReport) {
            Button("Annuler", role: .cancel) { }
            Button("Signaler", role: .destructive) {
                // Logique de signalement à implémenter
            }
        } message: {
            Text("Souhaitez-vous signaler ce compte pour comportement inapproprié?")
        }
        .sheet(isPresented: $showMessageComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposeView(recipient: "Profil TEMA: \(user.name)", message: "Bonjour \(user.name), je t'ai vu sur TEMA et...", isPresented: $showMessageComposer)
            } else {
                NoMessageServiceView()
            }
        }
    }
    
    private func toggleFollow() {
        // Logique de suivi à implémenter
        isFollowing.toggle()
    }
}

// Structure pour composer des messages SMS
struct MessageComposeView: UIViewControllerRepresentable {
    var recipient: String
    var message: String
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composeViewController = MFMessageComposeViewController()
        composeViewController.body = message
        composeViewController.subject = recipient
        composeViewController.messageComposeDelegate = context.coordinator
        return composeViewController
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.isPresented = false
        }
    }
}

// Vue affichée si les messages ne sont pas disponibles
struct NoMessageServiceView: View {
    var body: some View {
        VStack {
            Text("Messages non disponibles")
                .font(.title)
                .padding()
            
            Text("Votre appareil ne peut pas envoyer de messages.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("OK") {
                // Fermer la vue
            }
            .padding()
        }
        .padding()
    }
}

struct UserActionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserActionsView(user: User(id: "preview", name: "Preview User", email: "preview@example.com"))
                .environmentObject(AppData())
        }
    }
} 