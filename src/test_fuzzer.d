module test_fuzzer;

import core.stdc.stdlib : rand;
import memmgr;

version (X86) {
	enum ubyte OP_RET = 0xC3;
} else version (X86_64) {
	enum ubyte OP_RET = 0xC3;
}

extern (C):

int start_fuzzer() {
	mainbuf = __mem_create;

	const uint size = rand & 0xF; // 0-15 seems decent

	fgenerate(mainbuf, size);

	return 0;
}

/**
 * Generate random numbers in memory to fill as instructions.
 * This functions inserts, at the very end, a RET (or appropriate
 * instruction for the architecture) instruction.
 * Params:
 *   buffer = Live memory buffer
 *   size = Size in bytes, excluding RET instruction
 * Returns: Nothing
 */
void fgenerate(__membuf_s* buffer, uint size) {
	uint* up = cast(uint*)buffer;

	while (size -= 4 > 0)
		*up++ = rand;
	
	ubyte* bp = cast(ubyte*)up;

	const uint r = rand;
	switch (size) {
	case 3:
		*up = r & 0xFF_FFFF;
		bp[3] = OP_RET;
		break;
	case 2:
		*up = cast(ushort)r;
		bp[2] = OP_RET;
		break;
	case 1:
		*up = cast(ubyte)r;
		bp[1] = OP_RET;
		break;
	default: // 0, or ????
	}
}