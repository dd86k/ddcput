/**
 * Memory Manager
 */
module mm;

import core.stdc.stdio;

version (Windows) {
	import core.sys.windows.winbase :
		VirtualAlloc, VirtualProtect, VirtualFree, VirtualLock;
	import core.sys.windows.winnt :
		MEM_RESERVE, MEM_COMMIT, MEM_RELEASE,
		PAGE_READWRITE, PAGE_EXECUTE, PAGE_EXECUTE_READ, PAGE_EXECUTE_READWRITE;
}
version (Posix) {
	import core.sys.posix.sys.mman :
		mmap, mprotect, munmap,
		PROT_READ, PROT_WRITE, PROT_EXEC, MAP_ANON, MAP_PRIVATE;
}

extern (C):

// Page sizes may vary between 4K, 2M, 4M, and 1G
// (Windows) Normally check with GetSystemInfo->_SYSTEM_INFO.dwPageSize
// (Posix) Normally check with sysconf(_POSIX_FOO) then
// sysconf(_SC_PAGESIZE/PAGESIZE) to get pagesize in bytes
// 
//TODO: Get page sizes
enum PAGE_SIZE = 4096u;	/// Minimum page size
enum NULL = cast(void*)0; /// Alias to (void*)0

/// Memory block
struct page_t { align(1):
	ubyte[PAGE_SIZE - size_t.sizeof] code; /// Memory block data
	size_t size; /// Memory block size, should be PAGE_SIZE
}
static assert(page_t.sizeof == PAGE_SIZE, "page_t.sizeof != PAGE_SIZE");

/// Free-to-use global pointer for exec memory block
__gshared page_t *mainpage = void;

/**
 * Create a read/write memory block of PAGE_SIZE
 * (Windows) Calls VirtualAlloc with MEM_RESERVE | MEM_COMMIT
 * (Posix) Calls mmap with PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE
 * Returns: A __membuf_s pointer to the memory block
 */
page_t *mm_create() {
version (Windows)
	return cast(page_t*)VirtualAlloc(
		NULL, page_t.sizeof, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE
	);
version (Posix)
	return cast(page_t*)mmap(
		NULL, page_t.sizeof, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0
	);
}

/**
 * Protect a memory block as readable and executable.
 * (Windows) Calls VirtualProtect with PAGE_EXECUTE_READ
 * (Posix) Calls mprotect with PROT_READ | PROT_EXEC
 * Params: s = Memory block to protect
 */
void mm_protect(page_t *s) {
version (Windows) {
	uint e = void;
	VirtualProtect(s, page_t.sizeof, PAGE_EXECUTE_READ, &e);
}
version (Posix)
	mprotect(s, page_t.sizeof, PROT_READ | PROT_EXEC);
}

/**
 * Un-protect a memory block, making the memory block readable and writable.
 * (Windows) Calls VirtualProtect with PAGE_READWRITE
 * (Posix) Calls mprotect with PROT_READ | PROT_WRITE
 * Params: s = Memory block to unprotect
 */
void mm_unprotect(page_t *s) {
version (Windows) {
	uint e = void;
	VirtualProtect(s, page_t.sizeof, PAGE_READWRITE, &e);
}
version (Posix)
	mprotect(s, page_t.sizeof, PROT_READ | PROT_WRITE);
}

/**
 * Free a memory block
 * (Windows) Calls VirtualFree with MEM_RELEASE
 * (Posix) Calls munmap
 * Params: s = Memory block to free
 */
void mm_free(page_t *s) {
version (Windows) {
	VirtualFree(s, 0, MEM_RELEASE);
}
version (Posix)
	munmap(s, PAGE_SIZE);
}