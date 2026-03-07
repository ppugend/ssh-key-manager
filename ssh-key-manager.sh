#!/bin/bash

# Move to the .ssh directory
cd ~/.ssh || exit

# --- 1. Agent Check: Handle existing identities ---
if ssh-add -l > /dev/null 2>&1; then
    echo "Active SSH keys detected in agent."
    read -p "Clear them to continue? [y / Enter to Exit]: " CLEAR_CONFIRM
    if [[ "$CLEAR_CONFIRM" =~ ^[Yy]$ ]]; then
        ssh-add -D 2>/dev/null
        echo "Agent identities cleared."
    else
        echo "Exiting. Script requires a clean agent to function correctly."
        exit 0
    fi
fi

# --- 2. Startup Check: Handle existing real files ---
# If id_ed25519 exists and is NOT a symbolic link
if [ -f "id_ed25519" ] && [ ! -L "id_ed25519" ]; then
    echo "Found existing real key files in ~/.ssh/ (not a symlink)."
    read -p "Move them to a new profile folder? [Enter for Y / n]: " MOVE_CONFIRM
    
    if [[ -z "$MOVE_CONFIRM" || "$MOVE_CONFIRM" =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +%y%m%d%H%M%S)
        DEFAULT_DIR="default-$TIMESTAMP"
        
        mkdir -p "$DEFAULT_DIR"
        # Move all matching files (key, pub, etc) to the new folder
        mv id_ed25519* "$DEFAULT_DIR/"
        
        # Adjust permissions
        chmod 700 "$DEFAULT_DIR"
        chmod 600 "$DEFAULT_DIR/id_ed25519"
        chmod 644 "$DEFAULT_DIR/id_ed25519.pub"
        
        echo "Successfully moved existing keys to profile: $DEFAULT_DIR"
    fi
fi

# --- 3. Scan for profiles ---
get_profiles() {
    MAPFILE=()
    while IFS= read -r dir; do
        MAPFILE+=("$dir")
    done < <(find . -mindepth 2 -maxdepth 2 -name "id_ed25519" -exec dirname {} + | sed 's|./||' | sort)
}

get_profiles

# --- 4. Display the UI ---
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
echo " [x] None (Deactivate all)"
echo " [q] Quit"
echo "------------------------------------------"
read -p " Selection: " INPUT

# --- 5. Handle 'n' (New Key Generation) ---
if [[ "$INPUT" == "n" ]]; then
    read -p " > Enter folder name (e.g., work-profile): " NEW_DIR
    if [[ -z "$NEW_DIR" ]]; then echo "Error: Folder name cannot be empty."; exit 1; fi
    if [ -d "$NEW_DIR" ]; then echo "Error: Folder already exists."; exit 1; fi

    read -p " > Enter email/identity (Optional): " IDENTITY

    mkdir -p "$NEW_DIR"
    ssh-keygen -t ed25519 -C "$IDENTITY" -f "$HOME/.ssh/$NEW_DIR/id_ed25519" -N ""

    chmod 700 "$NEW_DIR"
    chmod 600 "$NEW_DIR/id_ed25519"
    chmod 644 "$NEW_DIR/id_ed25519.pub"

    echo "New profile [$NEW_DIR] created."
    get_profiles
    INPUT=$((${#MAPFILE[@]} - 1))
fi

# --- 6. Handle 'x' (None / Deactivate All) ---
if [[ "$INPUT" == "x" ]]; then
    rm -f "$HOME/.ssh/id_ed25519"*
    ssh-add -D 2>/dev/null
    echo "All managed keys deactivated."
    exit 0
fi

# --- 7. Handle 'q' (Quit) ---
if [[ "$INPUT" == "q" ]]; then
    exit 0
fi

# --- 8. Validate and Switch ---
SELECTED_DIR=${MAPFILE[$INPUT]}
if [ -z "$SELECTED_DIR" ]; then
    echo "Error: Invalid selection."
    exit 1
fi

# Cleanup: delete all id_ed25519* in .ssh before linking
rm -f "$HOME/.ssh/id_ed25519"*

# Create symbolic links
ln -s "$SELECTED_DIR/id_ed25519" id_ed25519
ln -s "$SELECTED_DIR/id_ed25519.pub" id_ed25519.pub

# Finalize SSH agent
echo "SSH Key switched to: [$SELECTED_DIR]"
eval "$(ssh-agent -s)" > /dev/null
ssh-add id_ed25519 2>/dev/null

# --- 9. Display Public Key for GitHub ---
echo "----------------------------------------------------------------------"
echo " COPY THE PUBLIC KEY BELOW FOR GITHUB:"
echo "----------------------------------------------------------------------"
cat id_ed25519.pub
echo "----------------------------------------------------------------------"
ssh-add -l
