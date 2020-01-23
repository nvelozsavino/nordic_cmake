cmake_minimum_required(VERSION 3.4.0)
set(nrf52_cmake_dir ${CMAKE_CURRENT_LIST_DIR})


if (WIN32)
	set(DELFILE_CMD del /f)
else()
	set(DELFILE_CMD rm -f)
endif()

FUNCTION(SET_COMPILER_OPTIONS TARGET)
	target_compile_options(${TARGET} PRIVATE
		$<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
			$<$<COMPILE_LANGUAGE:CXX>:${CXXFLAGS}>
			$<$<COMPILE_LANGUAGE:ASM>:${ASMFLAGS}>
		)
ENDFUNCTION()
set(CMAKE_SYSTEM_NAME Generic)

function(CHECK_VAR_FILE FILE_VAR)
	if(NOT ${FILE_VAR})
		message(WARNING "${FILE_VAR} was not set")
		set(${FILE_VAR}-VALID FALSE PARENT_SCOPE)
		return()
	endif()
	if (${FILE_VAR}-CREATE)
		message(STATUS "${FILE_VAR}=${${FILE_VAR}} will be created on compilation")
		get_filename_component(FILE_VAR_TXT ${${FILE_VAR}} ABSOLUTE)
		set (${FILE_VAR}-REALPATH ${FILE_VAR_TXT} PARENT_SCOPE)
		return()
	endif()
	set(FILE ${${FILE_VAR}})
	get_filename_component(FILE_PATH ${FILE} ABSOLUTE)
#	message(WARNING "Checking ${FILE_VAR} = ${FILE}")
	if(EXISTS "${FILE_PATH}")
		set(${FILE_VAR}-VALID TRUE PARENT_SCOPE)
		set (${FILE_VAR}-REALPATH ${FILE_PATH} PARENT_SCOPE)
	else()
		message(WARNING "${FILE} was not found")
		set(${FILE_VAR}-VALID FALSE PARENT_SCOPE)
	endif()
endfunction()

function(NRF_MERGE_HEX TARGET APP_HEX OUT_HEX)
	if (NOT GENERATE_MERGE_HEX)
		message(STATUS "Not generating a full merge hex" )

		return()
	endif()
	if (NOT MERGEHEX_BIN)
		find_program(MERGEHEX_BIN mergehex)
	endif()
	if (NOT MERGEHEX_BIN)
		message(WARNING "mergehex not found, no Full hex file can be created")
		return()
	endif()

