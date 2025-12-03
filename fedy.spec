Name:           fedy
Version:        5.0.0
Release:        1%{?dist}
Summary:        Install codecs and additional software with GTK4 and Flatpak support

Group:          System/Management
License:        GPLv3+
URL:            https://github.com/jdwininger/fedy
Source0:        https://github.com/jdwininger/%{name}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  desktop-file-utils
BuildRequires:  libappstream-glib

# Obsoletes introduced in f26
Provides: fedy-core = %{version}-%{release}
Obsoletes: fedy-core < 4.5.1-1
Provides: fedy-plugins = %{version}-%{release}
Obsoletes: fedy-plugins < 4.5.1-1

Requires: dnf-plugins-core
Requires: gjs
Requires: gtk4
Requires: libnotify
Requires: rpmfusion-free-release
Requires: rpmfusion-nonfree-release
Requires: sed
Requires: tar
Requires: wget
Requires: jq
Requires: flatpak


%description
Fedy lets you install multimedia codecs and additional software that Fedora
doesn't want to ship, like mp3 support, Adobe Flash, Oracle Java etc., and
much more with just a few clicks. This modern version includes GTK4 support,
Flatpak integration, and improved UI with alternating row colors.


%prep
%autosetup -p1


%build
#Nothing to build


%install
%make_install

# Validate desktop file
desktop-file-validate \
  %{buildroot}%{_datadir}/applications/*%{name}.desktop

# Validate appdata file
appstream-util validate-relax \
  %{buildroot}%{_datadir}/appdata/%{name}.appdata.xml


%files
%license LICENSE
%doc CREDITS README.md
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/*.%{name}.desktop
%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg
%{_datadir}/icons/hicolor/scalable/apps/%{name}-symbolic.svg
%{_datadir}/polkit-1/actions/org.folkswithhats.pkexec.run-as-root.policy
%{_datadir}/appdata/%{name}.appdata.xml


%changelog
* Mon Nov 18 2025 Jeremy Wininger <jeremy@example.com> - 5.0.0-1
- Modernize codebase: GTK4 migration, ES6+ JavaScript
- Add Flatpak install/uninstall support with status checking
- Implement alternating row colors and improved UI spacing
- Reorder tabs: rename "Themes" to "Games"
- Add comprehensive error handling and async operations
- Update dependencies: gtk4, flatpak
- Flesh out .gitignore and README.md
- Confirm GPL-3.0 license
- Update repository URL to fork
