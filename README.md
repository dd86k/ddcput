# DDCPUT, Processor testing tool

ddcput is a micro-processor testing utility that can:
- Measure user-code instruction latency.

## OPERATING SYSTEM SUPPORT

| Platform | Latency Tester | Fuzzer |
|---|---|---|
| Windows-x86 | ✔️ (5.1+) | 🔄 ongoing |
| Windows-amd64 | ✔️ (6.0+) | 🔄 ongoing |
| macOS-amd64 | Planned [1] | Planned [1] |
| Linux-x86 | Planned | Planned |
| Linux-amd64 | ✔️ | Planned |
| FreeBSD-x86 | Planned | Planned |
| FreeBSD-amd64 | Planned | Planned |
| OpenBSD-x86 | Planned | Planned |
| OpenBSD-amd64 | Planned | Planned |
| efi-amd64 | Considering | Considering |
| baremetal-x86 | Considering | Considering |
| baremetal-amd64 | Considering | Considering |

[1] Until I get a macOS VM or someone willing to implement the necessities

### NOTES

(x86/amd64) This tool is NOT supported in any 16-bit modes, such as real and
vm8086 modes.

# USAGE

## Latency Tester

Currently, the latency tester will run instructions depending on the compiled
binary. For example, the amd64 build will only run amd64 code while the x86
builds will run x86 code. A feature to run x86 code in amd64 is planned.

- Binary code (file) _must_ be flat (i.e. -fbin on NASM);
- It MUST NOT return (RET, LEAVE, etc.);
- And the flow must reach past the end of your code.
  - The tool inserts its own pre-test and post-test code.

### REGISTER USAGE

(x86) EDI and ESI registers are reserved for internal use.

(amd64) RDI and RSI registers are reserved for internal use.

# X86 PITFALLS

x86 is a complex ISA, it might happen that assemblers do not know the full
context of the source code and may generate improper code.

## OPCODE PREFIX

In x86 ("long compability mode"), NASM might prefix a MOV instruction with an
OPCODE PREFIX (66h), even if BITS 32 is specified (not effects in BITS 64).

The OPCODE prefix serves as inverting 16-bit and 32-bit instructions, useful
for executing 32-bit instructions in 16-bit mode (real-address mode) to
transition to protected-mode, but when used improperly, may result in serious
bugs.

For example, a `mov eax, 0` instruction should be encoded like so (x86-32):
```
B8 00 00 00 00
```

However, if the instruction is encoded like so:
```
66 B8 00 00 00 00
```

It results in `mov ax, 0`, and the processor will move a WORD (2 bytes)
instead of a DWORD (4 bytes) and move the Instruction Pointer to the next two
bytes: 00 00h, which is encoded like `add [eax], al`, and since EAX=0 in this
case, it will attempt to write at address 0h and effectively segfault (#UD).

# VIRTUALIZATION NOTES

Please note that some emulators and hypervisors, such as Oracle VirtualBox may
improperly emulate the RDTSC instruction.

# DISCLAIMER

SINCE THIS TOOL DIRECTLY RUNS USER GENERATED BINARY CODE, THIS TOOL IS ENTIRELY
UNSECURE. MAKE SURE THIS TOOL IS NOT AVALAIBLE WITHIN YOUR PATH FOR SECURITY
REASONS. **NEVER** RUN CODE THAT YOU DO NOT TRUST (i.e. COMPILED BY ANOTHER
PERSON, ONLINE EXAMPLES).

LATENCY RESULTS ARE BASED ON THE NUMBER OF TIMES THEY RAN, THE HIGHER THE
COUNT, THE HIGHER PRECISION. HOWEVER, THE LATENCY TESTS ARE STILL AVERAGE.

See LICENSE for more information.