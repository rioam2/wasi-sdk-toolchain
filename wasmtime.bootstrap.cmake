# SPDX-License-Identifier: Apache-2.0
# Bootstrap wasmtime binary from GitHub releases

include_guard(GLOBAL)

function(_wasmtime_find_root wasmtime_version out_wasmtime_root)
  if (DEFINED ENV{WASMTIME_INSTALLATION_ROOT})
    set(root "$ENV{WASMTIME_INSTALLATION_ROOT}")
  elseif(WIN32)
    set(root "$ENV{LOCALAPPDATA}/wasmtime/${wasmtime_version}/cache")
  else()
    set(root "$ENV{HOME}/.cache/wasmtime/${wasmtime_version}")
  endif()

  set(${out_wasmtime_root}
      ${root}
      PARENT_SCOPE
  )
endfunction()

function(wasmtime_bootstrap)
  cmake_parse_arguments(
    PARSE_ARGV 0 "arg"
    ""
    "TAG;WASMTIME_BINARY_OUTPUT"
    ""
  )
  if (DEFINED arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR
      "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
      "${arg_UNPARSED_ARGUMENTS}"
    )
  endif()

  # Parse version from tag (e.g., "v41.0.3" -> "41.0.3")
  string(REGEX REPLACE "^v" "" wasmtime_version "${arg_TAG}")

  # Locate cache root
  if(DEFINED CACHE{_WASMTIME_ROOT})
    set(wasmtime_root $CACHE{_WASMTIME_ROOT})
  else()
    _wasmtime_find_root("${wasmtime_version}" wasmtime_root)
  endif()
  if (NOT EXISTS ${wasmtime_root})
    message(STATUS "Creating wasmtime cache directory: ${wasmtime_root}")
    file(MAKE_DIRECTORY ${wasmtime_root})
  else()
    message(STATUS "Cache directory for wasmtime exists already: ${wasmtime_root}")
  endif()

  # Detect host OS
  set(host_os "${CMAKE_HOST_SYSTEM_NAME}")
  string(TOLOWER "${host_os}" host_os)
  if ("${host_os}" STREQUAL "darwin")
    set(host_os "macos")
  endif()

  # Detect host architecture
  set(host_architecture "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  string(TOLOWER "${host_architecture}" host_architecture)
  if ("${host_architecture}" STREQUAL "arm64")
    set(host_architecture "aarch64")
  elseif("${host_architecture}" STREQUAL "amd64")
    set(host_architecture "x86_64")
  endif()

  # Determine archive extension based on OS
  if ("${host_os}" STREQUAL "windows")
    set(archive_extension "zip")
  else()
    set(archive_extension "tar.xz")
  endif()

  # Construct host identifier (format: {arch}-{os})
  set(host_identifier "${host_architecture}-${host_os}")

  # Define wasmtime paths and download locations
  set(wasmtime_archive_name "wasmtime-v${wasmtime_version}-${host_identifier}.${archive_extension}")
  set(wasmtime_archive_path "${wasmtime_root}/${wasmtime_archive_name}")
  set(wasmtime_release_base_url "https://github.com/bytecodealliance/wasmtime/releases/download/${arg_TAG}")
  set(wasmtime_archive_url "${wasmtime_release_base_url}/${wasmtime_archive_name}")

  # Download wasmtime
  if (NOT EXISTS ${wasmtime_archive_path})
    message(STATUS "Downloading wasmtime from ${wasmtime_archive_url}")
    file(DOWNLOAD ${wasmtime_archive_url} ${wasmtime_archive_path} STATUS wasmtime_dl_status)
    list(GET wasmtime_dl_status 0 wasmtime_dl_failed)
    if (wasmtime_dl_failed)
      file(REMOVE ${wasmtime_archive_path})
      message(FATAL_ERROR "Download for wasmtime failed. ${wasmtime_dl_status}")
    else()
      message(STATUS "Successfully downloaded wasmtime to ${wasmtime_archive_path}")
    endif()
  else()
    message(STATUS "wasmtime has already been downloaded and cached.")
  endif()

  # Extract wasmtime to cache directory
  set(wasmtime_extract_dir "wasmtime-v${wasmtime_version}-${host_identifier}")
  if (NOT EXISTS "${wasmtime_root}/${wasmtime_extract_dir}")
    message(STATUS "Extracting wasmtime to ${wasmtime_root}")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xf ${wasmtime_archive_path}
      WORKING_DIRECTORY ${wasmtime_root}
    )
  endif()

  # Determine binary name based on OS
  if ("${host_os}" STREQUAL "windows")
    set(wasmtime_binary_name "wasmtime.exe")
  else()
    set(wasmtime_binary_name "wasmtime")
  endif()

  # Set output variable with path to wasmtime binary
  set(${arg_WASMTIME_BINARY_OUTPUT}
      "${wasmtime_root}/${wasmtime_extract_dir}/${wasmtime_binary_name}"
      PARENT_SCOPE
  )
endfunction()
