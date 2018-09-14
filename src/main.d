import core.stdc.stdio;

import ddcputester;
import os_utils;

version (Windows) {
	import seh_windows : seh_init;
}
version (Posix) {
	//import seh_posix : seh_init;
}

enum APP_VERSION = "0.0.0";

version (X86_64) {
	enum PLATFORM = "AMD64";
} else version (X86) {
	enum PLATFORM = "X86";
} else version (ARM) {
	enum PLATFORM = "ARM";
}

extern (C)
void p_help() {
	puts(
		"DDCPUTESTER, processor testing tool\n"~
		"  ddcputester [FILE]\n\n"~
		"  FILE        File containing instructions to measure latency"
	);
}

extern (C)
void p_version() {
	printf(
		"\nDDCPUTESTER-"~PLATFORM~" v"~APP_VERSION~"  ("~__TIMESTAMP__~")\n"~
		"Built with the "~__VENDOR__~" compiler (D v%u standard)\n\n"
		, __VERSION__
	);
}

extern (C)
int main(int argc, char** argv) {
	import core.stdc.string : strcmp;

	if (argc <= 1) {
		p_help; return 0;
	}

	while (--argc >= 1) {
		if (argv[argc][1] == '-') { // Long arguments
			char* a = argv[argc] + 2;
			if (strcmp(a, "help") == 0) {
				p_help; return 0;
			}
			if (strcmp(a, "version") == 0) {
				p_version; return 0;
			}
			printf("Unknown parameter: %s\n", a);
			return 1;
		} else if (argv[argc][0] == '-') { // Short arguments
			char* a = argv[argc];
			while (*++a != 0) {
				switch (*a) {
				case 'h', '?': p_help; return 0;
				case 'v': p_version; return 0;
				default:
					printf("Unknown parameter: %c\n", *a);
					return 1;
				} // switch
			} // while
		} // else if
	} // while arg
	
	version (X86_ANY) {
		if (core_check == 0) {
			puts("ABORT: RDTSC instruction not available");
			return 1;
		}
	}

	if (os_pexist(argv[1]) == 0) {
		puts("ABORT: Path not found");
		return 2;
	}

	if (os_pisdir(argv[1])) {
		puts("ABORT: Path is a directory");
		return 3;
	}

	printf("file: %s\n", argv[1]);

	seh_init;

	core_init;	// init ddcputester
	debug printf("delta penalty: %d\n", delta);

	switch (core_load_file(argv[1])) {
		case 0: break;
		case 1:
			puts("ABORT: File could not be opened");
			return 4;
		default:
			puts("ABORT: Unknown error on file load");
			return 0xfe;
	}

	__TEST_SETTINGS s = void;
	s.runs = RUNS;
	float result = core_test(&s);
	printf("Result: %f cycles\n", result);

	return 0;
}

