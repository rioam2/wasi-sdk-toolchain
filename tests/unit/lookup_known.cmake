include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkAcquire.cmake")

wasi_sdk_lookup_release(
  VERSION 33
  HOST_ID arm64-macos
  ASSET_VAR asset
  SHA256_VAR sha256
  URL_VAR url)

expect_eq("${asset}" "wasi-sdk-33.0-arm64-macos.tar.gz" "asset name")
expect_sha256("${sha256}" "digest shape")
expect_eq("${url}"
  "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-33/wasi-sdk-33.0-arm64-macos.tar.gz"
  "download url is built from the major version tag")

# The bare major form must resolve identically to the normalised one.
wasi_sdk_lookup_release(VERSION 33.0 HOST_ID arm64-macos SHA256_VAR sha256_dotted)
expect_eq("${sha256_dotted}" "${sha256}" "'33' and '33.0' resolve to the same release")

message(STATUS "release lookup OK")
