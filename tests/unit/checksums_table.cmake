include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkHost.cmake")

# A partially generated table would only fail on the one host that is missing,
# so check every version against every published host here.
include("${REPO_DIR}/cmake/WasiSdkChecksums.cmake")

expect_true("${WASI_SDK_KNOWN_VERSIONS}" "the checksum table must not be empty")

set(host_ids
  arm64-linux arm64-macos arm64-windows
  x86_64-linux x86_64-macos x86_64-windows)

foreach(version IN LISTS WASI_SDK_KNOWN_VERSIONS)
  wasi_sdk_version_key("${version}" key)
  foreach(host_id IN LISTS host_ids)
    set(asset "${_wasi_sdk_asset_${key}_${host_id}}")
    set(sha256 "${_wasi_sdk_sha256_${key}_${host_id}}")

    expect_true("${asset}" "missing asset name for ${version}/${host_id}")
    expect_eq("${asset}" "wasi-sdk-${version}-${host_id}.tar.gz"
      "asset name for ${version}/${host_id}")
    expect_sha256("${sha256}" "digest for ${version}/${host_id}")
  endforeach()
endforeach()

list(LENGTH WASI_SDK_KNOWN_VERSIONS count)
message(STATUS "checksum table OK (${count} versions)")
