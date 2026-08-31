.intel_syntax noprefix
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.ifndef AUDIT_CASE
.set AUDIT_CASE,1
.endif
.if AUDIT_CASE == 1
.equ C_DAY,-15055671
.equ T_DAY,-15055671
.equ E_YEAR,5000
.equ E_CUTLET,10
.equ E_DCUT,503
.equ E_MONTH,20
.equ E_DMONTH,56
.elseif AUDIT_CASE == 2
.equ C_DAY,-15055672
.equ T_DAY,-15055672
.equ E_YEAR,5000
.equ E_CUTLET,9
.equ E_DCUT,502
.equ E_MONTH,33
.equ E_DMONTH,14
.elseif AUDIT_CASE == 3
.equ C_DAY,-15055670
.equ T_DAY,-15055670
.equ E_YEAR,5000
.equ E_CUTLET,10
.equ E_DCUT,504
.equ E_MONTH,20
.equ E_DMONTH,112
.elseif AUDIT_CASE == 4
.equ C_DAY,-15055672
.equ T_DAY,-15055670
.equ E_YEAR,5000
.equ E_CUTLET,15
.equ E_DCUT,1
.equ E_MONTH,20
.equ E_DMONTH,15
.elseif AUDIT_CASE == 5
.equ C_DAY,-15055670
.equ T_DAY,-15055672
.equ E_YEAR,5000
.equ E_CUTLET,10
.equ E_DCUT,502
.equ E_MONTH,12
.equ E_DMONTH,106
.elseif AUDIT_CASE == 6
.equ C_DAY,-15055671
.equ T_DAY,-15057703
.equ E_YEAR,4999
.equ E_CUTLET,15
.equ E_DCUT,433
.equ E_MONTH,32
.equ E_DMONTH,121
.elseif AUDIT_CASE == 7
.equ C_DAY,-15055671
.equ T_DAY,-15057702
.equ E_YEAR,5000
.equ E_CUTLET,15
.equ E_DCUT,1
.equ E_MONTH,18
.equ E_DMONTH,1
.elseif AUDIT_CASE == 8
.equ C_DAY,-15055671
.equ T_DAY,-15056944
.equ E_YEAR,5000
.equ E_CUTLET,15
.equ E_DCUT,759
.equ E_MONTH,16
.equ E_DMONTH,20
.elseif AUDIT_CASE == 9
.equ C_DAY,-15055671
.equ T_DAY,-15053459
.equ E_YEAR,5000
.equ E_CUTLET,13
.equ E_DCUT,218
.equ E_MONTH,26
.equ E_DMONTH,105
.elseif AUDIT_CASE == 10
.equ C_DAY,-15055671
.equ T_DAY,-15053458
.equ E_YEAR,5001
.equ E_CUTLET,9
.equ E_DCUT,1
.equ E_MONTH,41
.equ E_DMONTH,1
.elseif AUDIT_CASE == 11
.equ C_DAY,-15055670
.equ T_DAY,-15055671
.equ E_YEAR,5000
.equ E_CUTLET,10
.equ E_DCUT,503
.equ E_MONTH,40
.equ E_DMONTH,99
.elseif AUDIT_CASE == 12
.equ C_DAY,-15056944
.equ T_DAY,-15055671
.equ E_YEAR,5000
.equ E_CUTLET,2
.equ E_DCUT,503
.equ E_MONTH,5
.equ E_DMONTH,122
.elseif AUDIT_CASE == 13
.equ C_DAY,-15056944
.equ T_DAY,-15056944
.equ E_YEAR,5000
.equ E_CUTLET,10
.equ E_DCUT,759
.equ E_MONTH,1
.equ E_DMONTH,85
.elseif AUDIT_CASE == 14
.equ C_DAY,-15055671
.equ T_DAY,-15056174
.equ E_YEAR,5000
.equ E_CUTLET,17
.equ E_DCUT,770
.equ E_MONTH,7
.equ E_DMONTH,27
.else
.error "AUDIT_CASE"
.endif
.section .rodata
green_token: .ascii "STAGE55_E2E_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE55_E2E_FAIL\n"
fail_len = . - fail_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern bi_from_i64
.extern bi_eq_u64
.extern catalog_get_cutlet
.extern catalog_get_month
_start:
    mov rdi,C_DAY
    mov rsi,T_DAY
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    test rdx,rdx
    je .Lfail
    mov r12,rdx
    mov rdi,qword ptr [r12+RES_YEAR]
    mov esi,E_YEAR
    call bi_eq_u64
    test eax,eax
    je .Lfail
    mov rdi,E_CUTLET
    call catalog_get_cutlet
    cmp rax,qword ptr [r12+RES_CUTLET_NAME]
    jne .Lfail
    cmp qword ptr [r12+RES_DAY_IN_CUTLET],E_DCUT
    jne .Lfail
    mov rdi,E_MONTH
    call catalog_get_month
    cmp rax,qword ptr [r12+RES_MONTH_NAME]
    jne .Lfail
    cmp qword ptr [r12+RES_DAY_IN_MONTH],E_DMONTH
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
