cmake_minimum_required(VERSION 3.25)
project(wasi_smoke LANGUAGES C CXX)

if(NOT WASI)
  message(FATAL_ERROR "expected the WASI platform variable to be set")
endif()
if(NOT CMAKE_CROSSCOMPILING)
  message(FATAL_ERROR "expected CMAKE_CROSSCOMPILING to be true")
endif()

add_executable(smoke main.cpp)
target_compile_features(smoke PRIVATE cxx_std_17)

add_executable(smoke_c main.c)
