#!/usr/bin/gjs

const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const ByteArray = imports.byteArray;

function loadJSON(path) {
    try {
        let file = Gio.File.new_for_path(path);
        if (!file.query_exists(null)) return null;
        let [ok, contents] = file.load_contents(null);
        if (!ok) return null;
        let s = (contents instanceof Uint8Array) ? ByteArray.toString(contents) : contents.toString();
        return JSON.parse(s);
    } catch (e) {
        return null;
    }
}

function runSync(cmd) {
    try {
        let [ok, stdout, stderr, status] = GLib.spawn_command_line_sync(cmd);
        let out = (stdout instanceof Uint8Array) ? ByteArray.toString(stdout) : (stdout || '');
        let err = (stderr instanceof Uint8Array) ? ByteArray.toString(stderr) : (stderr || '');
        return { ok: ok, out: out, err: err, status: status };
    } catch (e) {
        return { ok: false, out: '', err: e.message, status: 1 };
    }
}

function loadPluginsFromDir(dir) {
    let plugins = {};
    let gfile = Gio.File.new_for_path(dir);
    try {
        let enumr = gfile.enumerate_children('standard::name,standard::type', Gio.FileQueryInfoFlags.NONE, null);
        let info;
        while ((info = enumr.next_file(null)) !== null) {
            let name = info.get_name();
            if (/.*\.plugin$/.test(name)) {
                let metadata = loadJSON(dir + '/' + name + '/metadata.json');
                if (metadata && metadata.category) {
                    plugins[metadata.category] = plugins[metadata.category] || {};
                    let plugin = name.replace(/\.plugin$/, '');
                    metadata.path = dir + '/' + name;
                    metadata.slug = plugin;
                    plugins[metadata.category][plugin] = metadata;
                }
            }
        }
    } catch (e) {
        // ignore
    }
    return plugins;
}

function main() {
    let systemPlugins = loadPluginsFromDir(GLib.get_current_dir() + '/plugins');
    let userPlugins = loadPluginsFromDir(GLib.get_user_data_dir() + '/fedy/plugins');
    let plugins = Object.assign({}, systemPlugins, userPlugins);

    // flatten
    let all = [];
    for (let cat of Object.keys(plugins)) {
        for (let name of Object.keys(plugins[cat])) {
            all.push(plugins[cat][name]);
        }
    }

    let manifest = [];

    for (let p of all) {
        let checkCmd = null;
        if (p.scripts && p.scripts.status && p.scripts.status.command) {
            checkCmd = p.scripts.status.command;
        } else if (p.packages && Array.isArray(p.packages) && p.packages.length) {
            let pkgs = p.packages.map(x => x.replace(/'/g, "'\\''")).join(' ');
            checkCmd = "bash -lc 'for p in " + pkgs + "; do rpm -q \"$p\" >/dev/null 2>&1 && exit 0; done; exit 1'";
        } else if (p.flatpak && p.flatpak.app_id) {
            checkCmd = "bash -lc 'flatpak info " + p.flatpak.app_id + " >/dev/null 2>&1 && exit 0 || exit 1'";
        }

        if (!checkCmd) continue;
        let res = runSync(checkCmd);
        let installed = (res.ok && res.status === 0) || (!res.ok && res.status === 0);
        if (res.status === 0) {
            manifest.push({
                slug: p.slug || null,
                label: p.label || null,
                category: p.category || null,
                packages: p.packages || null,
                flatpak: p.flatpak || null,
                exec_command: (p.scripts && p.scripts.exec) ? p.scripts.exec.command : null,
                installed_at: (new Date()).toISOString()
            });
        }
    }

    let outpath = GLib.get_user_data_dir() + '/fedy/manifest.smoketest.json';
    try {
        let file = Gio.File.new_for_path(outpath);
        file.replace_contents(JSON.stringify(manifest, null, 2), null, false, Gio.FileCreateFlags.NONE, null);
        print('Wrote ' + manifest.length + ' entries to ' + outpath);
    } catch (e) {
        print('Failed to write manifest: ' + e.message);
    }

    if (manifest.length > 0) {
        print('Sample entry: ' + JSON.stringify(manifest[0], null, 2));
    }
}

main();