#	CHECK_VAR_FILE(TARGET_HEX_FILE)
#	if (NOT TARGET_HEX_FILE-REALPATH)
#		message(WARNING "No APP_HEX_FILE was specified or ${TARGET_HEX_FILE} doesn't exist")
#		return()
#	endif()

	CHECK_VAR_FILE(SOFTDEVICE_HEX_FILE)
	if (NOT SOFTDEVICE_HEX_FILE-REALPATH)
		message(WARNING "No SOFTDEVICE_HEX_FILE file was specified or ${SOFTDEVICE_HEX_FILE} doesn't exist")
		return()
	endif()
	if (HAS_BOOTLOADER)
		message(STATUS "MERGE HAS bootloader")

		CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
		if (NOT BOOTLOADER_HEX_FILE-REALPATH)
			message(WARNING "No BOOTLOADER_HEX_FILE file was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
			return()
		endif()
		NRF_GENERATE_SETTINGS(${TARGET} ${APP_HEX})

		set(BOOT_HEX_OUT ${CMAKE_BINARY_DIR}/${TARGET}-bootbundle.hex)
		set(MERGE_HEX_CMD
				${SETTINGS_HEX_CMD}
				COMMAND ${DELFILE_CMD} ${BOOT_HEX_OUT}
				COMMAND ${MERGEHEX_BIN} -m ${BOOTLOADER_HEX_FILE-REALPATH} ${SETTINGS_HEX_FILE} -o ${BOOT_HEX_OUT}
				)

	else()
		set(MERGE_HEX_CMD)
		set(BOOT_HEX_OUT)
	endif()
	set(MERGE_HEX_CMD ${MERGE_HEX_CMD}
			COMMAND ${MERGEHEX_BIN} -m ${BOOT_HEX_OUT} ${APP_HEX} ${SOFTDEVICE_HEX_FILE} -o ${OUT_HEX})
	message(STATUS "MERGE HEX: ${MERGE_HEX_CMD}")
	add_custom_command(TARGET ${TARGET} POST_BUILD ${MERGE_HEX_CMD})

endfunction()


function(NRF_GENERATE_SETTINGS TARGET APP_HEX)
#	CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
#	if (NOT BOOTLOADER_HEX_FILE-REALPATH)
#		message(WARNING "No BOOTLOADER_HEX_FILE was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
#		return()
#	endif()
#	CHECK_VAR_FILE(APP_HEX_FILE)
#	if (NOT APP_HEX_FILE-REALPATH)
#		message(WARNING "No APP_HEX_FILE was specified or ${APP_HEX_FILE} doesn't exist")
#		return()
#	endif()
#	Check for NRFUTIL to create the settings page
	if (NOT NRFUTIL_BIN)
		find_program(NRFUTIL_BIN nrfutil)
	endif()
	if (NOT NRFUTIL_BIN)
		message(WARNING "nrfutil not found, no Bootloader settings can be created")
		return()
	endif()

#	if (NOT MERGEHEX_BIN)
#		find_program(MERGEHEX_BIN mergehex)
#	endif()
#	if (NOT MERGEHEX_BIN)
#		message(WARNING "mergehex not found, the bootloader hex can't be created")
#		return()
#	endif()

	set(SETTINGS_HEX_FILE ${CMAKE_BINARY_DIR}/${TARGET}-settings.hex)
	set(SETTINGS_HEX_FILE ${CMAKE_BINARY_DIR}/${TARGET}-settings.hex PARENT_SCOPE)
	message(STATUS "DELFILE_CMD = ${DELFILE_CMD}")

	set(SETTINGS_HEX_CMD
			COMMAND echo "Preparing Settings hex file"
			COMMAND ${DELFILE_CMD} ${SETTINGS_HEX_FILE}
#			COMMAND ${DELFILE_CMD} ${BOOT_BUNDLE_HEX_FILE}
			COMMAND ${NRFUTIL_BIN} settings generate --family NRF52 --application ${APP_HEX} --application-version 1 --bootloader-version 1 --bl-settings-version 1 "${SETTINGS_HEX_FILE}"
#			COMMAND ${MERGEHEX_BIN} -m ${BOOTLOADER_HEX_FILE-REALPATH} ${SETTINGS_HEX_FILE} -o ${BOOT_BUNDLE_HEX_FILE}
#			COMMAND echo "Bootloader bundle hex done ${BOOT_BUNDLE_HEX_FILE}"
#			COMMAND ${DELFILE_CMD} ${SETTINGS_HEX_FILE}
			)
	set(SETTINGS_HEX_CMD "${SETTINGS_HEX_CMD}" PARENT_SCOPE)
	message(STATUS "SETTINGS_HEX_FILE = ${SETTINGS_HEX_FILE}")
	message(STATUS "SETTINGS_HEX_CMD = ${SETTINGS_HEX_CMD}")
endfunction()


function(NRF_FLASH_SOFTDEVICE)
	set(SOFTDEVICE_FLASH_CMD "" PARENT_SCOPE)

	CHECK_VAR_FILE(SOFTDEVICE_HEX_FILE)
	if (NOT SOFTDEVICE_HEX_FILE-REALPATH)
		message(WARNING "No SOFTDEVICE_HEX_FILE file was specified or ${SOFTDEVICE_HEX_FILE} doesn't exist")
		return()
	endif()

	message(STATUS "Softdevice file ${SOFTDEVICE_HEX_FILE-REALPATH}")

	set(SOFTDEVICE_FLASH_CMD -c "program \"${SOFTDEVICE_HEX_FILE-REALPATH}\" verify" PARENT_SCOPE)
endfunction()

function(NRF_FLASH_BOOTLOADER)
	set(BOOTLOADER_FLASH_CMD "" PARENT_SCOPE)

	CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
	if (NOT BOOTLOADER_HEX_FILE-REALPATH)
		message(WARNING "No BOOTLOADER_HEX_FILE file was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
		return()
	endif()

	message(STATUS "Bootloader file ${BOOTLOADER_HEX_FILE-REALPATH}")

	set(BOOTLOADER_FLASH_CMD -c "program \"${BOOTLOADER_HEX_FILE-REALPATH}\" verify" PARENT_SCOPE)
endfunction()


function(NRF_FLASH_TARGET TARGET APP_HEX_FILE)

	if (NOT OPENOCD_CFG)
#		set(OPENOCD_CFG board/nordic_nrf52_dk.cfg)
		set(OPENOCD_CFG ${nrf52_cmake_dir}/nrf52_stlink.cfg)
		message(STATUS "Using default OpenOCD config file: ${OPENOCD_CFG}")
	else()
		message(STATUS "Using OpenOCD config file: ${OPENOCD_CFG}")
	endif()

	if (NOT OPENOCD_BIN)
		find_program(OPENOCD_BIN openocd)

		if (NOT OPENOCD_BIN)
			message(WANING "OpenOCD binaries, not found, no FLASH target will be created")
			return()
		else()
			message(STATUS "Found OpenOCD binaries in ${OPENOCD_BIN}")
		endif()
	else()
		message(STATUS "Using OpenOCD binaries: ${OPENOCD_BIN}")

	endif()

	set(HLA_SERIAL "" CACHE STRING "HLA Serial")

	set(FLASH_CLEAN TRUE CACHE BOOL "Flash everything (TRUE) or just program and settings (FALSE)")

	set(HAS_BOOTLOADER TRUE CACHE BOOL "Specify if there's BOOTLOADER")
	set(GENERATE_MERGE_HEX TRUE CACHE BOOL "Generate Full HEX file")

	if (FLASH_CLEAN)
		set(FLASH_MASS_ERASE TRUE)
		set(FLASH_BOOTLOADER TRUE)
		set(FLASH_SETTINGS TRUE)
		set(FLASH_SOFTDEVICE TRUE)
	else()
		set(FLASH_MASS_ERASE FALSE)
		set(FLASH_BOOTLOADER FALSE)
		set(FLASH_SETTINGS TRUE)
		set(FLASH_SOFTDEVICE FALSE)

	endif()




	if (FLASH_MASS_ERASE)
		message(STATUS "Mass erase enabled")
		set(MASS_ERASE_FLASH_CMD -c "nrf5 mass_erase")
	else()
		message(STATUS "Mass erase disabled")
		set(MASS_ERASE_FLASH_CMD)
	endif()
	if (HAS_BOOTLOADER)
		CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
		if (NOT BOOTLOADER_HEX_FILE-REALPATH)
			message(WARNING "No BOOTLOADER_HEX_FILE was specified or ${BOOTLOADER_HEX_FILE} doesn't exist")
			set(HAS_BOOTLOADER FALSE)
		endif()
	endif()
	if (HAS_BOOTLOADER)
		message(STATUS "Creating config for bootloader")
		#	Check for bootloader requirements
		if (FLASH_BOOTLOADER)
			message(STATUS "Bootloader file flash enabled")
			NRF_FLASH_BOOTLOADER()
		else()
			message(STATUS "Bootloader file flash disabled")
		endif()

		#	Check for softdevice requirements
		if (FLASH_SETTINGS)
			message(STATUS "Settings file flash enabled")
			NRF_GENERATE_SETTINGS(${TARGET} ${APP_HEX_FILE})
			message(STATUS "Settings ${SETTINGS_HEX_FILE}")
			set(SETTINGS_FLASH_CMD
					-c "program \"${SETTINGS_HEX_FILE}\" verify")
		else()
			message(STATUS "Settings file flash disabled")
		endif()
	else(HAS_BOOTLOADER)
		message(STATUS "Not using config for bootloader")

	endif(HAS_BOOTLOADER)
	#	Check for softdevice requirements
	if (FLASH_SOFTDEVICE)
		message(STATUS "Softdevice file flash enabled")
		NRF_FLASH_SOFTDEVICE()
	else()
		message(STATUS "Softdevice file flash disabled")
	endif()

	if (OPENOCD_SCRIPT)
		set(OPENOCD_SCRIPT_CMD "-s \"${OPENOCD_SCRIPT}\"")
	else()
		set(OPENOCD_SCRIPT_CMD "")
	endif()

	set (APP_FLASH_CMD -c "program \"${APP_HEX_FILE}\" verify")

	if (HLA_SERIAL)
		set(HLA_SERIAL_FLASH_CMD "hla_serial ${HLA_SERIAL}")
	endif()


	set(OPENOCD_FLASH_CMD
			${HLA_SERIAL_FLASH_CMD}
			-c "reset_config none"
			-c init
			-c halt
			${MASS_ERASE_FLASH_CMD}
			${SOFTDEVICE_FLASH_CMD}
			${SETTINGS_FLASH_CMD}
			${BOOTLOADER_FLASH_CMD}
			${APP_FLASH_CMD})

	message(STATUS "OPENOCD_FLASH_CMD = ${OPENOCD_FLASH_CMD}")
	message(STATUS "SETTINGS_HEX_CMD = ${SETTINGS_HEX_CMD}")
	add_custom_target(Flash
			DEPENDS ${TARGET}

			COMMAND echo ${DELFILE_CMD} ${APP_HEX_FILE}.hex
			COMMAND ${DELFILE_CMD} ${APP_HEX_FILE}.hex
			COMMAND ${CMAKE_OBJCOPY} -Oihex ${CMAKE_BINARY_DIR}/${TARGET} ${APP_HEX_FILE}
			COMMAND echo ${APP_HEX_FILE} created
			${SETTINGS_HEX_CMD}
			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD}  ${OPENOCD_FLASH_CMD} -c reset -c exit
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)

	add_custom_target(Flash-debug
			DEPENDS ${TARGET}

			COMMAND echo ${DELFILE_CMD} ${APP_HEX_FILE}.hex
			COMMAND ${DELFILE_CMD} ${APP_HEX_FILE}.hex
			COMMAND ${CMAKE_OBJCOPY} -Oihex ${CMAKE_BINARY_DIR}/${TARGET} ${APP_HEX_FILE}
			COMMAND echo ${APP_HEX_FILE} created
			${BOOTLOADER_HEX_CMD}
			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD}  ${OPENOCD_FLASH_CMD} -c reset -c halt -c exit
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)
endfunction()

