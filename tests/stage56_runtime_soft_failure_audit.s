.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24

.section .bss
.align 8
fake_big:
    .skip 32

.section .rodata
green_token: .ascii "STAGE56_RUNTIME_SOFT_FAILURE_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE56_RUNTIME_SOFT_FAILURE_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern arena_alloc
.extern arena_mark
.extern arena_reset
.extern bi_from_u64
.extern bi_zero
.extern bi_reserve
.extern bi_divmod_u64_abs
.extern bi_divmod_abs

_start:
    # Ⲡarena ⲛϣⲟⲣⲡ ⲥⲱⲛⲧ ⲙⲡbase ⲉϥⲟⲩⲟⲛϩ.
    mov edi,16
    call arena_alloc
    test rax,rax
    je .Lfail

    # Ⲡoverflow route ⲙⲡarena ⲕⲧⲟ ⲛNULL, ⲁⲛ sys_exit.
    mov rdi,0xfffffffffffffff0
    call arena_alloc
    test rax,rax
    jne .Lfail

    # Ⲡinvalid reset mark ⲕⲧⲟ ⲛzero ⲙⲛⲧⲁϥ process abort.
    call arena_mark
    lea rdi,[rax+16]
    call arena_reset
    test rax,rax
    jne .Lfail

    # Ⲡu64 divide-by-zero detour.
    mov edi,7
    call bi_from_u64
    test rax,rax
    je .Lfail
    mov r12,rax
    mov rdi,r12
    xor esi,esi
    call bi_divmod_u64_abs
    test rax,rax
    jne .Lfail
    test rdx,rdx
    jne .Lfail

    # ⲠBigInt divide-by-zero detour.
    call bi_zero
    test rax,rax
    je .Lfail
    mov rsi,rax
    mov rdi,r12
    call bi_divmod_abs
    test rax,rax
    jne .Lfail
    test rdx,rdx
    jne .Lfail

    # Ⲡreserve overflow detour: ⲡfake header ⲥⲱⲣⲙ ⲙⲡdoubling ⲉcarry.
    lea r13,[rip+fake_big]
    mov qword ptr [r13+BI_SIGN],1
    mov qword ptr [r13+BI_LEN],1
    movabs rax,0x8000000000000000
    mov qword ptr [r13+BI_CAP],rax
    mov qword ptr [r13+BI_DATA],0
    mov rdi,r13
    mov rsi,-1
    call bi_reserve
    test rax,rax
    jne .Lfail

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lfail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,56
    syscall
