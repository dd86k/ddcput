/**
 * Show as many registers possible
 */
module modes.registers;

import core.stdc.stdio;

extern (C):

version (Windows)
	enum LONG_S = "%016llX";
else
	enum LONG_S = "%016lX";

/// 80-bit type
struct st_t { align(1):
	version (X86) uint low, high;
	version (X86_64) ulong low;
	ushort com;
}
static assert(st_t.sizeof == 10);

version (X86) {
	struct fsave_t { align(1): // 32-bit protected mode format
		ushort control, pad0, status, pad1, tag, pad2;
		uint fipo; // FPU Instruction Pointer Offset (FIP)
		ushort fips; // FPU Instruction Pointer Selector
		ushort op; // bits 10:0 of opcode
		uint fdp; // FPU Data Pointer Offset (FDP)
		ushort fds, pad3; // FPU Data Pointer Selector (FDS)
		st_t [8]r;
	}
	static assert(fsave_t.sizeof == 108); // 32-bit protected mode format
	struct fxsave_t { // if supported!
	
	}
} else
version (X86_64) {
	
}

int show_registers() {
	version (X86) {
		struct regs {
			uint eax, ebx, ecx, edx, ebp, esp, edi, esi;
			ushort cs, ds, es, fs, gs, ss;
			//uint cr0, cr2, cr3, cr4;
			//uint dr0, dr1, dr2, dr3, dr6, dr7;
			//uint tr3, tr4, tr5, tr6, tr7;
		}
		regs r = void; // stack
		fsave_t f = void;
		asm {
			mov [r + regs.eax.offsetof], EAX;
			mov [r + regs.ebx.offsetof], EBX;
			mov [r + regs.ecx.offsetof], ECX;
			mov [r + regs.edx.offsetof], EDX;
			mov [r + regs.ebp.offsetof], EBP;
			mov [r + regs.esp.offsetof], ESP;
			mov [r + regs.edi.offsetof], EDI;
			mov [r + regs.esi.offsetof], ESI;
			mov [r + regs.cs.offsetof], CS;
			mov [r + regs.ds.offsetof], DS;
			mov [r + regs.es.offsetof], ES;
			mov [r + regs.fs.offsetof], FS;
			mov [r + regs.gs.offsetof], GS;
			mov [r + regs.ss.offsetof], SS;
			//TODO: Check for CPL=0 before reading these
			//mov EAX, CR0; mov [r + regs.cr0.offsetof], EAX;
			//mov EAX, CR2; mov [r + regs.cr2.offsetof], EAX;
			//mov EAX, CR3; mov [r + regs.cr3.offsetof], EAX;
			//mov EAX, CR4; mov [r + regs.cr4.offsetof], EAX;
			//mov EAX, DR0; mov [r + regs.dr0.offsetof], EAX;
			//mov EAX, DR1; mov [r + regs.dr1.offsetof], EAX;
			//mov EAX, DR2; mov [r + regs.dr2.offsetof], EAX;
			//mov EAX, DR3; mov [r + regs.dr3.offsetof], EAX;
			//mov EAX, DR6; mov [r + regs.dr6.offsetof], EAX;
			//mov EAX, DR7; mov [r + regs.dr7.offsetof], EAX;
			//mov EAX, TR3; mov [r + regs.tr3.offsetof], EAX;
			//mov EAX, TR4; mov [r + regs.tr4.offsetof], EAX;
			//mov EAX, TR5; mov [r + regs.tr5.offsetof], EAX;
			//mov EAX, TR6; mov [r + regs.tr6.offsetof], EAX;
			//mov EAX, TR7; mov [r + regs.tr7.offsetof], EAX;
			fsave [f];
			//TODO: Use FXSAVE if supported!
		}
		printf(
			"* General\n"~
			"EAX=%08X  EBX=%08X  ECX=%08X  EDX=%08X\n"~
			"EBP=%08X  ESP=%08X  EDI=%08X  ESI=%08X\n"~
			"CS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X  SS=%04X\n"~
			"\n"~
			"* FPU\n"~
			"C=%04X  S=%04X  T=%04X  op=%04X\n"~
			"FIPo=%08X  FIPs=%08X  FDP=%08X  FDS=%04X\n"~
			"R0=%04X%08X%08X  R1=%04X%08X%08X\n"~
			"R2=%04X%08X%08X  R3=%04X%08X%08X\n"~
			"R4=%04X%08X%08X  R5=%04X%08X%08X\n"~
			"R6=%04X%08X%08X  R7=%04X%08X%08X\n",
			r.eax, r.ebx, r.ecx, r.edx,
			r.ebp, r.esp, r.edi, r.esi,
			r.cs, r.ds, r.es, r.fs, r.gs, r.ss,
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
	
	return 0;
}