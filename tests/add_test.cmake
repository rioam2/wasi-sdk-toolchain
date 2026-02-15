function(add_test test_name test_file)
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
        message(STATUS "Test program '${test_name}' compiled successfully.")
        message(STATUS "Test program result: ${RUN_RESULT_VAR}")
        if("${RUN_RESULT_VAR}" STREQUAL "0")
            message(STATUS "Test program '${test_name}' ran successfully with output: ${RUN_OUTPUT_VAR}")
        else()
            message(SEND_ERROR "Test program '${test_name}' ran but returned exit code: ${RUN_RESULT_VAR}")
        endif()
    else()
        message(SEND_ERROR "Test program '${test_name}' failed to compile: ${COMPILE_OUTPUT_VAR}")
    endif()
endfunction(add_test)
