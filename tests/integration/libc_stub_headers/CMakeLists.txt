cmake_minimum_required(VERSION 3.25)
project(wasi_libc_stub_headers LANGUAGES C CXX)

if(NOT WASI_SDK_LIBC_STUBS)
  message(FATAL_ERROR "this project expects WASI_SDK_LIBC_STUBS=ON")
endif()

# A static library, like the dependencies that need this: the declarations must
# be reachable at compile time even though nothing links the stub symbols.
add_library(unported STATIC unported.cc)
