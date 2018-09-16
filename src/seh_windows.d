module seh_windows;

import core.stdc.stdio : printf;
import ddcputester : putchar;

extern (C)
public void seh_init() {
	SetUnhandledExceptionFilter(cast(void*)&_except_handler);
}

private:

enum WOW64_SIZE_OF_80387_REGISTERS = 80;
enum EXCEPTION_CONTINUE_SEARCH = 0; // Shows dialog
enum EXCEPTION_EXECUTE_HANDLER = 1; // does not
enum WOW64_MAXIMUM_SUPPORTED_EXTENSION = 512;
enum EXCEPTION_MAXIMUM_PARAMETERS = 15; // valid in 8.1 .. 10.0.17134.0

alias uint EXCEPTION_DISPOSITION;
alias uint DWORD;
alias ushort WORD;
alias ulong DWORD64;
alias void* PVOID;
alias ubyte BYTE;
alias _CONTEXT* PCONTEXT;
alias _EXCEPTION_RECORD* PEXCEPTION_RECORD;

alias void* LPTOP_LEVEL_EXCEPTION_FILTER;

extern (Windows) LPTOP_LEVEL_EXCEPTION_FILTER
SetUnhandledExceptionFilter(LPTOP_LEVEL_EXCEPTION_FILTER);

extern (Windows)
uint _except_handler(_EXCEPTION_POINTERS* e) {
	version (Win32) {
		printf(
			"\n***** EXCEPTION\n" ~
			"Address: %X\n" ~
			"Code: %X\n\n" ~
			"EIP=%08X  EFLAG=%08X\n" ~
			"EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X\n" ~
			"EDI=%08X  ESI=%08X  EBP=%08X  ESP=%08X\n" ~
			"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  DS=%04X\n",
			e.ExceptionRecord.ExceptionAddress,
			e.ExceptionRecord.ExceptionCode,
			e.ContextRecord.Eip, e.ContextRecord.EFlags,
			e.ContextRecord.Eax, e.ContextRecord.Ebx,
			e.ContextRecord.Ecx, e.ContextRecord.Edx,
			e.ContextRecord.Edi, e.ContextRecord.Esi,
			e.ContextRecord.Ebp, e.ContextRecord.Esp,
			e.ContextRecord.SegCs, e.ContextRecord.SegDs, e.ContextRecord.SegEs,
			e.ContextRecord.SegFs, e.ContextRecord.SegGs, e.ContextRecord.SegSs
		);
	} else { // Win64
		printf(
			"\n***** EXCEPTION\n" ~
			"Address: %llX\n" ~
			"Code: %X\n\n" ~
			"RIP=%016llX  EFLAG=%08X\n" ~
			"RAX=%016llX  RBX=%016llX  RCX=%016llX  RDX=%016llX\n" ~
			"RDI=%016llX  RSI=%016llX  RBP=%016llX  RSP=%016llX\n" ~
			"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  DS=%04X\n",
			e.ExceptionRecord.ExceptionAddress,
			e.ExceptionRecord.ExceptionCode,
			e.ContextRecord.Rip, e.ContextRecord.EFlags,
			e.ContextRecord.Rax, e.ContextRecord.Rbx,
			e.ContextRecord.Rcx, e.ContextRecord.Rdx,
			e.ContextRecord.Rdi, e.ContextRecord.Rsi,
			e.ContextRecord.Rbp, e.ContextRecord.Rsp,
			e.ContextRecord.SegCs, e.ContextRecord.SegDs, e.ContextRecord.SegEs,
			e.ContextRecord.SegFs, e.ContextRecord.SegGs, e.ContextRecord.SegSs
		);
	}
	return EXCEPTION_EXECUTE_HANDLER;
}

struct _EXCEPTION_POINTERS {
	PEXCEPTION_RECORD ExceptionRecord;
	PCONTEXT          ContextRecord;
}

struct _EXCEPTION_RECORD {
	DWORD ExceptionCode;
	DWORD ExceptionFlags;
	_EXCEPTION_RECORD* ExceptionRecord;
	PVOID ExceptionAddress;
	DWORD NumberParameters;
	DWORD[EXCEPTION_MAXIMUM_PARAMETERS] ExceptionInformation;
}

