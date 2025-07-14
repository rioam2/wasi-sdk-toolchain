#!/usr/bin/env bash

set -e
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

WASI_SDK_TOOLCHAIN_FILE="$script_dir/../wasi-sdk.toolchain.cmake" \
    cmake -B ./build \
        -DCMAKE_TOOLCHAIN_FILE=./toolchain.cmake \
        -DCMAKE_INSTALL_PREFIX=./install \

cmake --build \
    ./build \
    --target install \
    --verbose
