cmake_minimum_required(VERSION 3.15)

# Project information
project(wasi-sdk-toolchain-libc-stubs VERSION 1.0.0 LANGUAGES C CXX)

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(c-stubs STATIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src/fcntl.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/setjmp.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/signal.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/time.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/unistd.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sys/file.c"
)

add_library(cxx-stubs STATIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src/cxxabi.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/fcntl.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/setjmp.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/signal.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/thread.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/time.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/unistd.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sys/file.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/sys/mman.cpp"
)

set_target_properties(c-stubs
    PROPERTIES 
        LINKER_LANGUAGE C
)

set_target_properties(cxx-stubs
    PROPERTIES 
        LINKER_LANGUAGE CXX
)

target_include_directories(c-stubs PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_include_directories(cxx-stubs PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

install(TARGETS c-stubs DESTINATION lib)
install(TARGETS cxx-stubs DESTINATION lib)
