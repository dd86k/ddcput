BITS 32

pre_test:
dec edi
jnz near pre_test
; -- Test finished at this point --
rdtsc
mov [esi + 8], eax	; __TEST_SETTINGS.ts2_l
mov [esi + 12], edx	; __TEST_SETTINGS.ts2_h
ret