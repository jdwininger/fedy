# Fedy

A modern, GTK4-based application for installing additional software and codecs on Fedora Linux that the distribution doesn't ship by default, such as multimedia codecs, Adobe Flash, Oracle Java, and much more.

## About

This is a fork of the original [Fedy](https://github.com/fedy/fedy) project, which appears to have been abandoned. This fork modernizes the codebase with GTK4, ES6+ JavaScript features, improved error handling, and new features like Flatpak support.

## Features

- **Modern UI**: Built with GTK4 and GJS (GNOME JavaScript)
- **Multiple Package Types**: Support for DNF/RPM packages, Flatpak applications, and custom scripts
- **Visual Enhancements**: Alternating row colors, improved spacing, and responsive button positioning
- **Flatpak Integration**: Install and uninstall Flatpak applications directly from the UI
- **Asynchronous Operations**: Non-blocking install/uninstall operations with progress indicators
- **Notifications**: Desktop notifications for task completion and errors
- **Plugin System**: Extensible plugin architecture for easy addition of new software
- **System Integration**: Proper desktop integration with icons and menu entries

## Installation

### From Source

```bash
# Install RPMFusion repositories
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install dependencies
sudo dnf install gjs gtk4 wget dnf-plugins-core flatpak

# Clone and install
git clone https://github.com/jdwininger/fedy.git
cd fedy
sudo make install

# Clean up
cd ..
rm -rf fedy
```

### Usage

After installation, launch Fedy from the applications menu or run `fedy` in the terminal.

## Plugin Types and Structure

Fedy uses a plugin-based architecture where each software package is defined in a separate plugin directory. Plugins are located in `/usr/share/fedy/plugins/` (system-wide) or `~/.local/share/fedy/plugins/` (user-specific).

Each plugin is a directory with the `.plugin` suffix containing at least a `metadata.json` file.

### Plugin Metadata Structure

```json
{
  "label": "Application Name",
  "description": "Brief description of the application",
  "category": "Apps|Games|Development Tools|Tweaks|Utilities",
  "icon": "icon-name",
  "license": "License name or array of licenses",
  "flatpak": {
    "app_id": "org.example.App"
  },
  "scripts": {
    "exec": {
      "label": "Install",
      "command": "run-as-root -s install.sh"
    },
    "undo": {
      "label": "Remove",
      "command": "run-as-root -s uninstall.sh"
    },
    "status": {
      "command": "test -f /usr/bin/app"
    },
    "show": {
      "command": "command -v app >/dev/null"
    }
  }
}
```

### Plugin Types

#### 1. DNF/RPM Packages (Traditional)

These plugins use DNF package manager for installation. They typically include shell scripts that handle package installation.

**Example structure:**
```
myapp.plugin/
├── metadata.json
├── install.sh
└── uninstall.sh
```

**metadata.json:**
```json
{
  "label": "My Application",
  "description": "Description of the app",
  "category": "Apps",
  "scripts": {
    "exec": {
      "label": "Install",
      "command": "run-as-root -s install.sh"
    },
    "undo": {
      "label": "Remove",
      "command": "run-as-root -s uninstall.sh"
    },
    "status": {
      "command": "rpm -q myapp >/dev/null"
    }
  }
}
```

#### 2. Flatpak Applications

These plugins integrate with Flatpak for sandboxed application installation. No root access required.

**metadata.json:**
```json
{
  "label": "My Flatpak App",
  "description": "Description of the Flatpak app",
  "category": "Apps",
  "flatpak": {
    "app_id": "org.example.MyApp"
  }
}
```

Fedy automatically:
- Checks if the Flatpak app is installed
- Shows "Install" or "Uninstall" button accordingly
- Handles installation/uninstallation with `flatpak install --user` / `flatpak uninstall --user`

#### 3. Custom Scripts

Plugins can run any custom commands or scripts (Bash, Python, etc.) for complex installations.

**metadata.json:**
```json
{
  "label": "Custom Tool",
  "description": "Custom installation tool",
  "category": "Utilities",
  "scripts": {
    "exec": {
      "label": "Run Setup",
      "command": "run-as-root -s setup.sh"
    }
  }
}
```

### Special Commands

- `run-as-root`: Execute commands as root
- `run-as-root -s script.sh`: Execute scripts as root
- Standard shell commands and package managers

## Development

### Prerequisites

- Fedora Linux
- GJS (GNOME JavaScript)
- GTK4 development libraries
- Flatpak (for Flatpak plugin testing)

### Building and Running

```bash
git clone https://github.com/jdwininger/fedy.git
cd fedy
./fedy  # Run directly
```

### Creating Plugins

1. Create a directory `myplugin.plugin/`
2. Add `metadata.json` with plugin configuration
3. Add installation scripts if needed
4. Place in `~/.local/share/fedy/plugins/` for testing

See existing plugins for examples.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

Please ensure new plugins follow the established patterns and include proper error handling.

## License

This project is licensed under the GNU General Public License Version 3 (GPL-3.0). See the [LICENSE](LICENSE) file for details.

The original Fedy project was also licensed under GPL-3.0, and this fork maintains compatibility with that license.

## Acknowledgments

- Original Fedy project developers
- Fedora community
- GNOME and GTK developers

## Changelog

### Recent Updates (Fork)

- Migrated to GTK4 and modern GJS
- Added ES6+ JavaScript features
- Implemented Flatpak support
- Enhanced UI with alternating colors and improved spacing
- Added comprehensive error handling
- Updated build system and dependencies
- Improved plugin system flexibility

$ git clone https://gitlab.com/fedy/fedy.git
```

### Bugs and feature requests

Please submit bugs and feature requests [here][fedy/issues]. Pull requests are
always welcome.

[fedy/issues]: https://github.com/folkswithhats/fedy/issues

### License

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see [gnu.org/licenses](http://www.gnu.org/licenses/).
