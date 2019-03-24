BITS 64

mov [rdi + 20], rdi	; Save RSI and RDI
mov [rdi + 28], rsi
mov rsi, rdi
xor rdi, rdi
mov rdi, [rsi + 16]	; __TEST_SETTINGS.runs
rdtsc
mov [rsi], eax	; __TEST_SETTINGS.ts1_l
mov [rsi + 4], edx	; __TEST_SETTINGS.ts1_h
; -- test should be here --