function(GET_UPDATE_SD_ARGS)
	message(STATUS "SOFTDEVICE_HEX_FILE=${SOFTDEVICE_HEX_FILE}")
	CHECK_VAR_FILE(SOFTDEVICE_HEX_FILE)
	if (NOT SOFTDEVICE_HEX_FILE-REALPATH)
		message(WARNING "No SOFTDEVICE_HEX_FILE file was specified or ${SOFTDEVICE_HEX_FILE} not found")
		return()
	endif()
	set (SD_UPDATE_ARGS 	--softdevice "${SOFTDEVICE_HEX_FILE-REALPATH}" PARENT_SCOPE)
endfunction()

function(GET_UPDATE_BL_ARGS)
	message(STATUS "BOOTLOADER_HEX_FILE=${BOOTLOADER_HEX_FILE}")

	CHECK_VAR_FILE(BOOTLOADER_HEX_FILE)
	if (NOT BOOTLOADER_HEX_FILE-REALPATH)
		message(WARNING "No BOOTLOADER_HEX_FILE file was specified or ${BOOTLOADER_HEX_FILE} not found")
		return()
	endif()
	set (BL_UPDATE_ARGS 	--bootloader "${BOOTLOADER_HEX_FILE-REALPATH}" --bootloader-version ${BOOTLOADER_VERSION} PARENT_SCOPE)
