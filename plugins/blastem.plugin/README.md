Place the provided BlastEm icon file (e.g. `blastem.png`) into this directory.

Files in this plugin:
  - `metadata.json`  : Plugin metadata used by Fedy
  - `install.sh`     : Installs `com.retrodev.blastem` from Flathub for the current user
  - `uninstall.sh`   : Uninstalls the Flatpak for the current user
  - `status.sh`      : Exit code 0 if installed, non-zero otherwise
  - `show.sh`        : Runs `flatpak run com.retrodev.blastem`

Usage notes:
- This plugin prefers user installs (`flatpak install --user`). If you want system-wide installs, adjust `install.sh` accordingly.
- Make scripts executable: `chmod +x install.sh uninstall.sh status.sh show.sh`
