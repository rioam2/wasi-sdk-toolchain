include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkHost.cmake")

# Every host wasi-sdk publishes for, plus the aliases CMake reports on them.
foreach(case IN ITEMS
    "Darwin|arm64|arm64-macos"
    "Darwin|x86_64|x86_64-macos"
    "Linux|aarch64|arm64-linux"
    "Linux|arm64|arm64-linux"
    "Linux|x86_64|x86_64-linux"
    "Windows|AMD64|x86_64-windows"
    "Windows|x64|x86_64-windows"
    "Windows|ARM64|arm64-windows")
  string(REPLACE "|" ";" parts "${case}")
  list(GET parts 0 system)
  list(GET parts 1 processor)
  list(GET parts 2 expected)

  wasi_sdk_host_id(actual SYSTEM "${system}" PROCESSOR "${processor}")
  expect_eq("${actual}" "${expected}" "host id for ${system}/${processor}")
endforeach()

message(STATUS "host id mapping OK")

# This script runs under `cmake -P`, where CMAKE_HOST_SYSTEM_PROCESSOR is empty,
# so detecting the running host must not rely on it.
wasi_sdk_host_id(detected)
expect_match("${detected}" "^(arm64|x86_64)-(linux|macos|windows)$"
  "the running host must be detectable in script mode")

message(STATUS "detected host: ${detected}")
