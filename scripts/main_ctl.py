# Script to create the Hex output to encode the ROM unit for main controller

from typing import List

addr_space_bit_size = 9
total_bytes = 2**addr_space_bit_size
data_map = {0b0010_1010: [0b1111_1111, 0b1111_1111]}


def gen_byte_arr(size: int) -> List[int]:
    data = [0 for _ in range(size)]
    return data


def insert_data(byte_arr: List[int], addr: int, data: List[int]):
    for offset, byte in enumerate(data):
        byte_arr[addr + offset] = byte


def build_rows(data: List[int], row_size: int) -> List[str]:
    lines = []
    line = ""
    for i, byte in enumerate(data):
        # Only print line at end of row and not first element
        if i % row_size == 0 and i != 0:
            # print row
            lines.append(line)

            # reset line
            line = ""

        # Ensure we only add space if not first char
        if len(line) != 0:
            line += " "
        line += f"{byte:02x}"

    return lines


def save_lines(lines: List[str]):
    with open("out.rom", "w") as f:
        for line in lines:
            f.write(f"{line}\n")


def main():
    data = gen_byte_arr(total_bytes)
    for addr, bytes in data_map.items():
        insert_data(data, addr, bytes)

    lines = build_rows(data, 16)
    save_lines(lines)


if __name__ == "__main__":
    main()
