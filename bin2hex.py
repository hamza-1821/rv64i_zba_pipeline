#!/usr/bin/env python3
"""
Convert binary file to hex format for memory initialization
Reads little-endian bytes and outputs as 32-bit hex values
"""
import sys

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} <input.bin> <output.hex>")
    sys.exit(1)

bin_file = sys.argv[1]
hex_file = sys.argv[2]

with open(bin_file, 'rb') as f:
    data = f.read()

with open(hex_file, 'w') as f:
    f.write("@00000000\n")
    # Read binary as little-endian bytes and write as 32-bit hex values
    for i in range(0, len(data), 4):
        # Get up to 4 bytes (little-endian)
        chunk = data[i:i+4]
        # Pad if needed
        while len(chunk) < 4:
            chunk += b'\x00'
        # Interpret bytes as little-endian integer:
        # byte0 is LSB, byte3 is MSB
        word = chunk[0] | (chunk[1] << 8) | (chunk[2] << 16) | (chunk[3] << 24)
        # Write as 8-digit hex (this represents the 32-bit value)
        hex_str = f"{word:08X}"
        f.write(hex_str)
        if ((i // 4 + 1) % 4 == 0):
            f.write("\n")
        else:
            f.write(" ")

print(f"Converted {len(data)} bytes to {hex_file}")

