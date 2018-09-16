BITS 64

pre_test:
dec rdi
jnz pre_test	; translates to a QWORD
; -- Test finished at this point --
rdtsc
mov [rsi + 8], eax	; __TEST_SETTINGS.ts2_l
mov [rsi + 12], edx	; __TEST_SETTINGS.ts2_h
mov rcx, rsi	; Safer to use ECX while restoring EDI and ESI
mov rdi, [rcx + 20]	; Restore RDI
mov rsi, [rcx + 24]	; Restore RSI
ret