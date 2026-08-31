.intel_syntax noprefix
.ifndef FAIL_N
.equ FAIL_N,0
.endif
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32

.section .data
.align 8
fail_budget: .quad FAIL_N
partition_calls: .quad 0

.section .rodata
green_token: .ascii "STAGE55_RECOVERY_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE55_RECOVERY_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.global __wrap_catalog_get_cutlet
.global __wrap_monster_cutlet_partition_route
.extern __real_catalog_get_cutlet
.extern __real_monster_cutlet_partition_route
.extern calendarDateSpaghetti
.extern bi_eq_u64
.extern catalog_get_month

.type __wrap_catalog_get_cutlet,@function
__wrap_catalog_get_cutlet:
    mov rax,qword ptr [rip+fail_budget]
    test rax,rax
    je .Ls55rc_real_cutlet
    dec qword ptr [rip+fail_budget]
    xor eax,eax
    ret
.Ls55rc_real_cutlet:
    jmp __real_catalog_get_cutlet
.size __wrap_catalog_get_cutlet,.-__wrap_catalog_get_cutlet

.type __wrap_monster_cutlet_partition_route,@function
__wrap_monster_cutlet_partition_route:
    inc qword ptr [rip+partition_calls]
    jmp __real_monster_cutlet_partition_route
.size __wrap_monster_cutlet_partition_route,.-__wrap_monster_cutlet_partition_route

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
.if FAIL_N < 3
    cmp eax,2
    jne .Ls55rc_fail
    test rdx,rdx
    je .Ls55rc_fail
    mov r12,rdx
    cmp qword ptr [rip+partition_calls],1
    jne .Ls55rc_fail
    cmp qword ptr [rip+fail_budget],0
    jne .Ls55rc_fail
    mov rdi,qword ptr [r12+RES_YEAR]
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Ls55rc_fail
    mov edi,10
    call __real_catalog_get_cutlet
    cmp rax,qword ptr [r12+RES_CUTLET_NAME]
    jne .Ls55rc_fail
    cmp qword ptr [r12+RES_DAY_IN_CUTLET],503
    jne .Ls55rc_fail
    mov edi,20
    call catalog_get_month
    cmp rax,qword ptr [r12+RES_MONTH_NAME]
    jne .Ls55rc_fail
    cmp qword ptr [r12+RES_DAY_IN_MONTH],56
    jne .Ls55rc_fail
.else
    test eax,eax
    jne .Ls55rc_fail
    test rdx,rdx
    jne .Ls55rc_fail
    cmp qword ptr [rip+partition_calls],1
    jne .Ls55rc_fail
    cmp qword ptr [rip+fail_budget],0
    jne .Ls55rc_fail
.endif
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Ls55rc_fail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,55
    syscall
.size _start,.-_start
