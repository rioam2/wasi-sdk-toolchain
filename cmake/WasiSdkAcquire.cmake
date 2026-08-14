# Downloads and unpacks a pinned wasi-sdk release.
#
# This module is deliberately separate from the toolchain file: acquiring an SDK
# is a side effect, and toolchain files are re-read in contexts (try_compile,
# nested project()) where side effects are not wanted. Use
# wasi-sdk-bootstrap.toolchain.cmake if you want both in one step.
#
# It can also be run directly to pre-populate a cache, which is useful in CI:
#
#   cmake -DVERSION=33 [-DDESTINATION=<dir>] -P cmake/WasiSdkAcquire.cmake

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/WasiSdkHost.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/WasiSdkChecksums.cmake")

set(WASI_SDK_RELEASE_BASE_URL "https://github.com/WebAssembly/wasi-sdk/releases/download"
  CACHE STRING "Base URL wasi-sdk release archives are downloaded from")

# Root of the shared download cache, in precedence order.
function(wasi_sdk_cache_root out_var)
  if(DEFINED WASI_SDK_CACHE_DIR AND NOT WASI_SDK_CACHE_DIR STREQUAL "")
    set(root "${WASI_SDK_CACHE_DIR}")
  elseif(DEFINED ENV{WASI_SDK_CACHE_DIR} AND NOT "$ENV{WASI_SDK_CACHE_DIR}" STREQUAL "")
    set(root "$ENV{WASI_SDK_CACHE_DIR}")
  elseif(CMAKE_HOST_WIN32 AND DEFINED ENV{LOCALAPPDATA})
    set(root "$ENV{LOCALAPPDATA}/wasi-sdk")
  elseif(DEFINED ENV{XDG_CACHE_HOME} AND NOT "$ENV{XDG_CACHE_HOME}" STREQUAL "")
    set(root "$ENV{XDG_CACHE_HOME}/wasi-sdk")
  elseif(DEFINED ENV{HOME})
    set(root "$ENV{HOME}/.cache/wasi-sdk")
  else()
    message(FATAL_ERROR
      "wasi-sdk: unable to determine a cache directory.\n"
      "  Set WASI_SDK_CACHE_DIR to choose one explicitly.")
  endif()
  file(TO_CMAKE_PATH "${root}" root)
  set("${out_var}" "${root}" PARENT_SCOPE)
endfunction()

