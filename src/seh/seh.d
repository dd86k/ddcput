module seh;

public:

/// Status code that SEH might affect under certain modes, affected by
/// MODE_FUZZER
__gshared int sehstatus = void;

version (Windows) {
	public import seh_windows : seh_init;
}
version (Posix) {
	//public import seh_posix : seh_init;
}