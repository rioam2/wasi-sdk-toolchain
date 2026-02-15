#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

# Array to track failed tests
failed_tests=()

for test_dir in */; do
    if [ -d "$test_dir" ]; then
        pushd "$test_dir"
        WASI_SDK_TOOLCHAIN_FILE="$script_dir/../wasi-sdk.toolchain.cmake" \
            cmake -B ./build -DCMAKE_TOOLCHAIN_FILE=./toolchain.cmake
        if [ $? -ne 0 ]; then
            failed_tests+=("$test_dir")
        fi
        popd
    fi
done

# Report results
echo ""
echo "============"
echo "Test Summary"
echo "============"

if [ ${#failed_tests[@]} -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Failed tests:"
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo "${#failed_tests[@]} test(s) failed."
    exit 1
fi
