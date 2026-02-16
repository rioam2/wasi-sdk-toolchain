include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.25)

# Keep track of whether the toolchain has been initialized
set(WASI_TOOLCHAIN_INITIALIZED OFF)

# Function to initialize the toolchain given specific versions of the supporting tools
function(initialize_wasi_toolchain)
    # Parse arguments to the function
    cmake_parse_arguments(
        PARSE_ARGV 0 "arg"
        ""
        "WIT_BINDGEN_TAG;WASMTIME_TAG;WASM_TOOLS_TAG;WASI_SDK_TAG;TARGET_TRIPLET;ENABLE_EXPERIMENTAL_STUBS;ENABLE_EXPERIMENTAL_SETJMP"
        ""
    )
    if (DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
        "internal error: ${CMAKE_CURRENT_FUNCTION} passed extra args:"
        "${arg_UNPARSED_ARGUMENTS}"
        )
    endif()

    # Guard against being called from within a try_compile or if the toolchain has already been initialized
    get_property(IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)
    if (IN_TRY_COMPILE OR WASI_TOOLCHAIN_INITIALIZED)
      return()
    endif()
    unset(IN_TRY_COMPILE)

    # Until Platform/WASI.cmake is upstream we need to inject the path to it
    # into CMAKE_MODULE_PATH.
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}")
    set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
    
    # Add wit-bindgen utilities
    message(STATUS "Initializing WASI toolchain ${CMAKE_CURRENT_FUNCTION_LIST_DIR}")
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wit-bindgen.bootstrap.cmake)
    wit_bindgen_bootstrap(
      WIT_BINDGEN_TAG "${arg_WIT_BINDGEN_TAG}"
      WIT_BINDGEN_BINARY_OUTPUT "_wit_bindgen_binary"
    )
    set(_wit_bindgen_binary "${_wit_bindgen_binary}" PARENT_SCOPE)
    
    # Add wasmtime runtime and polyfills
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wasmtime.bootstrap.cmake)
    wasmtime_bootstrap(
      TAG "${arg_WASMTIME_TAG}"
      WASMTIME_BINARY_OUTPUT "_wasmtime_binary"
      WASMTIME_POLYFILL_DIR_OUTPUT "_wasmtime_polyfill_dir"
    )
    set(_wasmtime_binary "${_wasmtime_binary}" PARENT_SCOPE)
    set(_wasmtime_polyfill_dir "${_wasmtime_polyfill_dir}" PARENT_SCOPE)
    
    # Add wasm-tools utilities
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wasm-tools.bootstrap.cmake)
    wasm_tools_bootstrap(
      WASM_TOOLS_TAG "${arg_WASM_TOOLS_TAG}"
      WASM_TOOLS_BINARY_OUTPUT "_wasm_tools_binary"
    )
    set(_wasm_tools_binary "${_wasm_tools_binary}" PARENT_SCOPE)
    
    if (arg_WASI_SDK_TAG MATCHES "wasi-sdk-30.0-cpp-exn")
      include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wasi-sdk-exceptions.bootstrap.cmake)
      wasi_sdk_exceptions_bootstrap(
        TAG "${arg_WASI_SDK_TAG}"
        WASI_SYSROOT_OUTPUT CMAKE_SYSROOT
        WASI_SDK_BIN_OUTPUT WASI_SDK_BIN
      )
      string(APPEND CMAKE_CXX_FLAGS " -fwasm-exceptions -mllvm -wasm-use-legacy-eh=false -Wl,-lunwind")
      string(APPEND CMAKE_EXE_LINKER_FLAGS " -lunwind")
    else()
      include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wasi-sdk.bootstrap.cmake)
      wasi_sdk_bootstrap(
        TAG "${arg_WASI_SDK_TAG}"
        WASI_SYSROOT_OUTPUT CMAKE_SYSROOT
        WASI_SDK_BIN_OUTPUT WASI_SDK_BIN
      )
    endif()

    set(CMAKE_SYSROOT "${CMAKE_SYSROOT}" PARENT_SCOPE)
    
    set(CMAKE_SYSTEM_NAME WASI PARENT_SCOPE)
    set(CMAKE_SYSTEM_VERSION 1 PARENT_SCOPE)
    set(CMAKE_SYSTEM_PROCESSOR wasm32 PARENT_SCOPE)
    set(triple "${arg_TARGET_TRIPLET}")
    
    set(CMAKE_C_COMPILER "${WASI_SDK_BIN}/clang" PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER "${WASI_SDK_BIN}/clang++" PARENT_SCOPE)
    set(CMAKE_ASM_COMPILER "${WASI_SDK_BIN}/clang" PARENT_SCOPE)
    set(CMAKE_AR "${WASI_SDK_BIN}/llvm-ar" PARENT_SCOPE)
    set(CMAKE_RANLIB "${WASI_SDK_BIN}/llvm-ranlib" PARENT_SCOPE)
    set(CMAKE_LINKER "${WASI_SDK_BIN}/wasm-ld" PARENT_SCOPE)
    set(CMAKE_C_COMPILER_TARGET ${triple} PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER_TARGET ${triple} PARENT_SCOPE)
    set(CMAKE_ASM_COMPILER_TARGET ${triple} PARENT_SCOPE)
    
    # Don't look in the sysroot for executables to run during the build
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER PARENT_SCOPE)
    # Only look in the sysroot (not in the host paths) for the rest
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY PARENT_SCOPE)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY PARENT_SCOPE)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY PARENT_SCOPE)
    
    # Use compiler-rt builtins (provided by wasi-sdk)
    set(CLANG_DEFAULT_RTLIB "compiler-rt" PARENT_SCOPE)
    set(LIBCXX_USE_COMPILER_RT "YES" PARENT_SCOPE)
    set(LIBCXXABI_USE_COMPILER_RT "YES" PARENT_SCOPE)

    # Set cross-compiling emulator for test executions using the downloaded wasmtime binary
    set(CMAKE_CROSSCOMPILING_EMULATOR "${_wasmtime_binary};run;--dir;/;-Wexceptions;-D;debug-info;-O;opt-level=0" PARENT_SCOPE)

    # Add include directory from the toolchain - provides helper headers from the SDK
    include_directories(SYSTEM "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/include")
    
    # Optionally add experimental stubs for libc functions
    if (arg_ENABLE_EXPERIMENTAL_STUBS)
      # Add libc-stubs include directories
      include_directories(SYSTEM "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/include" "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/include")
      # Include libc-stubs static library for linking
      set(LIBC_STUBS_LIB_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/install/lib/libc-stubs.a" CACHE FILEPATH "Path to libc stubs")
      set(LIBCXX_STUBS_LIB_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/install/lib/libcxx-stubs.a" CACHE FILEPATH "Path to libcxx stubs")
      string(APPEND CMAKE_EXE_LINKER_FLAGS " ${LIBCXX_STUBS_LIB_PATH} ${LIBC_STUBS_LIB_PATH}")
    endif()

    if (arg_ENABLE_EXPERIMENTAL_SETJMP)
      # Enable SJLJ support
      string(APPEND CMAKE_C_FLAGS " -mllvm -wasm-enable-sjlj -mllvm -wasm-use-legacy-eh=false -Wl,-lsetjmp")
      string(APPEND CMAKE_CXX_FLAGS " -mllvm -wasm-enable-sjlj -mllvm -wasm-use-legacy-eh=false -Wl,-lsetjmp")
      string(APPEND CMAKE_EXE_LINKER_FLAGS " -lsetjmp")
    endif()

    # Add a DEBUG_ENABLED definition for debug builds
    add_compile_definitions($<$<CONFIG:Debug>:DEBUG_ENABLED=1>)

    # Build type specific compiler and linker optimization flags
    if (CMAKE_BUILD_TYPE STREQUAL "Release")
      # Compiler options for release builds
      set(common_release_opt_compiler_flags "-O3 -flto -ffast-math -msimd128 -mbulk-memory -mmultivalue -msign-ext -mnontrapping-fptoint -finline-functions -funroll-loops -fvectorize -fslp-vectorize -fomit-frame-pointer -fstrict-aliasing -fdata-sections -ffunction-sections -fmerge-all-constants")
      string(APPEND CMAKE_C_FLAGS_RELEASE " ${common_release_opt_compiler_flags}")
      string(APPEND CMAKE_CXX_FLAGS_RELEASE " ${common_release_opt_compiler_flags}")

      # Linker options for release builds
      set(common_release_opt_linker_flags "-O3 -flto -Wl,-O3,--lto-O3,--lto-CGO3 -Wl,-s,--strip-all,--strip-debug -Wl,--gc-sections -Wl,--initial-memory=67108864 -Wl,-z,stack-size=2097152")
      string(APPEND CMAKE_EXE_LINKER_FLAGS_RELEASE " ${common_release_opt_linker_flags}")

      # Enable IPO/LTO for release builds
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE PARENT_SCOPE)
    endif()
    
    # Emulated libc functions that require additional support from the toolchain
    set(common_emulated_compiler_flags "-D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_GETPID")
    string(APPEND CMAKE_CXX_FLAGS " -stdlib=libc++ ${common_emulated_compiler_flags}")
    string(APPEND CMAKE_C_FLAGS " ${common_emulated_compiler_flags}")
    string(APPEND CMAKE_EXE_LINKER_FLAGS " -lwasi-emulated-signal -lwasi-emulated-mman -lwasi-emulated-process-clocks -lwasi-emulated-getpid")

    # Export accumulated flags to parent scope
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" PARENT_SCOPE)
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" PARENT_SCOPE)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" PARENT_SCOPE)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}" PARENT_SCOPE)
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}" PARENT_SCOPE)
    
    # Interface library to enable reactor model WebAssembly files
    add_library(wasi_sdk_reactor_module INTERFACE)
    target_link_options(wasi_sdk_reactor_module INTERFACE -nostartfiles -Wl,--no-entry)

    # Set the toolchain as initialized
    set(WASI_TOOLCHAIN_INITIALIZED ON PARENT_SCOPE)

endfunction()
