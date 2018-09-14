module ddcputester;
import core.stdc.stdio;

extern (C) int putchar(int);

version (X86)
	version = X86_ANY;
version (X86_64)
	version = X86_ANY;

version (Posix) {
	import core.sys.posix.sys.mman :
		mmap, mprotect, munmap,
		PROT_READ, PROT_WRITE, PROT_EXEC, MAP_ANON, MAP_PRIVATE;
}
version (Windows) {
	import core.sys.windows.winbase :
		VirtualAlloc, VirtualProtect, VirtualFree, VirtualLock;
	import core.sys.windows.winnt :
		MEM_RESERVE, MEM_COMMIT, MEM_RELEASE,
		PAGE_READWRITE, PAGE_EXECUTE, PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE;
}

// Page sizes may vary between 4K, 2M, and 1G
// Normally, you'd want to check that with 
enum PAGE_SIZE = 4096u;	/// Minimum page size
enum RUNS = 50_000;	/// Number of times to run the test
enum NULL = cast(void*)0;

/// (x86) Moving results from RDTSC penalty
__gshared uint delta = void;
__gshared __ASMBUF* asmbuf = void;

// NOTE: *_TEST code arrays returns _pointer_ size
version (X86) {
	version (Windows) {
		immutable ubyte* PRE_TEST = [
			// test -- Sets [ecx+4], 1234 and returns
			//0x8B, 0x4C, 0x24, 0x04, 0xC7, 0x01, 0xD2, 0x04, 0x00, 0x00, 0xC3

			// pre-x86-windows.asm
			0x8B, 0x4C, 0x24, 0x04, 0x89, 0x79, 0x14, 0x89, 0x71, 0x18, 0x89, 0xCE,
			0x8B, 0x7E, 0x10, 0x0F, 0x31, 0x89, 0x06, 0x89, 0x56, 0x04
		];
		enum PRE_TEST_SIZE = 22;

		immutable ubyte* POST_TEST = [
			// post-x86-windows.asm
			0x4F, 0x0F, 0x85, 0xF9, 0xFF, 0xFF, 0xFF, 0x0F, 0x31, 0x89, 0x46, 0x08,
			0x89, 0x56, 0x0C, 0x89, 0xF1, 0x8B, 0x79, 0x14, 0x8B, 0x71, 0x18, 0xC3
		];
		enum POST_TEST_SIZE = 24;
		enum POST_TEST_JMP = 3;	/// Jump patch offset, 0-based, aims at lowest byte
		//enum POST_TEST_JMP_OP_SIZE = 4;	// JNE REL16
	} // version Windows

	version (linux) {
		static assert(0, "x86-linux PRE_TEST code needed");
		static assert(0, "x86-linux POST_TEST code needed");
	} // version linux
} else version (X86_64) {
	static assert(0, "amd64-* PRE_TEST code needed");
	static assert(0, "amd64-* POST_TEST code needed");
}

debug {
	pragma(msg, "sizeof(__TEST_SETTINGS): ", __TEST_SETTINGS.sizeof);
}

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
	version (X86_ANY) {
		uint EDI;	// [20]
		uint ESI;	// [24]
	}
}

pragma(msg, "t1_l->", __TEST_SETTINGS.t1_l.offsetof);
pragma(msg, "t1_h->", __TEST_SETTINGS.t1_h.offsetof);
pragma(msg, "t2_l->", __TEST_SETTINGS.t2_l.offsetof);
pragma(msg, "t2_h->", __TEST_SETTINGS.t2_h.offsetof);
pragma(msg, "runs->", __TEST_SETTINGS.runs.offsetof);

static assert(__ASMBUF.sizeof == PAGE_SIZE, "Buffer size is not equal to PAGE_SIZE");

struct __ASMBUF { align(1):
	ubyte[PAGE_SIZE - size_t.sizeof] code;
	size_t count;
}

private
__ASMBUF* __asm_create() {
	version (Windows) {
		return cast(__ASMBUF*)VirtualAlloc(
			NULL, __ASMBUF.sizeof, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE
		);
	} else
	version (Posix) {
		return cast(__ASMBUF*)mmap(
			NULL, __ASMBUF.sizeof, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0
		);
	}
}
private
void __asm_protect(__ASMBUF* s) {
	version (Windows) {
		uint e = void;
		debug {
			printf("[debug] VirtualProtect: ");
			printf("%s\n",
				VirtualProtect(s, __ASMBUF.sizeof, PAGE_EXECUTE_READ, &e) ?
				"OK" : cast(char*)"FAIL");
		}
		debug {
			printf("[debug] VirtualLock: ");
			printf("%s\n",
				VirtualLock(s, __ASMBUF.sizeof) ? "OK" : cast(char*)"FAIL");
		}
	} else
	version (Posix) {
		mprotect(s, __ASMBUF.sizeof, PROT_READ | PROT_EXEC);
	}
}
private
void __asm_free(__ASMBUF* s) {
	version (Windows) {
		VirtualFree(s, 0, MEM_RELEASE);
	} else
	version (Posix) {
		munmap(s, PAGE_SIZE);
	}
}

/// (x86) Check if RDTSC is present
version (X86_ANY) {
	extern (C)
	uint core_check() {
		asm { naked;
			mov EAX, 1;
			cpuid;
			and EDX, 16;	// EDX[4] -- RDTSC
			mov EAX, EDX;
			ret;
		}
	}
} else { // version X86

}

