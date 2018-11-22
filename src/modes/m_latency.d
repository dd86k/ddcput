module m_latency;

import core.stdc.stdio :
	puts, printf, FILE, fopen, fseek, ftell, fread, SEEK_SET, SEEK_END;
import ddcput;
import os_utils;
import memmgr;
import stopwatch;
import misc;

// NOTE: *_TEST.size code arrays returns _pointer_ size
version (X86) {
version (Windows) {
	immutable ubyte *PRE_TEST = [
		// test -- Sets [ecx+4], 1234 and returns
		//0x8B, 0x4C, 0x24, 0x04, 0xC7, 0x01, 0xD2, 0x04, 0x00, 0x00, 0xC3

		// pre-x86-windows.asm
		0x8B, 0x4C, 0x24, 0x04, 0x89, 0x79, 0x14, 0x89, 0x71, 0x18, 0x89, 0xCE,
		0x8B, 0x7E, 0x10, 0x0F, 0x31, 0x89, 0x06, 0x89, 0x56, 0x04
	];
	enum PRE_TEST_SIZE = 22;

	immutable ubyte *POST_TEST = [
		// post-x86-windows.asm
		0x4F, 0x0F, 0x85, 0xF9, 0xFF, 0xFF, 0xFF, 0x0F, 0x31, 0x89, 0x46, 0x08,
		0x89, 0x56, 0x0C, 0x89, 0xF1, 0x8B, 0x79, 0x14, 0x8B, 0x71, 0x18, 0xC3
	];
	enum POST_TEST_SIZE = 24;
	enum POST_TEST_JMP = 3;	/// Jump patch offset, 0-based, aims at lowest byte
	enum POST_TEST_OFFSET_JMP = 7;	// DEC+JMP+IMM32
} // version Windows

version (linux) {
	static assert(0, "x86-linux PRE_TEST code needed");
	static assert(0, "x86-linux POST_TEST code needed");
} // version linux
} else version (X86_64) {
version (Windows) {
	immutable ubyte *PRE_TEST = [
		// pre-amd64-windows.asm
		0x48, 0x89, 0x79, 0x14, 0x48, 0x89, 0x71, 0x1C, 0x48, 0x89, 0xCE, 0x48,
		0x31, 0xFF, 0x8B, 0x7E, 0x10, 0x0F, 0x31, 0x89, 0x06, 0x89, 0x56, 0x04
	];
	enum PRE_TEST_SIZE = 24;

	immutable ubyte *POST_TEST = [
		// post-amd64-windows.asm
		0x48, 0xFF, 0xCF, 0x0F, 0x85, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x31, 0x89,
		0x46, 0x08, 0x89, 0x56, 0x0C, 0x48, 0x89, 0xF1, 0x48, 0x8B, 0x79, 0x14,
		0x48, 0x8B, 0x71, 0x18, 0xC3
	];
	enum POST_TEST_SIZE = 29;
	enum POST_TEST_JMP = 5;	/// Jump patch offset, 0-based, aims at lowest byte
	enum POST_TEST_OFFSET_JMP = 9;	// DEC+JMP+IMM32
}

version (linux) {
	static assert(0, "amd64-linux PRE_TEST code needed");
	static assert(0, "amd64-linux POST_TEST code needed");
}
}

debug pragma(msg, "sizeof(__TEST_SETTINGS): ", __TEST_SETTINGS.sizeof);

struct __TEST_SETTINGS { align(1):
	union {
		ulong t1;
		struct {
			uint t1_l;	// [0]
			uint t1_h;	// [4]
		}
	}
	union {
		ulong t2;
		struct {
			uint t2_l;	// [8]
			uint t2_h;	// [12]
		}
	}
	uint runs;	// [16]
	version (X86) {
		uint R0;	// [20]
		uint R1;	// [24]
	}
	version (X86_64) {
		ulong R0;	// [20]
		ulong R1;	// [28]
	}
}

pragma(msg, "__TEST_SETTINGS.t1_l@", __TEST_SETTINGS.t1_l.offsetof);
pragma(msg, "__TEST_SETTINGS.t1_h@", __TEST_SETTINGS.t1_h.offsetof);
pragma(msg, "__TEST_SETTINGS.t2_l@", __TEST_SETTINGS.t2_l.offsetof);
pragma(msg, "__TEST_SETTINGS.t2_h@", __TEST_SETTINGS.t2_h.offsetof);
pragma(msg, "__TEST_SETTINGS.runs@", __TEST_SETTINGS.runs.offsetof);

