function(add_tryrun_test test_name test_file)
    # Define variables to store the results
    set(RUN_RESULT_VAR "")
    set(RUN_OUTPUT_VAR "")
    set(COMPILE_RESULT_VAR "")
    set(COMPILE_OUTPUT_VAR "")

    # Try compiling and running a source file (e.g., test.c)
    try_run(
        RUN_RESULT_VAR
        COMPILE_RESULT_VAR
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/${test_file}
        RUN_OUTPUT_VARIABLE RUN_OUTPUT_VAR
        COMPILE_OUTPUT_VARIABLE COMPILE_OUTPUT_VAR
    )

    set(TEST_RUN_MESSAGE "Running test '${test_name}'...")
    string(LENGTH "${TEST_RUN_MESSAGE}" LEN)
    string(REPEAT "=" ${LEN} SEPARATOR)

    message(STATUS "")
    message(STATUS "${SEPARATOR}")
    message(STATUS "${TEST_RUN_MESSAGE}")
    message(STATUS "${SEPARATOR}")

    # Use the results
    if("${COMPILE_RESULT_VAR}" STREQUAL "TRUE")
        if("${RUN_RESULT_VAR}" STREQUAL "0")
            message(STATUS "Compiler output:")
            message(STATUS "${COMPILE_OUTPUT_VAR}")
            message(STATUS "Test program '${test_name}' ran successfully with output: \n${RUN_OUTPUT_VAR}")
        else()
            message(STATUS "Compiler output:")
            message(SEND_ERROR "${COMPILE_OUTPUT_VAR}")
            message(STATUS "Test program '${test_name}' ran but returned exit code: ${RUN_RESULT_VAR}")
            message(SEND_ERROR "${RUN_OUTPUT_VAR}")
        endif()
    else()
        message(SEND_ERROR "Test program '${test_name}' failed to compile: ${COMPILE_OUTPUT_VAR}")
    endif()
endfunction(add_tryrun_test)