/// Initiates essential stuff
/// - Calculate delta penalty for measuring 
/// - Create memory buffer
version (X86_ANY) extern (C)
void core_init() {
	debug puts("[debug] rdtsc+mov penalty");
	uint ts1_l = void, ts2_l = void;
	asm {
		mov ECX, RUNS;
		rdtsc;
		//mov ts1_h, EDX;
		mov ts1_l, EAX;
_TEST:
		dec ECX;
		jnz _TEST;
		rdtsc;
		//mov ts2_h, EDX;
		mov ts2_l, EAX;
	}
	delta = cast(uint)((ts2_l - ts1_l) / RUNS);

	debug puts("[debug] __asm_create");
	asmbuf = __asm_create;
	if (cast(size_t)asmbuf == 0) {
		puts("Could not initialize ASMBUF");
	}
	asmbuf.code[0] = 0;	// test write
}

/**
 * Load user code into memory including pre-test and post-test code.
 * Params:
 *   path = File path (binary data)
 * Returns:
 *   0 on success
 *   1 on file not found
 *   2 on file could not be read
 *   3 on file could not be loaded into memory
 */
extern (C)
int core_load_file(char* path) {
	import core.stdc.string : memmove;
	import os_utils : os_pexist;

	ubyte* buf = cast(ubyte*)asmbuf;

	// pre-test code
	debug puts("[debug] pre-test memmove");
	memmove(buf, PRE_TEST, PRE_TEST_SIZE);
	buf += PRE_TEST_SIZE;

	// user code
	debug puts("[debug] open user code");
	if (os_pexist(path) == 0) return 1;
	FILE* f = fopen(path, "rb");
	if (cast(uint)f == 0) return 2;

	debug puts("[debug] fseek end");
	fseek(f, 0, SEEK_END);

	debug puts("[debug] ftell");
	uint fl = ftell(f);	/// File size (length)

	debug printf("[debug] fseek set (from %u Bytes)\n", fl);
	fseek(f, 0, SEEK_SET);

	debug puts("[debug] fread");
	fread(buf, fl, 1, f);
	buf += fl;

	// post-test code + patch
	debug puts("[debug] post-test memmove");
	memmove(buf, POST_TEST, POST_TEST_SIZE);

	int jmp = -fl;
	debug printf("[debug] post-test jmp patch (jmp:");
	*cast(int*)(buf + POST_TEST_JMP) = jmp;

	debug {
		printf("%d -- %X)\n", jmp, jmp);
		ubyte* p = cast(ubyte*)asmbuf;

		printf("[debug] PRE  -- ");
		uint m = PRE_TEST_SIZE;
		do printf("%02X ", *p++); while (--m);
		putchar('\n');

		printf("[debug] TEST -- ");
		m = fl;
		do printf("%02X ", *p++); while (--m);
		putchar('\n');

		printf("[debug] POST -- ");
		m = POST_TEST_SIZE;
		do printf("%02X ", *p++); while (--m);
		putchar('\n');
	}

	debug puts("[debug] __asm_protect");
	__asm_protect(asmbuf);

	return 0;
}

/*extern (C)
void core_load_imm(ubyte* buffer, size_t size) {

}*/

/*version (X86_ANY) extern (C)
float core_test(__TEST_SETTINGS* s) {
	version (X86) asm { mov EDI, s; }
	version (X86_64) asm { mov RDI, s; }
	asm {
		mov ESI, RUNS;
		rdtsc;
		mov [EDI], EAX;
		mov [EDI + 4], EDX;
_TEST:
		mov EAX, 0;
		cpuid;

		dec ESI;
		jnz _TEST;
		rdtsc;
		mov [EDI + 8], EAX;
		mov [EDI + 12], EDX;
	}
	debug {
		printf("%u %u\n", s.t1_h, s.t1_l);
		printf("%u %u\n", s.t2_h, s.t2_l);
	}
	return (cast(float)s.t2_l - s.t1_l - delta) / RUNS;
}*/

float core_test(__TEST_SETTINGS* s) {
	debug puts("[debug] get __test");
	extern (C) void function(__TEST_SETTINGS*)
		__test = cast(void function(__TEST_SETTINGS*))asmbuf;

	debug printf("[debug] call __test@%Xh\n", cast(uint)__test);
	__test(s);

	debug {
		printf("[debug] %u %u\n", s.t1_h, s.t1_l);
		printf("[debug] %u %u\n", s.t2_h, s.t2_l);
	}

	return (cast(float)s.t2_l - s.t1_l - delta) / RUNS;
}

/**
 * Mingle two 4-byte numbers into an 8-byte number.
 * Params:
 *   high = High 4-byte
 *   low = Low 4-byte
 * Returns: 8-byte number
 * Notes: Tested on these platforms.
 *   x86-Windows-DMD
 *   x86-Windows-LDC2
 *   amd64-Windows-DMD
 *   amd64-Windows-LDC2
 */
version (0) extern (C)
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
		*((cast(uint*)&l) + 1) = high;
		return l;
	}
}

/*
 * Unitests
 */

unittest {
	import std.stdio;
	writefln("mlem: %X", mlem(0x11223344, 0xAABBCCDD));
	assert(mlem(0x11223344, 0xAABBCCDD) == 0x11223344_AABBCCDD);

	__TEST_SETTINGS a;

	a.t1 = 0xAABBCCDD_11223344;
	assert(a.t1_h == 0xAABBCCDD); assert(a.t1_l == 0x11223344);
	a.t2 = 0xAABBCCDD_11223344;
	assert(a.t2_h == 0xAABBCCDD); assert(a.t2_l == 0x11223344);
}