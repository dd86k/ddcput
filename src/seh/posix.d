module seh.posix;

import core.stdc.stdio : printf;
import core.stdc.stdlib : exit;
import os.setjmp;
import ddcput;

version (Posix):
extern (C):

import core.sys.posix.signal;

public void seh_init() {
	signal(SIGSEGV, &_except_handler);
}

private:

nothrow @nogc @system
void _except_handler(int s) {
	printf("Got SIGSEGV (%d), exiting", s);
	exit(s);
}
