module seh;

version (Windows) {
	import seh_windows : seh_init;
}
version (Posix) {
	//import seh_posix : seh_init;
}