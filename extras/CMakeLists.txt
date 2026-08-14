# Optional add-ons for wasm32-wasi builds. Added to a project through
# wasi_sdk_add_extras() from cmake/WasiSdkExtras.cmake; nothing here is applied
# by the toolchain itself, so a target only gets what it asks for.

if(NOT WASI)
  message(FATAL_ERROR "wasi-sdk extras can only be built for a WASI target")
endif()

# --- wasi::reactor ---------------------------------------------------------
# OBJECT rather than STATIC: the exported symbols are unreferenced, so archive
# members would be dropped before the linker ever looks at them.
add_library(wasi_sdk_reactor OBJECT "${CMAKE_CURRENT_LIST_DIR}/src/reactor.cpp")
target_include_directories(wasi_sdk_reactor
  SYSTEM PUBLIC "${CMAKE_CURRENT_LIST_DIR}/include")
target_link_options(wasi_sdk_reactor INTERFACE -nostartfiles -Wl,--no-entry)
add_library(wasi::reactor ALIAS wasi_sdk_reactor)

# --- wasi::abort-exceptions ------------------------------------------------
add_library(wasi_sdk_abort_exceptions STATIC
  "${CMAKE_CURRENT_LIST_DIR}/src/abort_exceptions.cpp")
target_include_directories(wasi_sdk_abort_exceptions
  SYSTEM PUBLIC "${CMAKE_CURRENT_LIST_DIR}/include")
add_library(wasi::abort-exceptions ALIAS wasi_sdk_abort_exceptions)

# --- wasi::libc-stubs ------------------------------------------------------
# Declarations for libc functionality wasi-libc does not implement, so that
# unported code links. Calls fail at runtime; see libc-stubs/README.md.
#
# The headers shadow real wasi-libc headers, so they are exposed only to
# targets that opt in rather than being placed on every include path.
add_library(wasi_sdk_libc_stubs STATIC
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/fcntl.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/setjmp.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/signal.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/time.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/unistd.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/sys/eventfd.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/sys/file.c"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/sys/mman.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/src/thread.cpp")
target_include_directories(wasi_sdk_libc_stubs
  SYSTEM PUBLIC "${CMAKE_CURRENT_LIST_DIR}/libc-stubs/include")
add_library(wasi::libc-stubs ALIAS wasi_sdk_libc_stubs)

foreach(target IN ITEMS wasi_sdk_reactor wasi_sdk_abort_exceptions wasi_sdk_libc_stubs)
  set_target_properties("${target}" PROPERTIES FOLDER "wasi-sdk-extras")
endforeach()
