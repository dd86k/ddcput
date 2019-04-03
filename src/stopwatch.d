module stopwatch;

version (Windows) {
	import core.sys.windows.windows;
}

extern (C):

struct swatch_t {
	long start, end, freq;
	ubyte running;
}

void watch_init(ref swatch_t s) {
	version (Windows) {
		LARGE_INTEGER l = void;
		QueryPerformanceFrequency(&l);
		s.freq = l.QuadPart;
	} else
	version (Posix) {
		
	}
	s.running = 0;
}

void watch_start(ref swatch_t s) {
version (Windows) {
	LARGE_INTEGER l = void;
	QueryPerformanceCounter(&l);
	s.start = l.QuadPart;
} // Windows
	s.running = 1;
}

void watch_stop(ref swatch_t s) {
version (Windows) {
	LARGE_INTEGER l = void;
	QueryPerformanceCounter(&l);
	s.end = l.QuadPart;
} // Windows
	s.running = 0;
}

float watch_ms(ref swatch_t s) {
	return ((s.end - s.start) * 1000.0f) / s.freq;
}