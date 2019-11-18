module modes.latency;

import core.stdc.stdio :
	puts, printf, FILE, fopen, fseek, ftell, fread, SEEK_END, SEEK_SET;
import ddcput, os.io, mm, stopwatch, cpuid, misc;

__gshared:
extern (C):

/*
 * They're not imported (e.g. import binaries) because I don't feel like
 * messing with that.
 */

version (X86) {
	version (Windows) {
		immutable ubyte []PRE_TEST = [ // pre-x86-windows.asm
			0x8B, 0x74, 0x24, 0x04, 0x8B, 0x7E, 0x10, 0x0F,
			0x31, 0x89, 0x06, 0x89, 0x56, 0x04
		];
		enum PRE_TEST_SIZE = PRE_TEST.length;

		immutable ubyte []POST_TEST = [ // post-x86-windows.asm
			0x4F, 0x0F, 0x85, 0x00, 0x00, 0x00, 0x00, 0x0F,
			0x31, 0x89, 0x46, 0x08, 0x89, 0x56, 0x0C, 0xC3
		];
		enum POST_TEST_SIZE = POST_TEST.length;
		enum POST_TEST_JMP_LOC = 3;	/// Jump patch offset, 0-based, aims at lowest byte
		enum POST_TEST_OFFSET = 7;	// DEC+JMP+IMM32
	} else // version Windows
	version (linux) {
		static assert(0, "x86-linux PRE_TEST code needed");
		static assert(0, "x86-linux POST_TEST code needed");
	} // version linux
} else
version (X86_64) {
	version (Windows) {
		immutable ubyte []PRE_TEST = [
			0x48, 0x89, 0xCE, 0x8B, 0x7E, 0x10, 0x0F, 0x31,
			0x89, 0x06, 0x89, 0x56, 0x04
		];
		enum PRE_TEST_SIZE = PRE_TEST.length;

		immutable ubyte []POST_TEST = [
			0xFF, 0xCF, 0x0F, 0x85, 0x00, 0x00, 0x00, 0x00,
			0x0F, 0x31, 0x89, 0x46, 0x08, 0x89, 0x56, 0x0C,
			0xC3
		];
		enum POST_TEST_SIZE = POST_TEST.length;
		enum POST_TEST_JMP_LOC = 4;	/// Jump patch offset, 0-based, aims at lowest byte
		enum POST_TEST_OFFSET = 8;	// DEC+JMP+IMM32
	} else
	version (linux) {
		immutable ubyte []PRE_TEST = [
			0x48, 0x89, 0xFE, 0x8B, 0x7E, 0x10, 0x0F, 0x31,
			0x89, 0x06, 0x89, 0x56, 0x04
		];
		enum PRE_TEST_SIZE = PRE_TEST.length;

		immutable ubyte []POST_TEST = [
			0xFF, 0xCF, 0x0F, 0x85, 0xF8, 0xFF, 0xFF, 0xFF,
			0x0F, 0x31, 0x89, 0x46, 0x08, 0x89, 0x56, 0x0C,
			0xC3
		];
		enum POST_TEST_SIZE = POST_TEST.length;
		enum POST_TEST_JMP_LOC = 4;	/// Jump patch offset, 0-based, aims at lowest byte
		enum POST_TEST_OFFSET = 8;	// DEC+JMP+IMM32
	}
}

debug pragma(msg, "__TEST_SETTINGS.sizeof: ", __TEST_SETTINGS.sizeof);

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
		uint EDI;	// [20]
		uint ESI;	// [24]
	}
	else
	version (X86_64) {
		ulong RDI;	// [20]
		ulong RSI;	// [28]
	}
}

static assert(__TEST_SETTINGS.t1.offsetof == 0);
static assert(__TEST_SETTINGS.t1_l.offsetof == 0);
static assert(__TEST_SETTINGS.t1_h.offsetof == 4);
static assert(__TEST_SETTINGS.t2.offsetof == 8);
static assert(__TEST_SETTINGS.t2_l.offsetof == 8);
static assert(__TEST_SETTINGS.t2_h.offsetof == 12);
static assert(__TEST_SETTINGS.runs.offsetof == 16);

