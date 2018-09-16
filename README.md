# DDCPUTESTER, Processor testing tool

ddcputester is a micro-processor testing utility that can:
 - Measure user-code instruction throughput/latency.

NOTICE: Currently checking why release builds are crashing right after calling
the memory block (e.g. how is the ABI affected in optimizations). This affects
Windows builds so far.

## OPERATING SYSTEM SUPPORT

| Platform (ABI) / ISA | x86 | AMD64 |
|---|---|---|
| Windows | ✔️ (5.1+) | ✔️ (6.0+) |
| macOS | On wait^1 | On wait^1 |
| Linux (System V) | Planned | On wait^2 |

^1: Until I get a macOS VM or someone willing to implement the necessities

^2: See NOTICE above

(x86) This tool is NOT supported in REAL-MODE and vm8086 (any 16-bit modes).

# USAGE

In order to test user-generated code:
- Binary code MUST be flat (-fbin on NASM);
- It MUST NOT return (RET nor LEAVE);
- And the flow must reach the end of your code.

## x86 REGISTER USAGE

EDI and ESI registers are reserved.

## AMD64 REGISTER USAGE

RDI and RSI registers are reserved.

## X86 PITFALLS

x86 is a complex ISA, it might happen that assemblers do not know the full context
of the source code and may generate improper code.

### OPCODE PREFIX

In x86 (long compability mode), NASM might prefix a MOV instruction with an
OPCODE prefix (66h), even if BITS 32 is specified.

For example, a `mov eax, 0` instruction would be encoded like so:
```
B8 00 00 00 00
```

However, if the instruction is encoded like so:
```
66 B8 00 00 00 00
```

The processor may attempt to move a WORD (2 bytes) and move the Instruction Pointer
to the next two bytes: 00 00h, which is encoded like `mov [eax], al`, and since
EAX=0 in this case (from ModR/M byte), it will attempt to write at address 0h and
effectively segfault (#UD).

# TODO

- Clear all registers before running user-code

# DISCLAIMER

SINCE THIS TOOL DIRECTLY RUNS USER GENERATED BINARY CODE, THIS TOOL IS ENTIRELY UNSECURE. MAKE SURE THIS TOOL IS NOT AVALAIBLE WITHIN YOUR $PATH (OR %PATH%) FOR SECURITY REASONS.

See LICENSE for more information