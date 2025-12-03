#!/usr/bin/gjs

imports.searchPath.unshift('.');
// Pick explicit GI versions to avoid warnings when multiple versions are present.
if (!imports.gi.versions) imports.gi.versions = {};
// Use GTK4 / GDK4 and the traditional gdk-pixbuf 2.0 bindings
imports.gi.versions.Gtk = '4.0';
imports.gi.versions.Gdk = '4.0';
imports.gi.versions.GdkPixbuf = '2.0';

const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
const GdkPixbuf = imports.gi.GdkPixbuf;
const Notify = imports.gi.Notify;
const Pango = imports.gi.Pango;
const Lang = imports.lang;
const System = imports.system;
const FedyCli = imports.cli.FedyCli;
const ByteArray = imports.byteArray;

const APP_NAME = "Fedy";

const Application = new Lang.Class({
    Name: APP_NAME,

    _init: function() {
        this.application = new Gtk.Application({
            application_id: "org.folkswithhats.fedy",
            flags: Gio.ApplicationFlags.FLAGS_NONE
        });

        this.application.connect("activate", Lang.bind(this, this._onActivate));
        this.application.connect("startup", Lang.bind(this, this._onStartup));

        this.cli = new FedyCli(this);

        Notify.init(APP_NAME);
    },

    _buildUI: function() {
        this._window = new Gtk.Window({
                application: this.application,
                title: APP_NAME
            });

        try {
            // Prefer bundled icon files (SVG then PNG) and fall back to theme name "fedy".
            let cwd = GLib.get_current_dir();
            let svgPath = cwd + "/fedy.svg";
            let pngPath = cwd + "/fedy.png";

            function _usePixmapPath(path) {
                try {
                    // Try to load into a Pixbuf and set it as the window icon if supported.
                    let pix = GdkPixbuf.Pixbuf.new_from_file(path);

                    if (typeof this._window.set_icon === 'function') {
                        this._window.set_icon(pix);
                        return true;
                    } else if (typeof this._window.set_icon_from_file === 'function') {
                        this._window.set_icon_from_file(path);
                        return true;
                    }

                    return false;
                } catch (e) {
                    return false;
                }
            }

            if (Gio.File.new_for_path(svgPath).query_exists(null)) {
                if (!_usePixmapPath.call(this, svgPath)) {
                    this._window.set_icon_name("fedy");
                }
            } else if (Gio.File.new_for_path(pngPath).query_exists(null)) {
                if (!_usePixmapPath.call(this, pngPath)) {
                    this._window.set_icon_name("fedy");
                }
            } else {
                this._window.set_icon_name("fedy");
            }
        } catch (e) {
            print("Failed to load application icon: " + e.message);
        }

        this._headerbar = new Gtk.HeaderBar({ show_title_buttons: true });

        this._renderPlugins();

        this._window.set_default_size(800, 600);
        this._window.set_titlebar(this._headerbar);
        this._window.show();

        // Hide the window if any task is running
        this._window.connect("close-request", w => {
            if (this._queue && this._queue.length) {
                w.hide();

                return true;
            }

            return false;
        });
    },

    _onActivate: function() {
        this._window.present();
    },

    _onStartup: function() {
        try {
            this._loadConfig();
            this._loadPlugins();
            this._buildUI();
        } catch (e) {
            print("Error during startup: " + e.message);
            this.application.quit();
        }
    },

    _hashString: function(str) {
        let hash = 0;

        for (let i = 0; i < str.length; i++) {
            hash += str.charCodeAt(i);
        }

        return hash;
    },

    _extendObject: function(...objs) {
        let orig = objs[0];

        if (typeof orig !== "object" || orig === null) {
            return orig;
        }

        for (let i = 1, l = objs.length; i < l; i++) {
            if (typeof objs[i] !== "object" || objs[i] === null) {
                return orig;
            }

            for (let o in objs[i]) {
                if (objs[i].hasOwnProperty(o)) {
                    if (typeof orig[o] === "object") {
                        this._extendObject(orig[o], objs[i][o]);
                    } else {
                        orig[o] = objs[i][o];
                    }
                }
            }
        }

        return orig;
    },

    _loadJSON: function(path) {
        let parsed;

        let file = Gio.File.new_for_path(path);

        if (file.query_exists(null)) {
            let size = file.query_info("standard::size",
                                       Gio.FileQueryInfoFlags.NONE,
                                       null).get_size();

            try {
                let data = file.read(null).read_bytes(size, null).get_data();
                let content = (data instanceof Uint8Array) ? ByteArray.toString(data) : data.toString();
                parsed = JSON.parse(content);
            } catch (e) {
                print("Error loading file " + file.get_path() + " : " + e.message);
            }
        }

        return parsed;
    },

    _showDialog: function(modal = {}, callback = () => {}) {
        let type, buttons;

        switch (modal.type) {
        case "info":
            type = Gtk.MessageType.INFO;
            buttons = Gtk.ButtonsType.OK;
            break;
        case "warning":
            type = Gtk.MessageType.WARNING;
            buttons = Gtk.ButtonsType.OK_CANCEL;
            break;
        case "question":
            type = Gtk.MessageType.QUESTION;
            buttons = Gtk.ButtonsType.YES_NO;
            break;
        default:
            type = Gtk.MessageType.OTHER;
            buttons = Gtk.ButtonsType.NONE;
            break;
        }

        let dialog = new Gtk.MessageDialog({
            modal: true,
            message_type: type,
            buttons: buttons,
            text: modal.text || "",
            use_markup: true,
            transient_for: this._window
        });

        dialog.connect("response", (...args) => {
            callback.apply(this, args);

            dialog.destroy();
        });

        // GTK4 doesn't expose show_all(), use show() instead
        if (typeof dialog.show === 'function') {
            dialog.show();
        } else if (typeof dialog.set_visible === 'function') {
            dialog.set_visible(true);
        }
    },

    _executeCommand: function(workingdir, command, callback = () => {}, spawnFlags = GLib.SpawnFlags.SEARCH_PATH_FROM_ENVP | GLib.SpawnFlags.DO_NOT_REAP_CHILD) {
        let [ status, argvp ] = GLib.shell_parse_argv(command);

        if (status === false) {
            callback(null, 1, new Error("Failed to parse command: " + command));
            return;
        }

        let envp = GLib.get_environ();

        let currdir = GLib.get_current_dir();

        let path = GLib.environ_getenv(envp, "PATH");

        envp = GLib.environ_setenv(envp, "PATH", path + ":" + currdir + "/bin", true);

        let ok, pid;

        try {
            [ ok, pid ] = GLib.spawn_async(workingdir, argvp, envp,
                                       spawnFlags, null);
        } catch (e) {
            print("Failed to run process: " + e.message);

            callback(null, 1, e);
            return;
        }

        if (ok === false) {
            callback(pid, 1, new Error("Failed to spawn process"));
            return;
        }

        if (typeof pid === "number") {
            GLib.child_watch_add(GLib.PRIORITY_DEFAULT, pid, (...args) => {
                GLib.spawn_close_pid(pid);

                callback.apply(this, args);
            });
        }
    },

    _queueCommand: function(...args) {
        function run(wd, cmd, cb) {
            this._executeCommand(wd, cmd, (...a) => {
                this._queue.splice(0, 1);

                cb.apply(this, a);

                if (this._queue.length) {
                    run.apply(this, this._queue[0]);
                }
            });
        }

        this._queue = this._queue || [];

        this._queue.push(args);

        if (this._queue.length === 1) {
            run.apply(this, args);
        }
    },

    _scanMaliciousCommand: function(plugin, command) {
        let mal = this._config.malicious || [];

        let parts = command.split(";");

        parts.push(command);

        let scripts = command.match(/\S+\.(sh|bash)/);

        if (Array.isArray(scripts)) {
            for (let script of scripts) {
                let file = Gio.File.new_for_path(plugin.path + "/" + script);

                if (file.query_exists(null)) {
                    let size = file.query_info("standard::size",
                                               Gio.FileQueryInfoFlags.NONE,
                                               null).get_size();

                    try {
                        let stream = file.open_readwrite(null).get_input_stream();
                        let data = stream.read_bytes(size, null).get_data();
                        let content = (data instanceof Uint8Array) ? ByteArray.toString(data) : data.toString();

                        stream.close(null);

                        let lines = content.split(/\n/);

                        parts = parts.concat(lines);
                    } catch (e) {
                        continue;
                    }
                }
            }
        }

        parts = parts.map(p => p.trim()).filter((p, i, s) => {
            return /^[^#]/.test(p) && p.length > 1 && s.indexOf(p) === i;
        });

        for (let item of mal) {
            if (Array.isArray(item.variations)) {
                for (let s of item.variations) {
                    let reg;

                    try {
                        reg = new RegExp(s);
                    } catch (e) {
                        print("Error parsing regex: " + e.message);

                        continue;
                    }

                    for (let p of parts) {
                        let malicious = reg.test(p);

                        if (malicious) {
                            return [ true, p, item.description ];
                        }
                    }
                }
            }
        }

        return [ false, null, null ];
    },

    _runPluginCommand: function(plugin, cmd, cb = () => {}, runner = () => {}) {
        let [ malicious, command, description ] = this._scanMaliciousCommand(plugin, cmd);

        if (malicious) {
            this._showDialog({
                type: "question",
                text: "The plugin <b>" + GLib.markup_escape_text(plugin.label, -1) + "</b> is trying to run the command \n" +
                      "<tt>" + GLib.markup_escape_text(command, -1) + "</tt>, \n" +
                      "which might <b>" + GLib.markup_escape_text(description, -1) + "</b>. \n" +
                      "Continue anyways?"
            }, (dialog, response) => {
                switch (response) {
                case Gtk.ResponseType.YES:
                    runner.call(this, plugin.path, cmd, cb);
                    break;
                default:
                    cb(null, 1);
                    break;
                }
            });

            return;
        }

        runner.call(this, plugin.path, cmd, cb);
    },

    _getPluginStatus: function(plugin, callback) {
        if (typeof callback !== "function") {
            return;
        }

        let scripts = plugin.scripts;

        if (scripts.status && scripts.status.command) {
            this._runPluginCommand(plugin, scripts.status.command, (pid, status) => {
                if (status === 0) {
                    callback(scripts.undo, status);
                } else {
                    callback(scripts.exec, status);
                }
            }, this._executeCommand);
        } else {
            callback(scripts.exec, 1);
        }
    },

    _setButtonState: function(button, plugin) {
        this._getPluginStatus(plugin, (action, status) => {
            button.set_label(action.label);

            if (status === 0) {
                button.get_style_context().add_class("destructive-action");
            } else {
                button.get_style_context().add_class("suggested-action");
            }

            button.set_sensitive(!!action.command);
        });
    },

    _handleTask: function(button, spinner, plugin) {
        try {
            spinner.start();

            button.set_label("Working...");
            button.get_style_context().remove_class("suggested-action");
            button.get_style_context().remove_class("destructive-action");
            button.set_sensitive(false);

            this._getPluginStatus(plugin, (action) => {
                this._runPluginCommand(plugin, action.command, (pid, status, error) => {

                    let summary, body, urgency = Notify.Urgency.NORMAL;

                    if (error) {
                        summary = "Task failed!";
                        body = plugin.label + " (" + action.label + ") failed with error: " + error.message;
                        urgency = Notify.Urgency.CRITICAL;
                    } else if (status === 0) {
                        summary = "Task completed!";
                        body = plugin.label + " (" + action.label + ") successfully completed.";
                    } else {
                        summary = "Task failed!";
                        body = plugin.label + " (" + action.label + ") failed with exit code " + status;
                        urgency = Notify.Urgency.CRITICAL;
                    }

                    try {
                        const notification = new Notify.Notification({
                            summary: summary,
                            body: body,
                            icon_name: "fedy",
                            id: this._hashString(plugin.category + plugin.label)
                        });

                        notification.set_urgency(urgency);
                        notification.set_timeout(1000);
                        notification.show();
                    } catch (e) {
                        print("Failed to show notification: " + e.message);
                    }

                    if (!this._window.visible && !(this._queue && this._queue.length)) {
                        this._window.close();

                        return;
                    }

                    spinner.stop();

                    if (status === 0) {
                        button.set_label("Finished!");
                    } else {
                        button.set_label("Error!");
                    }

                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
                        this._setButtonState(button, plugin);

                        return false;
                    }, null);
                }, this._queueCommand);
            });
        } catch (e) {
            print("Error in _handleTask: " + e.message);
            spinner.stop();
            button.set_sensitive(true);
        }
    },

    _renderPlugins: function() {
        this._css_provider = new Gtk.CssProvider();
        this._css_provider.load_from_string(`
            .even-row {
                background-color: rgba(173, 216, 230, 0.5);
            }
            .odd-row {
                background-color: rgba(255, 255, 255, 0.02);
            }

            /* Target buttons inside plugin list views to ensure a consistent
             * color scheme for Install/Uninstall actions across themes. We
             * still prefer theme classes but provide explicit coloring here
             * so the buttons match other action buttons visually. */
            .view button.suggested-action {
                background-image: none;
                background-color: #007AFF;
                color: #ffffff;
            }
            .view button.suggested-action:hover {
                background-color: #0062d6;
            }

            .view button.destructive-action {
                background-image: none;
                background-color: #D64545;
                color: #ffffff;
            }
            .view button.destructive-action:hover {
                background-color: #b53232;
            }

            /* Flatpak buttons now use theme-provided action classes
               (suggested-action/destructive-action) so their colors match
               the rest of the UI and respect the current GTK theme. */
        `);
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), this._css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        let stack = new Gtk.Stack({ transition_type: Gtk.StackTransitionType.CROSSFADE });

        stack.set_vexpand(true);

        this._panes = {};

        let categoryOrder = ["Apps", "Games", "Development Tools", "Tweaks", "Utilities"];

        let categories = Object.keys(this._plugins).sort((a, b) => {
            let indexA = categoryOrder.indexOf(a);
            let indexB = categoryOrder.indexOf(b);
            if (indexA === -1) indexA = categoryOrder.length;
            if (indexB === -1) indexB = categoryOrder.length;
            return indexA - indexB;
        });

        let switcher;

        if (categories.length === 0) {
            switcher = APP_NAME;
        } else if (categories.length === 1) {
            switcher = categories[0];
        } else {
            switcher = new Gtk.StackSwitcher({ stack: stack });
            switcher.get_style_context().add_class('header-switcher');
        }

        let sort = (row1, row2) => {
            let label1 = row1.get_child().get_child_at(1, 1).get_label(),
                label2 = row2.get_child().get_child_at(1, 1).get_label();

            if (label1 > label2) {
                return 1;
            } else if (label1 < label2) {
                return -1;
            } else {
                return 0;
            }
        };

        let settooltip = plugin => {
            return ((l, x, y, k, tip) => {
                if (l.get_layout().is_ellipsized()) {
                    tip.set_text(plugin.description);

                    return true;
                }

                return false;
            });
        };

        let setvisible = (plugin, grid) => {
            this._runPluginCommand(plugin, plugin.scripts.show.command, (pid, status) => {
                grid.set_visible(status === 0);
            }, this._executeCommand);
        };

        for (let category of categories) {
            this._panes[category] = new Gtk.ScrolledWindow();

            let list = new Gtk.ListBox({ selection_mode: Gtk.SelectionMode.NONE });

            list.get_style_context().add_class("view");
            list.row_spacing = 15;

            let sortedItems = Object.keys(this._plugins[category]).sort();

            let pluginIndex = 0;

            for (let item of sortedItems) {
                let plugin = this._plugins[category][item];
                print('fedy: loading plugin ' + plugin.category + '::' + plugin.label);

                let grid = new Gtk.Grid({
                    row_spacing: 5,
                    column_spacing: 10,
                    margin_start: 10,
                    margin_end: 10,
                    margin_top: 10,
                    margin_bottom: 10
                });

                grid.get_style_context().add_class(pluginIndex % 2 === 0 ? "even-row" : "odd-row");

                let image = new Gtk.Image();

                image.set_pixel_size(48);

                let icon;

                if (plugin.icon) {
                    let formats = [ "", ".svg", ".png" ];

                    for (let ext of formats) {
                        let path = plugin.path + "/" + plugin.icon + ext;

                        if (Gio.File.new_for_path(path).query_exists(null)) {
                            image.set_from_file(path);
                            break;
                        }
                    }

                    if (!image.get_paintable()) {
                        image.set_from_icon_name(plugin.icon);
                    }
                }

                if (!image.get_paintable()) {
                    image.set_from_icon_name("system-run");
                }

                grid.attach(image, 0, 1, 1, 2);

                let label = new Gtk.Label({
                    halign: Gtk.Align.START
                });

                label.set_markup("<b>" + plugin.label + "</b>");

                grid.attach(label, 1, 1, 1, 1);

                let license = new Gtk.Label({
                    halign: Gtk.Align.START
                });

                if (plugin.license !== null) {
                    license.set_text((Array.isArray(plugin.license) ? plugin.license.join(", ") : plugin.license) || "");
                    license.set_opacity(0.7);
                }

                grid.attach_next_to(license, label, Gtk.PositionType.RIGHT, 1, 1);

                let description = new Gtk.Label({
                    label: plugin.description,
                    halign: Gtk.Align.START
                });

                description.set_ellipsize(Pango.EllipsizeMode.END);
                description.set_has_tooltip(true);

                description.connect("query_tooltip", settooltip(plugin));

                grid.attach(description, 1, 2, 2, 1);

                if (plugin.scripts) {
                    if (plugin.scripts.exec) {
                        let spinner = new Gtk.Spinner();

                        grid.attach(spinner, 2, 1, 1, 2);

                        let box = new Gtk.Box({
                            orientation: Gtk.Orientation.VERTICAL,
                            halign: Gtk.Align.END,
                            hexpand: true
                        });

                        let button = new Gtk.Button({
                            label: plugin.scripts.exec.label,
                            sensitive: false
                        });

                        this._setButtonState(button, plugin);

                        button.connect("clicked", () => this._handleTask(button, spinner, plugin));

                        box.append(button);

                        grid.attach(box, 3, 1, 1, 2);
                    }

                    if (plugin.scripts.show && plugin.scripts.show.command) {
                        setvisible(plugin, grid);
                    }
                }

                if (plugin.flatpak) {
                    let spinner = new Gtk.Spinner();

                    grid.attach(spinner, 2, 1, 1, 2);

                    let box = new Gtk.Box({
                        orientation: Gtk.Orientation.VERTICAL,
                        halign: Gtk.Align.END,
                        hexpand: true
                    });

                    let button = new Gtk.Button({
                        label: "Checking...",
                        sensitive: false
                    });

                    this._setFlatpakButtonState(button, plugin, spinner);

                    button.connect("clicked", () => this._handleFlatpakTask(button, spinner, plugin));

                    box.append(button);

                    grid.attach(box, 3, 1, 1, 2);
                }

                list.append(grid);

                pluginIndex++;
            }

            this._panes[category].set_child(list);

            stack.add_titled(this._panes[category], category, category);
        }

        let searchentry = new Gtk.SearchEntry();

        searchentry.connect("search_changed", (entry) => {
            let searchtext = entry.get_text().toLowerCase();

            let filter = (row) => {
                let items = row.get_children()[0].get_children(),
                    title = items[4].get_label(),
                    description = items[2].get_label();

                return (title + description).toLowerCase().indexOf(searchtext) > -1;
            };

            let children = stack.get_children();

            for (let child of children) {
                let listbox = child.get_children()[0].get_children()[0];

                listbox.set_filter_func(filter);
            }
        });

        let searchbar = new Gtk.SearchBar();

        searchbar.set_child(searchentry);
        searchbar.connect_entry(searchentry);

        let searchicon = new Gtk.Image();

        searchicon.set_from_icon_name("edit-find-symbolic");

        let searchbutton = new Gtk.ToggleButton();

        searchbutton.set_child(searchicon);
        searchbutton.get_style_context().add_class('header-button');

        searchbutton.connect("toggled", b => searchbar.set_search_mode(b.get_active()));

        let gearicon = new Gtk.Image();
        gearicon.set_from_icon_name("preferences-system-symbolic");

        let gearbutton = new Gtk.Button();
        gearbutton.set_child(gearicon);
        gearbutton.get_style_context().add_class('header-button');
        gearbutton.connect("clicked", () => this._showOptionsDialog());

        // GTK4 HeaderBar uses append/prepend rather than pack_end/pack_start
        if (typeof this._headerbar.append === 'function') {
            this._headerbar.append(gearbutton);
            this._headerbar.append(searchbutton);
        } else if (typeof this._headerbar.pack_end === 'function') {
            this._headerbar.pack_end(gearbutton);
            this._headerbar.pack_end(searchbutton);
        }

        // GTK4 HeaderBar may not expose set_title / set_title_widget the same way
        try {
            if (typeof switcher === "string") {
                // Create a centered label for the title
                let titleLabel = new Gtk.Label({ label: switcher });

                    if (typeof this._headerbar.set_title_widget === 'function') {
                        this._headerbar.set_title_widget(titleLabel);
                    } else if (typeof this._headerbar.prepend === 'function') {
                        // prepend puts widget at the start on GTK4
                        this._headerbar.prepend(titleLabel);
                    } else if (typeof this._headerbar.pack_start === 'function') {
                        // fallback for older APIs
                        this._headerbar.pack_start(titleLabel);
                    } else if (typeof this._headerbar.append === 'function') {
                        this._headerbar.append(titleLabel);
                    }
            } else {
                // switcher is a widget (Gtk.StackSwitcher)
                if (typeof this._headerbar.set_title_widget === 'function') {
                    this._headerbar.set_title_widget(switcher);
                } else if (typeof this._headerbar.prepend === 'function') {
                    this._headerbar.prepend(switcher);
                } else if (typeof this._headerbar.pack_start === 'function') {
                    this._headerbar.pack_start(switcher);
                } else if (typeof this._headerbar.append === 'function') {
                    this._headerbar.append(switcher);
                }
            }
        } catch (e) {
            // Non-fatal; continue without a title widget if API differs
        }

        let vbox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL });

        vbox.append(searchbar);
        vbox.append(stack);

        this._window.set_child(vbox);
    },

    _showOptionsDialog: function() {
        let dialog = new Gtk.Dialog({
            title: "Options",
            modal: true,
            transient_for: this._window
        });

        dialog.add_button("Close", Gtk.ResponseType.CLOSE);

        let content = dialog.get_content_area();
        content.set_margin_start(20);
        content.set_margin_end(20);
        content.set_margin_top(20);
        content.set_margin_bottom(20);

        let label = new Gtk.Label({ label: "No options available." });
        content.append(label);

        dialog.connect("response", () => dialog.destroy());
        dialog.show();
    },

    _setFlatpakButtonState: function(button, plugin, spinner) {
        let app_id = plugin.flatpak.app_id;
        // Use flatpak info which returns non-zero when not installed — avoid shell pipes
        // Hide stdout/stderr so terminal control sequences from flatpak do not leak to the console
        const hideOutputFlags = GLib.SpawnFlags.SEARCH_PATH_FROM_ENVP | GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.STDOUT_TO_DEV_NULL | GLib.SpawnFlags.STDERR_TO_DEV_NULL;
        this._executeCommand(null, "flatpak info --user " + app_id, (pid, status) => {
            // status 0 means installed for the user
            button.label = status === 0 ? "Uninstall" : "Install";
            // Apply flatpak button style classes
            try {
                button.get_style_context().remove_class('suggested-action');
                button.get_style_context().remove_class('destructive-action');
                if (button.label === 'Install') {
                    button.get_style_context().add_class('suggested-action');
                } else {
                    button.get_style_context().add_class('destructive-action');
                }
            } catch (e) {
                // ignore if style_context not available
            }
            button.sensitive = true;
            spinner.stop();
        }, hideOutputFlags);
    },

    _handleFlatpakTask: function(button, spinner, plugin) {
        spinner.start();
        button.sensitive = false;
        let app_id = plugin.flatpak.app_id;
        // Default to installing from flathub when no remote specified
        let installCmd = "flatpak install --user -y flathub " + app_id;
        let uninstallCmd = "flatpak uninstall --user -y " + app_id;
        let command = button.label === "Install" ? installCmd : uninstallCmd;
        // Hide flatpak output (progress escapes) so the terminal or app console isn't littered
        const hideOutputFlags = GLib.SpawnFlags.SEARCH_PATH_FROM_ENVP | GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.STDOUT_TO_DEV_NULL | GLib.SpawnFlags.STDERR_TO_DEV_NULL;
        this._executeCommand(null, command, (pid, status) => {
            spinner.stop();
                if (status === 0) {
                // Toggle label and classes
                button.label = button.label === "Install" ? "Uninstall" : "Install";
                try {
                    button.get_style_context().remove_class('suggested-action');
                    button.get_style_context().remove_class('destructive-action');
                    if (button.label === 'Install') {
                        button.get_style_context().add_class('suggested-action');
                    } else {
                        button.get_style_context().add_class('destructive-action');
                    }
                } catch (e) {}
                // Show success notification
                try {
                    const notification = new Notify.Notification({
                        summary: "Task completed!",
                        body: plugin.label + " (" + (button.label === "Uninstall" ? "installed" : "uninstalled") + ") successfully.",
                        icon_name: "fedy"
                    });
                    notification.set_timeout(1000);
                    notification.show();
                } catch (e) {
                    print("Failed to show notification: " + e.message);
                }
            } else {
                // Try adding flathub remote and retry installation if install failed
                if (button.label === "Install") {
                    // add the remote for the current user (we default to user installs)
                    this._executeCommand(null, "flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo", (pid2, status2) => {
                        // Try install again once
                        this._executeCommand(null, installCmd, (pid3, status3) => {
                            if (status3 === 0) {
                                button.label = "Uninstall";
                                try {
                                    const notification = new Notify.Notification({
                                        summary: "Task completed!",
                                        body: plugin.label + " (installed) successfully.",
                                        icon_name: "fedy"
                                    });
                                    notification.set_timeout(1000);
                                    notification.show();
                                } catch (e) {
                                    print("Failed to show notification: " + e.message);
                                }
                            } else {
                                // Capture stderr for helpful diagnostics
                                try {
                                    let [ok, out, err, exit] = GLib.spawn_command_line_sync(installCmd);
                                    let reason = (err && err.length) ? (typeof err === 'string' ? err : ByteArray.toString(err)) : 'Unknown error';

                                    if (/No remote refs found/.test(reason)) {
                                        this._showDialog({ type: 'error', text: 'Install failed: the app id is not available from the remote (no remote refs found). ' + GLib.markup_escape_text(reason, -1) });
                                    } else if (/network|failed to download|Connection timed out|Could not resolve host/i.test(reason)) {
                                        this._showDialog({ type: 'error', text: 'Install failed due to network/remote access issues. ' + GLib.markup_escape_text(reason, -1) });
                                    } else {
                                        this._showDialog({ type: 'error', text: 'Install failed: ' + GLib.markup_escape_text(reason, -1) });
                                    }
                                } catch (e) {
                                    this._showDialog({ type: 'error', text: 'Install failed (no further diagnostics available).' });
                                }
                                }
                                // Ensure button is re-enabled for the user after retry attempt
                                button.sensitive = true;
                        }, hideOutputFlags);
                    }, hideOutputFlags);
                } else {
                    // Uninstall failed — capture stderr for diagnostics
                    try {
                        let [ok, out, err, exit] = GLib.spawn_command_line_sync(uninstallCmd);
                        let reason = (err && err.length) ? (typeof err === 'string' ? err : ByteArray.toString(err)) : 'Unknown error';
                        if (/not installed/i.test(reason)) {
                            this._showDialog({ type: 'info', text: 'Uninstall: the app does not appear to be installed. ' + GLib.markup_escape_text(reason, -1) });
                        } else {
                            this._showDialog({ type: 'error', text: 'Uninstall failed: ' + GLib.markup_escape_text(reason, -1) });
                        }
                    } catch (e) {
                        this._showDialog({ type: 'error', text: 'Uninstall failed (no further diagnostics available).' });
                    }
                }
            }
            button.sensitive = true;
        }, hideOutputFlags);
    },

    _loadPluginsFromDir: function(plugindir) {
        let plugins = {};

        let dir = Gio.File.new_for_path(plugindir);

        let fileEnum;

        try {
            fileEnum = dir.enumerate_children("standard::name,standard::type",
                                              Gio.FileQueryInfoFlags.NONE, null);
        } catch (e) {
            fileEnum = null;
        }

        if (fileEnum !== null) {
            let info;

            while ((info = fileEnum.next_file(null)) !== null) {
                let name = info.get_name();

                if (/.*\.plugin$/.test(name)) {
                    let parsed = this._loadJSON(plugindir + "/" + name + "/metadata.json");

                    if (parsed && parsed.category) {
                        plugins[parsed.category] = plugins[parsed.category] || {};

                        let plugin = name.replace(/\.plugin$/, "");

                        plugins[parsed.category][plugin] = parsed;
                        plugins[parsed.category][plugin].path = plugindir + "/" + name;
                    }
                }
            }
        }

        return plugins;
    },

    _loadPlugins: function() {
        this._plugins = {};

        // System plugins
        let system = this._loadPluginsFromDir(GLib.get_current_dir() + "/plugins");

        // User plugins
        let user = this._loadPluginsFromDir(GLib.get_user_data_dir() + "/fedy/plugins");

        this._extendObject(this._plugins, system, user);
    },

    _loadConfig: function() {
        this._config = {};

        // System config
        let system = this._loadJSON(GLib.get_current_dir() + "/config.json");

        // User config
        let user = this._loadJSON(GLib.get_user_data_dir() + "/fedy/config.json");

        this._extendObject(this._config, system, user);
    },
});

let app = new Application();

app.application.run([System.programInvocationName].concat(ARGV));
