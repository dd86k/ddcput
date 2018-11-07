module test_fuzzer;

import ddcput : Settings;
import memmgr;
import rand;
import misc : putchar;

version (X86) {
	enum ubyte OP_RET = 0xC3;
} else version (X86_64) {
	enum ubyte OP_RET = 0xC3;
}

extern (C):

int start_fuzzer() {
	import core.stdc.stdio : printf;
	import core.stdc.string : memset;

	rinit;

	mainbuf = __mem_create;

	ubyte* mmp = cast(ubyte*)mainbuf;
	size_t mmpi = void;

	extern (C) void function() __test = cast(void function())mainbuf;

	while (--Settings.runs > 0) {
		mmpi = 0;
		memset(mainbuf, 0, 16);

		const uint size = rnextb & 0xF; // 0-15 seems decent

		fgenerate(mainbuf, size);

		while (mmp[mmpi]) {
			printf("%02X ", mmp[mmpi]);
			++mmpi;
		}
		putchar('\n');

		__mem_protect(mainbuf);
		__test();
		__mem_unprotect(mainbuf);
	}



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
 * Notes: Windows' RAND_MAX goes up to 0xFFFF
 */
void fgenerate(__membuf_s* buffer, int size) {
	ubyte* up = cast(ubyte*)buffer;

	uint i;
	while (i < size) {
		// Another time I could directly use rsamplei
		*up++ = rnextb;
		++i;
	}

	*up = OP_RET;
}

unittest {
	import std.stdio;

	writeln("-- fgenerate 15");

	ubyte[512] b;

	fgenerate(cast(__membuf_s*)b, 15);

	i = 0;
	uint* bp = cast(uint*)b;
	while (bp[i]) {
		++i;
		writefln("%08x", bp[i]);
	}

	writeln("-- fgenerate 16");

	fgenerate(cast(__membuf_s*)b, 16);

	i = 0;
	while (bp[i]) {
		++i;
		writefln("%08x", bp[i]);
	}
}