endfunction()

function(GET_UPDATE_APP_ARGS)
	message(STATUS "APP_HEX_FILE=${APP_HEX_FILE}")

	CHECK_VAR_FILE(APP_HEX_FILE)
	if (NOT APP_HEX_FILE-REALPATH)
		message(WARNING "No APP_HEX_FILE file was specified or ${APP_HEX_FILE} not found")
		return()
	endif()
	set (APP_UPDATE_ARGS 	--application "${APP_HEX_FILE-REALPATH}" --application-version ${APP_VERSION} PARENT_SCOPE)
endfunction()


function(GENERATE_UPDATE_FLASH_TARGET TARGET UPDATE_FILE_TYPE ZIP_FILE)
	if (NOT NRF_HW_VERSION)
		set (NRF_HW_VERSION 52)
	endif()

	set(BOOTLOADER_FLASH_CMD "" PARENT_SCOPE)

	CHECK_VAR_FILE(KEY_PEM_FILE)
	if (NOT KEY_PEM_FILE-REALPATH)
		message(WARNING "No KEY_PEM_FILE was specified or ${KEY_PEM_FILE} doesn't exist")
		return()
	endif()


	if (NOT SOFTDEVICE_FWID)
		message(WARNING "No SOFTDEVICE_FWID was specified, please check codes in
		 		https://github.com/NordicSemiconductor/pc-nrfutil/blob/master/README.md")
		return()
	endif()


	#	Check for NRFUTIL to create the settings page
	if (NOT NRFUTIL_BIN)
		find_program(NRFUTIL_BIN nrfutil)
	endif()
	if (NOT NRFUTIL_BIN)
		message(WARNING "nrfutil not found, no Update zip can be generated")
		return()
	endif()

	set(UPDATE_CMD_START nrfutil pkg generate)
	set(UPDATE_ARGS_COMMON
			--key-file ${KEY_PEM_FILE-REALPATH}
			--hw-version ${NRF_HW_VERSION}
			--sd-req ${SOFTDEVICE_FWID})




	if (UPDATE_FILE_TYPE STREQUAL "BL")
		GET_UPDATE_BL_ARGS(BOOTLOADER_HEX_FILE BOOTLOADER_VERSION)
		if (NOT BL_UPDATE_ARGS)
			return()
		endif()

		set(GEN_UPDATE_ARGS
				${BL_UPDATE_ARGS}
				${UPDATE_ARGS_COMMON})


	elseif(UPDATE_FILE_TYPE STREQUAL "SD")

		GET_UPDATE_SD_ARGS(SOFTDEVICE_HEX_FILE)
		if (NOT SD_UPDATE_ARGS)
			return()
		endif()

		set(GEN_UPDATE_ARGS
				${SD_UPDATE_ARGS}
				${UPDATE_ARGS_COMMON})

	elseif(UPDATE_FILE_TYPE STREQUAL "APP")
		GET_UPDATE_APP_ARGS(APP_HEX_FILE APP_VERSION)
		if (NOT APP_UPDATE_ARGS)
			return()
		endif()

		set(GEN_UPDATE_ARGS
				${APP_UPDATE_ARGS}
				${UPDATE_ARGS_COMMON})


	elseif(UPDATE_FILE_TYPE STREQUAL "BL+SD")
		GET_UPDATE_BL_ARGS(BOOTLOADER_HEX_FILE BOOTLOADER_VERSION)
		if (NOT BL_UPDATE_ARGS)
			return()
		endif()

		GET_UPDATE_SD_ARGS(SOFTDEVICE_HEX_FILE)
		if (NOT SD_UPDATE_ARGS)
			return()
		endif()


		set(GEN_UPDATE_ARGS
				${BL_UPDATE_ARGS}
				${SD_UPDATE_ARGS}
				${UPDATE_ARGS_COMMON})


	elseif(UPDATE_FILE_TYPE STREQUAL "BL+SD+APP")

		GET_UPDATE_BL_ARGS(BOOTLOADER_HEX_FILE BOOTLOADER_VERSION)
		if (NOT BL_UPDATE_ARGS)
			return()
		endif()

		GET_UPDATE_SD_ARGS(SOFTDEVICE_HEX_FILE)
		if (NOT SD_UPDATE_ARGS)
			return()
		endif()

		GET_UPDATE_APP_ARGS(APP_HEX_FILE APP_VERSION)
		if (NOT APP_UPDATE_ARGS)
			return()
		endif()

		set(GEN_UPDATE_ARGS
				${APP_UPDATE_ARGS}
				${UPDATE_ARGS_COMMON})


		if (NOT SOFTDEVICE_FWID_OLD)
			message(WARNING "No SOFTDEVICE_FWID_OLD was specified, please check codes in
		 		https://github.com/NordicSemiconductor/pc-nrfutil/blob/master/README.md")
			return()
		endif()


		set(GEN_UPDATE_ARGS
				${BL_UPDATE_ARGS}
				${APP_UPDATE_ARGS}
				${SD_UPDATE_ARGS}
				--sd-id ${SOFTDEVICE_FWID_OLD}
				${UPDATE_ARGS_COMMON})


	elseif(UPDATE_FILE_TYPE STREQUAL "SD+APP")
		GET_UPDATE_SD_ARGS(SOFTDEVICE_HEX_FILE)
		if (NOT SD_UPDATE_ARGS)
			return()
		endif()

		GET_UPDATE_APP_ARGS(APP_HEX_FILE APP_VERSION)
		if (NOT APP_UPDATE_ARGS)
			return()
		endif()

		set(GEN_UPDATE_ARGS
				${APP_UPDATE_ARGS}
				${UPDATE_ARGS_COMMON})


		if (SOFTDEVICE_FWID_OLD)
			message(WARNING "No SOFTDEVICE_FWID_OLD was specified, please check codes in
		 		https://github.com/NordicSemiconductor/pc-nrfutil/blob/master/README.md")
			return()
		endif()


		set(GEN_UPDATE_ARGS
				${APP_UPDATE_ARGS}
				${SD_UPDATE_ARGS}
				--sd-id ${SOFTDEVICE_FWID_OLD}
				${UPDATE_ARGS_COMMON})




	else()
		message(WARNING "Unknown update type ${UPDATE_FILE_TYPE}, it should be BL, SD, APP, BL+SD, BL+SD+APP or SD+APP")
		return()
	endif()

	message(STATUS "UPDATE_CMD ${GEN_UPDATE_ARGS}")
	message(STATUS "Update file: ${ZIP_FILE}")
	add_custom_target(Generate_Update
			DEPENDS ${TARGET}
			COMMAND nrfutil -v pkg generate ${GEN_UPDATE_ARGS} ${ZIP_FILE}
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)


ENDFUNCTION()

FUNCTION(PRINT_SIZE_OF_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_SIZE} ${FILENAME})
ENDFUNCTION()


FUNCTION(ADD_HEX_BIN_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
	set(TARGET_HEX_FILE ${FILENAME}.hex)
	set(OUT_HEX_FILE ${FILENAME}-FULL.hex)
	set(TARGET_HEX_FILE ${FILENAME}.hex PARENT_SCOPE)
	set(TARGET_BIN_FILE ${FILENAME}.bin PARENT_SCOPE)
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILENAME} ${FILENAME}.hex)
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.bin)
	message(STATUS "ADD_HEX_BIN_TARGETS : ${TARGET} ${TARGET_HEX_FILE}" )
	NRF_MERGE_HEX(${TARGET} ${TARGET_HEX_FILE} ${OUT_HEX_FILE})
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



set(CMAKE_C_FLAGS_DEBUG "")
set(CMAKE_C_FLAGS_RELEASE "")
set(CMAKE_C_FLAGS_MINSIZEREL "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "")

set(CMAKE_CXX_FLAGS_DEBUG "")
set(CMAKE_CXX_FLAGS_RELEASE "")
set(CMAKE_CXX_FLAGS_MINSIZEREL "")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "")

set(CMAKE_ASM_FLAGS_DEBUG "")
set(CMAKE_ASM_FLAGS_RELEASE  "")
set(CMAKE_ASM_FLAGS_MINSIZEREL   "")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO "")

set(CMAKE_EXE_LINKE_FLAGS_DEBUG "")
set(CMAKE_EXE_LINKE_FLAGS_RELEASE  "")
set(CMAKE_EXE_LINKE_FLAGS_MINSIZEREL   "")
set(CMAKE_EXE_LINKE_FLAGS_RELWITHDEBINFO "")

