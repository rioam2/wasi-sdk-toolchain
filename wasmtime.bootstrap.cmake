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
    "TAG;WASMTIME_BINARY_OUTPUT;WASMTIME_POLYFILL_DIR_OUTPUT"
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
      RESULT_VARIABLE wasmtime_extract_result
      COMMAND ${CMAKE_COMMAND} -E tar xf ${wasmtime_archive_path}
      WORKING_DIRECTORY ${wasmtime_root}
      RESULT_VARIABLE wasmtime_extract_result
    )
    if (NOT wasmtime_extract_result STREQUAL "0")
      message(FATAL_ERROR "Extraction of wasmtime archive failed with exit code ${wasmtime_extract_result}")
    endif()
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

  # Download WASI preview1 polyfill adapters
  set(wasmtime_polyfill_dir "${wasmtime_root}/polyfills")
  if (NOT EXISTS ${wasmtime_polyfill_dir})
    file(MAKE_DIRECTORY ${wasmtime_polyfill_dir})
  endif()

  set(wasmtime_polyfill_proxy_name "wasi_snapshot_preview1.proxy.wasm")
  set(wasmtime_polyfill_reactor_name "wasi_snapshot_preview1.reactor.wasm")
  set(wasmtime_polyfill_command_name "wasi_snapshot_preview1.command.wasm")
  set(wasmtime_polyfill_proxy_path "${wasmtime_polyfill_dir}/${wasmtime_polyfill_proxy_name}")
  set(wasmtime_polyfill_reactor_path "${wasmtime_polyfill_dir}/${wasmtime_polyfill_reactor_name}")
  set(wasmtime_polyfill_command_path "${wasmtime_polyfill_dir}/${wasmtime_polyfill_command_name}")

  set(wasmtime_polyfill_proxy_url "${wasmtime_release_base_url}/${wasmtime_polyfill_proxy_name}")
  set(wasmtime_polyfill_reactor_url "${wasmtime_release_base_url}/${wasmtime_polyfill_reactor_name}")
  set(wasmtime_polyfill_command_url "${wasmtime_release_base_url}/${wasmtime_polyfill_command_name}")

  # Download wasmtime proxy polyfill
  if (NOT EXISTS ${wasmtime_polyfill_proxy_path})
    message(STATUS "Downloading wasmtime wasm32-wasip1 proxy polyfill from ${wasmtime_polyfill_proxy_url}")
    file(DOWNLOAD ${wasmtime_polyfill_proxy_url} ${wasmtime_polyfill_proxy_path} STATUS wasmtime_polyfill_proxy_dl_status)
    list(GET wasmtime_polyfill_proxy_dl_status 0 wasmtime_polyfill_proxy_dl_failed)
    if (wasmtime_polyfill_proxy_dl_failed)
      file(REMOVE ${wasmtime_polyfill_proxy_path})
      message(FATAL_ERROR "Download for wasmtime wasm32-wasip1 proxy polyfill failed.")
    else()
      message(STATUS "Successfully downloaded wasmtime wasm32-wasip1 proxy polyfill to ${wasmtime_polyfill_proxy_path}")
    endif()
  else()
    message(STATUS "wasmtime wasm32-wasip1 proxy polyfill has already been downloaded and cached.")
  endif()

  # Download wasmtime reactor polyfill
  if (NOT EXISTS ${wasmtime_polyfill_reactor_path})
    message(STATUS "Downloading wasmtime wasm32-wasip1 reactor polyfill from ${wasmtime_polyfill_reactor_url}")
    file(DOWNLOAD ${wasmtime_polyfill_reactor_url} ${wasmtime_polyfill_reactor_path} STATUS wasmtime_polyfill_reactor_dl_status)
    list(GET wasmtime_polyfill_reactor_dl_status 0 wasmtime_polyfill_reactor_dl_failed)
    if (wasmtime_polyfill_reactor_dl_failed)
      file(REMOVE ${wasmtime_polyfill_reactor_path})
      message(FATAL_ERROR "Download for wasmtime wasm32-wasip1 reactor polyfill failed.")
    else()
      message(STATUS "Successfully downloaded wasmtime wasm32-wasip1 reactor polyfill to ${wasmtime_polyfill_reactor_path}")
    endif()
  else()
    message(STATUS "wasmtime wasm32-wasip1 reactor polyfill has already been downloaded and cached.")
  endif()

  # Download wasmtime command polyfill
  if (NOT EXISTS ${wasmtime_polyfill_command_path})
    message(STATUS "Downloading wasmtime wasm32-wasip1 command polyfill from ${wasmtime_polyfill_command_url}")
    file(DOWNLOAD ${wasmtime_polyfill_command_url} ${wasmtime_polyfill_command_path} STATUS wasmtime_polyfill_command_dl_status)
    list(GET wasmtime_polyfill_command_dl_status 0 wasmtime_polyfill_command_dl_failed)
    if (wasmtime_polyfill_command_dl_failed)
      file(REMOVE ${wasmtime_polyfill_command_path})
      message(FATAL_ERROR "Download for wasmtime wasm32-wasip1 command polyfill failed.")
    else()
      message(STATUS "Successfully downloaded wasmtime wasm32-wasip1 command polyfill to ${wasmtime_polyfill_command_path}")
    endif()
  else()
    message(STATUS "wasmtime wasm32-wasip1 command polyfill has already been downloaded and cached.")
  endif()

  # Set output variable with path to polyfill directory
  set(${arg_WASMTIME_POLYFILL_DIR_OUTPUT}
      "${wasmtime_polyfill_dir}"
      PARENT_SCOPE
  )
endfunction()
