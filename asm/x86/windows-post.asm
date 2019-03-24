BITS 32

pre_test:
dec edi
jnz near pre_test
; -- Test finished at this point --
rdtsc
mov [esi + 8], eax	; __TEST_SETTINGS.ts2_l
mov [esi + 12], edx	; __TEST_SETTINGS.ts2_h
mov ecx, esi	; Safer to use ECX while restoring EDI and ESI
mov edi, [ecx + 20]	; Restore EDI
mov esi, [ecx + 24]	; Restore ESI
ret