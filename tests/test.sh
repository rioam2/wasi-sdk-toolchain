#!/usr/bin/env bash

set -e
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

set +e

for test_dir in */; do
    if [ -d "$test_dir" ]; then
        echo "Running tests in $test_dir"
        pushd "$test_dir"
        WASI_SDK_TOOLCHAIN_FILE="$script_dir/../wasi-sdk.toolchain.cmake" \
            cmake -B ./build -DCMAKE_TOOLCHAIN_FILE=./toolchain.cmake
        popd
    fi
done

set -e