cmake_minimum_required(VERSION 3.4.0)
set(nrf52_cmake_dir ${CMAKE_CURRENT_LIST_DIR})
FUNCTION(SET_COMPILER_OPTIONS TARGET)
	target_compile_options(${TARGET} PRIVATE
		$<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
			$<$<COMPILE_LANGUAGE:CXX>:${CXXFLAGS}>
			$<$<COMPILE_LANGUAGE:ASM>:${ASMFLAGS}>
		)
ENDFUNCTION()
set(CMAKE_SYSTEM_NAME Generic)

FUNCTION(NRF_FLASH_TARGET TARGET)


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

	find_program(NRFUTIL_BIN nrfutil)
	if (BOOTLOADER_FILE AND NOT NRFUTIL_BIN)
		if (NOT NRFUTIL_BIN)
			message(WANING "nrfutil binaries, not found, no Bootloader settings can be created")
			return()
		else()
			message(STATUS "Found nrfutil binaries in ${NRFUTIL_BIN}")
		endif()
	else()
		message(STATUS "Using nrfutil binaries: ${NRFUTIL_BIN}")
	endif()

	if (WIN32)
		set(DELFILE_CMD del /f)

	else()
		set(DELFILE_CMD rm -f)

	endif()


	set(FILE ${CMAKE_BINARY_DIR}/${TARGET})
	if (SOFTDEVICE)
		set(REQUIRE_MERGEHEX TRUE)
		set(SOFT_DEV_CMD "nrf5 mass_erase\; program \"${SOFTDEVICE}\" verify\;")
	else()
		set(SOFT_DEV_CMD "")
	endif()

	#nrfutil settings generate --family NRF52 --application remote_nordic.hex --application-version 1 --bootloader-version 1 --bl-settings-version 1 settings.hex

	set(BOOTLOADER_FILE ${CMAKE_BINARY_DIR}/remote-boot.hex)
	set(SOFTDEVICE_FILE ${CMAKE_BINARY_DIR}/s132.hex)

	if (BOOTLOADER_FILE)

		set(BOOT_FILE ${CMAKE_BINARY_DIR}/boot.hex)
		set(SETTINGS_FILE ${CMAKE_BINARY_DIR}/settings.hex)

		set(BOOT_CMD
				COMMAND echo "Preparing Bootloader"
				COMMAND ${DELFILE_CMD} ${SETTINGS_FILE}
				COMMAND ${DELFILE_CMD} ${BOOT_FILE}
				COMMAND ${NRFUTIL_BIN} settings generate --family NRF52 --application ${FILE}.hex --application-version 1 --bootloader-version 1 --bl-settings-version 1 ${SETTINGS_FILE}
				COMMAND ${MERGEHEX_BIN} -m ${BOOTLOADER_FILE} ${SETTINGS_FILE} -o ${BOOT_FILE}
				COMMAND echo "Bootloader hex done ${BOOT_FILE}"
				)
		set(REQUIRE_MERGEHEX TRUE)
	else()
		set(BOOT_CMD "")
	endif()
#	message(STATUS BOOT_CMD = ${BOOT_CMD})


	find_program(MERGEHEX_BIN mergehex)
	message(${MERGEHEX_BIN})
	if (REQUIRE_MERGEHEX AND NOT MERGEHEX_BIN)
		if (NOT MERGEHEX_BIN)
			message(WARNING "mergehex binaries, not found, no FLASH target will be created")
			return()
		else()
			message(STATUS "Found mergehex binaries in ${MERGEHEX_BIN}")
		endif()
	else()
		message(STATUS "Using mergehex binaries: ${MERGEHEX_BIN}")
	endif()




	if (OPENOCD_SCRIPT)
		set(OPENOCD_SCRIPT_CMD "-s ${OPENOCD_SCRIPT}")
	else()
		set(OPENOCD_SCRIPT_CMD "")
	endif()

	if(BOOT_FILE OR SOFTDEVICE)
		set(FULL_FILE ${CMAKE_BINARY_DIR}/full.hex)
		set(MERGE_CMD
				COMMAND ${DELFILE_CMD} ${FULL_FILE}
				COMMAND ${MERGEHEX_BIN} -m ${BOOT_FILE} ${SOFTDEVICE} ${FILE}.hex -o ${FULL_FILE}
				)
	else()
		set(FULL_FILE ${FILE}.hex)
		set(MERGE_CMD "")
	endif()
