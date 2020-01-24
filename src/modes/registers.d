/**
 * Show as many registers possible
 */
module modes.registers;

import core.stdc.stdio;
import core.stdc.inttypes : PRIX64;
import misc;

extern (C):

version (Windows)
	enum X16 = "%016llX";
else
	enum X16 = "%016lX";

enum CPUID_FXSR = BIT!(24);

/// 80-bit "real" type
struct st_t { align(1):
	uint low, high;
	ushort com;
}
static assert(st_t.sizeof == 10);

/// 128-bit "ubyte[16]" type
struct xmm_t { align(1):
	union {
		ubyte [16]data;
		version (X86) uint [4]u32;
		version (X86_64) ulong [2]u64;
	}
}
static assert(xmm_t.sizeof == 16);

version (X86) {
	struct regs_t {
		uint eax, ebx, ecx, edx, ebp, esp, edi, esi;
		uint eflag, eip;
		ushort cs, ds, es, fs, gs, ss;
		uint cr0, cr2, cr3, cr4;
		uint dr0, dr1, dr2, dr3, dr6, dr7;
		uint tr3, tr4, tr5, tr6, tr7;
		ubyte s_regs;	/// Has Access to Special Registers (e.g. CR0)
		ubyte s_fxsr;	/// FXSAVE has been used
	}
	struct fsave_t { align(1): // 64-bit format
		ushort control, pad0, status, pad1, tag, pad2;
		uint fipo;	/// FPU Instruction Pointer Offset (FIP)
		ushort fips;	/// FPU Instruction Pointer Selector
		ushort op;	/// Bits 10:0 of opcode
		uint fdp;	/// FPU Data Pointer Offset (FDP)
		ushort fds, pad3;	/// FPU Data Pointer Selector (FDS)
		st_t [8]r;	// Guessing
	}
	static assert(fsave_t.sizeof == 108); // 32-bit protected mode format
	struct fxsave_t { align(1): // If supported via CPUID.01h.EDX[24]
		ushort fcw, fsw;
		ubyte ftw, pad0;
		ushort fop;
		uint fip;
		ushort fcs, pad1;
		uint fdp;
		ushort fds, pad2;
		uint mxcsr, mxcsr_mask;
		st_t mm0; ubyte [6]pad3;
		st_t mm1; ubyte [6]pad4;
		st_t mm2; ubyte [6]pad5;
		st_t mm3; ubyte [6]pad6;
		st_t mm4; ubyte [6]pad7;
		st_t mm5; ubyte [6]pad8;
		st_t mm6; ubyte [6]pad9;
		st_t mm7; ubyte [6]pad10;
		xmm_t [16]xmm;
		ubyte [96]pad;
	}
	static assert(fxsave_t.sizeof == 512);
} else
version (X86_64) {
	struct regs_t {
		ulong rax, rbx, rcx, rdx, rbp, rsp, rdi, rsi;
		ulong rflag, rip;
		ushort cs, ds, es, fs, gs, ss;
		uint cr0, cr2, cr3, cr4;
		uint dr0, dr1, dr2, dr3, dr6, dr7;
		uint tr3, tr4, tr5, tr6, tr7;
		ubyte s_regs; /// Has Access to Special Registers (e.g. CR0)
		ubyte s_fxsr; /// FXSAVE has been used
	}
	struct fsave_t { align(1): // 64-bit format
		ushort control, pad0, status, pad1, tag, pad2;
		uint fipo; /// FPU Instruction Pointer Offset (FIP)
		ushort fips; /// FPU Instruction Pointer Selector
		ushort op; /// Bits 10:0 of opcode
		uint fdp; /// FPU Data Pointer Offset (FDP)
		ushort fds, pad3; // FPU Data Pointer Selector (FDS)
		st_t [8]r; // Guessing
	}
	static assert(fsave_t.sizeof == 108); // 32-bit protected mode format
	struct fxsave_t { align(1): // If supported via CPUID.01h.EDX[24]
		ushort fcw, fsw;
		ubyte ftw, pad0;
		ushort fop;
		uint fip;
		ushort fcs, pad1;
		uint fdp;
		ushort fds, pad2;
		uint mxcsr, mxcsr_mask;
		st_t mm0; ubyte [6]pad3;
		st_t mm1; ubyte [6]pad4;
		st_t mm2; ubyte [6]pad5;
		st_t mm3; ubyte [6]pad6;
		st_t mm4; ubyte [6]pad7;
		st_t mm5; ubyte [6]pad8;
		st_t mm6; ubyte [6]pad9;
		st_t mm7; ubyte [6]pad10;
		xmm_t [16]xmm;
		ubyte [96]pad;
	}
	static assert(fxsave_t.sizeof == 512);
}

