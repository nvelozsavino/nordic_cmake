    if (NOT MICRO_ECC_PATH)
        message(FATAL_ERROR "MICRO_ECC_PATH not set")
    endif()
    if (WIN32 OR WIN64)
        set(MICRO_ECC_BUILD build.bat)
    else()
        set(MICRO_ECC_BUILD build.sh)
    endif()
    message(STATUS "MICRO_ECC ${MICRO_ECC_PATH}")
    add_custom_target(.
            COMMAND ${CMAKE_COMMAND} -E env "GNU_INSTALL_ROOT=${TOOLCHAIN_PREFIX}/" ${MICRO_ECC_BUILD} nrf52hf_armgcc
            WORKING_DIRECTORY "${MICRO_ECC_PATH}"
            BYPRODUCTS 	${MICRO_ECC_PATH}/nrf52hf_armgcc/armgcc/_build
                        ${MICRO_ECC_PATH}/nrf52hf_armgcc/armgcc/micro_ecc_lib_nrf52.a
                        ${MICRO_ECC_PATH}/micro-ecc
            )
