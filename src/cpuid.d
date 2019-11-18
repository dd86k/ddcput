module cpuid;

extern (C):

/// Check if RDTSC is available
/// Returns: Non-zero if RDTSC is supported
uint cpuid_rdtsc() {
	/*version (GNU) asm {
		"mov $1, %%eax\n"~
		"cpuid\n"~
		"and $16, %%edx\n"~
		"mov %%edx, %%eax\n"~
		"ret"
	} else */
	asm {	naked;
		mov EAX, 1;
		cpuid;
		and EDX, 16;	// EDX[4]
		mov EAX, EDX;
		ret;
	}
}

/// Check if RDRAND is available
/// Returns: Non-zero if RDRAND is supported
uint cpuid_rdrand() {
	asm {	naked;
		mov EAX, 1;
		cpuid;
		and ECX, 0x40000000;	// EDX[30]
		mov EAX, ECX;
		ret;
	}
}