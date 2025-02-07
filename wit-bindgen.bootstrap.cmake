function(_wit_bindgen_find_root wit_bindgen_version out_wit_bindgen_root)
    if (DEFINED ENV{WIT_BINDGEN_INSTALLATION_ROOT})
        set(root "$ENV{WIT_BINDGEN_INSTALLATION_ROOT}")
    elseif(WIN32)
        set(root "$ENV{LOCALAPPDATA}/wit-bindgen/${wit_bindgen_version}/cache")
    else()
        set(root "$ENV{HOME}/.cache/wit-bindgen/${wit_bindgen_version}")
    endif()

    set(${out_wit_bindgen_root}
        ${root}
        PARENT_SCOPE
    )
endfunction()

function(wit_bindgen_bootstrap)
    cmake_parse_arguments(
        PARSE_ARGV 0 "arg"
        ""
        "WIT_BINDGEN_TAG;WIT_BINDGEN_BINARY_OUTPUT"
        ""
    )
    if (DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
        "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
        "${arg_UNPARSED_ARGUMENTS}"
        )
    endif()

    # Locate cache root
    if(DEFINED CACHE{_WIT_BINDGEN_ROOT})
        set(wit_bindgen_root $CACHE{_WIT_BINDGEN_ROOT})
    else()
        _wit_bindgen_find_root("${arg_WIT_BINDGEN_TAG}" wit_bindgen_root)
    endif()
    if (NOT EXISTS ${wit_bindgen_root})
        message(STATUS "Creating wit-bindgen cache directory: ${wit_bindgen_root}")
        file(MAKE_DIRECTORY ${wit_bindgen_root})
    else()
        message(STATUS "Cache directory for wit-bindgen exists already: ${wit_bindgen_root}")
    endif()

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

    # Get wit-bindgen bare version
    string(REGEX MATCH "([0-9.])+" wit_bindgen_version ${arg_WIT_BINDGEN_TAG})

    # Setup paths for downloaded content
    set(wit_bindgen_tarball_name "wit-bindgen-${wit_bindgen_version}-${host_identifier}.tar.gz")
    set(wit_bindgen_tarball_path "${wit_bindgen_root}/${wit_bindgen_tarball_name}")

    # Setup remote urls for downloadable content
    set(wit_bindgen_release_base_url "https://github.com/bytecodealliance/wit-bindgen/releases/download/${arg_WIT_BINDGEN_TAG}")
    set(wit_bindgen_tarball_url "${wit_bindgen_release_base_url}/${wit_bindgen_tarball_name}")

    # Download wit_bindgen binary
    if (NOT EXISTS ${wit_bindgen_tarball_path})
        message(STATUS "Downloading wit-bindgen binary from ${wit_bindgen_tarball_url}")
        file(DOWNLOAD ${wit_bindgen_tarball_url} ${wit_bindgen_tarball_path} STATUS wit_bindgen_dl_status)
        list(GET wit_bindgen_dl_status 0 wit_bindgen_dl_failed)
        if (wit_bindgen_dl_failed)
        file(REMOVE ${wit_bindgen_tarball_path})
        message(FATAL_ERROR "Download for wit-bindgen binary failed.")
        else()
        message(STATUS "Successfully downloaded wit-bindgen binary to ${wit_bindgen_tarball_path}")
        endif()
    else()
        message(STATUS "wit-bindgen binary has already been downloaded and cached.")
    endif()

    # Extract wit-bindgen sysroot to cache directory
    message(STATUS "Extracting wit-bindgen binary to ${wit_bindgen_root}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${wit_bindgen_tarball_path}
        WORKING_DIRECTORY ${wit_bindgen_root}
    )

    # Set location of wit-bindgen
    set(${arg_WIT_BINDGEN_BINARY_OUTPUT}
        "${wit_bindgen_root}/wit-bindgen-${wit_bindgen_version}-${host_identifier}/wit-bindgen"
        PARENT_SCOPE
    )
endfunction()

# Usage:
#
# wit_bindgen(
#     INTERFACE_FILE_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/module.wit"
#     BINDINGS_DIR_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/bindings"
#     GENERATED_FILES_OUTPUT wit_codegen_output_files
# )
# ...
# add_executable(<target> ${wit_codegen_output_files} ...)
#
function(wit_bindgen)
    cmake_parse_arguments(
        PARSE_ARGV 0 "arg"
        ""
        "INTERFACE_FILE_INPUT;BINDINGS_DIR_INPUT;GENERATED_FILES_OUTPUT"
        ""
    )
    if (DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
            "${arg_UNPARSED_ARGUMENTS}"
        )
    endif()

    # Set WIT file as a dependency for re-configure on change
    set_property(
      DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
       "${arg_INTERFACE_FILE_INPUT}"
    )

    # Generate bindings from WIT file
    execute_process(
        COMMAND ${_wit_bindgen_binary} c --out-dir "${arg_BINDINGS_DIR_INPUT}" "${arg_INTERFACE_FILE_INPUT}"
        RESULT_VARIABLE wit_codegen_result
        OUTPUT_VARIABLE wit_codegen_output
    )
    if (NOT wit_codegen_result EQUAL 0)
        message(FATAL_ERROR "WebAssembly Component Interface (WIT) bindings failed to generate. \n${wit_codegen_output} \n${wit_codegen_result}")
    endif()

    # Scrape generated files from wit-bindgen
    string(REGEX MATCHALL "[^\"\\ ]+\\.(c|h|o)" wit_codegen_output_files ${wit_codegen_output})

    # Set output variable to list of generated files
    set(${arg_GENERATED_FILES_OUTPUT}
        ${wit_codegen_output_files}
        PARENT_SCOPE
    )
endfunction()