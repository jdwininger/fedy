#!/bin/bash
set -e

# Install LM Studio AppImage into the user's Applications folder
INSTALL_DIR="$HOME/Applications/LM Studio"
APPIMAGE="$INSTALL_DIR/lm-studio.AppImage"
ICON_DEST="$HOME/.local/share/icons/hicolor/256x256/apps/lm-studio.png"
DESKTOP_FILE="$HOME/.local/share/applications/lm-studio.desktop"

mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$ICON_DEST")"
mkdir -p "$(dirname "$DESKTOP_FILE")"

echo "Downloading LM Studio..."
wget -O "$APPIMAGE" "https://lmstudio.ai/download/latest/linux/x64"
chmod +x "$APPIMAGE"

# Try to extract an icon from the AppImage; fall back to the bundled repo icon
pushd "$INSTALL_DIR" > /dev/null
"$APPIMAGE" --appimage-extract >/dev/null 2>&1 || true
if [ -f "squashfs-root/.DirIcon" ]; then
    mv "squashfs-root/.DirIcon" "$ICON_DEST"
    rm -rf squashfs-root
else
    # Use shipped plugin icon if extraction failed
    cp "$(dirname "${BASH_SOURCE[0]}")/lm-studio.png" "$ICON_DEST" 2>/dev/null || true
fi
popd > /dev/null

# Create desktop entry pointing at the user's AppImage
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=LM Studio
Comment=Discover, download, and run local LLMs
Exec="$APPIMAGE" --no-sandbox %U
Icon=$ICON_DEST
Type=Application
Categories=Development;Science;ArtificialIntelligence;
Terminal=false
StartupWMClass=LM Studio
EOF

# Inform the user
echo "LM Studio installed to $APPIMAGE"
