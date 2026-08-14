include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkHost.cmake")

wasi_sdk_normalize_version("33" v)
expect_eq("${v}" "33.0" "bare major gains a minor")

wasi_sdk_normalize_version("33.0" v)
expect_eq("${v}" "33.0" "already-normalised version is unchanged")

wasi_sdk_normalize_version("26.1" v)
expect_eq("${v}" "26.1" "non-zero minor is preserved")

wasi_sdk_version_key("33" k)
expect_eq("${k}" "33_0" "version key underscores the separator")

message(STATUS "version normalisation OK")
