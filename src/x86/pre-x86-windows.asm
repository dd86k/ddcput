BITS 32

mov ecx, [esp + 4]	; __TEST_SETTINGS Structure
mov [ecx + 20], edi	; Save EDI and ESI
mov [ecx + 24], esi
mov esi, ecx	; Safe to use ESI for now
mov edi, [esi + 16]	; __TEST_SETTINGS.runs
rdtsc
mov [esi], eax	; __TEST_SETTINGS.ts1_l
mov [esi + 4], edx	; __TEST_SETTINGS.ts1_h
; -- test should be here --