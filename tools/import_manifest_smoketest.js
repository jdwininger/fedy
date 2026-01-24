#!/usr/bin/gjs
// Simulate the in-app import self-test run to validate per-item logs and cancel behavior.

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

function readFile(path) {
    try {
        let [ok, buf] = Gio.File.new_for_path(path).load_contents(null);
        if (!ok) return '';
        return (buf instanceof Uint8Array) ? ByteArray.toString(buf) : buf.toString();
    } catch (e) {
        return '';
    }
}

function run_selftest_for_entry(idx, entry, base) {
    let outFile = base + '-' + idx + '.out';
    let errFile = base + '-' + idx + '.err';
    let exitFile = base + '-' + idx + '.exit';

    // Simulate command by writing files (as the app's self-test would do)
    writeFile(outFile, '[SELFTEST] ' + (entry.label || entry.slug || 'unknown') + '\n');
    writeFile(errFile, 'Simulated stderr for ' + (entry.label || entry.slug || 'unknown') + '\n');
    writeFile(exitFile, '0');

    // return the read logs
    return {
        out: readFile(outFile),
        err: readFile(errFile),
        exit: readFile(exitFile)
    };
}

function main() {
    let path = GLib.get_user_data_dir() + '/fedy/manifest.json';
    let manifest = loadJSON(path) || [];

    if (!manifest.length) {
        print('Manifest is empty. Nothing to do.');
        return;
    }

    let base = '/tmp/fedy-manifest-test-' + Date.now();

    print('Running self-test for ' + manifest.length + ' entries (showing first 6 and simulating cancel after 2)...');

    let logs = [];

    for (let i = 0; i < Math.min(6, manifest.length); i++) {
        print('\n-- Entry ' + (i+1) + ' / ' + manifest.length + ': ' + (manifest[i].label || manifest[i].slug));
        print('Status: installing...');

        let l = run_selftest_for_entry(i, manifest[i], base);

        print('Done. exit=' + l.exit.trim());
        print('STDOUT:\n' + l.out.trim());
        print('STDERR:\n' + l.err.trim());

        logs.push(l);

        // simulate cancellation after 2 entries: finish current, stop further
        if (i === 1) {
            print('\nCancellation requested: finishing current and skipping remaining entries.');
            // mark remaining as cancelled
            for (let j = i+1; j < Math.min(6, manifest.length); j++) {
                print('\n-- Entry ' + (j+1) + ' / ' + manifest.length + ': ' + (manifest[j].label || manifest[j].slug));
                print('Status: cancelled');
            }
            break;
        }
    }

    print('\nSelf-test simulation finished. Per-item logs captured.');
}

main();
