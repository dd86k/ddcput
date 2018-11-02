# DDCPUTESTER, Processor testing tool

ddcputester is a micro-processor testing utility that can:
- Measure user-code instruction latency.

## OPERATING SYSTEM SUPPORT

| Platform | Latency Tester | Fuzzer |
|---|---|---|
| Windows-x86 | ✔️ (5.1+) [2] | 🔄 ongoing |
| Windows-amd64 | ✔️ (6.0+) [2] | 🔄 ongoing |
| macOS-amd64 | Planned [1] | Planned [1] |
| Linux-x86 | Planned | Planned |
| Linux-amd64 | Planned | Planned |
| efi-amd64 | Considering | Considering |
| baremetal-x86 | Considering | Considering |
| baremetal-amd64 | Considering | Considering |

[1] Until I get a macOS VM or someone willing to implement the necessities

[2] Currently checking why release builds are crashing right after calling
the memory block (e.g. how is the ABI affected in optimizations). This affects
Windows builds so far.

### NOTES

(x86/amd64) This tool is NOT supported in real and vm8086 modes.

# USAGE

## Latency Tester

- Binary code (file) MUST be flat (-fbin on NASM);
- It MUST NOT return (RET, LEAVE, etc.);
- And the flow must reach past the end of your code.
  - The tool inserts its own post-test code.

### REGISTER USAGE

(x86) EDI and ESI registers are reserved.

(amd64) RDI and RSI registers are reserved.

# X86 PITFALLS

x86 is a complex ISA, it might happen that assemblers do not know the full context
of the source code and may generate improper code.

## OPCODE PREFIX

In x86 (long compability mode), NASM might prefix a MOV instruction with an
OPCODE prefix (66h), even if BITS 32 is specified (not present in BITS 64).

For example, a `mov eax, 0` instruction should be encoded like so:
```
B8 00 00 00 00
```

However, if the instruction is encoded like so:
```
66 B8 00 00 00 00
```

The processor will move a WORD (2 bytes) and move the Instruction Pointer
to the next two bytes: 00 00h, which is encoded like `add [eax], al`, and since
EAX=0 in this case, it will attempt to write at address 0h and effectively
segfault (#UD).

# DISCLAIMER

SINCE THIS TOOL DIRECTLY RUNS USER GENERATED BINARY CODE, THIS TOOL IS ENTIRELY
UNSECURE. MAKE SURE THIS TOOL IS NOT AVALAIBLE WITHIN YOUR $PATH (OR %PATH%)
FOR SECURITY REASONS. **NEVER** RUN CODE THAT YOU DO NOT TRUST (i.e. COMPILED
BY ANOTHER PERSON, ONLINE EXAMPLES).

LATENCY RESULTS ARE BASED ON THE NUMBER OF TIMES THEY RAN, THE HIGHER THE COUNT,
THE HIGHER PRECISION. HOWEVER, THE LATENCY TESTS ARE STILL AVERAGE.

See LICENSE for more information.