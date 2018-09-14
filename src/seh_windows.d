module seh_windows;

import core.stdc.stdio : printf;
import ddcputester : putchar;

extern (C)
public void seh_init() {
	SetUnhandledExceptionFilter(cast(void*)&_except_handler);
}

private:

enum SIZE_OF_80387_REGISTERS = 80;
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
			e.ContextRecord.SegFs, e.ContextRecord.SegGs, e.ContextRecord.SegSs,
		);
	} else { // Win64
		static assert(0, "Win64 UnhandledExceptionFilter");
	}
	return EXCEPTION_EXECUTE_HANDLER;
}

struct _EXCEPTION_POINTERS {
	PEXCEPTION_RECORD ExceptionRecord;
	PCONTEXT          ContextRecord;
}

struct _EXCEPTION_RECORD { align(1):
	DWORD ExceptionCode;
	DWORD ExceptionFlags;
	_EXCEPTION_RECORD* ExceptionRecord;
	PVOID ExceptionAddress;
	DWORD NumberParameters;
	DWORD[EXCEPTION_MAXIMUM_PARAMETERS] ExceptionInformation;
}

version (Win32)
	/// Win32 _CONTEXT
	struct _CONTEXT {
		DWORD ContextFlags;
		DWORD Dr0;
		DWORD Dr1;
		DWORD Dr2;
		DWORD Dr3;
		DWORD Dr6;
		DWORD Dr7;
		_FLOATING_SAVE_AREA FloatSave;
		DWORD SegGs;
		DWORD SegFs;
		DWORD SegEs;
		DWORD SegDs;
		DWORD Edi;
		DWORD Esi;
		DWORD Ebx;
		DWORD Edx;
		DWORD Ecx;
		DWORD Eax;
		DWORD Ebp;
		DWORD Eip;
		DWORD SegCs;
		DWORD EFlags;
		DWORD Esp;
		DWORD SegSs;
		BYTE[WOW64_MAXIMUM_SUPPORTED_EXTENSION] ExtendedRegisters;
	}
else // Win64
	/// Win64 _CONTEXT
	struct _CONTEXT { align(16): // DECLSPEC_ALIGN(16)
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
			XMM_SAVE_AREA32 FltSave;
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

struct M128A { align(1):
	ulong low;
	ulong high;
}

struct _FLOATING_SAVE_AREA {
    DWORD   ControlWord;
    DWORD   StatusWord;
    DWORD   TagWord;
    DWORD   ErrorOffset;
    DWORD   ErrorSelector;
    DWORD   DataOffset;
    DWORD   DataSelector;
    BYTE[SIZE_OF_80387_REGISTERS]    RegisterArea;
    DWORD   Spare0;
}