#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Turtle WoW"
INSTALLDIR="$HOME/Applications/TurtleWoW"
DESKTOP_FILE="$HOME/.local/share/applications/turtlewow.desktop"
ICON_NAME="turtle"

_show_msg() {
  local title="$1"; shift
  local text="$*"
  if command -v zenity >/dev/null 2>&1; then
    zenity --question --title="$title" --no-wrap --text="$text" || return 1
  else
    echo "$title: $text"
  fi
}

# Warn the user that WINE prefix will not be deleted
_show_msg "$APP_NAME — Uninstall" "The WINE prefix (~/.wine) will NOT be deleted by this uninstaller because it may be used by other applications.\n\nPress OK to continue and remove the launcher and desktop entry, or Cancel to abort." || exit 1

# Remove installed files
if [ -d "$INSTALLDIR" ]; then
  rm -rf "$INSTALLDIR"
fi

if [ -f "$DESKTOP_FILE" ]; then
  rm -f "$DESKTOP_FILE"
fi

# Remove icon resource if possible
if command -v xdg-icon-resource >/dev/null 2>&1; then
  xdg-icon-resource uninstall --size 128 "$ICON_NAME" || true
else
  rm -f "$HOME/.local/share/icons/hicolor/128x128/apps/$ICON_NAME.png" || true
fi

# Update desktop db
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v zenity >/dev/null 2>&1; then
  zenity --info --title="$APP_NAME" --no-wrap --text="Uninstallation complete. The WINE prefix (~/.wine) was not removed." || true
else
  echo "Uninstallation complete. The WINE prefix (~/.wine) was not removed."
fi

exit 0
