cmake_minimum_required(VERSION 3.25)
project(wasi_reentrancy_nested LANGUAGES CXX)

# The toolchain defines wasi_sdk_add_extras(); re-reading it here must leave the
# helper callable rather than skipping the definition.
if(NOT COMMAND wasi_sdk_add_extras)
  message(FATAL_ERROR "wasi_sdk_add_extras() is missing after a nested project()")
endif()

add_library(nested STATIC nested.cpp)
