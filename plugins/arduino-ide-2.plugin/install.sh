#!/bin/bash
set -e

# Install Arduino IDE 2 AppImage into user's Applications folder
INSTALL_DIR="$HOME/Applications/ArduinoIDE2"
ICON_DEST="$HOME/.local/share/icons/hicolor/256x256/apps/arduino-ide-2.png"
DESKTOP_FILE="$HOME/.local/share/applications/arduino-ide-2.desktop"

mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$ICON_DEST")"
mkdir -p "$(dirname "$DESKTOP_FILE")"

APPIMAGE_URL="https://github.com/arduino/arduino-ide/releases/latest/download/arduino-ide_Linux_64bit.AppImage"

# Download and preserve upstream filename
echo "Downloading Arduino IDE 2..."
wget --content-disposition -P "$INSTALL_DIR" "$APPIMAGE_URL"

# Find the downloaded AppImage (accept versioned filenames)
shopt -s nullglob
files=("$INSTALL_DIR"/arduino-ide*.AppImage "$INSTALL_DIR"/*.AppImage)
if (( ${#files[@]} )); then
    APPIMAGE="${files[0]}"
else
    echo "Failed to find downloaded Arduino IDE 2 AppImage" >&2
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

# Try to extract an icon from the AppImage; fallback to bundled svg
pushd "$INSTALL_DIR" > /dev/null
"$APPIMAGE" --appimage-extract >/dev/null 2>&1 || true
if [ -f "squashfs-root/.DirIcon" ]; then
    mv "squashfs-root/.DirIcon" "$ICON_DEST"
    rm -rf squashfs-root
else
    # Use repo-provided icon if available
    cp "$(dirname "${BASH_SOURCE[0]}")/arduino.svg" "$ICON_DEST" 2>/dev/null || true
fi
popd > /dev/null

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Arduino IDE 2
Comment=Arduino IDE 2
Exec="$APPIMAGE" %U
Icon=$ICON_DEST
Type=Application
Categories=Development;IDE;
Terminal=false
StartupWMClass=Arduino
EOF

echo "Arduino IDE 2 installed to $APPIMAGE"