int start_latency() {
	if (core_check == 0) {
		puts("ABORT: RDTSC instruction not available");
		return 1;
	}

	debug printf("file: %s\n", Settings.filepath);

	core_init;	// init ddcputester
	debug printf("delta penalty: %d\n", Settings.delta);

	switch (core_load_file(Settings.filepath)) {
	case 0: break;
	case 1:
		puts("ABORT: File could not be opened");
		return 4;
	default:
		puts("ABORT: Unknown error on file load");
		return 0xfe;
	}

	__TEST_SETTINGS s = void;
	s.runs = Settings.runs;

	swatch_t sw = void;
	watch_init(&sw);

	extern (C) void function(__TEST_SETTINGS*)
		__test = cast(void function(__TEST_SETTINGS*))mainbuf;

	//watch_start(&sw);
	__test(&s);
	//watch_stop(&sw);

	const float ms = 0;//watch_ms(&sw);

	debug {
		printf("[debug] t1: %u %u\n", s.t1_h, s.t1_l);
		printf("[debug] t2: %u %u\n", s.t2_h, s.t2_l);
	}

	float r = (cast(float)s.t2_l - s.t1_l - Settings.delta) / Settings.runs;
	printf("~%.1f cycles, ~%.3f ms (~%f ms each), %d runs\n",
		r, ms, ms / Settings.runs, Settings.runs);

	return 0;
}

/// (x86) Check if RDTSC is present
/// Returns: Non-zero if RDTSC is supported
extern (C)
uint core_check() {
	/*version (GNU) asm {
		"mov $1, %%eax\n"~
		"cpuid\n"~
		"and $16, %%edx\n"~
		"mov %%edx, %%eax\n"~
		"ret"
	} else */
	asm { naked;
		mov EAX, 1;
		cpuid;
		and EDX, 16;	// EDX[4] -- RDTSC
		mov EAX, EDX;
		ret;
	}
}

/// Initiates essential stuff and calculate delta penalty for measuring
extern (C)
void core_init() {
	__TEST_SETTINGS s;
	s.runs = DEFAULT_RUNS;
	version (X86) asm {
		lea ESI, s;
		mov EDI, [ESI + 16];
		rdtsc;
		mov [ESI], EAX;
		mov [ESI + 4], EDX;
_TEST:
		dec EDI;
		jnz _TEST;
		rdtsc;
		mov [ESI + 8], EAX;
		mov [ESI + 12], EDX;
	}
	version (X86_64) asm {
		lea RSI, s;
		xor RDI, RDI;
		mov EDI, [RSI + 16];
		rdtsc;
		mov [RSI], EAX;
		mov [RSI + 4], EDX;
_TEST:
		dec RDI;
		jnz _TEST;
		rdtsc;
		mov [RSI + 8], EAX;
		mov [RSI + 12], EDX;
	}

	Settings.delta = cast(uint)((cast(float)s.t2_l - s.t1_l) / DEFAULT_RUNS);

	mainbuf = __mem_create;
	if (cast(size_t)mainbuf == 0) {
		puts("Could not initialize mainbuf");
	}
	mainbuf.code[0] = 0;	// test write
}

/**
 * Load user code into memory including pre-test and post-test code.
 * Params:
 *   path = File path (binary data)
 * Returns:
 *   0 on success
 *   1 on file could not be open
 *   2 on file could not be loaded into memory
 */
extern (C)
int core_load_file(immutable(char) *path) {
	import core.stdc.string : memmove;
	import os_utils : os_pexist;

	ubyte *buf = cast(ubyte*)mainbuf;

	// pre-test code
	memmove(buf, PRE_TEST, PRE_TEST_SIZE);
	buf += PRE_TEST_SIZE;

	// user code
	FILE *f = fopen(path, "rb");
	if (cast(uint)f == 0) return 1;

	fseek(f, 0, SEEK_END);

	const uint fl = ftell(f);	/// File size (length)

	debug printf("[debug] size:\n", fl);
	fseek(f, 0, SEEK_SET);

	fread(buf, fl, 1, f);
	buf += fl;

	// post-test code + patch
	memmove(buf, POST_TEST, POST_TEST_SIZE);

	int jmp = -(fl + POST_TEST_OFFSET_JMP); // + DEC + JNE + OP
	debug printf("[debug] jmp: ");
	*cast(int*)(buf + POST_TEST_JMP) = jmp;

	debug {
		printf("%d -- %Xh\n", jmp, jmp);
		ubyte *p = cast(ubyte*)mainbuf;

		uint m = PRE_TEST_SIZE;
		printf("[debug] PRE [%3d] -- ", m);
		do printf("%02X ", *p++); while (--m);
		putchar('\n');

		m = fl;
		printf("[debug] TEST[%3d] -- ", m);
		do printf("%02X ", *p++); while (--m);
		putchar('\n');

		m = POST_TEST_SIZE;
		printf("[debug] POST[%3d] -- ", m);
		do printf("%02X ", *p++); while (--m);
		putchar('\n');
	}

	__mem_protect(mainbuf);

	return 0;
}