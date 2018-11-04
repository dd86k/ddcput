module test_fuzzer;

import memmgr;

version (X86) {
	enum OP_RET = 0xC3;
} else version (X86_64) {
	enum OP_RET = 0xC3;
}

struct fuzzer_s {

}

extern (C):

__gshared fuzzer_s fuzzer_settings = void;

int start_fuzzer() {
	asmbuf = __mem_create;

	

	return 0;
}