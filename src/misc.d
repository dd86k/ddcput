module misc;

extern (C) int putchar(int);

version (X86)
	version = X86_ANY;
version (X86_64)
	version = X86_ANY;