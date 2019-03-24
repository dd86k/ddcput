// Main module

module ddcput;

import core.stdc.stdio;
import os.setjmp;
import mm;
import misc;

enum : ubyte {
	MODE_NONE,	/// none/other
	MODE_LATENCY,	/// Latency tester, -L
	MODE_FUZZER,	/// Fuzzer feature, -F
}

enum DEFAULT_RUNS = 50_000;	/// (Latency) Number of times to run the test by default

struct settings_s {
	/// Current operation mode, defaults to MODE_NONE
	ubyte cmode;
	/// (Latency) Number of times to loop code
	/// (Fuzzer) Number of times to generate and execute instructions
	uint runs;
	/// (Latency) Load binary test
	const(char) *filepath;
	/// (Latency) (x86, AMD64) Moving results from RDTSC penalty
	uint delta;
	/// (Latency) No effect. Consider: Random number of times to run
	/// (Fuzzer) Genereate instructions randomly instead of tunneling
	ubyte random;
	/// (Internal)
	/// If non-zero, skip halting program (bypass SEH).
	/// Defaults to 0 (no).
	ubyte seh_skip;
	/// (Internal)
	/// Status code affected by SEH
	ubyte seh_status;
}

/// Program settings
__gshared settings_s Settings; // default everything to .init (0)

/**
 * Mingle two 4-byte numbers into an 8-byte number.
 * Params:
 *   high = High 4-byte (dword)
 *   low = Low 4-byte (dword)
 * Returns: 8-byte number
 * Notes: Tested on these platforms.
 *   x86-Windows-DMD
 *   x86-Windows-LDC2
 *   amd64-Windows-DMD
 *   amd64-Windows-LDC2
 */
version (none) extern (C)
ulong mlem(uint high, uint low) {
	version (D_InlineAsm_X86) {
		pragma(msg, "-- mlem : D_InlineAsm_X86");
		version (Windows) asm { naked;
			mov EAX, dword ptr [ESP + 8]; // low
			mov EDX, dword ptr [ESP + 4]; // high
			ret; // EDX:EAX
		} else version (linux) asm { naked;
			mov EAX, dword ptr [EBP - 8]; // low
			mov EDX, dword ptr [EBP - 4]; // high
			ret; // EDX:EAX
		} else static assert(0, "Implement mlem");
	} else version (D_InlineAsm_X86_64) {
		pragma(msg, "-- mlem : D_InlineAsm_X86_64");
		version (Windows) asm { naked;
			shl RCX, 32;
			mov EAX, EDX;
			or RAX, RCX;
			ret; // RAX
		} else version (linux) asm { naked;
			shl RDI, 32;
			mov EAX, ESI;
			or RAX, RDI;
			ret; // RAX
		} else static assert(0, "Implement mlem");
	} else {
		pragma(msg, "-- mlem : D_InlineAsm unavailable");
		// D does not support bit shifting higher than 32 bits
		ulong l = low;
		uint* lp = cast(uint*)&l;
		lp[1] = high;
		//ulong l = low;
		//*((cast(uint*)&l) + 1) = high;
		return l;
	}
}

//
// Unitests
//

unittest {
	import std.stdio : writefln;
	import m_latency;

	writefln("mlem: %X", mlem(0x11223344, 0xAABBCCDD));
	assert(mlem(0x11223344, 0xAABBCCDD) == 0x11223344_AABBCCDD);

	__TEST_SETTINGS a;

	a.t1 = 0xAABBCCDD_11223344;
	assert(a.t1_h == 0xAABBCCDD); assert(a.t1_l == 0x11223344);
	a.t2 = 0xAABBCCDD_11223344;
	assert(a.t2_h == 0xAABBCCDD); assert(a.t2_l == 0x11223344);
}