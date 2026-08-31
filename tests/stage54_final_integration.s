.intel_syntax noprefix
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.section .rodata
green_token: .ascii "STAGE54_INTEGRATION_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE54_INTEGRATION_FAIL\n"
fail_len = . - fail_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern bi_eq_u64
.extern catalog_get_cutlet
.extern catalog_get_month
.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Ls54test_fail
    test rdx,rdx
    je .Ls54test_fail
    mov r12,rdx
    mov rdi,qword ptr [r12+RES_YEAR]
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Ls54test_fail
    mov edi,10
    call catalog_get_cutlet
    cmp rax,qword ptr [r12+RES_CUTLET_NAME]
    jne .Ls54test_fail
    cmp qword ptr [r12+RES_DAY_IN_CUTLET],503
    jne .Ls54test_fail
    mov edi,20
    call catalog_get_month
    cmp rax,qword ptr [r12+RES_MONTH_NAME]
    jne .Ls54test_fail
    cmp qword ptr [r12+RES_DAY_IN_MONTH],56
    jne .Ls54test_fail
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Ls54test_fail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,54
    syscall
.size _start,.-_start
