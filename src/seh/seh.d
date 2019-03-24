module seh.seh;

version (Windows) {
	public import seh.windows;
}
version (Posix) {
	public import seh.posix;
}