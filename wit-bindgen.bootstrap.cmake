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

    # Ensure wit-bindgen is installed and in path
    find_program(WIT_BINDGEN_EXECUTABLE "wit-bindgen")
    if(NOT WIT_BINDGEN_EXECUTABLE)
        message(FATAL_ERROR
            "internal error: wit-bindgen is not installed."
            "https://github.com/bytecodealliance/wit-bindgen/blob/main/README.md#cli-installation"
        )
    endif()

    # Generate bindings from WIT file
    execute_process(
        COMMAND ${WIT_BINDGEN_EXECUTABLE} c --out-dir "${arg_BINDINGS_DIR_INPUT}" "${arg_INTERFACE_FILE_INPUT}"
        RESULT_VARIABLE wit_codegen_result
        OUTPUT_VARIABLE wit_codegen_output
    )
    if (NOT wit_codegen_result EQUAL 0)
        message(FATAL_ERROR "WebAssembly Component Interface (WIT) bindings failed to generate. \n${wit_codegen_output}")
    endif()

    # Scrape generated files from wit-bindgen
    string(REGEX MATCHALL "[^\"\\ ]+\\.(c|h|o)" wit_codegen_output_files ${wit_codegen_output})

    # Set output variable to list of generated files
    set(${arg_GENERATED_FILES_OUTPUT}
        ${wit_codegen_output_files}
        PARENT_SCOPE
    )
endfunction()