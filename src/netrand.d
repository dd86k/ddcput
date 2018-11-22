/*
 * Random module. Adapted from and based on .NET's Random class.
 */

module netrand;

import os_utils : os_tick;

private enum int MSEED = 161803398;
private enum int MBIG = int.max;

private ulong inc = void;
private ulong state = void;
private int inext = void;
private int inextp = void;
private int [56]seedarr = void;
private int MZ;

extern (C):

void rinit(uint seed = os_tick) {
	MZ = 0;

	int ii;
	int mj, mk;

	mj = MSEED - seed;
	seedarr[55] = mj;
	mk = 1;
	for (int i = 1; i < 55; ++i) {
		ii = (21 * i) % 55;
		seedarr[ii] = mk;
		mk = mj - mk;
		if (mk < 0)
			mk += MBIG;
		mj = seedarr[ii];
	}
	for (int k = 1; k < 5; ++k) {
		for (int i = 1; i < 56; ++i) {
			seedarr[i] -= seedarr[1 + (i + 30) % 55];
			if (seedarr[i] < 0)
				seedarr[i] += MBIG;
		}
	}
	inext = 0;
	inextp = 21;
	seed = 1;
}

ubyte rnextb() {
	return cast(ubyte)(rsample * 256);
}

float rsample() {
	return (rsamplei * (1.0f / MBIG));
}

int rsamplei() {
	int r = void;
	int i = inext;
	int ip = inextp;

	if (++i >=56) i = 1;
	if (++ip >= 56) ip = 1;

	r = seedarr[i] - seedarr[ip];

	if (r == MBIG) --r;          
	if (r < 0) r += MBIG;

	seedarr[i] = r;

	inext = i;
	inextp = ip;

	return r;
}

unittest {
	import std.stdio;
	rinit;
	uint i = 8;
	writeln("-- rnextb");
	while (--i)
		writefln("%02X ", rnextb);
	i = 8;
	while (--i)
		writefln("%08X ", rsamplei);
}