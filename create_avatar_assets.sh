#!/bin/bash

# Directory paths
AVATARS_DIR="TEMA/AvatarsPokemons"
ASSETS_DIR="TEMA/Assets.xcassets/Avatars"

# Process each avatar PNG file
for avatar_file in "$AVATARS_DIR"/avatar*.png; do
  # Extract the base name without extension
  base_name=$(basename "$avatar_file" .png)
