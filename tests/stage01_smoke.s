.intel_syntax noprefix
.section .rodata
ok_token: .ascii "STAGE01_SMOKE_OK\n"
ok_len = . - ok_token
fail_token: .ascii "STAGE01_SMOKE_FAIL\n"
fail_len = . - fail_token

.section .text
.extern oracle_init
.extern oracle_FOUNDATION
.extern oracle_calendar_date
.extern bi_eq_u64
.extern catalog_get_cutlet
.extern catalog_get_month

.global _start
.type _start,@function
_start:
    call oracle_init
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_calendar_date
    test rax,rax
    je .Lfail
    mov r12,rax

    mov rdi,qword ptr [r12]
    mov rsi,5000
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,10
    call catalog_get_cutlet
    cmp rax,qword ptr [r12+8]
    jne .Lfail

    cmp qword ptr [r12+16],503
    jne .Lfail

    mov rdi,20
    call catalog_get_month
    cmp rax,qword ptr [r12+24]
    jne .Lfail

    cmp qword ptr [r12+32],56
    jne .Lfail

    mov eax,1
    mov edi,1
    lea rsi,[rip+ok_token]
    mov edx,ok_len
    syscall
    xor edi,edi
    mov eax,60
    syscall
.Lfail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov edi,1
    mov eax,60
    syscall
.size _start,.-_start
