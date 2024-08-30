include_guard(GLOBAL)

cmake_minimum_required(VERSION 3.25)

get_property(IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)

if (IN_TRY_COMPILE)
  return()
endif()

unset(IN_TRY_COMPILE)

# Check clang version
set(REQUIRED_CLANG_VERSION "17.0.0")
execute_process(COMMAND clang --version OUTPUT_VARIABLE CLANG_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
string(REGEX MATCH "[0-9]+.[0-9]+.[0-9]+" CLANG_VERSION "${CLANG_VERSION}")
if (CLANG_VERSION VERSION_LESS REQUIRED_CLANG_VERSION)
  message(FATAL_ERROR "Clang must be version ${REQUIRED_CLANG_VERSION} or greater to compile for wasm32-wasi. Current Clang version: ${CLANG_VERSION}")
endif()

# Until Platform/WASI.cmake is upstream we need to inject the path to it
# into CMAKE_MODULE_PATH.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

# Add wit-bindgen utilities
include(${CMAKE_CURRENT_LIST_DIR}/wit-bindgen.bootstrap.cmake)
wit_bindgen_bootstrap(
  WIT_BINDGEN_TAG "v0.29.0"
  WIT_BINDGEN_BINARY_OUTPUT "_wit_bindgen_binary"
)

# Add wasm-tools utilities
include(${CMAKE_CURRENT_LIST_DIR}/wasm-tools.bootstrap.cmake)
wasm_tools_bootstrap(
  WASMTIME_POLYFILL_TAG "v23.0.1"
  WASMTIME_POLYFILL_DIR_OUTPUT "_wasm_tools_polyfill_dir"
  WASM_TOOLS_TAG "v1.215.0"
  WASM_TOOLS_BINARY_OUTPUT "_wasm_tools_binary"
)

include(${CMAKE_CURRENT_LIST_DIR}/wasi-sdk.bootstrap.cmake)
wasi_sdk_bootstrap(
  TAG wasi-sdk-23
  WASI_SYSROOT_OUTPUT CMAKE_SYSROOT
  WASI_RESOURCE_DIR_OUTPUT WASI_RESOURCE_DIR
  CLANG_DEFAULT_RESOURCE_DIR_OUTPUT CLANG_DEFAULT_RESOURCE_DIR
)

set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(triple wasm32-wasip2)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_AR llvm-ar)
set(CMAKE_RANLIB llvm-ranlib)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER_TARGET ${triple})
set(CMAKE_ASM_COMPILER_TARGET ${triple})

# Don't look in the sysroot for executables to run during the build
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Only look in the sysroot (not in the host paths) for the rest
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Use compiler-rt builtins (provided by wasi-sdk)
set(CLANG_DEFAULT_RTLIB "compiler-rt")
set(LIBCXX_USE_COMPILER_RT "YES")
set(LIBCXXABI_USE_COMPILER_RT "YES")

# Global compiler flags - all targets should use compiler-rt builtins from wasi-sdk
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -resource-dir='${WASI_RESOURCE_DIR}' --include-directory-after='${CLANG_DEFAULT_RESOURCE_DIR}/include' --include-directory-after='${CMAKE_CURRENT_LIST_DIR}/include'")
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -resource-dir='${WASI_RESOURCE_DIR}' --include-directory-after='${CLANG_DEFAULT_RESOURCE_DIR}/include'")

# Release-specific compiler and linker flags because CMake does not automatically include them
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
add_link_options($<$<CONFIG:Release>:-Wl,--strip-debug,--lto-O2,--lto-CGO3,-O3>)

# Project compiler flags
add_compile_options(
  -stdlib=libc++
  -fignore-exceptions
  -D_WASI_EMULATED_SIGNAL
  -D_WASI_EMULATED_PROCESS_CLOCKS
  -D_WASI_EMULATED_MMAN
  -D_WASI_EMULATED_GETPID
)

# Project linker flags
add_link_options(
  -lwasi-emulated-signal
  -lwasi-emulated-mman
  -lwasi-emulated-process-clocks
  -lwasi-emulated-getpid
)

# Interface library to enable reactor model WebAssembly files
add_library(wasi_sdk_reactor_module INTERFACE)
target_link_options(wasi_sdk_reactor_module INTERFACE -nostartfiles -Wl,--no-entry)
