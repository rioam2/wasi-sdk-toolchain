cmake_minimum_required(VERSION 3.25)
project(wasi_setjmp LANGUAGES C)

if(NOT WASI_SDK_SETJMP)
  message(FATAL_ERROR "this project expects WASI_SDK_SETJMP=ON")
endif()

add_executable(setjmp_test main.c)
