; Compile with: NASM -fbin cpuid_1.asm

BITS 64	; Avoids nasm putting the OPCODE prefix (66h)

RDRAND EDX