function(_wasm_tools_find_root wasm_tools_version out_wasm_tools_root)
    if (DEFINED ENV{WASM_TOOLS_INSTALLATION_ROOT})
        set(root "$ENV{WASM_TOOLS_INSTALLATION_ROOT}")
    elseif(WIN32)
        set(root "$ENV{LOCALAPPDATA}/wasm-tools/${wasm_tools_version}/cache")
    else()
        set(root "$ENV{HOME}/.cache/wasm-tools/${wasm_tools_version}")
    endif()

    set(${out_wasm_tools_root}
        ${root}
        PARENT_SCOPE
    )
endfunction()

function(wasm_tools_bootstrap)
    cmake_parse_arguments(
        PARSE_ARGV 0 "arg"
        ""
        "WASMTIME_POLYFILL_TAG;WASMTIME_POLYFILL_DIR_OUTPUT;WASM_TOOLS_TAG;WASM_TOOLS_BINARY_OUTPUT"
        ""
    )
    if (DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
        "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
        "${arg_UNPARSED_ARGUMENTS}"
        )
    endif()

    # Locate cache root
    if(DEFINED CACHE{_WASM_TOOLS_ROOT})
        set(wasm_tools_root $CACHE{_WASM_TOOLS_ROOT})
    else()
        _wasm_tools_find_root("${arg_WASM_TOOLS_TAG}" wasm_tools_root)
    endif()
    if (NOT EXISTS ${wasm_tools_root})
        message(STATUS "Creating wasm-tools cache directory: ${wasm_tools_root}")
        file(MAKE_DIRECTORY ${wasm_tools_root})
    else()
        message(STATUS "Cache directory for wasm-tools exists already: ${wasm_tools_root}")
    endif()

    # Setup paths for downloaded content
    set(wasmtime_polyfill_proxy_name "wasi_snapshot_preview1.proxy.wasm")
    set(wasmtime_polyfill_reactor_name "wasi_snapshot_preview1.reactor.wasm")
    set(wasmtime_polyfill_command_name "wasi_snapshot_preview1.command.wasm")
    set(wasmtime_polyfill_proxy_path "${wasm_tools_root}/polyfills/${wasmtime_polyfill_proxy_name}")
    set(wasmtime_polyfill_reactor_path "${wasm_tools_root}/polyfills/${wasmtime_polyfill_reactor_name}")
    set(wasmtime_polyfill_command_path "${wasm_tools_root}/polyfills/${wasmtime_polyfill_command_name}")

    # Setup remote urls for downloadable content
    set(wasmtime_release_base_url "https://github.com/bytecodealliance/wasmtime/releases/download/${arg_WASMTIME_POLYFILL_TAG}")
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

    set(${arg_WASMTIME_POLYFILL_DIR_OUTPUT}
        "${wasm_tools_root}/polyfills"
        PARENT_SCOPE
    )

    # Detect host identifier
    set(host_os "${CMAKE_HOST_SYSTEM_NAME}")
    string(TOLOWER "${host_os}" host_os)
    if ("${host_os}" STREQUAL "darwin")
        set(host_os "macos")
    endif()
    set(host_architecture "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    string(TOLOWER "${host_architecture}" host_architecture)
    if ("${host_architecture}" STREQUAL "arm64")
        set(host_architecture "aarch64")
    endif()
    set(host_identifier "${host_architecture}-${host_os}")

    # Get wasm-tools bare version
    string(REGEX MATCH "([0-9.])+" wasm_tools_version ${arg_WASM_TOOLS_TAG})

    # Setup paths for downloaded content
    set(wasm_tools_tarball_name "wasm-tools-${wasm_tools_version}-${host_identifier}.tar.gz")
    set(wasm_tools_tarball_path "${wasm_tools_root}/${wasm_tools_tarball_name}")

    # Setup remote urls for downloadable content
    set(wasm_tools_release_base_url "https://github.com/bytecodealliance/wasm-tools/releases/download/${arg_WASM_TOOLS_TAG}")
    set(wasm_tools_tarball_url "${wasm_tools_release_base_url}/${wasm_tools_tarball_name}")

    # Download wasm_tools binary
    if (NOT EXISTS ${wasm_tools_tarball_path})
        message(STATUS "Downloading wasm-tools binary from ${wasm_tools_tarball_url}")
        file(DOWNLOAD ${wasm_tools_tarball_url} ${wasm_tools_tarball_path} STATUS wasm_tools_dl_status)
        list(GET wasm_tools_dl_status 0 wasm_tools_dl_failed)
        if (wasm_tools_dl_failed)
        file(REMOVE ${wasm_tools_tarball_path})
        message(FATAL_ERROR "Download for wasm-tools binary failed.")
        else()
        message(STATUS "Successfully downloaded wasm-tools binary to ${wasm_tools_tarball_path}")
        endif()
    else()
        message(STATUS "wasm-tools binary has already been downloaded and cached.")
    endif()

    # Extract wasm-tools sysroot to cache directory
    message(STATUS "Extracting wasm-tools binary to ${wasm_tools_root}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${wasm_tools_tarball_path}
        WORKING_DIRECTORY ${wasm_tools_root}
    )

    # Set location of wasm-tools
    set(${arg_WASM_TOOLS_BINARY_OUTPUT}
        "${wasm_tools_root}/wasm-tools-${wasm_tools_version}-${host_identifier}/wasm-tools"
        PARENT_SCOPE
    )
endfunction()


function(wasm_create_component)
    cmake_parse_arguments(
        PARSE_ARGV 0 "arg"
        ""
        "COMPONENT_TARGET;CORE_WASM_TARGET;COMPONENT_TYPE"
        ""
    )
    if (DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
            "${arg_UNPARSED_ARGUMENTS}"
        )
    endif()

    # Validate component type
    set(component_type_options "proxy" "reactor" "command")
    list(FIND component_type_options ${arg_COMPONENT_TYPE} index)
    if(index EQUAL -1)
        message(FATAL_ERROR "COMPONENT_TYPE must be one of ${component_type_options}")
    endif()

    # Get source target name
    get_target_property(src_target_name ${arg_CORE_WASM_TARGET} OUTPUT_NAME)
    get_filename_component(src_target_basename ${src_target_name} NAME_WE)

    # Derive name of component output
    set(component_output_file "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/${src_target_basename}_component.wasm")

    # Add a custom command to create the WebAssembly component
    add_custom_command(
        OUTPUT "${component_output_file}"
        COMMAND ${_wasm_tools_binary} component new 
            $<TARGET_FILE:${arg_CORE_WASM_TARGET}> 
            -o "${component_output_file}" 
            --adapt "${_wasm_tools_polyfill_dir}/wasi_snapshot_preview1.${arg_COMPONENT_TYPE}.wasm"
        DEPENDS ${arg_CORE_WASM_TARGET}
        COMMENT "Creating WebAssembly component ${component_output_file}"
    )
    
    # Create a custom target that depends on the output file
    add_custom_target(
        "${arg_COMPONENT_TARGET}" ALL
        DEPENDS "${component_output_file}"
    )

    # Ensure the component target is built after the executable
    add_dependencies(${arg_COMPONENT_TARGET} ${arg_CORE_WASM_TARGET})
endfunction()