version (Win32) {
	struct _WOW64_FLOATING_SAVE_AREA {
		DWORD ControlWord;
		DWORD StatusWord;
		DWORD TagWord;
		DWORD ErrorOffset;
		DWORD ErrorSelector;
		DWORD DataOffset;
		DWORD DataSelector;
		BYTE[WOW64_SIZE_OF_80387_REGISTERS]  RegisterArea;
		DWORD Cr0NpxState;
	}
	/// Win32 _CONTEXT
	struct _CONTEXT {
		DWORD ContextFlags;
		//
		// Debug registers
		//
		DWORD Dr0;
		DWORD Dr1;
		DWORD Dr2;
		DWORD Dr3;
		DWORD Dr6;
		DWORD Dr7;
		//
		// Float
		//
		_WOW64_FLOATING_SAVE_AREA FloatSave;
		//
		// Segments
		//
		DWORD SegGs;
		DWORD SegFs;
		DWORD SegEs;
		DWORD SegDs;
		//
		// General registers
		//
		DWORD Edi;
		DWORD Esi;
		DWORD Ebx;
		DWORD Edx;
		DWORD Ecx;
		DWORD Eax;
		DWORD Ebp;
		DWORD Eip;
		DWORD SegCs; // segment
		//
		// Flags
		//
		DWORD EFlags;
		DWORD Esp; // generic
		DWORD SegSs; // segment
		BYTE[WOW64_MAXIMUM_SUPPORTED_EXTENSION] ExtendedRegisters;
	}
} else { // Win64
	struct _XSAVE_FORMAT { align(16):
		WORD   ControlWord;
		WORD   StatusWord;
		BYTE  TagWord;
		BYTE  Reserved1;
		WORD   ErrorOpcode;
		DWORD ErrorOffset;
		WORD   ErrorSelector;
		WORD   Reserved2;
		DWORD DataOffset;
		WORD   DataSelector;
		WORD   Reserved3;
		DWORD MxCsr;
		DWORD MxCsr_Mask;
		M128A[8] FloatRegisters;

		version (Win64) {
			M128A[16] XmmRegisters;
			BYTE[96]  Reserved4;
		} else {
			M128A[8]  XmmRegisters;
			BYTE[224] Reserved4;
		}
	}
	/// Win64 _CONTEXT
	struct _CONTEXT { // DECLSPEC_ALIGN(16) is a lie
		//
		// Register parameter home addresses.
		//
		// N.B. These fields are for convience - they could be used to extend the
		//      context record in the future.
		//
		DWORD64 P1Home;
		DWORD64 P2Home;
		DWORD64 P3Home;
		DWORD64 P4Home;
		DWORD64 P5Home;
		DWORD64 P6Home;
		//
		// Control flags.
		//
		DWORD ContextFlags;
		DWORD MxCsr;
		//
		// Segment Registers and processor flags.
		//
		WORD   SegCs;
		WORD   SegDs;
		WORD   SegEs;
		WORD   SegFs;
		WORD   SegGs;
		WORD   SegSs;
		DWORD EFlags;
		//
		// Debug registers
		//
		DWORD64 Dr0;
		DWORD64 Dr1;
		DWORD64 Dr2;
		DWORD64 Dr3;
		DWORD64 Dr6;
		DWORD64 Dr7;
		//
		// Integer registers.
		//
		DWORD64 Rax;
		DWORD64 Rcx;
		DWORD64 Rdx;
		DWORD64 Rbx;
		DWORD64 Rsp;
		DWORD64 Rbp;
		DWORD64 Rsi;
		DWORD64 Rdi;
		DWORD64 R8;
		DWORD64 R9;
		DWORD64 R10;
		DWORD64 R11;
		DWORD64 R12;
		DWORD64 R13;
		DWORD64 R14;
		DWORD64 R15;
		//
		// Program counter.
		//
		DWORD64 Rip;
		//
		// Floating point state.
		//
		union {
			_XSAVE_FORMAT FltSave;
			struct {
				M128A[2] Header;
				M128A[8] Legacy;
				M128A Xmm0;
				M128A Xmm1;
				M128A Xmm2;
				M128A Xmm3;
				M128A Xmm4;
				M128A Xmm5;
				M128A Xmm6;
				M128A Xmm7;
				M128A Xmm8;
				M128A Xmm9;
				M128A Xmm10;
				M128A Xmm11;
				M128A Xmm12;
				M128A Xmm13;
				M128A Xmm14;
				M128A Xmm15;
			}
		}
		//
		// Vector registers.
		//
		M128A[26] VectorRegister;
		DWORD64 VectorControl;
		//
		// Special debug control registers.
		//
		DWORD64 DebugControl;
		DWORD64 LastBranchToRip;
		DWORD64 LastBranchFromRip;
		DWORD64 LastExceptionToRip;
		DWORD64 LastExceptionFromRip;
	}
}

struct M128A { align(1):
	ulong low; 	ulong high;
}