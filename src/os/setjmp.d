/**
 * setjmp.h wrapper to use alongside the C runtime
 *
 * This brings back the setjmp wrapper that D once had at std.c.setjmp, which
 * should of been at core.stdc.setjmp by now, but is nowhere to be found.
 * 
 * Windows reference:
 * "[Visual Studio Path]\VC\Tools\MSVC\14.15.26726\include\setjmp.h"
 * Glibc reference:
 * sysdeps/i386/jmpbuf-offsets.h
 * sysdeps/x86_64/jmpbuf-offsets.h
 * sysdeps/aarch64/jmpbuf-offsets.h
 */
module os.setjmp;

extern (C):

/**
 * Save a jump point for a long jump.
 * Params:
 *   e = Jump environment (jmp_buf structure)
 * Returns: Usually returns 0 for the first call. When longjmp is called,
 *          this function returns the second value passed to longjmp.
 */
int setjmp(jmp_buf *e);
/**
 * Performs a long jump from the saved jump point.
 * Params:
 *   e = Jump environment (jmp_buf structure)
 *   s = Pass value to setjmp
 */
void longjmp(jmp_buf *e, int s) @nogc nothrow;

__gshared jmp_buf *jmpcpy; /// jmp_buf copy for seh

//alias jmp_buf[_JBLEN] _JBTYPE;

version (X86) {
	version (Windows) {
		enum _JBLEN = 16;
		alias int _JBTYPE;
		struct __JUMP_BUFFER {
			uint Ebp, Ebx, Edi, Esi, Esp, Eip, Registration,
				TryLevel, Cookie, UnwindFunc;
			uint [6]UnwindData;
		}

		public alias __JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf {
			uint ebx, esi, edi, ebp, esp, eip;
		}

		public alias __jmp_buf jmp_buf;
	}
} else
version (X86_64) {
	version (Windows) {
		struct _SETJMP_FLOAT128 { align(16):
			ulong [2]Part;
		}

		enum _JBLEN = 16;
		alias _SETJMP_FLOAT128 _JBTYPE;

		struct _JUMP_BUFFER {
			ulong Frame, Rbx, Rsp, Rbp, Rsi, Rdi,
				R12, R13, R14, R15, Rip;
			uint MxCsr;
			ushort FpCsr;
			ushort Spare;

			_SETJMP_FLOAT128 Xmm6, Xmm7, Xmm8, Xmm9, Xmm10,
				Xmm11, Xmm12, Xmm13, Xmm14, Xmm15;
		}

		public alias _JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf {
			ulong rbx, rbp, r12, r13, r14, r15, rsp, rip;
		}

		public alias __jmp_buf jmp_buf;
	}
} else
version (ARM) {
	version (Windows) { // AArch32
		enum _JBLEN = 28;
		alias int _JBTYPE;

		struct _JUMP_BUFFER {
			uint Frame, R4, R5, R6, R7, R8, R9, R10, R11,
				Sp, Pc, Fpscr;
			ulong [8]D; // D8-D15 VFP/NEON regs
		}

		alias _JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf { // assumed from aarch64
			uint x19, x20, x21, x22, x23, x24, x25, x26,
				x27, x28, x29, lr, sp;
			float d8, d9, d10, d11, d12, d13, d14, d15;
		}

		alias __jmp_buf jmp_buf;
	}
} else
version (AArch64) {
	version (Windows) {
		enum _JBLEN = 24;
		alias ulong _JBTYPE;

		struct _JUMP_BUFFER {
			// x19 -- x28: callee saved registers
			// x29 frame pointer
			// x30 link register
			// x31 stack pointer
			ulong Frame, Reserved, X19, X20, X21, X22, X23, X24,
				X25, X26, X27, X28, Fp, Lr, Sp;    
			uint Fpcr;  // fp control register
			uint Fpsr;  // fp status register

			double [8]D; // D8-D15 FP regs
		}

		alias _JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf {
			ulong x19, x20, x21, x22, x23, x24, x25, x26,
				x27, x28, x29, lr, sp;
			double d8, d9, d10, d11, d12, d13, d14, d15;
		}

		alias __jmp_buf jmp_buf;
	}
}