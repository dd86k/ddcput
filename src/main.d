import core.stdc.stdio;
import core.stdc.stdlib : atoi;
import core.stdc.string : strcmp;
import ddcput;
import os.io;
import seh.seh;
import modes.latency, modes.fuzzer, modes.registers;
import misc : PLATFORM;

enum APP_VERSION = "0.0.0"; /// Application version

extern (C):

/// Print help
void phelp() {
	puts(
	"ddcput, processor testing tool\n"~
	"Usage:\n"~
	"\t(Latency) ddcput -L [FILE]\n"~
	//"\t(Fuzzer)  ddcput -F\n"~
	"\tddcput {-v|-h|--version|--help}\n"~
	"\n"~
	"Latency\n"~
	"\t-L FILE     File containing machine instructions to measure latency\n"~
	"\t-n          Number of times to run tests invidually\n"~
	"\t-i          Run integrated tests\n" //TODO:
	//"Fuzzer\n"
	);
}

/// Print version
void pversion() {
	import d = std.compiler : version_major, version_minor;
	printf(
	"ddcput-"~PLATFORM~" v"~APP_VERSION~"  ("~__TIMESTAMP__~")\n"~
	"License: MIT <https://opensource.org/licenses/MIT>\n"~
	"Home: https://git.dd86k.space/dd86k/ddcput\n"~
	"Compiler: "~__VENDOR__~" v%u.%u\n",
	d.version_major, d.version_minor
	);
}

int pcheck(const(char) *path) {
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

int main(const int argc, const(char) **argv) {
	if (argc <= 1) {
		phelp; return 0;
	}

	uint ai; /// argument index
	const(char) *a = void; /// temporary arg pointer
	while (++ai < argc) {
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
				Settings.cmode = MODE_FUZZER;
				Settings.runs = DEFAULT_RUNS;
				break;
			case 'L':
				if (ai + 1 >= argc) {
					puts("File argument missing for -L");
					return 2;
				}
				const(char) *fp = argv[ai + 1];
				if (pcheck(fp)) return 2;
				Settings.filepath = fp;
				Settings.cmode = MODE_LATENCY;
				Settings.runs = DEFAULT_RUNS;
				break;
			case 'R':
				Settings.cmode = MODE_REGISTERS;
				break;
			case 'r':
				Settings.random = 1;
				break;
			case 'n':
				if (ai + 1 >= argc) {
					puts("File argument missing for -r");
					return 2;
				}
				Settings.runs = atoi(argv[ai + 1]);
				if (Settings.runs == 0) {
					puts("Run times must be higher than 0 (-n)");
					return 3;
				}
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

	switch (Settings.cmode) {
	case MODE_LATENCY:
		return l_start;
	case MODE_FUZZER:
		return start_fuzzer;
	case MODE_REGISTERS:
		return show_registers;
	default: // MODE_NONE
		puts("Please select an operation mode");
		return 1;
	}
}