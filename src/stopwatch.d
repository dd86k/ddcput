/**
 * Stopwatch module.
 * 
 * Windows uses QueryPerformanceFrequency and QueryPerformanceCounter.
 * Posix platforms use clock_gettime (CLOCK_MONOTONIC).
 */
module stopwatch;

extern (C):

version (Windows) {
	import core.sys.windows.windows;
} else
version (Posix) {
	import core.sys.posix.time :
		CLOCK_MONOTONIC, timespec, clock_getres, clock_gettime;
	private enum CLOCK_TYPE = CLOCK_MONOTONIC;
	private enum TIME_NS = 1.0e12;	// ns, used with clock_gettime
	private enum TIME_US = 1.0e9;	// µs, used with clock_gettime
	private enum TIME_MS = 1.0e6;	// ms, used with clock_gettime
	private enum BILLION = TIME_US;
}

struct swatch_t {
	version (Windows) {
		long start, end, freq;
	} else
	version (Posix) {
		timespec start, end, freq;
	}
	ubyte running;
}

void watch_init(ref swatch_t s) {
	version (Windows) {
		LARGE_INTEGER l = void;
		QueryPerformanceFrequency(&l);
		s.freq = l.QuadPart;
	} else
	version (Posix) {
		clock_getres(CLOCK_TYPE, &s.freq);
	}
	s.running = 0;
}

void watch_start(ref swatch_t s) {
	version (Windows) {
		LARGE_INTEGER l = void;
		QueryPerformanceCounter(&l);
		s.start = l.QuadPart;
	} else
	version (Posix) {
		clock_gettime(CLOCK_TYPE, &s.start);
	}
	s.running = 1;
}

void watch_stop(ref swatch_t s) {
	version (Windows) {
		LARGE_INTEGER l = void;
		QueryPerformanceCounter(&l);
		s.end = l.QuadPart;
	} else
	version (Posix) {
		clock_gettime(CLOCK_TYPE, &s.end);
	}
	s.running = 0;
}

float watch_ms(ref swatch_t s) {
	version (Windows)
		return ((s.end - s.start) * 1000.0f) / s.freq;
	else
	version (Posix) {
		return cast(float)
			((BILLION * (s.end.tv_sec - s.start.tv_sec))
			+ s.end.tv_nsec - s.start.tv_nsec) / 1_000_000f;
	}
}

float watch_us(ref swatch_t s) {
	version (Windows)
		return (s.end - s.start) / s.freq;
	else
	version (Posix)
		return cast(float)
			((BILLION * (s.end.tv_sec - s.start.tv_sec))
			+ s.end.tv_nsec - s.start.tv_nsec) / 1_000f;
}

