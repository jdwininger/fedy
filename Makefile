# Install Fedy

install-core:
	install -dm755 $(DESTDIR)/usr/bin/
	install -dm755 $(DESTDIR)/usr/share/fedy/

	for f in *; do [[ $$f != "plugins" ]] && cp -pr $$f $(DESTDIR)/usr/share/fedy/; done

	install -Dpm 0755 fedy.exec $(DESTDIR)/usr/bin/fedy

	install -Dpm 0644 fedy.desktop $(DESTDIR)/usr/share/applications/org.folkswithhats.fedy.desktop
	install -Dpm 0644 fedy.appdata.xml $(DESTDIR)/usr/share/appdata/fedy.appdata.xml

	install -Dpm 0644 fedy.svg $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/fedy.svg
	install -Dpm 0644 fedy-symbolic.svg $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/fedy-symbolic.svg

	install -Dpm 0644 run-as-root.policy $(DESTDIR)/usr/share/polkit-1/actions/org.folkswithhats.pkexec.run-as-root.policy

	@-if test -z $(DESTDIR); then gtk-update-icon-cache -f -t $(DESTDIR)/usr/share/icons/hicolor; fi


install-plugins:
	install -dm755 $(DESTDIR)/usr/share/fedy/plugins

	cp -pr plugins/* $(DESTDIR)/usr/share/fedy/plugins/


install-user:
	@echo "Installing Fedy for current user (~/.local)..."
	install -dm755 $(HOME)/.local/bin
	install -dm755 $(HOME)/.local/share/fedy
	for f in *; do [[ $$f != "plugins" ]] && cp -pr $$f $(HOME)/.local/share/fedy/; done
	install -Dpm 0755 fedy.exec $(HOME)/.local/bin/fedy
	install -Dpm 0644 fedy.desktop $(HOME)/.local/share/applications/org.folkswithhats.fedy.desktop
	install -Dpm 0644 fedy.appdata.xml $(HOME)/.local/share/appdata/fedy.appdata.xml
	install -Dpm 0644 fedy.svg $(HOME)/.local/share/icons/hicolor/scalable/apps/fedy.svg
	install -Dpm 0644 fedy-symbolic.svg $(HOME)/.local/share/icons/hicolor/scalable/apps/fedy-symbolic.svg
	install -dm755 $(HOME)/.local/share/fedy/plugins
	cp -pr plugins/* $(HOME)/.local/share/fedy/plugins/
	@-gtk-update-icon-cache -f -t $(HOME)/.local/share/icons/hicolor || true
	@echo "Note: polkit policies cannot be installed at user level. For system-wide features please run 'sudo make install'"


install: install-core install-plugins


uninstall:
	rm -rf $(DESTDIR)/usr/share/fedy/

	rm -f $(DESTDIR)/usr/bin/fedy

	rm -f $(DESTDIR)/usr/share/applications/org.folkswithhats.fedy.desktop
	rm -f $(DESTDIR)/usr/share/appdata/fedy.appdata.xml

	rm -f $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/fedy.svg
	rm -f $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/fedy-symbolic.svg

	rm -f $(DESTDIR)/usr/share/polkit-1/actions/org.folkswithhats.pkexec.run-as-root.policy

	@-if test -z $(DESTDIR); then gtk-update-icon-cache -f -t $(DESTDIR)/usr/share/icons/hicolor; fi

uninstall-user:
	@echo "Uninstalling Fedy from current user's ~/.local..."
	# Remove user data and binaries
	rm -rf $(HOME)/.local/share/fedy/
	 rm -f $(HOME)/.local/bin/fedy

	# Remove desktop & appdata entries
	rm -f $(HOME)/.local/share/applications/org.folkswithhats.fedy.desktop
	rm -f $(HOME)/.local/share/appdata/fedy.appdata.xml

	# Remove icons from the user's icon cache area
	rm -f $(HOME)/.local/share/icons/hicolor/scalable/apps/fedy.svg
	rm -f $(HOME)/.local/share/icons/hicolor/scalable/apps/fedy-symbolic.svg

	@-gtk-update-icon-cache -f -t $(HOME)/.local/share/icons/hicolor || true
	@echo "Note: polkit policies cannot be uninstalled at user level; system features remain."
