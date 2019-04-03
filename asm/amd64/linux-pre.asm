BITS 64

mov rsi, rdi
mov edi, [rsi + 16]	; __TEST_SETTINGS.runs
rdtsc
mov [rsi], eax	; __TEST_SETTINGS.ts1_l
mov [rsi + 4], edx	; __TEST_SETTINGS.ts1_h
; -- test should be here --