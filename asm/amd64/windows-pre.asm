BITS 64

mov [rcx + 20], rdi	; RCX already set, save RDI and RSI
mov [rcx + 28], rsi
mov rsi, rcx
mov edi, [rsi + 16]	; __TEST_SETTINGS.runs
rdtsc
mov [rsi], eax	; __TEST_SETTINGS.ts1_l
mov [rsi + 4], edx	; __TEST_SETTINGS.ts1_h
; -- test should be here --