#	message(STATUS MERGE_CMD = ${MERGE_CMD})
	message(STATUS MERGE_CMD = ${MERGE_CMD})
	set(OPENOCD_FLASH_CMD "reset_config none\; init\; halt\; nrf5 mass_erase\; program \"${FULL_FILE}\" verify\; reset\; exit")
	set(OPENOCD_DEBUG_CMD "reset_config none\; init\; halt\; nrf5 mass_erase\; program \"${FULL_FILE}\" verify\; verify\; reset halt\; exit")
	if (HLA_SERIAL)
		set(OPENOCD_FLASH_CMD "hla_serial ${HLA_SERIAL}\; ${OPENOCD_FLASH_CMD}")
		set(OPENOCD_DEBUG_CMD "hla_serial ${HLA_SERIAL}\; ${OPENOCD_DEBUG_CMD}")
	endif()
set (PEM_FILE ${CMAKE_BINARY_DIR}/unlimited.pem)
set (FULL_FILE_ZIP ${CMAKE_BINARY_DIR}/remote_update_${BOARD}.zip)
#	message(File: ${FILE})
		SET(FULL_FILEF ${FULL_FILE})
	if(WIN32)
		string(REPLACE "/" "\\" FILE ${FILE})
		string(REPLACE "/" "\\" FULL_FILEF ${FULL_FILE})
		string(REPLACE "/" "\\" BOOT_CMD ${BOOT_CMD})
		string(REPLACE "/" "\\" MERGE_CMD ${MERGE_CMD})
		string(REPLACE "/" "\\" OPENOCD_CFG ${OPENOCD_CFG})
		string(REPLACE "/" "\\" SETTINGS_FILE ${SETTINGS_FILE})
		string(REPLACE "/" "\\" BOOT_FILE ${BOOT_FILE})
		string(REPLACE "/" "\\" BOOTLOADER_FILE ${BOOTLOADER_FILE})
		string(REPLACE "/" "\\" SOFTDEVICE_FILE ${SOFTDEVICE_FILE})
		string(REPLACE "/" "\\" PEM_FILE ${PEM_FILE})
		string(REPLACE "/" "\\" FULL_FILE_ZIP ${FULL_FILE_ZIP})
	endif()
	message(FULL_FILE: ${FULL_FILEF})

	if (WIN32 OR WIN64)
#		set(FLASH_CMD "-c \"reset_config ${OPENOCD_RESET_CFG}\" -c \"program \"${FILE_PATH}.hex\" verify\"" )
		set(OPENOCD_FLASH_CMD "-c \"reset_config none\" -c \"init\" -c \"halt\" -c \"nrf5 mass_erase\" -c \"program \"${FULL_FILE}\" verify\" -c \"reset\" -c \"exit\"")
	else()
#		set(FLASH_CMD -c "reset_config ${OPENOCD_RESET_CFG}" -c "program \"${FILE_PATH}.hex\" verify" )
		set(OPENOCD_FLASH_CMD "reset_config none\; init\; halt\; nrf5 mass_erase\; program \"${FULL_FILE}\" verify\; reset\; exit")
	endif()
message(STATUS OPENOCD_FLASH_CMD ${OPENOCD_FLASH_CMD})
set(SETTINGS_CMD nrfutil settings generate --family NRF52 --application ${FILE}.hex --application-version 1 --bootloader-version 1 --bl-settings-version 1 ${SETTINGS_FILE})
set(MERGE_BOOT_CMD mergehex -m ${BOOTLOADER_FILE} ${SETTINGS_FILE} -o ${BOOT_FILE})
set(MERGE_FULL_CMD mergehex -m ${BOOT_FILE} ${SOFTDEVICE_FILE} ${FILE}.hex -o ${FULL_FILEF})
set(GEN_UPDATE_CMD nrfutil pkg generate --application ${FILE}.hex --application-version 5 --key-file ${PEM_FILE}  --hw-version 52 --sd-req 0xa8 ${FULL_FILE_ZIP})

	add_custom_target(Flash
			DEPENDS ${TARGET}
#			COMMAND echo FULL_FILE: ${FULL_FILE}
#			COMMAND echo FILE: ${FILE}
#			COMMAND echo BOOT_CMD: ${BOOT_CMD}
#			COMMAND echo DELFULLFILECMD: ${DELFULLFILECMD}
#			COMMAND echo NRFUTIL_BIN: ${NRFUTIL_BIN}
#			COMMAND echo MERGE_CMD: ${MERGE_CMD}
			COMMAND echo ${DELFILE_CMD} ${FILE}.hex
			COMMAND cd
			COMMAND ${DELFILE_CMD} ${FILE}.hex
			COMMAND ${DELFILE_CMD} ${FULL_FILEF}
			COMMAND echo fullfile deleted
			COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILE} ${FILE}.hex
			COMMAND echo cmake_objcopy


			${BOOT_CMD}
			${MERGE_CMD}
			COMMAND ${OPENOCD_BIN} -v
			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} ${OPENOCD_FLASH_CMD}
