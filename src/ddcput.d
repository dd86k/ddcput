// Main module

module ddcput;

enum : ubyte {
	MODE_NONE,	/// none/other
	MODE_LATENCY,	/// Latency tester, -L
	MODE_FUZZER,	/// Fuzzer feature, -F
	MODE_TLBTESTER,	/// TLB tester, -T
	MODE_REGISTERS,	/// Show all registers, -R
}

/// Default times to run stuff
/// (Latency) Number of times to run the test
/// (TLB) Number of times to run through the page
enum DEFAULT_RUNS = 50_000;

struct settings_s {
	/// Current operation mode, defaults to MODE_NONE
	ubyte opmode;
	/// (Latency) Number of times to loop code
	/// (Fuzzer) Number of times to generate and execute instructions
	uint runs;
	/// (Latency) Load binary test
	const(char) *filepath;
	/// (Latency: x86, AMD64) Moving results from RDTSC penalty
	uint delta;
	/// (Latency) Run integrated tests instead of file.
	ubyte integrated;
	/// (Fuzzer) Genereate instructions randomly instead of tunneling
	ubyte random;
	/// (Internal) If non-zero, skip halting program (bypass SEH).
	/// Defaults to 0 (no).
	/// Current modes that uses this setting:
	/// - Fuzzer
	ubyte seh_skip;
	/// (Internal) Status code affected by SEH
	ubyte seh_status;
}

/// Program settings
__gshared settings_s Settings; // default everything to .init (0)