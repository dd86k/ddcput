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
	"\tddcput {-v|-h|--version|--help}\n"~
	"\t(Latency) ddcput -L [FILE]\n"~
	//"\t(Fuzzer)  ddcput -F\n"~
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
	"Compiler: "~__VENDOR__~" v%u.%03u\n",
	d.version_major, d.version_minor
	);
}

void plicense() {
	puts(
`Copyright (c) 2018-2019 dd86k

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.`
	);
}

/**
 * Check if path exists and is file.
 * Params: path = File path
 * Returns: Non-zero on error; otherwise zero
 */
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

int main(const(int) argc, const(char) **argv) {
	if (argc <= 1) {
		phelp; return 0;
	}

	size_t argi; /// argument index
	const(char) *a = void; /// temporary arg pointer
	while (++argi < argc) {
		if (argv[argi][1] == '-') { // Long arguments
			a = argv[argi] + 2;
			if (strcmp(a, "help") == 0) {
				phelp; return 0;
			}
			if (strcmp(a, "version") == 0) {
				pversion; return 0;
			}
			if (strcmp(a, "license") == 0) {
				plicense; return 0;
			}
			printf("Unknown parameter: %s\n", a);
			return 1;
		} else if (argv[argi][0] == '-') { // Short arguments
			a = argv[argi];
			while (*++a != 0) switch (*a) {
			case 'F':
				Settings.opmode = MODE_FUZZER;
				Settings.runs = DEFAULT_RUNS;
				break;
			case 'L':
				if (argi + 1 >= argc) {
					puts("File argument missing for -L");
					return 2;
				}
				Settings.filepath = argv[argi + 1];
				Settings.opmode = MODE_LATENCY;
				Settings.runs = DEFAULT_RUNS;
				break;
			case 'R':
				Settings.opmode = MODE_REGISTERS;
				break;
			case 'r':
				Settings.random = 1;
				break;
			case 'n':
				if (argi + 1 >= argc) {
					puts("File argument missing for -r");
					return 2;
				}
				Settings.runs = atoi(argv[argi + 1]);
				if (Settings.runs == 0) {
					puts("Run times must be higher than 0 (-n)");
					return 3;
				}
				break;
			case 'i':
				Settings.integrated = true;
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

	switch (Settings.opmode) {
	case MODE_LATENCY:
		if (Settings.integrated) {
			return latency_run_integrated;
		} else {
			if (pcheck(Settings.filepath))
				return 2;
			return latency_run;
		}
	case MODE_FUZZER:
		return fuzzer_run;
	case MODE_REGISTERS:
		return registers_run;
	default: // MODE_NONE
		puts("Please select an operation mode");
		return 1;
	}
}