#			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} ${FLASH_CMD} -c "reset run" -c "exit"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)

	add_custom_target(Flash2
			DEPENDS ${TARGET}
			COMMAND ${DELFILE_CMD} ${SETTINGS_FILE}
			COMMAND ${DELFILE_CMD} ${BOOT_FILE}
			COMMAND ${DELFILE_CMD} ${FULL_FILEF}
			COMMAND ${SETTINGS_CMD}
			COMMAND echo settings done
			COMMAND ${MERGE_BOOT_CMD}
			COMMAND echo merge boot done
			COMMAND ${MERGE_FULL_CMD}
			COMMAND echo merge full done
			COMMAND echo ${FULL_FILE}

						COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} ${OPENOCD_FLASH_CMD}
			#			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} ${FLASH_CMD} -c "reset run" -c "exit"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)

	add_custom_target(Generate_Update
			DEPENDS ${TARGET}
			COMMAND ${GEN_UPDATE_CMD}

			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)

	add_custom_target(Flash3
			DEPENDS ${TARGET}
			COMMAND ${DELFILE_CMD} ${SETTINGS_FILE}
			COMMAND ${DELFILE_CMD} ${BOOT_FILE}
			COMMAND ${DELFILE_CMD} ${FULL_FILE})



	add_custom_target(Flash-Debug
			DEPENDS ${TARGET}
						${DELFILECMD}
						${DELFULLFILECMD}
			COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILE} ${FILE}.hex
			${BOOT_CMD}
			${MERGE_CMD}
			COMMAND ${OPENOCD_BIN} -f ${OPENOCD_CFG} ${OPENOCD_SCRIPT_CMD} -c "${OPENOCD_DEBUG_CMD}"
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} USES_TERMINAL)


ENDFUNCTION()

FUNCTION(PRINT_SIZE_OF_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_SIZE} ${FILENAME})
ENDFUNCTION()


FUNCTION(ADD_HEX_BIN_TARGETS TARGET)
    SET(FILENAME "${CMAKE_BINARY_DIR}/${TARGET}")
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILENAME} ${FILENAME}.hex)
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.bin)
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
	if(NOT TOOLCHAIN_PREFIX)
		if (C_COMPILER)
			get_filename_component(TOOLCHAIN_PREFIX ${C_COMPILER} DIRECTORY)
		else()
			set(TOOLCHAIN_PREFIX "")
			message(STATUS "Using default TOOLCHAIN_PREFIX: ${TOOLCHAIN_PREFIX}")
		endif()
		message(STATUS "Using TOOLCHAIN_PREFIX from C_COMPILER: ${TOOLCHAIN_PREFIX}")
	else()
		message(STATUS "Using TOOLCHAIN_PREFIX: ${TOOLCHAIN_PREFIX}")
	endif()
	if (NOT TOOLCHAIN_PREFIX STREQUAL "")
		set(TOOLCHAIN_PREFIX ${TOOLCHAIN_PREFIX}/)
	endif()

	if(NOT C_COMPILER)
		set(C_COMPILER ${TOOLCHAIN_PREFIX}${TARGET_TRIPLET}-gcc${EXE_EXTENSION})
		message(STATUS "Using default C compiler: ${C_COMPILER}")
	else()
		message(STATUS "Using C compiler: ${CXX_COMPILER}")
	endif()

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

