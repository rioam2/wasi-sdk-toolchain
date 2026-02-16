#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

workspace_dir="$(cd "$script_dir/.." && pwd)"

# Array to track failed tests
failed_tests=()

for test_dir in */; do
    if [ -d "$test_dir" ]; then
        if ! pushd "$test_dir" > /dev/null; then
            failed_tests+=("$test_dir")
            continue
        fi
        cmake -B ./build -DCMAKE_TOOLCHAIN_FILE=./toolchain.cmake
        if [ $? -ne 0 ]; then
            failed_tests+=("$test_dir")
        fi
        popd > /dev/null
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
