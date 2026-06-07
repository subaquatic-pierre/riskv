#!/bin/bash

# Check if an input file was provided
if [ -z "$1" ]; then
	echo "Usage: $0 <assembly_file.s>"
	exit 1
fi

ASM_FILE="$1"
BASE_NAME="${ASM_FILE%.s}"
HEX_FILE="${BASE_NAME}.hex"

# 1. Initialize the Logisim format header
echo "v2.0 raw" >"$HEX_FILE"

# 2. Assemble and read the listing stream line-by-line
# -march=rv32i: Targets standard 32-bit integer instructions
# -al: Generates an assembly listing showing line numbers, hex values, and source code
riscv64-unknown-elf-as "$ASM_FILE" -al | while read -r line; do
	# riscv64-unknown-elf-as -march=rv32im "$ASM_FILE" -al 2>/dev/null | while read -r line; do

	# Match lines containing hex machine code (e.g., "   3 0004 73000000     ecall")
	# Group 1: Hex Byte Address (4 hex digits)
	# Group 2: Hex Machine Word (8 hex digits)
	# Group 3: Original Assembly Code Line
	if [[ "$line" =~ ^[[:space:]]*[0-9]+[[:space:]]+([0-9a-fA-F]{4})[[:space:]]+([0-9a-fA-F]{8})[[:space:]]+(.*)$ ]]; then
		ADDR_RAW="${BASH_REMATCH[1]}"
		HEX_VAL_RAW="${BASH_REMATCH[2]}"
		ASM_CODE="${BASH_REMATCH[3]}"

		# Normalize address token to match your preferred '0x0000' format
		ADDR_HEX="0x${ADDR_RAW}"

		# Logisim needs little-endian words rearranged to big-endian (AABBCCDD -> DDCCBBAA)
		HEX_VAL=$(echo "$HEX_VAL_RAW" | sed -E 's/(..)(..)(..)(..)/\4\3\2\1/')

		# Format the comment to include both the byte location and instruction name
		ASM_COMMENT="# [$ADDR_HEX] $ASM_CODE"

		# Write cleanly to Logisim target file
		printf "%s     %s\n" "${HEX_VAL,,}" "$ASM_COMMENT" >>"$HEX_FILE"
	fi
done

echo "Success! Generated: $HEX_FILE"
