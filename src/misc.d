module misc;

extern (C) int putchar(int);

version (X86) {
	enum PLATFORM = "x86";	/// Compiled platform
	version = X86_ANY;
	enum ubyte OP_RET = 0xC3;
} else version (X86_64) {
	enum PLATFORM = "amd64";	/// Compiled platform
	version = X86_ANY;
	enum ubyte OP_RET = 0xC3;
} else {//version (ARM) {
	//enum PLATFORM = "arm";	/// Compiled platform
	static assert(0,
		"ddcput is currently only supported on x86 and x86-64");
}

template BIT(int n) { enum { BIT = 1 << n } }