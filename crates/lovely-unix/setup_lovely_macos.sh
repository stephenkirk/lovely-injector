#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "====== Lovely Injector macOS Setup ======"

# Check for liblovely.dylib
if [ ! -f "$SCRIPT_DIR/liblovely.dylib" ]; then
    echo "✗ Could not find liblovely.dylib in the current directory"
    exit 1
fi

# Remove quarantine attribute
echo "Removing quarantine with sudo (you may be asked for your password)"
sudo xattr -d com.apple.quarantine "$SCRIPT_DIR/liblovely.dylib"
if [ $? -ne 0 ]; then
    echo "✗ Failed to remove quarantine attribute"
else
    echo "✓ Quarantine attribute removed successfully"
fi

# Game selection menu
echo -e "\n====== Game Selection ======"
echo "1) Balatro"
# Add more games here as they're supported
echo "Please select a game to install (1):"
read -r GAME_CHOICE

# Default to Balatro if no valid selection
if [ "$GAME_CHOICE" != "1" ]; then
    echo "Invalid selection, defaulting to Balatro."
    GAME_CHOICE="1"
fi

# Set game-specific variables
case "$GAME_CHOICE" in
    "1")
        GAME_NAME="Balatro"
        GAME_PATH="/Users/$USER/Library/Application Support/Steam/steamapps/common/$GAME_NAME"
        MOD_PATH="/Users/$USER/Library/Application Support/$GAME_NAME/Mods"
        ALIAS_NAME="balatro"
        ;;
    # Add more games here as they're supported
esac

# Create mod directory if it doesn't exist
mkdir -p "$MOD_PATH"
echo "✓ Created mod directory at: $MOD_PATH"

# Copy run script if needed
RUN_SCRIPT="$SCRIPT_DIR/run_lovely_macos.sh"
if [ ! -f "$RUN_SCRIPT" ]; then
    echo "Creating run script..."
    cat > "$RUN_SCRIPT" << EOL
#!/bin/bash
export DYLD_INSERT_LIBRARIES=liblovely.dylib
cd "$GAME_PATH"
./$GAME_NAME.app/Contents/MacOS/love "\$@"
EOL
    chmod +x "$RUN_SCRIPT"
    echo "✓ Created run script at: $RUN_SCRIPT"
else
    # Update the run script with the proper game path
    sed -i '' "s|^gamename=.*|gamename=\"$GAME_NAME\"|g" "$RUN_SCRIPT"
    echo "✓ Updated run script with game: $GAME_NAME"
fi

# Ask to set up shell alias
echo -e "\nWould you like to set up a shell alias to launch the game from anywhere? (y/n)"
read -r SETUP_ALIAS

if [[ $SETUP_ALIAS =~ ^[Yy]$ ]]; then
    # Determine user's shell
    USER_SHELL=$(basename "$SHELL")
    echo "Detected shell: $USER_SHELL"

    ALIAS_COMMAND="alias $ALIAS_NAME=\"$SCRIPT_DIR/run_lovely_macos.sh\""
    FISH_FUNCTION="function $ALIAS_NAME\n    \"$SCRIPT_DIR/run_lovely_macos.sh\" \$argv\nend"

    case "$USER_SHELL" in
        "bash")
            CONFIG_FILE="$HOME/.bashrc"
            echo -e "\n# $GAME_NAME launcher shortcut\n$ALIAS_COMMAND" >> "$CONFIG_FILE"
            echo "✓ Added alias to $CONFIG_FILE"
            echo "Run source $CONFIG_FILE to apply changes immediately"
            ;;
        "zsh")
            CONFIG_FILE="$HOME/.zshrc"
            echo -e "\n# $GAME_NAME launcher shortcut\n$ALIAS_COMMAND" >> "$CONFIG_FILE"
            echo "✓ Added alias to $CONFIG_FILE"
            echo "Run source $CONFIG_FILE to apply changes immediately"
            ;;
        "fish")
            CONFIG_DIR="$HOME/.config/fish"
            CONFIG_FILE="$CONFIG_DIR/config.fish"

            # Create config directory if it doesn't exist
            if [ ! -d "$CONFIG_DIR" ]; then
                mkdir -p "$CONFIG_DIR"
            fi

            echo -e "\n# $GAME_NAME launcher shortcut\n$FISH_FUNCTION" >> "$CONFIG_FILE"
            echo "✓ Added function to $CONFIG_FILE"
            echo "Run source $CONFIG_FILE to apply changes immediately"
            ;;
        *)
            echo "⚠ Unsupported shell: $USER_SHELL"
            echo "To create an alias manually, add the following to your shell's config file:"
            echo "alias $ALIAS_NAME=\"$SCRIPT_DIR/run_lovely_macos.sh\""
            ;;
    esac
fi

echo -e "\n====== Setup Complete ======"
echo "✓ $GAME_NAME has been set up with Lovely Injector"
echo "✓ Mods should be placed in: $MOD_PATH"
if [[ $SETUP_ALIAS =~ ^[Yy]$ ]]; then
    echo "✓ You can now launch the game by typing $ALIAS_NAME in your terminal"
    echo "  (after sourcing your shell config or starting a new terminal session)"
else
    echo "✓ You can launch the game by running $SCRIPT_DIR/run_lovely_macos.sh"
fi