import core.stdc.stdio;

import ddcput;
import os_utils;
import seh;
import test_latency;
import test_fuzzer;

enum APP_VERSION = "0.0.0"; /// Application version

version (X86) {
	enum PLATFORM = "x86";	/// Compiled platform
} else version (X86_64) {
	enum PLATFORM = "amd64";	/// Compiled platform
} else version (ARM) {
	enum PLATFORM = "arm";	/// Compiled platform
	static assert(0,
		"ddcputester is currently only supported on x86");
}

enum : ubyte {
	MODE_NONE,	/// none/other
	MODE_LATENCY,	/// Latency tester, -L
	MODE_FUZZER,	/// Fuzzer feature, -F
}

__gshared ubyte opt_currentmode; /// Current operation mode, defaults to MODE_NONE

/// Print help
extern (C) void phelp() {
	puts(
		"ddcput, processor testing tool\n"~
		"  Usage:\n"~
		"    ddcputester -L [FILE]\n"~
		"    ddcputester -F\n"~
		"    ddcputester -v|-h|--version|--help\n"~
		"\n"~
		"  (-L) FILE        File containing instructions to measure latency\n"
	);
}

/// Print version
extern (C) void pversion() {
	printf(
		"ddcput-"~PLATFORM~" v"~APP_VERSION~"  ("~__TIMESTAMP__~")\n"~
		"License: MIT <https://opensource.org/licenses/MIT>\n"~
		"Compiler: "~__VENDOR__~" v%u\n",
		__VERSION__
	);
}

extern (C)
int main(const int argc, immutable(char)** argv) {
	import core.stdc.string : strcmp;

	if (argc <= 1) {
		phelp; return 0;
	}

	uint ai = argc; /// argument index
	immutable(char)* a = void; /// temporary arg pointer
	while (--ai >= 1) {
		if (argv[ai][1] == '-') { // Long arguments
			a = argv[ai] + 2;
			if (strcmp(a, "help") == 0) {
				phelp; return 0;
			}
			if (strcmp(a, "version") == 0) {
				pversion; return 0;
			}
			printf("Unknown parameter: %s\n", a);
			return 1;
		} else if (argv[ai][0] == '-') { // Short arguments
			a = argv[ai];
			while (*++a != 0) switch (*a) {
			case 'F':
				opt_currentmode = MODE_FUZZER;
				Settings.runs = DEFAULT_RUNS;
				break;
			case 'L':
				//TODO: 
				if (ai + 1 >= argc) { // temp until -b/-i idk
					puts("File argument missing for -L");
					return 2;
				}
				immutable(char)* fp = argv[ai + 1];
				const uint r = clicheckpath(fp);
				if (r) return r;
				opt_currentmode = MODE_LATENCY;
				Settings.filepath = fp;
				Settings.runs = DEFAULT_RUNS;
				break;
			case 'h', '?': phelp; return 0;
			case 'v': pversion; return 0;
			default:
				printf("Unknown parameter: %c\n", *a);
				return 1;
			} // while/switch
		} // else if
	} // while arg

	seh_init;

	switch (opt_currentmode) {
	case MODE_LATENCY:
		start_latency;
		break;
	debug {
	case MODE_FUZZER:
		start_fuzzer;
		break;
	}
	default: // MODE_NONE
		puts("Please select an operation mode");
		return 1;
	}

	return 0;
}

int clicheckpath(immutable(char)* path) {
	if (os_pexist(path) == 0) {
		puts("File not found");
		return 3;
	}
	if (os_pisdir(path)) {
		puts("Path is directory");
		return 4;
	}
	return 0;
}