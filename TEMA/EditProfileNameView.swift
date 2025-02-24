//
//  EditProfileNameView.swift
//  TEMA
//
//  Created by Paul Paturel on 14/02/2025.
//

import SwiftUI

struct EditProfileNameView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Modifier votre nom")) {
                    TextField("Prénom", text: $firstName)
                    TextField("Nom", text: $lastName)
                }
            }
            .navigationTitle("Modifier le nom")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        appData.updateUserName(firstName: firstName, lastName: lastName) { error in
                            if let error = error {
                                print("Erreur: \(error.localizedDescription)")
                            } else {
                                print("Nom mis à jour")
                                dismiss()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Si un nom complet existe déjà, on le divise en prénom et nom
                if let name = appData.currentUser?.name, !name.isEmpty {
                    let components = name.split(separator: " ")
                    if components.count >= 2 {
                        firstName = String(components.first!)
                        lastName = components.dropFirst().joined(separator: " ")
                    } else {
                        firstName = name
                        lastName = ""
                    }
                }
            }
        }
    }
}

#Preview {
    EditProfileNameView().environmentObject(AppData())
}
