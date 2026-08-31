.intel_syntax noprefix
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.equ FOUNDATION,-15055671
.section .bss
.align 8
fake_cutlets: .zero 32
fake_months: .zero 64
.section .rodata
green_token: .ascii "STAGE55_LOCALE_CATALOG_GREEN\n"
green_len=.-green_token
fail_token: .ascii "STAGE55_LOCALE_CATALOG_FAIL\n"
fail_len=.-fail_token
.section .text
.global _start
.global __wrap_catalog_get_cutlet
.global __wrap_catalog_get_month
.extern __real_catalog_get_cutlet
.extern __real_catalog_get_month
.extern catalog_cutlet_count
.extern catalog_month_count
.extern catalog_validate
.extern calendarDateSpaghetti
.extern bi_eq_u64
__wrap_catalog_get_cutlet:
    cmp rdi,1
    jb .Lwc_bad
    cmp rdi,17
    ja .Lwc_bad
    lea rax,[rip+fake_cutlets]
    add rax,rdi
    ret
.Lwc_bad:
    xor eax,eax
    ret
__wrap_catalog_get_month:
    cmp rdi,1
    jb .Lwm_bad
    cmp rdi,47
    ja .Lwm_bad
    lea rax,[rip+fake_months]
    add rax,rdi
    ret
.Lwm_bad:
    xor eax,eax
    ret
_start:
    call catalog_validate
    cmp eax,1
    jne .Lfail
    call catalog_cutlet_count
    cmp eax,17
    jne .Lfail
    call catalog_month_count
    cmp eax,47
    jne .Lfail

    mov r12,1
.Lcut_outer:
    mov rdi,r12
    call __real_catalog_get_cutlet
    test rax,rax
    je .Lfail
    mov r13,rax
    mov r14,r12
    inc r14
.Lcut_inner:
    cmp r14,18
    jae .Lcut_next
    mov rdi,r14
    call __real_catalog_get_cutlet
    cmp rax,r13
    je .Lfail
    inc r14
    jmp .Lcut_inner
.Lcut_next:
    inc r12
    cmp r12,18
    jb .Lcut_outer

    mov r12,1
.Lmon_outer:
    mov rdi,r12
    call __real_catalog_get_month
    test rax,rax
    je .Lfail
    mov r13,rax
    mov r14,r12
    inc r14
.Lmon_inner:
    cmp r14,48
    jae .Lmon_next
    mov rdi,r14
    call __real_catalog_get_month
    cmp rax,r13
    je .Lfail
    inc r14
    jmp .Lmon_inner
.Lmon_next:
    inc r12
    cmp r12,48
    jb .Lmon_outer

    mov rdi,FOUNDATION
    mov rsi,FOUNDATION
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    test rdx,rdx
    je .Lfail
    mov r12,rdx
    mov rdi,qword ptr [r12+RES_YEAR]
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lfail
    cmp qword ptr [r12+RES_DAY_IN_CUTLET],503
    jne .Lfail
    cmp qword ptr [r12+RES_DAY_IN_MONTH],56
    jne .Lfail
    lea rax,[rip+fake_cutlets]
    add rax,10
    cmp qword ptr [r12+RES_CUTLET_NAME],rax
    jne .Lfail
    lea rax,[rip+fake_months]
    add rax,20
    cmp qword ptr [r12+RES_MONTH_NAME],rax
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
    mov edi,55
    syscall
