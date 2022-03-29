cmake_minimum_required(VERSION 3.4.0)
include(${CMAKE_CURRENT_LIST_DIR}/utils.cmake)

function(GENERATE_DFU_ZIP_CMD TYPE ZIP_FILE OUTPUT_VAR)
    set(TYPES BL SD APP BL+SD BL+SD+APP SD+APP)
    EXTRACT_PARAM(APP_HEX_FILE ${ARGV})
    EXTRACT_PARAM(APP_VERSION ${ARGV})

    EXTRACT_PARAM(SOFTDEVICE_HEX_FILE ${ARGV})
    EXTRACT_PARAM(SOFTDEVICE_FWID_REQ ${ARGV})
    EXTRACT_PARAM(SOFTDEVICE_FWID_ID ${ARGV})

    EXTRACT_PARAM(BOOTLOADER_HEX_FILE ${ARGV})
    EXTRACT_PARAM(BOOTLOADER_VERSION ${ARGV})

    EXTRACT_PARAM(KEY_PEM_FILE ${ARGV})
    EXTRACT_PARAM(NRF_HW_VERSION ${ARGV})
#    math(EXPR lastIndex "${ARGC}-1")
#    message("lastIndex = ${lastIndex}")
#
#
#    foreach(index RANGE 0 ${lastIndex})
#        MATH(EXPR val_index "${index}+1")
#        message("arguments at index ${index}: ${ARGV${index}} val_index ${val_index}")
#        if ("${ARGV${index}}" STREQUAL "BOOT_FILE" AND ${val_index} LESS_EQUAL ${lastIndex})
#            set(VALUE ${ARGV${val_index}})
#            set(BOOTLOADER_HEX_FILE ${VALUE})
#            message(STATUS "BOOT_FILE = ${BOOTLOADER_HEX_FILE} (Bootloader hex file)")
#        else()
#            continue()
#        endif()
#
#    endforeach()

    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== GENERATE_DFU_ZIP - Starting ====")
    message(STATUS "\n")
    message(STATUS "Function Parameters:")
    message(STATUS "\t TYPE = ${TYPE} (Type of the Update file: ${TYPES})")
    message(STATUS "\t ZIP_FILE = ${ZIP_FILE} (Output zip file)")
    message(STATUS "\n")
    message(STATUS "Global Variables:")

    message(STATUS "\t APP_HEX_FILE = ${APP_HEX_FILE} (Application hex file)")
    message(STATUS "\t APP_VERSION = ${APP_VERSION} (Application Version)")

    message(STATUS "\t SOFTDEVICE_HEX_FILE = ${SOFTDEVICE_HEX_FILE} (Softdevice hex file)")
    message(STATUS "\t SOFTDEVICE_FWID_REQ = ${SOFTDEVICE_FWID_REQ} (Required Softdevice to be present on the device)")
    message(STATUS "\t SOFTDEVICE_FWID_ID = ${SOFTDEVICE_FWID_ID} (New Softdevice to be installed)")

    message(STATUS "\t BOOTLOADER_HEX_FILE = ${BOOTLOADER_HEX_FILE} (Bootloader hex file)")
    message(STATUS "\t BOOTLOADER_VERSION = ${BOOTLOADER_VERSION} (Bootloader VERSION)")
    message(STATUS "\t KEY_PEM_FILE = ${KEY_PEM_FILE} (Sign key)")
    message(STATUS "\t NRF_HW_VERSION = ${NRF_HW_VERSION} (Hardware Version)")
    message(STATUS "\n")

    if (NOT NRFUTIL_BIN)
        find_program(NRFUTIL_BIN nrfutil)
    endif()
    if (NOT NRFUTIL_BIN)
        message(WARNING "nrfutil not found, no Update zip can be generated")
        return()
    endif()

    if (NOT NRF_HW_VERSION)
        set (NRF_HW_VERSION 52)
        message(STATUS "Using NRF_HW_VERSION = ${NRF_HW_VERSION} as default" )
    endif()

    CHECK_VAR_FILE(KEY_PEM_FILE)
    if (NOT KEY_PEM_FILE-REALPATH)
        message(WARNING "No KEY_PEM_FILE was specified or ${KEY_PEM_FILE} doesn't exist")
        return()
    endif()

    if (NOT SOFTDEVICE_FWID_REQ)
        message(WARNING "No SOFTDEVICE_FWID_REQ was specified, please check codes in
		 		https://github.com/NordicSemiconductor/pc-nrfutil/blob/master/README.md")
        return()
    endif()

    set(REQ_CMD ${NRFUTIL_BIN} pkg generate
            --key-file ${KEY_PEM_FILE-REALPATH}
            --hw-version ${NRF_HW_VERSION}
            --sd-req ${SOFTDEVICE_FWID_REQ})



    if (NOT ${TYPE} IN_LIST TYPES)
        message(WARNING "Unknown update type ${TYPE}, it should be one of these: ${TYPES}")
        return()
    endif()

    # check Files
    set(APP_TYPES APP BL+SD+APP SD+APP)

    if (${TYPE} IN_LIST APP_TYPES)
        message(STATUS "Check for Application hex file ${APP_HEX_FILE}")
        CHECK_VAR_FILE(APP_HEX_FILE CREATE)
        if (NOT APP_HEX_FILE-REALPATH)
            message(WARNING "No APP_HEX_FILE was specified or ${APP_HEX_FILE} doesn't exist")
            return()
        endif()
        IS_NUMBER(APP_VERSION)
        if (NOT DEFINED APP_VERSION OR NOT APP_VERSION-IS_NUMBER)
            message(WARNING "APP_VERSION (${APP_VERSION}) incorrect, expected number")
            return()
        endif()
        set(APP_CMD --application ${APP_HEX_FILE-REALPATH} --application-version ${APP_VERSION})
    endif()


    set(BL_TYPES BL BL+SD BL+SD+APP)
    if (${TYPE} IN_LIST BL_TYPES)
        message(STATUS "Check for Bootloader hex file ${BOOTLOADER_HEX_FILE}")
        CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
        if (NOT BOOTLOADER_HEX_FILE-REALPATH)
            message(WARNING "No BOOTLOADER_HEX_FILE was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
            return()
        endif()

        IS_NUMBER(BOOTLOADER_VERSION)
        if (NOT DEFINED BOOTLOADER_VERSION OR NOT BOOTLOADER_VERSION-IS_NUMBER)
            message(WARNING "BOOTLOADER_VERSION (${BOOTLOADER_VERSION}) incorrect, expected number")
            return()
        endif()
        set(BOOT_CMD --bootloader ${BOOTLOADER_HEX_FILE-REALPATH} --bootloader-version ${BOOTLOADER_VERSION})
    endif()

    set(SD_TYPES SD BL+SD BL+SD+APP SD+APP)
    if (${TYPE} IN_LIST SD_TYPES)
        message(STATUS "Check for Softdevice hex file ${SOFTDEVICE_HEX_FILE}")
        CHECK_VAR_FILE(SOFTDEVICE_HEX_FILE)
        if (NOT SOFTDEVICE_HEX_FILE-REALPATH)
            message(WARNING "No SOFTDEVICE_HEX_FILE was specified or ${SOFTDEVICE_HEX_FILE} doesn't exist")
            return()
        endif()
        set(SD_CMD --softdevice ${SOFTDEVICE_HEX_FILE-REALPATH})
    endif()

    set(SD_APP_TYPES BL+SD+APP SD+APP)
    if (${TYPE} IN_LIST SD_APP_TYPES)
        if (NOT SOFTDEVICE_FWID_ID)
            message(WARNING "No SOFTDEVICE_FWID_ID was specified, please check codes in
		 		https://github.com/NordicSemiconductor/pc-nrfutil/blob/master/README.md")
            return()
        endif()
        set(SD_ID_CMD --sd-id ${SOFTDEVICE_FWID_ID})
    endif()

    set(GENERATE_ZIP_CMD
            ${REQ_CMD}
            ${APP_CMD}
            ${BOOT_CMD}
            ${SD_CMD}
            ${SD_ID_CMD}
            ${ZIP_FILE}
            )
    message(STATUS "GENERATE_ZIP_CMD: ${GENERATE_ZIP_CMD}")
    message(STATUS "Update file: ${ZIP_FILE}")
    set(${OUTPUT_VAR} ${GENERATE_ZIP_CMD} PARENT_SCOPE)

    message(STATUS "==== GENERATE_DFU_ZIP - Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
endfunction()

function(GENERATE_DFU_ZIP TARGET TYPE ZIP_FILE)
    EXTRACT_PARAM(DEPENDS ${ARGV})
    if (DEPENDS)
        message(STATUS "DEPENDS ${DEPENDS}")
    endif()
    GENERATE_DFU_ZIP_CMD(${TYPE} ${ZIP_FILE} GENERATE_ZIP_CMD ${ARGV})
    if (GENERATE_ZIP_CMD)
    add_custom_target(${TARGET}
            DEPENDS ${DEPENDS}
            COMMAND ${GENERATE_ZIP_CMD}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)
    endif()
endfunction()

function(GENERATE_SETTINGS_CMD SETTINGS_FILE OUTPUT_VAR)
    set(ARGV_LIST ${ARGV})
    EXTRACT_PARAM(APP_HEX_FILE ${ARGV})
    EXTRACT_PARAM(APP_VERSION ${ARGV})
    EXTRACT_PARAM(KEY_PEM_FILE ${ARGV})

    EXTRACT_PARAM(SOFTDEVICE_HEX_FILE ${ARGV})
    EXTRACT_PARAM(SOFTDEVICE_FWID_REQ ${ARGV})
    EXTRACT_PARAM(SOFTDEVICE_FWID_ID ${ARGV})

    EXTRACT_PARAM(NRF_FAMILY ${ARGV})
    EXTRACT_PARAM(BOOTLOADER_VERSION ${ARGV})
    EXTRACT_PARAM(BL_SETTINGS_VERSION ${ARGV})

    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== GENERATE_SETTINGS - Starting ====")
    message(STATUS "\n")
    message(STATUS "Function Parameters:")
    message(STATUS "\t SETTINGS_FILE = ${SETTINGS_FILE} (Output hex file)")
    message(STATUS "\n")
    message(STATUS "Global Variables:")
    message(STATUS "\t NRF_FAMILY = ${NRF_FAMILY} (nrf family: NRF51, NRF52, NRF52QFAB, NRF52810, NRF52840")
    message(STATUS "\t BOOTLOADER_VERSION = ${BOOTLOADER_VERSION} (The bootloader version: INTEGER")
    message(STATUS "\t BL_SETTINGS_VERSION = ${BL_SETTINGS_VERSION} (The Bootloader settings version.Defined in
                                  nrf_dfu_types.h: INTEGER")
    message(STATUS "\t APP_HEX_FILE = ${APP_HEX_FILE} (Application hex file)")
    message(STATUS "\t APP_VERSION = ${APP_VERSION} (Application Version)")
    message(STATUS "\t KEY_PEM_FILE = ${KEY_PEM_FILE} (Sign key)")


    if (NOT NRFUTIL_BIN)
        find_program(NRFUTIL_BIN nrfutil)
    endif()
    if (NOT NRFUTIL_BIN)
        message(WARNING "nrfutil not found, no Update zip can be generated")
        return()
    endif()

    if (NOT NRF_FAMILY)
        message(WARNING "NRF_FAMILY not set. Use: NRF51, NRF52, NRF52QFAB, NRF52810 or NRF52840")
        return()
    endif()

    IS_NUMBER(BOOTLOADER_VERSION)
    message(STATUS "BOOTLOADER_VERSION ${BOOTLOADER_VERSION} is number ${BOOTLOADER_VERSION-IS_NUMBER}")
    if (NOT DEFINED BOOTLOADER_VERSION OR NOT BOOTLOADER_VERSION-IS_NUMBER)
        message(WARNING "BOOTLOADER_VERSION (${BOOTLOADER_VERSION}) incorrect, expected number")
        return()
    endif()
    IS_NUMBER(BL_SETTINGS_VERSION)
    message(STATUS "BOOTLOADER_VERSION ${BL_SETTINGS_VERSION} is number ${BL_SETTINGS_VERSION-IS_NUMBER}")
    if (NOT DEFINED BOOTLOADER_VERSION OR NOT BOOTLOADER_VERSION-IS_NUMBER)
        message(WARNING "BL_SETTINGS_VERSION (${BL_SETTINGS_VERSION}) incorrect, expected number")
        return()
    endif()

    set(REQ_CMD ${NRFUTIL_BIN} settings generate
            --family ${NRF_FAMILY}
            --bootloader-version ${BOOTLOADER_VERSION}
            --bl-settings-version ${BL_SETTINGS_VERSION})




    if (APP_HEX_FILE OR APP_VERSION)
        message(STATUS "Check for Application hex file ${APP_HEX_FILE}")
        CHECK_VAR_FILE(APP_HEX_FILE CREATE)
        if (NOT APP_HEX_FILE-REALPATH)
            message(WARNING "No APP_HEX_FILE was specified or ${APP_HEX_FILE} doesn't exist")
            return()
        endif()
        IS_NUMBER(APP_VERSION)
        message(STATUS "APP_VERSION ${APP_VERSION} is number ${APP_VERSION-IS_NUMBER}")
        if (NOT DEFINED APP_VERSION OR NOT APP_VERSION-IS_NUMBER)
            return()
        endif()
        set(APP_CMD --application ${APP_HEX_FILE-REALPATH} --application-version ${APP_VERSION})
    endif()


    if (KEY_PEM_FILE)
        message(STATUS "Check for Key PEM file hex file ${KEY_PEM_FILE}")
        CHECK_VAR_FILE(KEY_PEM_FILE)
        if (NOT KEY_PEM_FILE-REALPATH)
            message(WARNING "No KEY_PEM_FILE was specified or ${KEY_PEM_FILE} doesn't exist")
            return()
        endif()
        set(KEY_CMD --key-file ${KEY_PEM_FILE-REALPATH})
    endif()

    set(GENERATE_SETTINGS_CMD
            ${REQ_CMD}
            ${APP_CMD}
            ${KEY_CMD}
            ${SETTINGS_FILE}
            )
    message(STATUS "GENERATE_SETTINGS_CMD: ${GENERATE_SETTINGS_CMD}")
    message(STATUS "Settings file: ${SETTINGS_FILE}")

    set(${OUTPUT_VAR} ${GENERATE_SETTINGS_CMD} PARENT_SCOPE)

    message(STATUS "==== GENERATE_SETTINGS - Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
endfunction()

function(GENERATE_SETTINGS TARGET SETTINGS_FILE)
    GENERATE_SETTINGS_CMD(${SETTINGS_FILE} GENERATE_SETTINGS_CMD ${ARGV})
    if (GENERATE_SETTINGS_CMD)
        add_custom_target(${TARGET}
                COMMAND ${GENERATE_SETTINGS_CMD}
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)
    endif()

endfunction()

function(MERGE_FILES_CMD FILES_VAR OUTPUT_FILE OUTPUT_VAR)
    set(INPUT_FILES ${${FILES_VAR}})
    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== MERGE_FILES- Starting ====")
    message(STATUS "\n")
    message(STATUS "Function Parameters:")
    message(STATUS "\t FILES_VAR = ${INPUT_FILES} (Input hex files)")
    message(STATUS "\t OUTPUT_FILE = ${OUTPUT_FILE} (Output hex file)")
    message(STATUS "\n")

    if (NOT MERGEHEX_BIN)
        find_program(MERGEHEX_BIN mergehex)
    endif()
    if (NOT MERGEHEX_BIN)
        message(FATAL_ERROR "mergehex not found, no merge can be done")
        return()
    endif()

    list(LENGTH INPUT_FILES INPUT_FILES-LENGTH)
    message(STATUS "INPUT_FILES length = ${INPUT_FILES-LENGTH}")
    if (${INPUT_FILES-LENGTH} LESS 2)
        message(FATAL_ERROR "At least 2 files are needed to do a merge ${INPUT_FILES}")
        return()
    endif()

    set(MERGE_CMD
            ${MERGEHEX_BIN} -m ${INPUT_FILES} -o ${OUTPUT_FILE})
    message(STATUS "MERGE_CMD: ${MERGE_CMD}")
    message(STATUS "Output file: ${OUTPUT_FILE}")
    set(${OUTPUT_VAR} ${MERGE_CMD} PARENT_SCOPE)
    message(STATUS "==== MERGE_FILES - Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
endfunction()
function(MERGE_FILES TARGET FILES_VAR OUTPUT_FILE)
    MERGE_FILES_CMD(${FILES_VAR} ${OUTPUT_FILE} MERGE_CMD)
    if (MERGE_CMD)
        add_custom_target(${TARGET}
                COMMAND ${MERGE_CMD}
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)
    endif()
endfunction()

function(GENERATE_DFU_KEY_CMD KEY_PEM_FILE OUTPUT_FILE OUTPUT_VAR)
    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== GENERATE_DFU_KEY_CMD- Starting ====")
    message(STATUS "\n")
    message(STATUS "Function Parameters:")
    message(STATUS "\t KEY_PEM_FILE = ${KEY_PEM_FILE} (Key file)")
    message(STATUS "\t OUTPUT_FILE = ${OUTPUT_FILE} (Output c file)")
    message(STATUS "\n")

    if (NOT NRFUTIL_BIN)
        find_program(NRFUTIL_BIN nrfutil)
    endif()
    if (NOT NRFUTIL_BIN)
        message(WARNING "nrfutil not found, no Update zip can be generated")
        return()
    endif()



    message(STATUS "Check for Key PEM file hex file ${KEY_PEM_FILE}")
    CHECK_VAR_FILE(KEY_PEM_FILE)
    if (NOT KEY_PEM_FILE-REALPATH)
        message(WARNING "No KEY_PEM_FILE was specified or ${KEY_PEM_FILE} doesn't exist")
        return()
    endif()
    set(KEY_CMD --key-file ${KEY_PEM_FILE})


    CHECK_VAR_FILE(OUTPUT_FILE CREATE)
    if (NOT OUTPUT_FILE-REALPATH)
        message(WARNING "No OUTPUT_FILE was specified")
        return()
    endif()

    set(GENERATE_CODE_CMD ${NRFUTIL_BIN} keys display
            --key pk
            --format code
            --out_file ${OUTPUT_FILE-REALPATH}
            ${KEY_PEM_FILE}
            )
    message(STATUS "CMD: ${GENERATE_CODE_CMD}")
    set(${OUTPUT_VAR} ${GENERATE_CODE_CMD} PARENT_SCOPE)

    message(STATUS "==== GENERATE_DFU_KEY_CMD - Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
endfunction()

function(GENERATE_DFU_KEY TARGET KEY_PEM_FILE OUTPUT_FILE)
    CHECK_VAR_FILE(OUTPUT_FILE CREATE)
    GENERATE_DFU_KEY_CMD(${KEY_PEM_FILE} ${OUTPUT_FILE-REALPATH} GENERATE_CODE_CMD)
    if (GENERATE_CODE_CMD)
        message(STATUS "Creating DFU Key in ${OUTPUT_FILE-REALPATH}")
        add_custom_command(OUTPUT ${OUTPUT_FILE-REALPATH}
                COMMAND ${GENERATE_CODE_CMD}
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                USES_TERMINAL
                )
    endif()
endfunction()

function(GENERATE_FLASH_CMD FILE OUTPUT_VAR)

    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== GENERATE_FLASH_CMD- Starting ====")
    message(STATUS "\n")
    message(STATUS "Function Parameters:")
    message(STATUS "\t FILE = ${FILE} (File to flash)")
    message(STATUS "\n")

    CHECK_VAR_FILE(FILE CREATE)
    if (NOT FILE-REALPATH)
        message(WARNING "No FILE was specified")
        return()
    endif()

    IS_PARAM(MASS_ERASE ${ARGV})
    IS_PARAM(RESET ${ARGV})
    IS_PARAM(NOT_VERIFY ${ARGV})

    if (MASS_ERASE)
        message(STATUS "\t MASS_ERASE Enabled")
    else()
        message(STATUS "\t MASS_ERASE Disabled")
    endif()

    if (RESET)
        message(STATUS "\t RESET Enabled")
    else()
        message(STATUS "\t RESET Disabled")
    endif()

    if (NOT_VERIFY)
        message(STATUS "\t NOT_VERIFY Enabled (Verification disabled)")
    else()
        message(STATUS "\t NOT_VERIFY Disabled (Verification enabled)")
    endif()
    IS_PARAM(ALL ${ARGV})
    if (ALL)
        set(SEGGER TRUE)
        set(OPENOCD TRUE)
    else()
        IS_PARAM(SEGGER ${ARGV})
        IS_PARAM(OPENOCD ${ARGV})
    endif()
    if (SEGGER)
        message(STATUS "\t SEGGER Enabled")
    else()
        message(STATUS "\t SEGGER Disabled")
    endif()
    if (OPENOCD)
        message(STATUS "\t OPENOCD Enabled")
    else()
        message(STATUS "\t OPENOCD Disabled")
    endif()

    if (NOT SEGGER AND NOT OPENOCD)
        message(WARNING "At least one of the options SEGGER, OPENOCD must be selected")
        return()
    endif()

    if (SEGGER)
        if (NOT NRFJPROG_BIN)
            find_program(NRFJPROG_BIN nrfjprog)
        endif()
        if (NOT NRFJPROG_BIN)
            message(WARNING "nrfjprog was not found and is required to Flash with SEGGER")
            set(SEGGER FALSE)
        else()
            EXTRACT_PARAM(NRFJPROG_FAMILY ${ARGV})
            if (NOT NRFJPROG_FAMILY)
                message(STATUS "NRFJPROG_FAMILY not set, using default: NRF52. Other options:
                 NRF51, NRF52, NRF53, NRF91, and UNKNOWN")
                set(NRFJPROG_FAMILY NRF52)
            else()
                message(STATUS "NRFJPROG_FAMILY set to ${NRF_FAMILY}")
            endif()
            set(SEGGER_CMD
                    ${NRFJPROG_BIN} -f ${NRFJPROG_FAMILY} --program ${FILE-REALPATH})
            if (MASS_ERASE)
                set(SEGGER_CMD ${SEGGER_CMD} --chiperase)
            endif()
            if (NOT NOT_VERIFY)
                set(SEGGER_CMD ${SEGGER_CMD} --verify)
            endif()
            if (RESET)
                set(SEGGER_CMD ${SEGGER_CMD} --reset)
            endif()
            set(SEGGER_CMD ${SEGGER_CMD} --log)

            message(STATUS "Segger CMD: ${SEGGER_CMD}")
            set(${OUTPUT_VAR}-SEGGER ${SEGGER_CMD} PARENT_SCOPE)
        endif()
    endif()

    if (OPENOCD)
        if (NOT OPENOCD_BIN)
            find_program(OPENOCD_BIN openocd)
        endif()
        if (NOT OPENOCD_BIN)
            message(WARNING "OpenOCD was not found")
            set(OPENOCD FALSE)
        else()
            EXTRACT_PARAM(OPENOCD_CFG ${ARGV})
            if (NOT OPENOCD_CFG)
                message(STATUS "OpenOCD cfg (OPENOCD_CFG) file is not set, using default: nrf52_stlink.cfg")
                set(OPENOCD_CFG ${CMAKE_CURRENT_SOURCE_DIR}/nrf52_stlink.cfg)
            else()
                message(STATUS "OpenOCD cfg (OPENOCD_CFG) set to ${OPENOCD_CFG}")
            endif()

            EXTRACT_PARAM(OPENOCD_SCRIPT ${ARGV})
            if (NOT OPENOCD_SCRIPT)
                message(STATUS "OpenOCD script file (OPENOCD_SCRIPT_CMD) is not set, using none")
            else()
                set(OPENOCD_SCRIPT_CMD "-s \"${OPENOCD_SCRIPT}\"")
                message(STATUS "OpenOCD script file (OPENOCD_SCRIPT_CMD) set to ${OPENOCD_SCRIPT_CMD}")
            endif()

            EXTRACT_PARAM(OPENOCD_RESET_CFG ${ARGV})
            if (NOT OPENOCD_RESET_CFG)
                message(STATUS "OpenOCD reset cfg (OPENOCD_RESET_CFG) not set, using reset-config none")
                set(OPENOCD_RESET_CFG_CMD -c "reset_config none")
            else()
                set(OPENOCD_RESET_CFG_CMD -c "reset_config ${OPENOCD_RESET_CFG}")
                message(STATUS "OpenOCD reset cfg (OPENOCD_RESET_CFG) set to ${OPENOCD_RESET_CFG}")

            endif()

            EXTRACT_PARAM(HLA_SERIAL ${ARGV})
            if (HLA_SERIAL)
                message(STATUS "OpenOCD HLA_SERIAL set to ${HLA_SERIAL}")
                set(HLA_SERIAL_CMD -c "hla_serial ${HLA_SERIAL}")
            else()
                message(STATUS "OpenOCD HLA_SERIAL not set")
            endif()

            EXTRACT_PARAM(OPENOCD_EXTRA_CMD ${ARGV})
            if (OPENOCD_EXTRA_CMD)
                message(STATUS "OpenOCD extra command (OPENOCD_EXTRA_CMD) set to: ${OPENOCD_EXTRA_CMD}")
            else()
                message(STATUS "NO OpenOCD extra command (OPENOCD_EXTRA_CMD) not set")
            endif()

            if (MASS_ERASE)
#                message(STATUS "OpenOCD mass erase")
                set(OPENOCD_MASS_ERASE_CMD -c "nrf5 mass_erase")
            endif()
            if (NOT NOT_VERIFY)
                set(OPENOCD_PROGRAM_CMD -c "program \"${SETTINGS_HEX_FILE}\"")
            else()
                set(OPENOCD_PROGRAM_CMD -c "program \"${SETTINGS_HEX_FILE}\" verify")
            endif()
            set(OPENOCD_CMD
                    ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD}
                    ${HLA_SERIAL_CMD}
                    ${OPENOCD_EXTRA_CMD}
                    ${OPENOCD_RESET_CFG_CMD}
                    -c init
                    -c halt
                    ${OPENOCD_MASS_ERASE_CMD}
                    ${OPENOCD_PROGRAM_CMD}
                    )


            if (RESET)
                set(OPENOCD_CMD ${OPENOCD_CMD} -c reset)
            endif()
            IS_PARAM(OPENOCD_NO_EXIT ${ARGV})
            if (NOT OPENOCD_NO_EXIT)
                set(OPENOCD_CMD ${OPENOCD_CMD} -c exit)
            endif()
            message(STATUS "OpenOCD CMD: ${OPENOCD_CMD}")
            set(${OUTPUT_VAR}-OPENOCD ${OPENOCD_CMD} PARENT_SCOPE)
        endif()
    endif()

    message(STATUS "==== GENERATE_FLASH_CMD  - Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")

endfunction()

#function(GENERATE_MERGED_TARGET TARGET)
#    message(STATUS "\n")
#    message(STATUS "\n")
#    message(STATUS "==== GENERATE_MERGED_TARGET (${TARGET})- Starting ====")
#    message(STATUS "\n")
#    message(STATUS "Function Parameters:")
#    message(STATUS "\t FILE = ${FILE} (File to flash)")
#    message(STATUS "\n")
#
#    EXTRACT_PARAM(SOFTDEVICE_HEX_FILE ${ARGV})
#    EXTRACT_PARAM(OUTPUT_FOLDER ${ARGV})
#    EXTRACT_PARAM(BOOTLOADER_HEX_FILE ${ARGV})
#    EXTRACT_PARAM(BOOTLOADER_VERSION ${ARGV})
#    set(MERGED_FILE ${OUTPUT_FOLDER}/${TARGET}-FULL.hex)
#
#    message(STATUS "Other Parameters:")
#    message(STATUS "\t SOFTDEVICE_HEX_FILE = ${FILE}")
#    message(STATUS "\t OUTPUT_FOLDER = ${OUTPUT_FOLDER}")
#    message(STATUS "\t BOOTLOADER_HEX_FILE = ${BOOTLOADER_HEX_FILE}")
#    message(STATUS "\t BOOTLOADER_VERSION = ${BOOTLOADER_VERSION}")
#    message(STATUS "\n")
#
#
#    if (BOOTLOADER_HEX_FILE)
#        CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
#        if (NOT BOOTLOADER_HEX_FILE-REALPATH)
#            message(WARNING "No BOOTLOADER_HEX_FILE was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
#            return()
#        endif()
#        set(SETTINGS_FILE ${OUTPUT_FOLDER}/${TARGET}-SETTINGS.hex)
#        GENERATE_SETTINGS_CMD(${SETTINGS_FILE} SETTINGS_CMD
#                APP_HEX_FILE ${${TARGET}-HEX_FILE}
#                ${ARGV})
#        set(COMMANDS ${COMMANDS} COMMAND ${SETTINGS_CMD})
#        set(FILES ${FILES} ${SETTINGS_FILE})
#    endif()
#
#    if (SOFTDEVICE_HEX_FILE)
#        CHECK_VAR_FILE(SOFTDEVICE_HEX_FILE)
#        if (NOT SOFTDEVICE_HEX_FILE-REALPATH)
#            message(WARNING "No SOFTDEVICE_HEX_FILE was specified or ${SOFTDEVICE_HEX_FILE} doesn't exist")
#            return()
#        endif()
#        set(FILES ${FILES} ${OFTDEVICE_HEX_FILE-REALPATH})
#    endif()
#
#    set(FILES ${FILES} ${TARGET}-HEX_FILE)
#
#    MERGE_FILES_CMD(FILES ${MERGED_FILE} MERGED_CMD)
#    if (NOT MERGED_CMD)
#        message(WARNING "Merge command failed")
#        return()
#    endif()
#    set(COMMANDS ${COMMANDS}
#            COMMAND ${MERGED_CMD})
#    add_custom_command(TARGET ${TARGET} POST-BUILD
#            ${COMMANDS}
#            DEPENDS ${TARGET})
#
#
#    message(STATUS "==== GENERATE_MERGED_TARGET (${TARGET})- Ending ====")
#    message(STATUS "\n")
#    message(STATUS "\n")
#endfunction()



FUNCTION(CREATE_ELF_HEX_BIN_TARGETS TARGET)


    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== CREATE_ELF_HEX_BIN_TARGETS (${TARGET})- Starting ====")
    message(STATUS "\n")

    EXTRACT_PARAM(OUTPUT_FOLDER ${ARGV})
    EXTRACT_PARAM(OUTPUT_NAME ${ARGV})
    if (NOT OUTPUT_NAME)
        set(OUTPUT_NAME ${TARGET})
    endif()
    IS_PARAM(NO_MERGE ${ARGV})
    IS_PARAM(NO_SETTINGS ${ARGV})
    IS_PARAM(CLEAN_OUTPUT ${ARGV})
    message(STATUS "Other Parameters:")
    message(STATUS "\t OUTPUT_FOLDER = ${OUTPUT_FOLDER}")
    message(STATUS "\t OUTPUT_NAME = ${OUTPUT_NAME}")
    message(STATUS "\t SOFTDEVICE_HEX_FILE = ${SOFTDEVICE_HEX_FILE}")
    message(STATUS "\t BOOTLOADER_HEX_FILE = ${BOOTLOADER_HEX_FILE}")
    message(STATUS "\t BOOTLOADER_VERSION = ${BOOTLOADER_VERSION}")
    message(STATUS "\t BL_SETTINGS_VERSION = ${BL_SETTINGS_VERSION}")
    message(STATUS "\t NO_MERGE = ${NO_MERGE}")
    message(STATUS "\t NO_SETTINGS = ${NO_SETTINGS}")
    message(STATUS "\t CLEAN_OUTPUT = ${CLEAN_OUTPUT}")
    message(STATUS "\n")



    if (NOT OUTPUT_FOLDER)
        get_filename_component(OUTPUT_FOLDER ${OUTPUT_NAME} DIRECTORY)
    else()
        get_filename_component(OUTPUT_FOLDER ${OUTPUT_FOLDER}/dummy DIRECTORY)
    endif()
    message(STATUS "Output directory ${OUTPUT_FOLDER}")
    set(${TARGET}-ELF_FILE ${OUTPUT_FOLDER}/${OUTPUT_NAME}.elf )
    set(${TARGET}-HEX_FILE ${OUTPUT_FOLDER}/${OUTPUT_NAME}.hex )
    set(${TARGET}-BIN_FILE ${OUTPUT_FOLDER}/${OUTPUT_NAME}.bin )



    set(${TARGET}-ELF_FILE ${${TARGET}-ELF_FILE} PARENT_SCOPE )
    set(${TARGET}-HEX_FILE ${${TARGET}-HEX_FILE} PARENT_SCOPE )
    set(${TARGET}-BIN_FILE ${${TARGET}-BIN_FILE} PARENT_SCOPE )
    message(STATUS "\t ELF file = ${${TARGET}-ELF_FILE}")
    message(STATUS "\t HEX file = ${${TARGET}-HEX_FILE}")
    message(STATUS "\t BIN file = ${${TARGET}-BIN_FILE}")
    set(COMMANDS)
    set(FILES)
    set(BYPRODUCTS ${TARGET}.hex ${TARGET}.bin ${TARGET}.elf)
    if (CLEAN_OUTPUT)
        set(BYPRODUCTS ${BYPRODUCTS}
                ${${TARGET}-ELF_FILE}
                ${${TARGET}-HEX_FILE}
                ${${TARGET}-BIN_FILE}
                )
    endif()
    #    set(OUT_HEX_FILE ${OUTPUT}-FULL.hex PARENT_SCOPE)



    if (BOOTLOADER_HEX_FILE)
        CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
        if (NOT BOOTLOADER_HEX_FILE-REALPATH)
            message(WARNING "No BOOTLOADER_HEX_FILE was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
            return()
        endif()
        if (NOT NO_SETTINGS)
            set(${TARGET}-SETTINGS ${OUTPUT_FOLDER}/${OUTPUT_NAME}-SETTINGS.hex)
            set(${TARGET}-SETTINGS ${${TARGET}-SETTINGS} PARENT_SCOPE )
            GENERATE_SETTINGS_CMD(${${TARGET}-SETTINGS} SETTINGS_CMD
                    APP_HEX_FILE ${${TARGET}-HEX_FILE}
                    ${ARGV})
            set(COMMANDS ${COMMANDS}
                    COMMAND echo "Creating Settings hex"
                    COMMAND ${CMAKE_COMMAND} -E rm -f ${${TARGET}-SETTINGS}
                    COMMAND ${SETTINGS_CMD})
            set(FILES ${FILES} ${${TARGET}-SETTINGS} ${BOOTLOADER_HEX_FILE-REALPATH})
            if (CLEAN_OUTPUT)
                set(BYPRODUCTS ${BYPRODUCTS}
                        ${${TARGET}-SETTINGS}
                        )
            endif()
        endif()
    endif()

    if (SOFTDEVICE_HEX_FILE)
        CHECK_VAR_FILE(SOFTDEVICE_HEX_FILE)
        if (NOT SOFTDEVICE_HEX_FILE-REALPATH)
            message(WARNING "No SOFTDEVICE_HEX_FILE was specified or ${SOFTDEVICE_HEX_FILE} doesn't exist")
            return()
        endif()
        message(STATUS "Adding Softdevice to the merge files: ${SOFTDEVICE_HEX_FILE-REALPATH}")
        set(FILES ${FILES} ${SOFTDEVICE_HEX_FILE-REALPATH})
    endif()

    if (NOT NO_MERGE)
        set(${TARGET}-MERGED_FILE ${OUTPUT_FOLDER}/${OUTPUT_NAME}-FULL.hex)
        set(${TARGET}-MERGED_FILE ${${TARGET}-MERGED_FILE} PARENT_SCOPE )

        set(FILES ${FILES} ${${TARGET}-HEX_FILE})

        message(STATUS "Files to merge: ${FILES}")
        MERGE_FILES_CMD(FILES ${${TARGET}-MERGED_FILE} MERGED_CMD)
        if (NOT MERGED_CMD)
            message(WARNING "Merge command failed")
            return()
        endif()
        set(COMMANDS ${COMMANDS}
                COMMAND echo "Creating Merged hex"
                COMMAND ${CMAKE_COMMAND} -E rm -f ${${TARGET}-MERGED_FILE}
                COMMAND ${MERGED_CMD})
        if (CLEAN_OUTPUT)
            set(BYPRODUCTS ${BYPRODUCTS}
                    ${${TARGET}-MERGED_FILE}
                    )
        endif()

    endif()

    message(STATUS "ByProducts: ${BYPRODUCTS}")
    add_custom_command(TARGET ${TARGET} POST_BUILD
            COMMAND echo "Creating elf, hex and bin"
            COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_FOLDER}
            COMMAND ${CMAKE_COMMAND} -E rm -f ${TARGET}.elf ${TARGET}.hex ${TARGET}.bin
            COMMAND ${CMAKE_COMMAND} -E rm -f ${${TARGET}-ELF_FILE} ${${TARGET}-HEX_FILE} ${${TARGET}-BIN_FILE}
            COMMAND ${CMAKE_OBJCOPY} ${TARGET} ${TARGET}.elf
            COMMAND ${CMAKE_OBJCOPY} -Oihex ${TARGET} ${TARGET}.hex
            COMMAND ${CMAKE_OBJCOPY} -Obinary ${TARGET} ${TARGET}.bin
            COMMAND echo "Copy elf, hex and bin"
            COMMAND ${CMAKE_COMMAND} -E copy ${TARGET}.elf ${${TARGET}-ELF_FILE}
            COMMAND ${CMAKE_COMMAND} -E copy ${TARGET}.hex ${${TARGET}-HEX_FILE}
            COMMAND ${CMAKE_COMMAND} -E copy ${TARGET}.bin ${${TARGET}-BIN_FILE}
            ${COMMANDS}
            BYPRODUCTS  ${BYPRODUCTS}
            )
    message(STATUS "==== CREATE_ELF_HEX_BIN_TARGETS (${TARGET})- Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
endfunction()



function(CREATE_FLASH TARGET)
    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== CREATE_FLASH (${TARGET})- Starting ====")
    message(STATUS "\n")

    if (${TARGET}-MERGED_FILE)
        GENERATE_FLASH_CMD(${${TARGET}-MERGED_FILE} FULL_FLASH_CMD ${ARGV} MASS_ERASE RESET)
        if (FULL_FLASH_CMD-OPENOCD)
        add_custom_target("FULL_FLASH-${TARGET}-OPENOCD"
                DEPENDS ${TARGET}
                COMMAND ${FULL_FLASH_CMD-OPENOCD}
                )
        endif()
        if (FULL_FLASH_CMD-SEGGER)
            add_custom_target("FULL_FLASH-${TARGET}-SEGGER"
                    DEPENDS ${TARGET}
                    COMMAND ${FULL_FLASH_CMD-SEGGER}
                    )
        endif()
    endif()

    GENERATE_FLASH_CMD(${${TARGET}-HEX_FILE} FLASH_CMD ${ARGV} RESET)
    if (FLASH_CMD-OPENOCD)
        add_custom_target("FLASH-${TARGET}-OPENOCD"
                DEPENDS ${TARGET}
                COMMAND ${FLASH_CMD-OPENOCD}
                )
    endif()
    if (FLASH_CMD-SEGGER)
        add_custom_target("FLASH-${TARGET}-SEGGER"
                DEPENDS ${TARGET}
                COMMAND ${FLASH_CMD-SEGGER}
                )
    endif()

    message(STATUS "==== CREATE_FLASH (${TARGET})- Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
ENDFUNCTION()


function(CREATE_DFU TARGET)
    message(STATUS "\n")
    message(STATUS "\n")
    message(STATUS "==== CREATE_DFU (${TARGET})- Starting ====")
    message(STATUS "\n")
    EXTRACT_PARAM(OUTPUT_FOLDER ${ARGV})
    EXTRACT_PARAM(OUTPUT_NAME ${ARGV})
    if (NOT OUTPUT_NAME)
        set(OUTPUT_NAME ${TARGET}.zip)
    endif()

    message(STATUS "Other Parameters:")
    message(STATUS "\t OUTPUT_FOLDER = ${OUTPUT_FOLDER}")
    message(STATUS "\t OUTPUT_NAME = ${OUTPUT_NAME}")
    message(STATUS "\t SOFTDEVICE_HEX_FILE = ${SOFTDEVICE_HEX_FILE}")
    message(STATUS "\t BOOTLOADER_HEX_FILE = ${BOOTLOADER_HEX_FILE}")
    message(STATUS "\t BOOTLOADER_VERSION = ${BOOTLOADER_VERSION}")
    message(STATUS "\t BL_SETTINGS_VERSION = ${BL_SETTINGS_VERSION}")
    message(STATUS "\t NO_MERGE = ${NO_MERGE}")
    message(STATUS "\t NO_SETTINGS = ${NO_SETTINGS}")
    message(STATUS "\t CLEAN_OUTPUT = ${CLEAN_OUTPUT}")
    message(STATUS "\n")

    GENERATE_DFU_ZIP(${TARGET}-DFU-APP "APP"
            ${OUTPUT_FOLDER}/${OUTPUT_NAME}
            APP_HEX_FILE ${${TARGET}-HEX_FILE}
            DEPENDS ${TARGET}
            ${ARGV}
            )

    message(STATUS "==== CREATE_DFU (${TARGET})- Ending ====")
    message(STATUS "\n")
    message(STATUS "\n")
ENDFUNCTION()




FUNCTION(NRF_SET_COMPILERS)

	if (WIN32 OR WIN64)
		set(TOOL_EXECUTABLE_SUFFIX .exe)
	else()
		set(TOOL_EXECUTABLE_SUFFIX )
	endif()


	if(NOT TARGET_TRIPLET)
		set(TARGET_TRIPLET arm-none-eabi)
		set(EXE_EXTENSION ${TOOL_EXECUTABLE_SUFFIX})
		message(STATUS "Using default target triplet ${TARGET_TRIPLET}")
	else()
		set(EXE_EXTENSION )
		message(STATUS "Using target triplet ${TARGET_TRIPLET}")
	endif()



	if(NOT C_COMPILER)
		set(C_COMPILER ${TOOLCHAIN_PREFIX}${TARGET_TRIPLET}-gcc${EXE_EXTENSION})
		message(STATUS "Using default C compiler: ${C_COMPILER}")
	else()
		message(STATUS "Using C compiler: ${CXX_COMPILER}")
	endif()

	if(NOT TOOLCHAIN_PREFIX)
		if (C_COMPILER)
			find_program(C_COMPILER_FILE ${C_COMPILER})
			message(STATUS "C_COMPILER_FILE = ${C_COMPILER_FILE}")
			get_filename_component(TOOLCHAIN_PREFIX ${C_COMPILER_FILE} DIRECTORY)
		else()
			message(FATAL_ERROR "NO C_COMPILER")
		endif()
		message(STATUS "Using TOOLCHAIN_PREFIX from C_COMPILER: ${TOOLCHAIN_PREFIX}")
	endif()


	if (NOT TOOLCHAIN_PREFIX STREQUAL "")
		set(TOOLCHAIN_PREFIX ${TOOLCHAIN_PREFIX}/)
	endif()

	message(STATUS "Using TOOLCHAIN_PREFIX: ${TOOLCHAIN_PREFIX}")
	set (TOOLCHAIN_PREFIX ${TOOLCHAIN_PREFIX} PARENT_SCOPE)

	if(NOT CXX_COMPILER)
		set(CXX_COMPILER ${TOOLCHAIN_PREFIX}${TARGET_TRIPLET}-c++${EXE_EXTENSION})
		message(STATUS "Using default C++ compiler: ${CXX_COMPILER}")
	else()
		message(STATUS "Using C++ compiler: ${CXX_COMPILER}")
	endif()

	if(NOT ASM_COMPILER)
		set(ASM_COMPILER ${TOOLCHAIN_PREFIX}${TARGET_TRIPLET}-gcc${EXE_EXTENSION})
		message(STATUS "Using default ASM compiler: ${ASM_COMPILER}")
	else()
		message(STATUS "Using ASM compiler: ${ASM_COMPILER}")
	endif()

	if(NOT COMPILER_SIZE_TOOL)
		set(COMPILER_SIZE_TOOL ${TOOLCHAIN_PREFIX}${TARGET_TRIPLET}-size${EXE_EXTENSION})
		message(STATUS "Using default compiler size tool: ${COMPILER_SIZE_TOOL}")
	else()
		message(STATUS "Using compiler size tool: ${COMPILER_SIZE_TOOL}")
	endif()

	if(NOT COMPILER_OBJCOPY_TOOL)
		set(COMPILER_OBJCOPY_TOOL ${TOOLCHAIN_PREFIX}${TARGET_TRIPLET}-objcopy${EXE_EXTENSION})
		message(STATUS "Using default compiler objcopy tool: ${COMPILER_OBJCOPY_TOOL}")
	else()
		message(STATUS "Using compiler objcopy tool: ${COMPILER_OBJCOPY_TOOL}")
	endif()

	if( ${CMAKE_VERSION} VERSION_LESS 3.6.0)
		INCLUDE(CMakeForceCompiler)
		CMAKE_FORCE_C_COMPILER( ${C_COMPILER} GNU)
		CMAKE_FORCE_CXX_COMPILER( ${CXX_COMPILER} GNU)
	else()
		SET(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY PARENT_SCOPE)
		SET(CMAKE_C_COMPILER ${C_COMPILER} PARENT_SCOPE)
		SET(CMAKE_CXX_COMPILER ${CXX_COMPILER} PARENT_SCOPE)
	endif()

	SET(CMAKE_SIZE ${COMPILER_SIZE_TOOL} PARENT_SCOPE)
	SET(CMAKE_OBJCOPY ${COMPILER_OBJCOPY_TOOL} PARENT_SCOPE)
	SET(CMAKE_ASM_COMPILER ${ASM_COMPILER} PARENT_SCOPE)
ENDFUNCTION()


FUNCTION(SET_COMPILATION_FLAGS)
	foreach(LIB ${LIB_FILES})
		find_file(LIB_FILE_${LIB} ${LIB} ${CMAKE_SOURCE_DIR})
		if (NOT LIB_FILE_${LIB})
			string(REGEX REPLACE "-l(.*)" "\\1" LIB_CLEAN ${LIB})
			list(APPEND LIBS_CLEAN ${LIB_CLEAN})
		else ()
			list(APPEND LIB_FILES_CLEAN ${LIB_FILE_${LIB}})
		endif()
	endforeach()
	string(REPLACE ";" " " LDFLAGS "${LDFLAGS}")
	set(LIB_FILES_CLEAN ${LIB_FILES_CLEAN} PARENT_SCOPE)
	set(LIBS_CLEAN ${LIBS_CLEAN} PARENT_SCOPE)
	set(CMAKE_C_FLAGS "" CACHE INTERNAL "c compiler flags")
	set(CMAKE_CXX_FLAGS "" CACHE INTERNAL "c++ compiler flags")
	set(CMAKE_ASM_FLAGS "-x assembler-with-cpp" CACHE INTERNAL "asm compiler flags")
	set(CMAKE_EXE_LINKER_FLAGS "${LDFLAGS} " CACHE INTERNAL "executable linker flags")
ENDFUNCTION()

FUNCTION(SET_COMPILER_OPTIONS TARGET)
	target_compile_options(${TARGET} PRIVATE
		$<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
			$<$<COMPILE_LANGUAGE:CXX>:${CXXFLAGS}>
			$<$<COMPILE_LANGUAGE:ASM>:${ASMFLAGS}>
		)
	target_link_options(${TARGET} PRIVATE -Wl,-gc-sections,--print-memory-usage)
ENDFUNCTION()

FUNCTION(PRINT_SIZE_OF_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_SIZE} ${FILENAME})
ENDFUNCTION()

set(CMAKE_SYSTEM_NAME Generic)
