/**
 * Stopwatch module. Windows uses QueryPerformanceFrequency and
 * QueryPerformanceCounter and Posix systems use gettimeofday.
 */
module stopwatch;

version (Windows) {
	import core.sys.windows.windows;
} else
version (Posix) {
	import core.sys.posix.sys.time : gettimeofday, timeval;
	import core.sys.linux.time :
		clock_getres, clock_gettime, clockid_t, timespec,
		CLOCK_MONOTONIC, CLOCK_MONOTONIC_COARSE,
		CLOCK_MONOTONIC_RAW,
		CLOCK_REALTIME, CLOCK_REALTIME_COARSE,
		CLOCK_THREAD_CPUTIME_ID, CLOCK_PROCESS_CPUTIME_ID;
	enum CLOCK_TYPE = CLOCK_MONOTONIC;
	enum TIME_NS = 1.0e12; // ns, used with clock_gettime
	enum TIME_US = 1.0e9; // µs, used with clock_gettime
	enum TIME_MS = 1.0e6; // ms, used with clock_gettime
}

extern (C):

struct swatch_t {
	version (Windows) {
		long start, end, freq;
	} else
	version (Posix) {
		//timeval start, end;
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
	//gettimeofday(&s.start, cast(void*)0);
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
	//gettimeofday(&s.end, cast(void*)0);
	clock_gettime(CLOCK_TYPE, &s.end);
}
	s.running = 0;
}

float watch_ms(ref swatch_t s) {
	version (Windows)
		return ((s.end - s.start) * 1000.0f) / s.freq;
	else
	version (Posix) {
		float te = cast(float)s.end.tv_nsec;
		float ts = cast(float)s.start.tv_nsec;
		if (s.end.tv_sec) {
			te += (s.end.tv_sec * TIME_NS);
		}
		if (s.start.tv_sec) {
			ts += (s.start.tv_sec * TIME_NS);
		}
		return (te - ts) / s.freq.tv_nsec / TIME_MS;
		//return (s.end.tv_usec - s.start.tv_usec) * 1000.0f;
	}
}

float watch_us(ref swatch_t s) {
	version (Windows)
		return (s.end - s.start) / s.freq;
	else
	version (Posix)
		return (s.end.tv_nsec - s.start.tv_nsec) / TIME_MS;
		//return s.end.tv_usec - s.start.tv_usec;
}

