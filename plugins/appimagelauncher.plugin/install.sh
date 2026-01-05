#!/bin/bash
set -e

INSTALL_DIR="$HOME/Applications/AppImageLauncher"
ICON_DEST="$HOME/.local/share/icons/hicolor/256x256/apps/appimagelauncher.png"
DESKTOP_FILE="$HOME/.local/share/applications/appimagelauncher-lite.desktop"

mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$ICON_DEST")"
mkdir -p "$(dirname "$DESKTOP_FILE")"

# Download the Lite AppImage (preserve upstream filename)
echo "Downloading AppImageLauncher Lite..."
wget --content-disposition -P "$INSTALL_DIR" "https://github.com/TheAssassin/AppImageLauncher/releases/latest/download/appimagelauncher-lite-x86_64.AppImage"

# Find the downloaded AppImage
shopt -s nullglob
files=("$INSTALL_DIR"/appimagelauncher-lite*.AppImage "$INSTALL_DIR"/*.AppImage)
if (( ${#files[@]} )); then
    APPIMAGE="${files[0]}"
else
    echo "Failed to find downloaded AppImage" >&2
    exit 1
fi
chmod +x "$APPIMAGE"

# Run the AppImage with the "install" action to integrate into the system
# This will typically register AppImageLauncher and integrate AppImages
echo "Running AppImageLauncher Lite installer (this may prompt for confirmation)..."
"$APPIMAGE" install || true

# Try to extract an icon from the AppImage (fallback to a shipped icon)
pushd "$(dirname "$APPIMAGE")" > /dev/null
"$APPIMAGE" --appimage-extract >/dev/null 2>&1 || true
if [ -f "squashfs-root/.DirIcon" ]; then
    mv "squashfs-root/.DirIcon" "$ICON_DEST"
    rm -rf squashfs-root
else
    # If our repo has a downloaded icon, use that; otherwise ignore
    cp "$(dirname "${BASH_SOURCE[0]}")/appimagelauncher.png" "$ICON_DEST" 2>/dev/null || true
fi
popd > /dev/null

# Create a simple desktop entry so users can launch the AppImage directly if they want
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=AppImageLauncher (Lite)
Comment=Manage AppImages
Exec="$APPIMAGE" %U
Icon=$ICON_DEST
Type=Application
Categories=Utility;
Terminal=false
EOF

# Keep the latest 2 copies by default (configurable via KEEP)
KEEP=${KEEP:-2}
mapfile -t appimages < <(ls -1t "$INSTALL_DIR"/*.AppImage 2>/dev/null || true)
if (( ${#appimages[@]} > KEEP )); then
    for ((i=KEEP;i<${#appimages[@]};i++)); do
        rm -f "${appimages[$i]}"
    done
    echo "Removed $(( ${#appimages[@]} - KEEP )) old AppImage(s) from $INSTALL_DIR"
fi

# Inform the user
printf "AppImageLauncher Lite installed (AppImage: %s)\n" "$APPIMAGE"
exit 0