# wasi_sdk_lookup_release(VERSION <v> [HOST_ID <id>] [ASSET_VAR <v>] [SHA256_VAR <v>] [URL_VAR <v>])
#
# Resolves a version onto its published asset name and digest. Split out from
# the download so the pin table can be tested without touching the network.
function(wasi_sdk_lookup_release)
  cmake_parse_arguments(PARSE_ARGV 0 arg "" "VERSION;HOST_ID;ASSET_VAR;SHA256_VAR;URL_VAR" "")
  if(DEFINED arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "wasi_sdk_lookup_release: unexpected arguments: ${arg_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT DEFINED arg_VERSION OR arg_VERSION STREQUAL "")
    message(FATAL_ERROR "wasi_sdk_lookup_release: VERSION is required")
  endif()
  if(NOT DEFINED arg_HOST_ID OR arg_HOST_ID STREQUAL "")
    wasi_sdk_host_id(arg_HOST_ID)
  endif()

  wasi_sdk_normalize_version("${arg_VERSION}" version)
  wasi_sdk_version_key("${version}" key)

  if(NOT DEFINED _wasi_sdk_sha256_${key}_${arg_HOST_ID})
    string(REPLACE ";" ", " known "${WASI_SDK_KNOWN_VERSIONS}")
    message(FATAL_ERROR
      "wasi-sdk: no pinned checksum for version '${version}' on host '${arg_HOST_ID}'.\n"
      "  Pinned versions: ${known}\n"
      "  To add a newer release, run:\n"
      "      cmake -P tools/update-checksums.cmake\n"
      "  To use an unpinned release, pass its digest via WASI_SDK_SHA256.")
  endif()

  set(asset "${_wasi_sdk_asset_${key}_${arg_HOST_ID}}")
  string(REGEX MATCH "^[0-9]+" major "${version}")

  if(DEFINED arg_ASSET_VAR)
    set("${arg_ASSET_VAR}" "${asset}" PARENT_SCOPE)
  endif()
  if(DEFINED arg_SHA256_VAR)
    set("${arg_SHA256_VAR}" "${_wasi_sdk_sha256_${key}_${arg_HOST_ID}}" PARENT_SCOPE)
  endif()
  if(DEFINED arg_URL_VAR)
    set("${arg_URL_VAR}" "${WASI_SDK_RELEASE_BASE_URL}/wasi-sdk-${major}/${asset}" PARENT_SCOPE)
  endif()
endfunction()

# wasi_sdk_acquire(VERSION <v> OUTPUT_ROOT <var> [DESTINATION <dir>] [SHA256 <hex>] [QUIET])
#
# Idempotent: returns immediately when the target directory already holds an
# unpacked SDK, so it is safe to call on every configure.
function(wasi_sdk_acquire)
  cmake_parse_arguments(PARSE_ARGV 0 arg "QUIET" "VERSION;DESTINATION;SHA256;OUTPUT_ROOT" "")
  if(DEFINED arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "wasi_sdk_acquire: unexpected arguments: ${arg_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT DEFINED arg_VERSION OR arg_VERSION STREQUAL "")
    message(FATAL_ERROR "wasi_sdk_acquire: VERSION is required")
  endif()

  wasi_sdk_normalize_version("${arg_VERSION}" version)
  wasi_sdk_host_id(host_id)
  string(REGEX MATCH "^[0-9]+" major "${version}")

  if(DEFINED arg_SHA256 AND NOT arg_SHA256 STREQUAL "")
    # Caller-supplied digest lets an unpinned release be used without editing
    # the generated table.
    set(sha256 "${arg_SHA256}")
    set(asset "wasi-sdk-${version}-${host_id}.tar.gz")
    set(url "${WASI_SDK_RELEASE_BASE_URL}/wasi-sdk-${major}/${asset}")
  else()
    wasi_sdk_lookup_release(
      VERSION "${version}"
      HOST_ID "${host_id}"
      ASSET_VAR asset
      SHA256_VAR sha256
      URL_VAR url)
  endif()

  # CMake's regex engine has no {n} quantifier, so check the length separately.
  string(LENGTH "${sha256}" sha256_length)
  if(NOT sha256_length EQUAL 64 OR NOT sha256 MATCHES "^[0-9a-fA-F]+$")
    message(FATAL_ERROR "wasi-sdk: '${sha256}' is not a SHA256 digest")
  endif()

  if(DEFINED arg_DESTINATION AND NOT arg_DESTINATION STREQUAL "")
    set(root "${arg_DESTINATION}")
  else()
    wasi_sdk_cache_root(cache_root)
    string(SUBSTRING "${sha256}" 0 12 short_sha)
    set(root "${cache_root}/${version}-${host_id}-${short_sha}")
  endif()
  file(TO_CMAKE_PATH "${root}" root)

  if(CMAKE_HOST_WIN32)
    set(sentinel "${root}/bin/clang.exe")
  else()
    set(sentinel "${root}/bin/clang")
  endif()

  if(NOT EXISTS "${sentinel}")
    _wasi_sdk_download_and_extract("${url}" "${sha256}" "${root}" "${sentinel}" "${arg_QUIET}")
  elseif(NOT arg_QUIET)
    message(STATUS "wasi-sdk ${version} already present at ${root}")
  endif()

  if(DEFINED arg_OUTPUT_ROOT)
    set("${arg_OUTPUT_ROOT}" "${root}" PARENT_SCOPE)
  endif()
endfunction()

function(_wasi_sdk_download_and_extract url sha256 root sentinel quiet)
  get_filename_component(parent "${root}" DIRECTORY)
  file(MAKE_DIRECTORY "${parent}")

  # Concurrent configures (vcpkg builds ports in parallel) must not race to
  # populate the same directory.
  file(LOCK "${root}.lock" GUARD FUNCTION TIMEOUT 900)
  if(EXISTS "${sentinel}")
    return()
  endif()

  set(archive "${root}.download")
  set(staging "${root}.staging")
  file(REMOVE "${archive}")
  file(REMOVE_RECURSE "${staging}")

  if(NOT quiet)
    message(STATUS "Downloading ${url}")
  endif()
  set(progress "")
  if(NOT quiet)
    set(progress SHOW_PROGRESS)
  endif()
  file(DOWNLOAD "${url}" "${archive}"
    EXPECTED_HASH "SHA256=${sha256}"
    TLS_VERIFY ON
    STATUS status
    ${progress})
  list(GET status 0 code)
  if(NOT code EQUAL 0)
    list(GET status 1 reason)
    file(REMOVE "${archive}")
    message(FATAL_ERROR "wasi-sdk: download failed for ${url}\n  ${reason}")
  endif()

  file(MAKE_DIRECTORY "${staging}")
  file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${staging}")
  file(REMOVE "${archive}")

  # Releases contain exactly one top-level directory; hoist it so the layout is
  # independent of the archive's internal naming.
  file(GLOB extracted "${staging}/*")
  list(LENGTH extracted extracted_count)
  if(NOT extracted_count EQUAL 1)
    file(REMOVE_RECURSE "${staging}")
    message(FATAL_ERROR
      "wasi-sdk: expected exactly one directory inside the archive, found ${extracted_count}")
  endif()

  file(RENAME "${extracted}" "${root}")
  file(REMOVE_RECURSE "${staging}")

  if(NOT EXISTS "${sentinel}")
    file(REMOVE_RECURSE "${root}")
    message(FATAL_ERROR "wasi-sdk: unpacked archive is missing ${sentinel}")
  endif()
  if(NOT quiet)
    message(STATUS "wasi-sdk unpacked to ${root}")
  endif()
endfunction()

if(DEFINED CMAKE_SCRIPT_MODE_FILE AND CMAKE_SCRIPT_MODE_FILE STREQUAL CMAKE_CURRENT_LIST_FILE)
  if(NOT DEFINED VERSION)
    message(FATAL_ERROR "Usage: cmake -DVERSION=<n> [-DDESTINATION=<dir>] -P WasiSdkAcquire.cmake")
  endif()
  if(NOT DEFINED DESTINATION)
    set(DESTINATION "")
  endif()
  wasi_sdk_acquire(VERSION "${VERSION}" DESTINATION "${DESTINATION}" OUTPUT_ROOT acquired_root)
  message(STATUS "WASI_SDK_ROOT=${acquired_root}")
  if(DEFINED ROOT_FILE)
    file(WRITE "${ROOT_FILE}" "${acquired_root}")
  endif()
endif()
