function(_wasi_sdk_find_root wasi_sdk_version out_wasi_sdk_root)
  if (DEFINED ENV{WASI_SDK_INSTALLATION_ROOT})
    set(root "$ENV{WASI_SDK_INSTALLATION_ROOT}")
  elseif(WIN32)
    set(root "$ENV{LOCALAPPDATA}/wask-sdk/${wasi_sdk_version}/cache")
  else()
    set(root "$ENV{HOME}/.cache/wasi-sdk/${wasi_sdk_version}")
  endif()

  set(${out_wasi_sdk_root}
      ${root}
      PARENT_SCOPE
  )
endfunction()

function(wasi_sdk_bootstrap)
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

  # Parse release version
  string(REGEX MATCH "([0-9.])+" wasi_sdk_version ${arg_TAG})
  if (NOT "${wasi_sdk_version}" MATCHES "[.]+")
    set(wasi_sdk_version "${wasi_sdk_version}.0")
  endif()

  # Locate cache root
  if(DEFINED CACHE{_WASI_SDK_ROOT})
    set(wasi_sdk_root $CACHE{_WASI_SDK_ROOT})
  else()
    _wasi_sdk_find_root("${wasi_sdk_version}" wasi_sdk_root)
  endif()
  if (NOT EXISTS ${wasi_sdk_root})
    message(STATUS "Creating wasi-sdk cache directory: ${wasi_sdk_root}")
    file(MAKE_DIRECTORY ${wasi_sdk_root})
  else()
    message(STATUS "Cache directory for wasi-sdk exists already: ${wasi_sdk_root}")
  endif()

  # Detect host identifier
  set(host_os "${CMAKE_HOST_SYSTEM_NAME}")
  string(TOLOWER "${host_os}" host_os)
  if ("${host_os}" STREQUAL "darwin")
      set(host_os "macos")
  endif()
  set(host_architecture "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  string(TOLOWER "${host_architecture}" host_architecture)
  set(host_identifier "${host_architecture}-${host_os}")

  # Define wasi-sdk dependencies, paths and download locations
  set(wasi_sdk_tarball_name "wasi-sdk-${wasi_sdk_version}-${host_identifier}.tar.gz")
  set(wasi_sdk_libclang_tarball_name "libclang_rt.builtins-wasm32-wasi-${wasi_sdk_version}.tar.gz")
  set(wasi_sdk_tarball_path "${wasi_sdk_root}/${wasi_sdk_tarball_name}")
  set(wasi_sdk_libclang_tarball_path "${wasi_sdk_root}/${wasi_sdk_libclang_tarball_name}")
  set(wasi_sdk_release_base_url "https://github.com/WebAssembly/wasi-sdk/releases/download/${arg_TAG}")
  set(wasi_sdk_tarball_url "${wasi_sdk_release_base_url}/${wasi_sdk_tarball_name}")
  set(wasi_sdk_libclang_tarball_url "${wasi_sdk_release_base_url}/${wasi_sdk_libclang_tarball_name}")

  # Download wasi-sdk toolchain
  if (NOT EXISTS ${wasi_sdk_tarball_path})
    message(STATUS "Downloading wasi-sdk toolchain from ${wasi_sdk_tarball_url}")
    file(DOWNLOAD ${wasi_sdk_tarball_url} ${wasi_sdk_tarball_path} STATUS wasi_sdk_dl_status)
    list(GET wasi_sdk_dl_status 0 wasi_sdk_dl_failed)
    if (wasi_sdk_dl_failed)
      file(REMOVE ${wasi_sdk_tarball_path})
      message(FATAL_ERROR "Download for wasi-sdk toolchain failed. ${wasi_sdk_dl_status}")
    else()
      message(STATUS "Successfully downloaded wasi-sdk toolchain to ${wasi_sdk_tarball_path}")
    endif()
  else()
    message(STATUS "wasi-sdk toolchain has already been downloaded and cached.")
  endif()

  # Extract wasi-sdk toolchain to cache directory
  message(STATUS "Extracting wasi-sdk toolchain to ${wasi_sdk_root}")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xzf ${wasi_sdk_tarball_path}
    WORKING_DIRECTORY ${wasi_sdk_root}
  )

  set(${arg_WASI_SYSROOT_OUTPUT}
      "${wasi_sdk_root}/wasi-sdk-${wasi_sdk_version}-${host_identifier}/share/wasi-sysroot"
      PARENT_SCOPE
  )

  set(${arg_WASI_SDK_BIN_OUTPUT}
      "${wasi_sdk_root}/wasi-sdk-${wasi_sdk_version}-${host_identifier}/bin"
      PARENT_SCOPE
  )
endfunction()
