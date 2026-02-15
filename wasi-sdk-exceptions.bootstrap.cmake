# Important note: This bootstrap is specifically for the wasi-sdk C++ exceptions release
# from a fork created by Alex Crichton at https://github.com/alexcrichton/wasi-sdk
# This separate bootstrap file can be removed once the C++ exceptions support is 
# merged upstream into the main wasi-sdk repository.

include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.25)

function(_wasi_sdk_find_root wasi_sdk_version out_wasi_sdk_root)
  if (DEFINED ENV{WASI_SDK_INSTALLATION_ROOT})
    set(root "$ENV{WASI_SDK_INSTALLATION_ROOT}")
  elseif(WIN32)
    set(root "$ENV{LOCALAPPDATA}/wasi-sdk/${wasi_sdk_version}/cache")
  else()
    set(root "$ENV{HOME}/.cache/wasi-sdk/${wasi_sdk_version}")
  endif()

  set(${out_wasi_sdk_root}
      ${root}
      PARENT_SCOPE
  )
endfunction()

function(wasi_sdk_exceptions_bootstrap)
  cmake_parse_arguments(
    PARSE_ARGV 0 "arg"
    ""
    "TAG;WASI_SYSROOT_OUTPUT;WASI_SDK_BIN_OUTPUT"
    ""
  )
  if (DEFINED arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
      "${arg_UNPARSED_ARGUMENTS}"
    )
  endif()

  if (NOT arg_TAG MATCHES "wasi-sdk-30.0-cpp-exn")
    message(FATAL_ERROR
      "Unsupported WASI_SDK_TAG for wasi_sdk_exceptions_bootstrap: ${arg_TAG}"
      "This bootstrap is only compatible with the wasi-sdk-30.0-cpp-exn release from https://github.com/alexcrichton/wasi-sdk"
    )
  endif()

  # This bootstrap is specifically for the wasi-sdk C++ exceptions release
  # from https://github.com/alexcrichton/wasi-sdk
  set(wasi_sdk_version "30.1g-exns+m")
  set(wasi_sdk_release_tag "${arg_TAG}")

  # Locate cache root
  if(DEFINED CACHE{_WASI_SDK_ROOT})
    set(wasi_sdk_root $CACHE{_WASI_SDK_ROOT})
  else()
    _wasi_sdk_find_root("${wasi_sdk_version}" wasi_sdk_root)
  endif()
  if (NOT EXISTS ${wasi_sdk_root})
    message(STATUS "Creating wasi-sdk-exceptions cache directory: ${wasi_sdk_root}")
    file(MAKE_DIRECTORY ${wasi_sdk_root})
  else()
    message(STATUS "Cache directory for wasi-sdk-exceptions exists already: ${wasi_sdk_root}")
  endif()

  # Detect host identifier
  set(host_os "${CMAKE_HOST_SYSTEM_NAME}")
  string(TOLOWER "${host_os}" host_os)
  if ("${host_os}" STREQUAL "darwin")
      set(host_os "macos")
  endif()
  set(host_architecture "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  string(TOLOWER "${host_architecture}" host_architecture)
  if ("${host_architecture}" STREQUAL "aarch64")
    set(host_architecture "arm64")
  endif()
  set(host_identifier "${host_architecture}-${host_os}")

  # Define wasi-sdk dependencies, paths and download locations
  # Note: The tarball naming convention for this release is different from upstream wasi-sdk
  set(wasi_sdk_tarball_name "wasi-sdk-${wasi_sdk_version}-${host_identifier}.tar.gz")
  set(wasi_sdk_libclang_tarball_name "libclang_rt-${wasi_sdk_version}.tar.gz")
  set(wasi_sdk_tarball_path "${wasi_sdk_root}/${wasi_sdk_tarball_name}")
  set(wasi_sdk_libclang_tarball_path "${wasi_sdk_root}/${wasi_sdk_libclang_tarball_name}")
  set(wasi_sdk_release_base_url "https://github.com/alexcrichton/wasi-sdk/releases/download/${wasi_sdk_release_tag}")
  set(wasi_sdk_tarball_url "${wasi_sdk_release_base_url}/${wasi_sdk_tarball_name}")
  set(wasi_sdk_libclang_tarball_url "${wasi_sdk_release_base_url}/${wasi_sdk_libclang_tarball_name}")

  # Download wasi-sdk toolchain
  if (NOT EXISTS ${wasi_sdk_tarball_path})
    message(STATUS "Downloading wasi-sdk-exceptions toolchain from ${wasi_sdk_tarball_url}")
    file(DOWNLOAD ${wasi_sdk_tarball_url} ${wasi_sdk_tarball_path} STATUS wasi_sdk_dl_status)
    list(GET wasi_sdk_dl_status 0 wasi_sdk_dl_failed)
    if (wasi_sdk_dl_failed)
      file(REMOVE ${wasi_sdk_tarball_path})
      message(FATAL_ERROR "Download for wasi-sdk-exceptions toolchain failed. ${wasi_sdk_dl_status}")
    else()
      message(STATUS "Successfully downloaded wasi-sdk-exceptions toolchain to ${wasi_sdk_tarball_path}")
    endif()
  else()
    message(STATUS "wasi-sdk-exceptions toolchain has already been downloaded and cached.")
  endif()

  # Extract wasi-sdk toolchain to cache directory
  if (NOT EXISTS "${wasi_sdk_root}/wasi-sdk-${wasi_sdk_version}-${host_identifier}")
    message(STATUS "Extracting wasi-sdk-exceptions toolchain to ${wasi_sdk_root}")
    execute_process(
      RESULT_VARIABLE wasi_sdk_extract_result
      COMMAND ${CMAKE_COMMAND} -E tar xzf ${wasi_sdk_tarball_path}
      WORKING_DIRECTORY ${wasi_sdk_root}
    )
    if (NOT wasi_sdk_extract_result STREQUAL "0")
      message(FATAL_ERROR "Extraction of wasi-sdk-exceptions archive failed...")
    endif()
  endif()

  set(${arg_WASI_SYSROOT_OUTPUT}
      "${wasi_sdk_root}/wasi-sdk-${wasi_sdk_version}-${host_identifier}/share/wasi-sysroot"
      PARENT_SCOPE
  )

  set(${arg_WASI_SDK_BIN_OUTPUT}
      "${wasi_sdk_root}/wasi-sdk-${wasi_sdk_version}-${host_identifier}/bin"
      PARENT_SCOPE
  )
endfunction()
