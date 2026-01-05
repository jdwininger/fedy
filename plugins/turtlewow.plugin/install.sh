#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Turtle WoW"
DESC="MMO Game server. Free account required."
URL="https://launcher.turtlecraft.gg/api/launcher/TurtleWoW.AppImage?download=bunny"
INSTALLDIR="$HOME/Applications/TurtleWoW"
DESKTOP_FILE="$HOME/.local/share/applications/turtlewow.desktop"
ICON_NAME="turtle"
ICON_SRC="$(pwd)/turtle.png"

# Confirm installation with user
if command -v zenity >/dev/null 2>&1; then
  if ! zenity --question --title="$APP_NAME — Install" --no-wrap --text="This will install $APP_NAME:\n\n- Ensure Wine and Winetricks are installed (or offer to install them)\n- Create default WINE prefix if missing\n- Install DXVK into default prefix\n- Download launcher to: $INSTALLDIR\n- Create desktop entry at: $DESKTOP_FILE\n\nContinue?" --ok-label="Install" --cancel-label="Cancel"; then
    _show_msg "$APP_NAME" "Installation cancelled by user."
    exit 1
  fi
else
  read -p "Install $APP_NAME and its launcher to $INSTALLDIR? (y/N): " ans
  case "$ans" in
    [Yy]*) ;;
    *) echo "Installation cancelled."; exit 1 ;;
  esac
fi

# helper: show message via zenity if available, otherwise echo
_show_msg() {
  local title="$1"; shift
  local text="$*"
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="$title" --no-wrap --text="$text" || true
  else
    echo "$title: $text"
  fi
}

# Check for wine and winetricks
missing=()
if ! command -v wine >/dev/null 2>&1; then missing+=(wine); fi
if ! command -v winetricks >/dev/null 2>&1; then missing+=(winetricks); fi

if (( ${#missing[@]} )); then
  CMD="dnf install -y ${missing[*]}"

  # If zenity available, offer to install automatically using run-as-root (pkexec)
  if command -v zenity >/dev/null 2>&1; then
    if zenity --question --title="Missing dependencies" --no-wrap --text="The following packages are required but not installed: ${missing[*]}\n\nInstall them now?\n\n(You will be prompted for your password to allow package installation.)" --ok-label="Install" --cancel-label="Cancel"; then
      # Prefer run-as-root helper if available (Fedy provides bin/run-as-root)
      if command -v run-as-root >/dev/null 2>&1; then
        if ! run-as-root dnf -y install ${missing[*]}; then
          _show_msg "Error" "Automatic installation of packages failed. Please install manually with: sudo ${CMD}"
          exit 1
        fi
      else
        # Fallback to pkexec if run-as-root not found
        if ! pkexec dnf -y install ${missing[*]}; then
          _show_msg "Error" "Automatic installation of packages failed. Please install manually with: sudo ${CMD}"
          exit 1
        fi
      fi
    else
      _show_msg "Missing dependencies" "Please install the required packages first by running:\n\nsudo ${CMD}\n\nThen re-run this installer."
      exit 1
    fi
  else
    # No zenity: instruct user to install packages manually
    _show_msg "Missing dependencies" "The following packages are required but not installed: ${missing[*]}\n\nPlease install them using:\n\nsudo ${CMD}\n\nThen re-run this installer."
    exit 1
  fi

  # Re-check that requested commands are available
  for pkg in "${missing[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      _show_msg "Error" "$pkg still not available after attempted install. Aborting."
      exit 1
    fi
  done
fi

# Ensure default WINEPREFIX exists (do not overwrite if present)
if [ ! -d "$HOME/.wine" ]; then
  _show_msg "$APP_NAME — creating WINE prefix" "Creating default WINE prefix at $HOME/.wine (this may take a moment)."
  WINEPREFIX="$HOME/.wine" wineboot -i >/dev/null 2>&1 || true
fi

# Install dxvk into default prefix using winetricks
_show_msg "$APP_NAME — installing DXVK" "Installing DXVK into default WINE prefix (this may take a few minutes)."
WINEPREFIX="$HOME/.wine" winetricks -q dxvk || {
  _show_msg "Error" "winetricks failed to install DXVK. You may try running: WINEPREFIX=~/.wine winetricks dxvk"
  exit 1
}

# Create install dir and download launcher
mkdir -p "$INSTALLDIR"

if command -v curl >/dev/null 2>&1; then
  curl -fL --progress-bar -o "$INSTALLDIR/TurtleWoW.AppImage" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -q -O "$INSTALLDIR/TurtleWoW.AppImage" "$URL"
else
  _show_msg "Error" "Neither curl nor wget is available to download the launcher."
  exit 1
fi

chmod +x "$INSTALLDIR/TurtleWoW.AppImage"

# Install icon into icon theme if possible, otherwise copy to local icons
if command -v xdg-icon-resource >/dev/null 2>&1; then
  xdg-icon-resource install --novendor --size 128 "$ICON_SRC" "$ICON_NAME" || true
else
  mkdir -p "$HOME/.local/share/icons/hicolor/128x128/apps"
  cp -f "$ICON_SRC" "$HOME/.local/share/icons/hicolor/128x128/apps/$ICON_NAME.png" || true
fi

# Create desktop file
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=$DESC
Exec=$INSTALLDIR/TurtleWoW.AppImage %u
Icon=$ICON_NAME
Terminal=false
Categories=Game;
EOF

# Update desktop database if available
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

_show_msg "$APP_NAME installed" "The $APP_NAME launcher was downloaded to:\n$INSTALLDIR\nA desktop entry was created at:\n$DESKTOP_FILE"

exit 0