int registers_run() {
	version (X86) {
		regs_t r = void; // stack
		fsave_t f = void;
		fxsave_t fx = void;
		asm {
			mov [r + regs_t.eax.offsetof], EAX;
			mov [r + regs_t.ebx.offsetof], EBX;
			mov [r + regs_t.ecx.offsetof], ECX;
			mov [r + regs_t.edx.offsetof], EDX;
			mov [r + regs_t.ebp.offsetof], EBP;
			mov [r + regs_t.esp.offsetof], ESP;
			mov [r + regs_t.edi.offsetof], EDI;
			mov [r + regs_t.esi.offsetof], ESI;
			mov [r + regs_t.cs.offsetof], CS;
			mov [r + regs_t.ds.offsetof], DS;
			mov [r + regs_t.es.offsetof], ES;
			mov [r + regs_t.fs.offsetof], FS;
			mov [r + regs_t.gs.offsetof], GS;
			mov [r + regs_t.ss.offsetof], SS;
			pushfd;
			pop [r + regs_t.eflag.offsetof]; // Save EFLAG
			mov byte ptr [r + regs_t.s_regs.offsetof], 0; // so far, no access
			mov AX, CS; // Hopefully loaded CS[1:0] with CPL
			test AX, 3; // Check CPL
			jnz NO_SPEC_REGS; // Jump if CPL != 0
			mov byte ptr [r + regs_t.s_regs.offsetof], 1; // has access!
			mov EAX, CR0; mov [r + regs_t.cr0.offsetof], EAX;
			mov EAX, CR2; mov [r + regs_t.cr2.offsetof], EAX;
			mov EAX, CR3; mov [r + regs_t.cr3.offsetof], EAX;
			mov EAX, CR4; mov [r + regs_t.cr4.offsetof], EAX;
			mov EAX, DR0; mov [r + regs_t.dr0.offsetof], EAX;
			mov EAX, DR1; mov [r + regs_t.dr1.offsetof], EAX;
			mov EAX, DR2; mov [r + regs_t.dr2.offsetof], EAX;
			mov EAX, DR3; mov [r + regs_t.dr3.offsetof], EAX;
			mov EAX, DR6; mov [r + regs_t.dr6.offsetof], EAX;
			mov EAX, DR7; mov [r + regs_t.dr7.offsetof], EAX;
			mov EAX, TR3; mov [r + regs_t.tr3.offsetof], EAX;
			mov EAX, TR4; mov [r + regs_t.tr4.offsetof], EAX;
			mov EAX, TR5; mov [r + regs_t.tr5.offsetof], EAX;
			mov EAX, TR6; mov [r + regs_t.tr6.offsetof], EAX;
			mov EAX, TR7; mov [r + regs_t.tr7.offsetof], EAX;
		NO_SPEC_REGS:
		//
		// Check if FXSAVE is supported (Intel/AMD)
		//
			mov EAX, 1;
			cpuid;
			test EDX, CPUID_FXSR;
			jnz HAS_FXSAVE;
			fsave [f];	// -- Use FSAVE
			jmp USED_FSAVE;
		HAS_FXSAVE:
			fxsave [fx];	// -- Use FXSAVE
		USED_FSAVE:
			even;
		}
		printf(
		"* General\n"~
		"EFLAG=%08X\n"~
		"EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X\n"~
		"EBP=%08X  ESP=%08X  EDI=%08X  ESI=%08X\n"~
		"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  SS=%04X\n",
		r.eflag,
		r.eax, r.ebx, r.ecx, r.edx,
		r.ebp, r.esp, r.edi, r.esi,
		r.cs, r.ds, r.es, r.fs, r.gs, r.ss
		);
		if (r.s_regs) { // if special registers were loaded
			printf(
			"CR0=%08X  CR2=%08X  CR3=%08X  CR4=%08X\n"~
			"DR0=%08X  DR1=%08X  DR2=%08X  DR3=%08X\n"~
			"DR6=%08X  DR7=%08X\n"~
			"TR3=%08X  TR4=%08X  TR5=%08X  TR6=%08X\n"~
			"TR7=%08X\n",
			r.cr0, r.cr2, r.cr3, r.cr4,
			r.dr0, r.dr1, r.dr2, r.dr3,
			r.dr6, r.dr7,
			r.tr3, r.tr4, r.tr5, r.tr6,
			r.tr7
			);
		}
		if (r.s_fxsr) { // if FXSAVE has been used
			printf(
			"\n"~
			"* FPU (fxsave)\n"~
			"C=%04X  S=%04X  T=%02X  op=%04X\n"~
			"FIPo=%08X  FIPs=%08X  FDP=%08X  FDS=%04X\n"~
			"R0=%04X%08X%08X  R1=%04X%08X%08X\n"~
			"R2=%04X%08X%08X  R3=%04X%08X%08X\n"~
			"R4=%04X%08X%08X  R5=%04X%08X%08X\n"~
			"R6=%04X%08X%08X  R7=%04X%08X%08X\n",
			fx.fcw, fx.fsw, fx.ftw, fx.fop,
			fx.fip, fx.fcs, fx.fdp, fx.fds,
			fx.mm0.com, fx.mm0.high, fx.mm0.low,
			fx.mm1.com, fx.mm1.high, fx.mm1.low,
			fx.mm2.com, fx.mm2.high, fx.mm2.low,
			fx.mm3.com, fx.mm3.high, fx.mm3.low,
			fx.mm4.com, fx.mm4.high, fx.mm4.low,
			fx.mm5.com, fx.mm5.high, fx.mm5.low,
			fx.mm6.com, fx.mm6.high, fx.mm6.low,
			fx.mm7.com, fx.mm7.high, fx.mm7.low,
			);
		} else {
			printf(
			"\n"~
			"* FPU\n"~
			"C=%04X  S=%04X  T=%04X  op=%04X\n"~
			"FIPo=%08X  FIPs=%08X  FDP=%08X  FDS=%04X\n"~
			"R0=%04X%08X%08X  R1=%04X%08X%08X\n"~
			"R2=%04X%08X%08X  R3=%04X%08X%08X\n"~
			"R4=%04X%08X%08X  R5=%04X%08X%08X\n"~
			"R6=%04X%08X%08X  R7=%04X%08X%08X\n",
			f.control, f.status, f.tag, f.op,
			f.fipo, f.fips, f.fdp, f.fds,
			f.r[0].com, f.r[0].high, f.r[0].low,
			f.r[1].com, f.r[1].high, f.r[1].low,
			f.r[2].com, f.r[2].high, f.r[2].low,
			f.r[3].com, f.r[3].high, f.r[3].low,
			f.r[4].com, f.r[4].high, f.r[4].low,
			f.r[5].com, f.r[5].high, f.r[5].low,
			f.r[6].com, f.r[6].high, f.r[6].low,
			f.r[7].com, f.r[7].high, f.r[7].low,
			);
		}
	} else
	version (X86_64) {
		regs_t r = void; // stack
		fsave_t f = void;
		fxsave_t fx = void;
		asm {
			mov [r + regs_t.rax.offsetof], RAX;
			mov [r + regs_t.rbx.offsetof], RBX;
			mov [r + regs_t.rcx.offsetof], RCX;
			mov [r + regs_t.rdx.offsetof], RDX;
			mov [r + regs_t.rbp.offsetof], RBP;
			mov [r + regs_t.rsp.offsetof], RSP;
			mov [r + regs_t.rdi.offsetof], RDI;
			mov [r + regs_t.rsi.offsetof], RSI;
			mov [r + regs_t.cs.offsetof], CS;
			mov [r + regs_t.ds.offsetof], DS;
			mov [r + regs_t.es.offsetof], ES;
			mov [r + regs_t.fs.offsetof], FS;
			mov [r + regs_t.gs.offsetof], GS;
			mov [r + regs_t.ss.offsetof], SS;
			pushfq;
			pop [r + regs_t.rflag.offsetof]; // Save EFLAG
			mov byte ptr [r + regs_t.s_regs.offsetof], 0; // so far, no access
			mov AX, CS; // Hopefully loaded CS[1:0] with CPL
			test AX, 3; // Check CPL
			jnz NO_SPEC_REGS; // Jump if CPL != 0
			mov byte ptr [r + regs_t.s_regs.offsetof], 1; // has access!
			mov EAX, CR0; mov [r + regs_t.cr0.offsetof], EAX;
			mov EAX, CR2; mov [r + regs_t.cr2.offsetof], EAX;
			mov EAX, CR3; mov [r + regs_t.cr3.offsetof], EAX;
			mov EAX, CR4; mov [r + regs_t.cr4.offsetof], EAX;
			mov EAX, DR0; mov [r + regs_t.dr0.offsetof], EAX;
			mov EAX, DR1; mov [r + regs_t.dr1.offsetof], EAX;
			mov EAX, DR2; mov [r + regs_t.dr2.offsetof], EAX;
			mov EAX, DR3; mov [r + regs_t.dr3.offsetof], EAX;
			mov EAX, DR6; mov [r + regs_t.dr6.offsetof], EAX;
			mov EAX, DR7; mov [r + regs_t.dr7.offsetof], EAX;
			mov EAX, TR3; mov [r + regs_t.tr3.offsetof], EAX;
			mov EAX, TR4; mov [r + regs_t.tr4.offsetof], EAX;
			mov EAX, TR5; mov [r + regs_t.tr5.offsetof], EAX;
			mov EAX, TR6; mov [r + regs_t.tr6.offsetof], EAX;
			mov EAX, TR7; mov [r + regs_t.tr7.offsetof], EAX;
		NO_SPEC_REGS:
		//
		// Check if FXSAVE is supported (Intel/AMD)
		//
			mov EAX, 1;
			cpuid;
			test EDX, CPUID_FXSR;
			jnz HAS_FXSAVE;
			fsave [f];	// -- Use FSAVE
			jmp USED_FSAVE;
		HAS_FXSAVE:
			fxsave [fx];	// -- Use FXSAVE
		USED_FSAVE:
			even;
		}
		printf(
		"* General\n"~
		"RFLAG=%llX\n"~
		"RAX=%016llX  RBX=%016llX\n"~
		"RCX=%016llX  RDX=%016llX\n"~
		"RBP=%016llX  RSP=%016llX\n"~
		"RDI=%016llX  RSI=%016llX\n"~
		"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  SS=%04X\n",
		r.rflag,
		r.rax, r.rbx, r.rcx, r.rdx,
		r.rbp, r.rsp, r.rdi, r.rsi,
		r.cs, r.ds, r.es, r.fs, r.gs, r.ss
		);
		if (r.s_regs) { // if special registers were loaded
			printf(
			"CR0=%08X  CR2=%08X  CR3=%08X  CR4=%08X\n"~
			"DR0=%08X  DR1=%08X  DR2=%08X  DR3=%08X\n"~
			"DR6=%08X  DR7=%08X\n"~
			"TR3=%08X  TR4=%08X  TR5=%08X  TR6=%08X\n"~
			"TR7=%08X\n",
			r.cr0, r.cr2, r.cr3, r.cr4,
			r.dr0, r.dr1, r.dr2, r.dr3,
			r.dr6, r.dr7,
			r.tr3, r.tr4, r.tr5, r.tr6,
			r.tr7
			);
		}
		if (r.s_fxsr) { // if FXSAVE has been used
			printf(
			"\n"~
			"* FPU (fxsave)\n"~
			"C=%04X  S=%04X  T=%02X  op=%04X\n"~
			"FIPo=%08X  FIPs=%08X  FDP=%08X  FDS=%04X\n"~
			"R0=%04X%08X%08X  R1=%04X%08X%08X\n"~
			"R2=%04X%08X%08X  R3=%04X%08X%08X\n"~
			"R4=%04X%08X%08X  R5=%04X%08X%08X\n"~
			"R6=%04X%08X%08X  R7=%04X%08X%08X\n",
			fx.fcw, fx.fsw, fx.ftw, fx.fop,
			fx.fip, fx.fcs, fx.fdp, fx.fds,
			fx.mm0.com, fx.mm0.high, fx.mm0.low,
			fx.mm1.com, fx.mm1.high, fx.mm1.low,
			fx.mm2.com, fx.mm2.high, fx.mm2.low,
			fx.mm3.com, fx.mm3.high, fx.mm3.low,
			fx.mm4.com, fx.mm4.high, fx.mm4.low,
			fx.mm5.com, fx.mm5.high, fx.mm5.low,
			fx.mm6.com, fx.mm6.high, fx.mm6.low,
			fx.mm7.com, fx.mm7.high, fx.mm7.low,
			);
		} else {
			printf(
			"\n"~
			"* FPU\n"~
			"C=%04X  S=%04X  T=%04X  op=%04X\n"~
			"FIPo=%08X  FIPs=%08X  FDP=%08X  FDS=%04X\n"~
			"R0=%04X%08X%08X  R1=%04X%08X%08X\n"~
			"R2=%04X%08X%08X  R3=%04X%08X%08X\n"~
			"R4=%04X%08X%08X  R5=%04X%08X%08X\n"~
			"R6=%04X%08X%08X  R7=%04X%08X%08X\n",
			f.control, f.status, f.tag, f.op,
			f.fipo, f.fips, f.fdp, f.fds,
			f.r[0].com, f.r[0].high, f.r[0].low,
			f.r[1].com, f.r[1].high, f.r[1].low,
			f.r[2].com, f.r[2].high, f.r[2].low,
			f.r[3].com, f.r[3].high, f.r[3].low,
			f.r[4].com, f.r[4].high, f.r[4].low,
			f.r[5].com, f.r[5].high, f.r[5].low,
			f.r[6].com, f.r[6].high, f.r[6].low,
			f.r[7].com, f.r[7].high, f.r[7].low,
			);
		}
	}
	
	return 0;
}