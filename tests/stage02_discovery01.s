.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE02_DISCOVERY01_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE02_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE02_DISCOVERY01_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern legacy_remainder_M
.extern monster_remainder_route
.extern bi_mul_u64
.extern bi_add_u64
.extern bi_cmp
.extern bi_eq_u64
.extern bi_is_zero
.global _start
.type _start,@function
_start:
    xor r12d,r12d

    lea rdi,[rip+legacy_remainder_M]
    call monster_remainder_route
    mov r13,rax
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    je .Lm_ok
    mov rdi,r13
    call bi_is_zero
    test eax,eax
    je .Lpattern
    inc r12
.Lm_ok:

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,2
    call bi_mul_u64
    mov rdi,rax
    call monster_remainder_route
    mov r13,rax
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    je .L2m_ok
    mov rdi,r13
    call bi_is_zero
    test eax,eax
    je .Lpattern
    inc r12
.L2m_ok:

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,3
    call bi_mul_u64
    mov rdi,rax
    call monster_remainder_route
    mov r13,rax
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    je .L3m_ok
    mov rdi,r13
    call bi_is_zero
    test eax,eax
    je .Lpattern
    inc r12
.L3m_ok:

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,1
    call bi_add_u64
    mov rdi,rax
    call monster_remainder_route
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lpattern

    test r12,r12
    je .Lgreen
    cmp r12,3
    jne .Lpattern

    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall

.Lgreen:
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lpattern:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,2
    syscall
.size _start,.-_start
