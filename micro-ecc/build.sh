#!/bin/bash

# This script will use git (must be in $PATH) and arm-none-eabi tools in combination with GNU Make
# to both fetch and compile all variants of micro-ecc for the nRF5 families
if [ -z $1 ]; then
  echo "you need to select an architecture/compiler. Ex: nrf52hf_armgcc"
  exit
fi

if [ ! -d "$1" ]; then
  echo "architecture/compiler $1 doesn't exit"
  exit
fi

if [ ! -d "$1/armgcc" ]; then
  echo "architecture/compiler $1/armgcc doesn't exit"
  exit
fi



if ! [ -x "$(command -v git)" ]; then
    echo 'git is not installed. Please install and append to PATH.' >&2
    exit
fi

if [ ! -f micro-ecc/uECC.c ]; then
    echo "micro-ecc not found! Let's pull it from HEAD."
    git clone https://github.com/kmackay/micro-ecc.git
fi

make -C "$1/armgcc"