/// Run latency test
/// Returns: Non-zero on error code
int latency_run() {
	if (cpuid_rdtsc == 0) {
		puts("ABORT: RDTSC instruction not available");
		return 1;
	}

	latency_init;	// init ddcputester
	debug printf("delta penalty: %d\n", Settings.delta);

	printf("file: %s\n", Settings.filepath);
	switch (latency_load_file(Settings.filepath)) {
	case 0: break;
	case 1:
		puts("ABORT: File could not be opened");
		return 4;
	default:
		puts("ABORT: Unknown error on file load");
		return 0xfe;
	}

	latency_test();

	return 0;
}

version (X86) {
	immutable ubyte [3]test_rdrand_edx = [ 0x0F, 0xC7, 0xF2 ];
} else
version (X86_64) {
	immutable ubyte [3]test_rdrand_edx = [ 0x0F, 0xC7, 0xF2 ];
}

/// Run integrated latency tests
/// Returns: Non-zero on error code
int latency_run_integrated() {
	if (cpuid_rdtsc == 0) {
		puts("ABORT: RDTSC instruction not available");
		return 1;
	}
	latency_init;	// init ddcputester

	if (cpuid_rdrand) {
		printf("RDRAND EDX: ");
		latency_load(test_rdrand_edx.ptr, 3);
		latency_test();
	}
	return 0;
}

/// Initiates essential stuff and calculate delta penalty for measuring
void latency_init() {
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

	mainpage = mm_create;
	if (cast(size_t)mainpage == 0) {
		puts("Could not initialize mainpage");
	}
	mainpage.code[0] = 0;	// test write
	printf("Running %u times\n", Settings.runs);
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
int latency_load_file(const(char) *path) {
	// user code
	FILE *f = fopen(path, "rb");
	if (cast(uint)f == 0) return 1;

	fseek(f, 0, SEEK_END);

	const uint fl = cast(uint)ftell(f);	/// File size (length)

	debug printf("[debug] size: %u\n", fl);
	fseek(f, 0, SEEK_SET);

	ubyte [4096]buf = void;
	fread(buf.ptr, fl, 1, f);

	latency_load(buf.ptr, fl);

	return 0;
}

int latency_load(const(ubyte) *data, int len) {
	import core.stdc.string : memmove;

	ubyte *buf = cast(ubyte*)mainpage;

	// pre-test code
	memmove(buf, cast(ubyte*)PRE_TEST, PRE_TEST_SIZE);
	size_t offset = PRE_TEST_SIZE;

	// test data
	memmove(buf + offset, data, len);
	offset += len;

	// post-test code + jmp patch
	memmove(buf + offset, cast(ubyte*)POST_TEST, POST_TEST_SIZE);
	int jmp = -(len + POST_TEST_OFFSET); // DEC + JNE + IMM32
	*cast(int*)(buf + offset + POST_TEST_JMP_LOC) = jmp;

	debug {
		printf("[debug] jmp: %d (%Xh)\n", jmp, jmp);
		ubyte *p = cast(ubyte*)mainpage;

		uint m = PRE_TEST_SIZE;
		printf("[debug] PRE [%2d]: ", m);
		do printf("%02X ", *p++); while (--m);
		putchar('\n');

		m = len;
		printf("[debug] TEST[%2d]: ", m);
		do printf("%02X ", *p++); while (--m);
		putchar('\n');

		m = POST_TEST_SIZE;
		printf("[debug] POST[%2d]: ", m);
		do printf("%02X ", *p++); while (--m);
		putchar('\n');
	}

	mm_protect(mainpage);
	return 0;
}

int latency_test() {
	swatch_t sw = void;
	watch_init(sw);
	__TEST_SETTINGS s = void;
	s.runs = Settings.runs;

	extern (C) void function(__TEST_SETTINGS*)
		__test = cast(void function(__TEST_SETTINGS*))mainpage;

	watch_start(sw);
	asm { nop; }
	__test(&s);
	asm { nop; }
	watch_stop(sw);

	const float ms = watch_ms(sw);
	const uint c = s.t2_l - s.t1_l - Settings.delta;
	float r = cast(float)c / Settings.runs;

	debug {
		printf("[debug] t1: %u %u\n", s.t1_h, s.t1_l);
		printf("[debug] t2: %u %u\n", s.t2_h, s.t2_l);
	}

	printf("~%.1f cycles (%u total), ~%f ms (~%f ms total)\n",
		r, c, ms / Settings.runs, ms);
	return 0;
}