#!/usr/bin/gjs
// Simulate fallback installs for manifest entries (flatpak/packages/exec)

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

function writeFile(path, content) {
    try {
        Gio.File.new_for_path(path).replace_contents(content, null, false, Gio.FileCreateFlags.NONE, null);
    } catch (e) {
        print('Failed to write ' + path + ': ' + e.message);
    }
}

function simulateCommand(cmd, idx, entry, base) {
    let outFile = base + '-' + idx + '.out';
    let errFile = base + '-' + idx + '.err';
    let exitFile = base + '-' + idx + '.exit';

    // Simple heuristics for simulation: if 'flatpak' in cmd -> success; if 'libdvdcss' -> success; if 'dnf' and other odd package -> simulate repo SSL error
    let out = '';
    let err = '';
    let exit = 0;

    if (cmd.indexOf('flatpak') !== -1) {
        out = '[FLATPAK] Installed ' + (entry.flatpak ? entry.flatpak.app_id : '') + '\n';
        err = '';
        exit = 0;
    } else if (cmd.indexOf('libdvdcss') !== -1) {
        out = 'Package "libdvdcss" is already installed.\n';
        err = '';
        exit = 0;
    } else if (cmd.indexOf('dnf') !== -1) {
        // Simulate a repository SSL error for some packages to mirror the user's earlier output
        if (cmd.indexOf('livna') !== -1 || cmd.indexOf('badrepo') !== -1) {
            out = '';
            err = 'Failed to download files\n Librepo error: Curl error (60): SSL peer certificate or SSH remote key was not OK for https://rpm.livna.org/livna-release.rpm [SSL certificate problem: self-signed certificate]\n';
            exit = 1;
        } else {
            out = 'Installing packages...\nDone.\n';
            err = '';
            exit = 0;
        }
    } else {
        // Exec command: simulate running and succeeding
        out = '[EXEC] Simulated run of: ' + cmd + '\n';
        err = '';
        exit = 0;
    }

    writeFile(outFile, out);
    writeFile(errFile, err);
    writeFile(exitFile, String(exit));

    return { out: out, err: err, exit: exit };
}

function main() {
    let path = GLib.get_user_data_dir() + '/fedy/manifest.json';
    let manifest = loadJSON(path) || [];

    if (!manifest.length) {
        print('Manifest is empty. Nothing to do.');
        return;
    }

    // Gather fallbackable entries
    let fallback = [];
    for (let e of manifest) {
        let fb = null;
        if (e.flatpak && e.flatpak.app_id) {
            let remote = e.flatpak.remote ? (e.flatpak.remote + ' ') : '';
            fb = 'flatpak install --user -y ' + remote + e.flatpak.app_id;
        } else if (e.packages && Array.isArray(e.packages) && e.packages.length) {
            let pkgs = e.packages.map(x => x).join(' ');
            fb = 'dnf -y install ' + pkgs;
        } else if (e.exec_command) {
            fb = e.exec_command;
        }

        if (fb) fallback.push({ entry: e, command: fb });
    }

    print('Found ' + fallback.length + ' fallbackable entries out of ' + manifest.length + ' total. Running simulation on first 8.');

    let base = '/tmp/fedy-fallback-test-' + Date.now();
    let toRun = fallback.slice(0, 8);
    for (let i = 0; i < toRun.length; i++) {
        let f = toRun[i];
        print('\n-- Simulating fallback for ' + (f.entry.label || f.entry.slug || 'unknown') + ': ' + f.command);
        let r = simulateCommand(f.command, i, f.entry, base);
        print('exit=' + r.exit);
        if (r.out) print('STDOUT:\n' + r.out.trim());
        if (r.err) print('STDERR:\n' + r.err.trim());

        if (r.exit !== 0) {
            print('-> Simulated failure for this fallback entry, stopping further fallback installs.');
            break;
        }
    }

    print('\nFallback simulation finished. Logs written to ' + base + '-<n>.{out,err,exit}');
}

main();
