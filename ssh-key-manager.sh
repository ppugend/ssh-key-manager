#!/bin/bash

# Move to the .ssh directory
cd ~/.ssh || exit

# 1. Scan ONLY for subdirectories containing 'id_ed25519'
# Changed -mindepth 2 to ignore files in the current .ssh directory
get_profiles() {
    MAPFILE=()
    while IFS= read -r dir; do
        MAPFILE+=("$dir")
    done < <(find . -mindepth 2 -maxdepth 2 -name "id_ed25519" -exec dirname {} + | sed 's|./||' | sort)
}

get_profiles

# 2. Display the UI
echo "------------------------------------------"
echo " SSH Key Manager (Switch or Create)"
echo "------------------------------------------"
if [ ${#MAPFILE[@]} -eq 0 ]; then
    echo " (No profiles found)"
else
    for i in "${!MAPFILE[@]}"; do
        printf " [%d] %s\n" "$i" "${MAPFILE[$i]}"
    done
fi
echo " [n] Create a NEW key profile"
echo " [q] Quit"
echo "------------------------------------------"
read -p " Selection: " INPUT

# 3. Handle 'n' (New Key Generation)
if [[ "$INPUT" == "n" ]]; then
    read -p " > Enter folder name (e.g., rasp5-work): " NEW_DIR
    if [[ -z "$NEW_DIR" ]]; then echo "❌ Folder name cannot be empty."; exit 1; fi
    
    # Check if folder already exists
    if [ -d "$NEW_DIR" ]; then echo "❌ Folder already exists."; exit 1; fi

    read -p " > Enter email/identity (Optional): " IDENTITY
    
    mkdir -p "$NEW_DIR"
    ssh-keygen -t ed25519 -C "$IDENTITY" -f "$HOME/.ssh/$NEW_DIR/id_ed25519" -N ""
    
    chmod 700 "$NEW_DIR"
    chmod 600 "$NEW_DIR/id_ed25519"
    chmod 644 "$NEW_DIR/id_ed25519.pub"
    
    echo "✅ New profile [$NEW_DIR] created."
    get_profiles
    # Select the last added profile
    INPUT=$((${#MAPFILE[@]} - 1))
fi

# 4. Handle 'q' (Quit)
if [[ "$INPUT" == "q" ]]; then
    exit 0
fi

# 5. Validate and Switch
SELECTED_DIR=${MAPFILE[$INPUT]}
if [ -z "$SELECTED_DIR" ]; then
    echo "❌ [Error] Invalid selection."
    exit 1
fi

# Update symbolic links
rm -f id_ed25519 id_ed25519.pub
ln -s "$SELECTED_DIR/id_ed25519" id_ed25519
ln -s "$SELECTED_DIR/id_ed25519.pub" id_ed25519.pub

# Finalize SSH agent
echo "✅ SSH Key switched to: [$SELECTED_DIR]"
eval "$(ssh-agent -s)" > /dev/null
ssh-add id_ed25519 2>/dev/null

# 6. Display Public Key for GitHub
echo "----------------------------------------------------------------------"
echo "📋 COPY THE PUBLIC KEY BELOW FOR GITHUB:"
echo "----------------------------------------------------------------------"
cat id_ed25519.pub
echo "----------------------------------------------------------------------"
ssh-add -l
