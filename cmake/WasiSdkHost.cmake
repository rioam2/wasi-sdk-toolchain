# Maps the host machine onto the {arch}-{os} identifier used in wasi-sdk
# release asset names.

include_guard(GLOBAL)

# wasi_sdk_host_id(<out-var> [SYSTEM <name>] [PROCESSOR <name>])
#
# SYSTEM/PROCESSOR default to the running host and exist so the mapping can be
# exercised for every supported host from a single test run.
function(wasi_sdk_host_id out_var)
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "SYSTEM;PROCESSOR" "")
  if(DEFINED arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "wasi_sdk_host_id: unexpected arguments: ${arg_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT DEFINED arg_SYSTEM OR arg_SYSTEM STREQUAL "")
    set(arg_SYSTEM "${CMAKE_HOST_SYSTEM_NAME}")
  endif()
  if(NOT DEFINED arg_PROCESSOR OR arg_PROCESSOR STREQUAL "")
    set(arg_PROCESSOR "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  endif()

  string(TOLOWER "${arg_SYSTEM}" system)
  if(system STREQUAL "darwin")
    set(os "macos")
  elseif(system STREQUAL "linux")
    set(os "linux")
  elseif(system STREQUAL "windows")
    set(os "windows")
  else()
    message(FATAL_ERROR
      "wasi-sdk: unsupported host system '${arg_SYSTEM}'.\n"
      "  wasi-sdk publishes binaries for Darwin, Linux and Windows only.")
  endif()

  string(TOLOWER "${arg_PROCESSOR}" processor)
  if(processor MATCHES "^(arm64|aarch64)$")
    set(arch "arm64")
  elseif(processor MATCHES "^(x86_64|amd64|x64)$")
    set(arch "x86_64")
  else()
    message(FATAL_ERROR
      "wasi-sdk: unsupported host processor '${arg_PROCESSOR}'.\n"
      "  wasi-sdk publishes binaries for arm64 and x86_64 only.")
  endif()

  set("${out_var}" "${arch}-${os}" PARENT_SCOPE)
endfunction()

# Normalises a user supplied version onto the "<major>.<minor>" form used by
# release asset names, so that both "33" and "33.0" are accepted.
function(wasi_sdk_normalize_version version out_var)
  if(NOT version MATCHES "^[0-9]+(\\.[0-9]+)*$")
    message(FATAL_ERROR
      "wasi-sdk: invalid version '${version}'.\n"
      "  Expected a release number such as '33' or '33.0'.")
  endif()
  if(NOT version MATCHES "\\.")
    set(version "${version}.0")
  endif()
  set("${out_var}" "${version}" PARENT_SCOPE)
endfunction()

# Version numbers are used to build variable names, where '.' is legal but
# awkward; the checksum table keys on the underscored form instead.
function(wasi_sdk_version_key version out_var)
  wasi_sdk_normalize_version("${version}" normalized)
  string(REPLACE "." "_" key "${normalized}")
  set("${out_var}" "${key}" PARENT_SCOPE)
endfunction()
