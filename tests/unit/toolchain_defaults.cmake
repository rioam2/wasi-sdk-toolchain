include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")

set(WASI_SDK_ROOT "${FIXTURE_SDK}")
include("${REPO_DIR}/wasi-sdk.toolchain.cmake")

expect_eq("${CMAKE_SYSTEM_NAME}" "WASI" "system name")
expect_eq("${CMAKE_SYSTEM_PROCESSOR}" "wasm32" "system processor")
expect_eq("${CMAKE_SYSTEM_VERSION}" "1" "system version")
expect_eq("${CMAKE_SYSROOT}" "${FIXTURE_SDK}/share/wasi-sysroot" "sysroot")

expect_eq("${WASI_SDK_TARGET_TRIPLE}" "wasm32-wasip1" "default triple")
foreach(lang IN ITEMS C CXX ASM)
  expect_eq("${CMAKE_${lang}_COMPILER_TARGET}" "wasm32-wasip1" "${lang} compiler target")
endforeach()

expect_match("${CMAKE_C_COMPILER}" "fake-sdk/bin/clang" "C compiler comes from the SDK")
expect_match("${CMAKE_CXX_COMPILER}" "fake-sdk/bin/clang\\+\\+" "CXX compiler comes from the SDK")
expect_match("${CMAKE_AR}" "fake-sdk/bin/llvm-ar" "archiver comes from the SDK")
expect_match("${CMAKE_RANLIB}" "fake-sdk/bin/llvm-ranlib" "ranlib comes from the SDK")

expect_eq("${CMAKE_FIND_ROOT_PATH_MODE_PROGRAM}" "NEVER" "host programs stay findable")
foreach(mode IN ITEMS LIBRARY INCLUDE PACKAGE)
  expect_eq("${CMAKE_FIND_ROOT_PATH_MODE_${mode}}" "ONLY" "${mode} lookups are sysroot-only")
endforeach()

# Linking runs through the clang driver; naming wasm-ld here breaks CMake's own
# linker detection, so the toolchain must leave it unset.
expect_eq("${CMAKE_LINKER}" "" "CMAKE_LINKER is left for CMake to determine")

expect_match("${CMAKE_CXX_FLAGS_INIT}" "-stdlib=libc\\+\\+" "libc++ is the default C++ stdlib")
# clang selects the sysroot's "noeh" multilib by default, whose libc++ is built
# for -fno-exceptions; omitting the flag produces undefined exception symbols.
expect_match("${CMAKE_CXX_FLAGS_INIT}" "-fno-exceptions" "exceptions are off by default")

# Nothing optional may be enabled implicitly.
expect_no_match("${CMAKE_C_FLAGS_INIT}" "_WASI_EMULATED" "no emulated defines by default")
expect_no_match("${CMAKE_C_STANDARD_LIBRARIES}" "wasi-emulated" "no emulated libs by default")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "fwasm-exceptions" "no wasm exceptions by default")
expect_no_match("${CMAKE_C_FLAGS_INIT}" "-fno-exceptions" "C is not given a C++ flag")
expect_no_match("${CMAKE_C_FLAGS_INIT}" "sjlj" "no setjmp support by default")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "-O[0-9s]" "no optimisation policy by default")
expect_no_match("${CMAKE_CXX_FLAGS_INIT}" "flto" "no LTO policy by default")
expect_eq("${CMAKE_CROSSCOMPILING_EMULATOR}" "" "no emulator unless one is given")

message(STATUS "toolchain defaults OK")
