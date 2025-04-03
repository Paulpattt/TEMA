#!/bin/bash

# Chemin vers le dossier des avatars
AVATARS_DIR="AvatarsPokemons"

# Vérifier si le dossier existe
if [ ! -d "$AVATARS_DIR" ]; then
    echo "Le dossier $AVATARS_DIR n'existe pas"
    exit 1
fi

# Créer un fichier temporaire pour stocker les commandes Firebase
echo "// Initialisation des avatars dans Firebase" > firebase_avatars.js

# Parcourir tous les fichiers PNG dans le dossier
for file in "$AVATARS_DIR"/*.png; do
    if [ -f "$file" ]; then
        # Obtenir le nom du fichier sans extension
        filename=$(basename "$file")
        name="${filename%.*}"
        
        # Ajouter la commande pour initialiser l'avatar
        echo "db.collection('avatars').doc('$name').set({
    isAvailable: true,
    userId: null,
    userName: null,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
});" >> firebase_avatars.js
    fi
done

echo "Script généré avec succès dans firebase_avatars.js"
echo "Pour l'exécuter, utilisez : firebase firestore:run firebase_avatars.js" 