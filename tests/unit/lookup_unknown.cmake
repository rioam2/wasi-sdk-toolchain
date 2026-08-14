include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkAcquire.cmake")

# An unpinned release must fail loudly and say how to pin it, rather than
# silently downloading something unverified.
wasi_sdk_lookup_release(VERSION 999 HOST_ID arm64-macos ASSET_VAR asset)

message(FATAL_ERROR "expected the lookup above to fail")
