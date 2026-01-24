#!/bin/bash
set -e

# Install LM Studio AppImage into the user's Applications folder
INSTALL_DIR="$HOME/Applications/LM Studio"
ICON_DEST="$HOME/.local/share/icons/hicolor/256x256/apps/lm-studio.png"
DESKTOP_FILE="$HOME/.local/share/applications/lm-studio.desktop"

mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$ICON_DEST")"
mkdir -p "$(dirname "$DESKTOP_FILE")"

# Download the AppImage and preserve the upstream filename if present
echo "Downloading LM Studio..."
wget --content-disposition --trust-server-names -P "$INSTALL_DIR" "https://lmstudio.ai/download/latest/linux/x64"

# Find the downloaded AppImage (accept versioned filenames)
shopt -s nullglob
files=("$INSTALL_DIR"/LM-Studio*.AppImage "$INSTALL_DIR"/lm-studio*.AppImage "$INSTALL_DIR"/*.AppImage)
if (( ${#files[@]} )); then
    APPIMAGE="${files[0]}"
else
    echo "Failed to find downloaded LM Studio AppImage" >&2
    exit 1
fi
chmod +x "$APPIMAGE"

# Keep only the latest N AppImage files (default 2) to allow rollback but avoid disk clutter
KEEP=${KEEP:-2}
shopt -s nullglob
mapfile -t appimages < <(ls -1t "$INSTALL_DIR"/*.AppImage 2>/dev/null || true)
if (( ${#appimages[@]} > KEEP )); then
    for ((i=KEEP;i<${#appimages[@]};i++)); do
        rm -f "${appimages[$i]}"
    done
    echo "Removed $(( ${#appimages[@]} - KEEP )) old AppImage(s) from $INSTALL_DIR"
fi

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
