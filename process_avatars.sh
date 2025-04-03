#!/bin/bash

# Process each avatar in the AvatarsPokemons directory
for avatar_file in TEMA/AvatarsPokemons/avatar*.png; do
  # Extract the base name without extension
  base_name=$(basename "$avatar_file" .png)
  
  # Create the image set directory
  mkdir -p "TEMA/Assets.xcassets/Avatars/${base_name}.imageset"
  
  # Copy the avatar file
  cp "$avatar_file" "TEMA/Assets.xcassets/Avatars/${base_name}.imageset/"
  
  # Create the Contents.json file
  cat > "TEMA/Assets.xcassets/Avatars/${base_name}.imageset/Contents.json" << EOT
{
  "images" : [
    {
      "filename" : "${base_name}.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOT
  
  echo "Processed $base_name"
done

echo "All done!" 