module misc;

extern (C) int putchar(int);

version (X86) {
	version = X86_ANY;
	enum PLATFORM = "x86";	/// Compiled platform
} else version (X86_64) {
	version = X86_ANY;
	enum PLATFORM = "amd64";	/// Compiled platform
} else {//version (ARM) {
	//enum PLATFORM = "arm";	/// Compiled platform
	static assert(0,
		"ddcputester is currently only supported on x86");
}