BITS 32

mov esi, [esp + 4]	; __TEST_SETTINGS Structure
mov edi, [esi + 16]	; __TEST_SETTINGS.runs
rdtsc
mov [esi], eax	; __TEST_SETTINGS.ts1_l
mov [esi + 4], edx	; __TEST_SETTINGS.ts1_h
; -- test should be here --