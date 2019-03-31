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

int setjmp(jmp_buf*);
void longjmp(jmp_buf*, int);

//alias jmp_buf[_JBLEN] _JBTYPE;

__gshared jmp_buf *jmpcpy; /// jmp_buf copy for seh

version (X86) {
	version (Windows) {
		enum _JBLEN = 16;
		alias int _JBTYPE;
		struct __JUMP_BUFFER {
			uint Ebp;
			uint Ebx;
			uint Edi;
			uint Esi;
			uint Esp;
			uint Eip;
			uint Registration;
			uint TryLevel;
			uint Cookie;
			uint UnwindFunc;
			uint [6]UnwindData;
		}

		public alias __JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf {
			uint ebx;
			uint esi;
			uint edi;
			uint ebp;
			uint esp;
			uint eip;
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
			ulong Frame;
			ulong Rbx;
			ulong Rsp;
			ulong Rbp;
			ulong Rsi;
			ulong Rdi;
			ulong R12;
			ulong R13;
			ulong R14;
			ulong R15;
			ulong Rip;
			uint MxCsr;
			ushort FpCsr;
			ushort Spare;

			_SETJMP_FLOAT128 Xmm6;
			_SETJMP_FLOAT128 Xmm7;
			_SETJMP_FLOAT128 Xmm8;
			_SETJMP_FLOAT128 Xmm9;
			_SETJMP_FLOAT128 Xmm10;
			_SETJMP_FLOAT128 Xmm11;
			_SETJMP_FLOAT128 Xmm12;
			_SETJMP_FLOAT128 Xmm13;
			_SETJMP_FLOAT128 Xmm14;
			_SETJMP_FLOAT128 Xmm15;
		}

		public alias _JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf {
			ulong rbx;
			ulong rbp;
			ulong r12, r13, r14, r15;
			ulong rsp;
			ulong rip;
		}

		public alias __jmp_buf jmp_buf;
	}
} else
version (ARM) {
	version (Windows) { // AArch32
		enum _JBLEN = 28;
		alias int _JBTYPE;

		struct _JUMP_BUFFER {
			uint Frame;
			uint R4;
			uint R5;
			uint R6;
			uint R7;
			uint R8;
			uint R9;
			uint R10;
			uint R11;
			uint Sp;
			uint Pc;
			uint Fpscr;
			ulong [8]D; // D8-D15 VFP/NEON regs
		}

		alias _JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf { // assumed from aarch64
			uint x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29;
			uint lr, sp;
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
			ulong Frame;
			ulong Reserved;
			ulong X19;   // x19 -- x28: callee saved registers
			ulong X20;
			ulong X21;
			ulong X22;
			ulong X23;
			ulong X24;
			ulong X25;
			ulong X26;
			ulong X27;
			ulong X28;
			ulong Fp;    // x29 frame pointer
			ulong Lr;    // x30 link register
			ulong Sp;    // x31 stack pointer
			uint Fpcr;  // fp control register
			uint Fpsr;  // fp status register

			double [8]D; // D8-D15 FP regs
		}

		alias _JUMP_BUFFER jmp_buf;
	} else
	version (CRuntime_Glibc) {
		struct __jmp_buf {
			ulong x19, x20, x21, x22, x23, x24, x25, x26, x27, x28, x29;
			ulong lr, sp;
			double d8, d9, d10, d11, d12, d13, d14, d15;
		}

		alias __jmp_buf jmp_buf;
	}
}