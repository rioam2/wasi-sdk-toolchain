# Adds the optional wasm32-wasi helper targets to the current project.
#
#   wasi_sdk_add_extras()
#   target_link_libraries(my_module PRIVATE wasi::reactor)
#
# Provides:
#   wasi::reactor           reactor-style module entry points and linker flags
#   wasi::abort-exceptions  __cxa_throw/__cxa_allocate_exception that abort
#   wasi::libc-stubs        declarations for unimplemented libc functionality
#
# The toolchain file includes this module, so wasi_sdk_add_extras() is already
# defined in a project it configures. Only the function is defined there: the
# targets are declared where the function is called, because targets declared by
# a toolchain cannot be exported and reappear in every nested project().

function(wasi_sdk_add_extras)
  cmake_parse_arguments(PARSE_ARGV 0 arg "" "SOURCE_DIR;BINARY_DIR" "")
  if(DEFINED arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "wasi_sdk_add_extras: unexpected arguments: ${arg_UNPARSED_ARGUMENTS}")
  endif()

  if(TARGET wasi_sdk_reactor)
    return()
  endif()

  if(NOT DEFINED arg_SOURCE_DIR OR arg_SOURCE_DIR STREQUAL "")
    if(DEFINED WASI_SDK_EXTRAS_DIR AND NOT WASI_SDK_EXTRAS_DIR STREQUAL "")
      set(arg_SOURCE_DIR "${WASI_SDK_EXTRAS_DIR}")
    else()
      set(arg_SOURCE_DIR "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../extras")
    endif()
  endif()
  if(NOT DEFINED arg_BINARY_DIR OR arg_BINARY_DIR STREQUAL "")
    set(arg_BINARY_DIR "${CMAKE_BINARY_DIR}/_wasi_sdk_extras")
  endif()

  if(NOT EXISTS "${arg_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
      "wasi-sdk: extras not found at '${arg_SOURCE_DIR}'.\n"
      "  Set WASI_SDK_EXTRAS_DIR or pass SOURCE_DIR.")
  endif()

  add_subdirectory("${arg_SOURCE_DIR}" "${arg_BINARY_DIR}" EXCLUDE_FROM_ALL)
endfunction()
