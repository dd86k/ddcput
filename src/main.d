import core.stdc.stdio;

import ddcputester;
version (Windows) {
	import seh_windows;
}
version (Posix) {
	//import seh_posix;
}

extern (C)
int main(int argc, char** argv) {
	if (argc < 2) {
		puts("todo help screen");
		return 0;
	}
	
	version (X86_ANY) {
		if (core_check == 0) {
			puts("RDTSC instruction not available");
			return 1;
		}
	} else { // version X86

	}
	
	printf("file: %s\n", argv[1]);

	seh_init;

	core_init;	// init ddcputester
	debug printf("delta penalty: %d\n", delta);

	//core_load();	// load file with user code
	switch (core_load_file(argv[1])) {
		case 0: break;
		default: puts("????");
	}

	__TEST_SETTINGS s = void;
	s.runs = RUNS;
	float result = core_test(&s);
	printf("Result: %f cycles\n", result);
//	printf("cpuid EAX=0: %f\n", result);
	//result = core_test(&s);
	//printf("cpuid EAX=1%f\n", result);

	return 0;
}

