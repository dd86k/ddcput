// Fuzzer module

module modes.fuzzer;

import ddcput : Settings;
import mm;
import netrand;
import msetjmp;
import seh.seh;
import misc;

extern (C):

int start_fuzzer() {
	import core.stdc.stdio : printf, puts;
	import core.stdc.string : memset;

	mainpage = mm_create;

	rinit;

	ubyte *mmp = cast(ubyte*)mainpage;
	size_t mmpi = void;

	extern (C) void function() __test = cast(void function())mainpage;

	Settings.seh_skip = 1;

	jmp_buf jmpl;
	// SETJMP REMINDER
	// When first called, setjmp will return 0
	// When called by longjmp, it will return the value passed (second param)
	// Flow restarts after this statement when an exception occurs (SEH)
	// SEH status will always be non-zero, so do not bother checking it
	const int r = setjmp(&jmpl);
	jmpcpy = &jmpl;

	if (r) puts(" failed");

	mm_unprotect(mainpage);

	while (--Settings.runs > 0) {
		mmpi = 0;
		memset(mainpage, 0, 16);

		const uint size = rnextb & 0xF; // 0-15

		fgenerate(mainpage, size);

		while (mmp[mmpi]) {
			printf("%02X ", mmp[mmpi]);
			++mmpi;
		}
		putchar('\n');

		mm_protect(mainpage);
		__test();
		mm_unprotect(mainpage);
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
void fgenerate(page_t *buffer, int size) {
	ubyte* up = cast(ubyte*)buffer;

	uint i;
	while (i < size) {
		//TODO: Consider using rsamplei directly
		*up++ = rnextb;
		++i;
	}

	*up = OP_RET;
}

unittest {
	import std.stdio;

	writeln("-- fgenerate 15");

	ubyte [512]b;

	fgenerate(cast(page_t*)b, 15);

	int i = 0;
	uint *bp = cast(uint*)b;
	while (bp[i]) {
		++i;
		writefln("%08x", bp[i]);
	}

	writeln("-- fgenerate 16");

	fgenerate(cast(page_t*)b, 16);

	i = 0;
	while (bp[i]) {
		++i;
		writefln("%08x", bp[i]);
	}
}