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
    
    # Add wasm-tools utilities
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wasm-tools.bootstrap.cmake)
    wasm_tools_bootstrap(
      WASMTIME_POLYFILL_TAG "${arg_WASMTIME_TAG}"
      WASMTIME_POLYFILL_DIR_OUTPUT "_wasm_tools_polyfill_dir"
      WASM_TOOLS_TAG "${arg_WASM_TOOLS_TAG}"
      WASM_TOOLS_BINARY_OUTPUT "_wasm_tools_binary"
    )
    set(_wasm_tools_binary "${_wasm_tools_binary}" PARENT_SCOPE)
    set(_wasm_tools_polyfill_dir "${_wasm_tools_polyfill_dir}" PARENT_SCOPE)
    
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wasi-sdk.bootstrap.cmake)
    wasi_sdk_bootstrap(
      TAG "${arg_WASI_SDK_TAG}"
      WASI_SYSROOT_OUTPUT CMAKE_SYSROOT
      WASI_SDK_BIN_OUTPUT WASI_SDK_BIN
    )

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
    
    # Add include directory from the toolchain - provides helper headers from the SDK
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I'${CMAKE_CURRENT_FUNCTION_LIST_DIR}/include'" PARENT_SCOPE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I'${CMAKE_CURRENT_FUNCTION_LIST_DIR}/include'" PARENT_SCOPE)
    
    # Optionally add experimental stubs for libc functions
    if (arg_ENABLE_EXPERIMENTAL_STUBS)
      # Add libc-stubs include directories
       set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I'${CMAKE_CURRENT_FUNCTION_LIST_DIR}/include' -I'${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/include'" PARENT_SCOPE)
       set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I'${CMAKE_CURRENT_FUNCTION_LIST_DIR}/include' -I'${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/include'" PARENT_SCOPE)
      # Include libc-stubs static library for linking
       set(LIBC_STUBS_LIB_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/install/lib/libc-stubs.a" CACHE FILEPATH "Path to libc stubs")
       set(LIBCXX_STUBS_LIB_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libc-stubs/install/lib/libcxx-stubs.a" CACHE FILEPATH "Path to libcxx stubs")
      add_link_options(${LIBCXX_STUBS_LIB_PATH} ${LIBC_STUBS_LIB_PATH})
    endif()

    if (arg_ENABLE_EXPERIMENTAL_SETJMP)
      # Enable SJLJ support
      add_compile_options(-mllvm -wasm-enable-sjlj)
      add_link_options(-mllvm -wasm-enable-sjlj -lsetjmp -Wl,-mllvm,-wasm-enable-sjlj,-mllvm,-wasm-use-legacy-eh=false)
    endif()

    # Add a DEBUG_ENABLED definition for debug builds
    add_compile_definitions($<$<CONFIG:Debug>:DEBUG_ENABLED=1>)

    # Build type specific compiler and linker optimization flags
    add_compile_options(
      $<$<CONFIG:Debug>:-O0>
      $<$<CONFIG:Debug>:-g>
      $<$<CONFIG:Debug>:-fno-inline>
      $<$<CONFIG:Debug>:-fno-omit-frame-pointer>
      $<$<CONFIG:Release>:-O3>
      $<$<CONFIG:Release>:-flto>
      $<$<CONFIG:Release>:-ffast-math>
      $<$<CONFIG:Release>:-msimd128>
      $<$<CONFIG:Release>:-mbulk-memory>
      $<$<CONFIG:Release>:-mmultivalue>
      $<$<CONFIG:Release>:-msign-ext>
      $<$<CONFIG:Release>:-mnontrapping-fptoint>
      $<$<CONFIG:Release>:-finline-functions>
      $<$<CONFIG:Release>:-funroll-loops>
      $<$<CONFIG:Release>:-fvectorize>
      $<$<CONFIG:Release>:-fslp-vectorize>
      $<$<CONFIG:Release>:-fomit-frame-pointer>
      $<$<CONFIG:Release>:-fstrict-aliasing>
      $<$<CONFIG:Release>:-fdata-sections>
      $<$<CONFIG:Release>:-ffunction-sections>
      $<$<CONFIG:Release>:-fmerge-all-constants>
    )

    # Linker options for release builds
    add_link_options(
      $<$<CONFIG:Release>:-O3>
      $<$<CONFIG:Release>:-flto>
      $<$<CONFIG:Release>:-Wl,-O3,--lto-O3,--lto-CGO3>
      $<$<CONFIG:Release>:-Wl,-s,--strip-all,--strip-debug>
      $<$<CONFIG:Release>:-Wl,--gc-sections>
      $<$<CONFIG:Release>:-Wl,--initial-memory=67108864>
      $<$<CONFIG:Release>:-Wl,-z,stack-size=2097152>
    )

    # Enable IPO/LTO for release builds
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE PARENT_SCOPE)

    # Project compiler flags
    add_compile_options(
      $<$<COMPILE_LANGUAGE:CXX>:-stdlib=libc++>
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

    # Set the toolchain as initialized
    set(WASI_TOOLCHAIN_INITIALIZED ON PARENT_SCOPE)

endfunction()
