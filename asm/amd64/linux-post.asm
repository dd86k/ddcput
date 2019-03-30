BITS 64

pre_test:
dec edi
jnz near pre_test	; translates to a DWORD
; -- Test finished at this point --
rdtsc
mov [rsi + 8], eax	; __TEST_SETTINGS.ts2_l
mov [rsi + 12], edx	; __TEST_SETTINGS.ts2_h
mov rdi, rsi	; Safer to use RDI while restoring RDI and RSI
mov rsi, [rdi + 28]	; Restore RSI, RDI was already restored
ret