set(TEST_NAME "exceptions_test")

include(../add_tryrun_test.cmake)

cmake_minimum_required(VERSION 3.15)

# Project information
project(test_${TEST_NAME} VERSION 1.0.0 LANGUAGES CXX)

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_tryrun_test(${TEST_NAME} main.cpp)
add_tryrun_node_test(${TEST_NAME} main.cpp)
