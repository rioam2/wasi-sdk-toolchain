include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkHost.cmake")

wasi_sdk_normalize_version("latest" version)

message(FATAL_ERROR "expected a non-numeric version to be rejected")
