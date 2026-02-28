#! /usr/bin/env node

import { readFile } from 'fs/promises';
import { WASI } from 'wasi';


async function main() {
    const inputFile = process.argv[2];
    if (!inputFile) {
        console.error(`Usage: ${process.argv[1]} <input_file>`);
        process.exit(1);
    }

    const wasmBytes = await readFile(inputFile);
    const wasi = new WASI({
        version: 'preview1',
        args: process.argv,
        env: process.env,
        stdin: 0,
        stdout: 1,
        stderr: 2,
        preopens: {},
    });

    const wasmModule = await WebAssembly.compile(wasmBytes);
    const instance = await WebAssembly.instantiate(wasmModule, {
        wasi_snapshot_preview1: wasi.wasiImport,
    });

    const status = wasi.start(instance);
    process.exit(status);
}

main().catch(err => {
    console.error(`Error: ${err}`);
    process.exit(1);
});
