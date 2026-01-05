#!/bin/bash
set -e

INSTALL_DIR="/opt/lm-studio"
APPIMAGE="$INSTALL_DIR/lm-studio.AppImage"
ICON_DEST="/usr/share/icons/hicolor/256x256/apps/lm-studio.png"
DESKTOP_FILE="/usr/share/applications/lm-studio.desktop"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download AppImage
echo "Downloading LM Studio..."
wget -O "$APPIMAGE" "https://lmstudio.ai/download/latest/linux/x64"
chmod +x "$APPIMAGE"

# Extract Icon
echo "Extracting icon..."
pushd "$INSTALL_DIR" > /dev/null
# Run with --appimage-extract to get the icon
# We use a timeout or expect it to exit? No, --appimage-extract exits after extraction.
"$APPIMAGE" --appimage-extract .DirIcon > /dev/null 2>&1
if [ -f "squashfs-root/.DirIcon" ]; then
    mkdir -p "$(dirname "$ICON_DEST")"
    mv "squashfs-root/.DirIcon" "$ICON_DEST"
    rm -rf squashfs-root
fi
popd > /dev/null

# Create Desktop Entry
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=LM Studio
Comment=Discover, download, and run local LLMs
Exec="$APPIMAGE" --no-sandbox %U
Icon=lm-studio
Type=Application
Categories=Development;Science;ArtificialIntelligence;
Terminal=false
StartupWMClass=LM Studio
EOF

# Update icon cache
gtk-update-icon-cache /usr/share/icons/hicolor || true
