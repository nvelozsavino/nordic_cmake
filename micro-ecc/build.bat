@ECHO OFF

:: This script will use git (must be in %PATH%) and arm-none-eabi tools in combination with GNU Make
:: to both fetch and compile all variants of micro-ecc for the nRF5 families

IF [%1] == [] (
  ECHO "you need to select an architecture/compiler. Ex: nrf52hf_armgcc"

)

IF NOT EXIST "%1" (
  ECHO "architecture/compiler %1 doesn't exit"
)

IF NOT EXIST "%1/armgcc" (
  ECHO "architecture/compiler %1/armgcc doesn't exit"
)


WHERE >nul 2>nul git
IF %ERRORLEVEL% NEQ 0 (
    ECHO "git is not installed. Please install and append to PATH."
)



IF NOT EXIST micro-ecc/uECC.c (
    ECHO "micro-ecc not found! Let's pull it from HEAD."
    git clone https://github.com/kmackay/micro-ecc.git
)

make -C "%1/armgcc"
