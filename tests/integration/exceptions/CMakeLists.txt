cmake_minimum_required(VERSION 3.25)
project(wasi_exceptions LANGUAGES C CXX)

if(NOT WASI_SDK_EXCEPTIONS STREQUAL "wasm")
  message(FATAL_ERROR "this project expects WASI_SDK_EXCEPTIONS=wasm")
endif()

add_executable(exceptions main.cpp)
target_compile_features(exceptions PRIVATE cxx_std_17)

# C emits no exception opcodes, so the encoding flag must not reach it: the
# backend aborts with "-exception-model=wasm only allowed with ...".
add_executable(exceptions_c main.c)
