#!/bin/bash

# Check if an input file was provided
if [ -z "$1" ]; then
	echo "Usage: $0 <assembly_file.s>"
	exit 1
fi

ASM_FILE="$1"
BASE_NAME="${ASM_FILE%.s}"

ELF_FILE="${BASE_NAME}.elf"
BIN_FILE="${BASE_NAME}.bin"
HEX_FILE="${BASE_NAME}.hex"

# 1. Compile assembly to a flat 32-bit RISC-V ELF binary
# -march=rv32i: Restricts compilation strictly to standard, base 32-bit integer instructions.
# -mabi=ilp32: Enforces standard 32-bit integer ABI calling conventions.
# -nostdlib: Excludes standard system libraries to ensure no extra wrapper code is added.
# -Ttext=0x00000000: Sets the base execution entry point memory address to zero.
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0x00000000 -o "$ELF_FILE" "$ASM_FILE"

if [ $? -ne 0 ]; then
	echo "Error: Compilation failed."
	exit 1
fi

# 2. Extract raw machine code bytes from the compiled ELF file
# -O binary: Strips out ELF headers, symbols, and section metadata, exporting pure byte data.
riscv64-unknown-elf-objcopy -O binary "$ELF_FILE" "$BIN_FILE"

# 3. Initialize the Logisim format header
echo "v3.0 hex" >"$HEX_FILE"

# 4. Clean up and parse assembly file lines into an array
# sed -e 's/^[ \t]*//': Strips away leading tabs and spaces.
# -e '/^$/d': Deletes empty lines.
# -e '/^\./d': Removes assembler directives (like .global, .text).
# -e '/^[^:]*:/d': Removes label declarations (like _start:) so they don't misalign comment matching.
mapfile -t ASM_LINES < <(sed -e 's/^[ \t]*//' -e '/^$/d' -e '/^\./d' -e '/^[^:]*:/d' "$ASM_FILE")

# 5. Loop through the binary file 4 bytes at a time and correct the endianness
TOTAL_BYTES=$(stat -c%s "$BIN_FILE")
TOTAL_WORDS=$((TOTAL_BYTES / 4))

for ((i = 0; i < TOTAL_WORDS; i++)); do
	# Extract 4 bytes at the current word offset and swap little-endian bytes to big-endian
	# -s $((i * 4)): Seeks to the specific byte index matching the current instruction word.
	# -l 4: Caps the read width to exactly 4 bytes.
	# -e: Toggles little-endian byte-swapping to output human-readable/Logisim-ready machine words.
	# awk '{print $2}': Extracts only the data column, ignoring memory offsets and ASCII characters.
	HEX_VAL=$(xxd -e -s $((i * 4)) -l 4 "$BIN_FILE" | awk '{print $2}')

	# HEX_VAL=$(xxd -e -s $((i * 4)) -l 4 "$BIN_FILE" | awk '{print $1 "  " $2}')

	# Check if a matching source assembly text line exists for the current instruction offset
	ASM_COMMENT=""
	if [ $i -lt ${#ASM_LINES[@]} ]; then
		if [[ "${ASM_LINES[$i]}" =~ ^[[:space:]]*# ]] || [[ -z "${ASM_LINES[$i]}" ]]; then
			unset 'ASM_LINES[$i]'
			ASM_LINES=("${ASM_LINES[@]}")
			((i--))
			continue
		else
			ASM_COMMENT="# ${ASM_LINES[$i]}"
		fi
	fi

	# Write the formatted instruction word and the matching assembly text line to the .hex file
	printf "%s     %s\n" "$HEX_VAL" "$ASM_COMMENT" >>"$HEX_FILE"
done

# Clean up intermediary files
rm "$ELF_FILE" "$BIN_FILE"

echo "Success! Generated: $HEX_FILE"
