#!/usr/bin/env bash
set -euo pipefail

DEFAULT_PREFIX="$HOME/.wine"
PREFIX="$DEFAULT_PREFIX"

# helper to show messages
_show_msg() {
  local title="$1"; shift
  local text="$*"
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="$title" --no-wrap --text="$text" || true
  else
    echo "$title: $text"
  fi
}

# Ask for prefix via zenity entry or fallback to prompt
if command -v zenity >/dev/null 2>&1; then
  PREFIX=$(zenity --entry --title="Install DXVK" --text="Enter WINEPREFIX to install DXVK into:" --entry-text="$DEFAULT_PREFIX" ) || exit 1
else
  read -p "Enter WINEPREFIX to install DXVK into [$DEFAULT_PREFIX]: " input
  PREFIX=${input:-$DEFAULT_PREFIX}
fi

# Ensure winetricks available
if ! command -v winetricks >/dev/null 2>&1; then
  _show_msg "Missing dependency" "winetricks is not installed. Please install the 'Wine' plugin in Fedy or install winetricks manually and re-run this action."
  exit 1
fi

# Ensure prefix exists
if [ ! -d "$PREFIX" ]; then
  _show_msg "WINEPREFIX missing" "The specified WINEPREFIX does not exist. Creating it via wineboot (this may take a moment)."
  WINEPREFIX="$PREFIX" wineboot -i || true
fi

_show_msg "Installing DXVK" "Installing DXVK into $PREFIX (this may take a few minutes)."
WINEPREFIX="$PREFIX" winetricks -q dxvk || {
  _show_msg "Error" "winetricks failed to install DXVK into $PREFIX. You may try: WINEPREFIX=\"$PREFIX\" winetricks dxvk"
  exit 1
}

_show_msg "Done" "DXVK installed into $PREFIX"
exit 0
