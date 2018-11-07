module seh;

version (Windows) {
	public import seh_windows : seh_init;
}
version (Posix) {
	//public import seh_posix : seh_init;
}