.intel_syntax noprefix
.equ CTX_STAGE40_YEAR,1696
.equ CTX_STAGE40_YEAR_FIRST_DAY,1704
.equ CTX_STAGE40_ORIGINAL_TARGET,1712
.equ CTX_STAGE40_GHOST_SAUCE,1720
.equ CTX_STAGE40_ROUTE_SAUCE,1728
.equ CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY,1736
.equ CTX_STAGE40_GHOST_USED_AS_SEMANTIC,1744
.equ CTX_STAGE40_SEEN,1752
.equ CTX_STAGE41_ROUTE_GHOST,1760
.equ CTX_STAGE41_ROUTE_GHOST_SEEN,1768
.equ CTX_STAGE41_PATCH_SEEN,1776
.equ CTX_STAGE41_GHOST_REUSE_EQUAL,1784
.equ S23_FINAL_BOWLS,8
.equ S23_QUERY_ORDER,40
.equ YJ_NUMBER,0
.equ YJ_FIRST_DAY,16

.section .rodata
green_token: .ascii "STAGE41_PATCH20_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE41_PATCH20_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage40_legacy_structure_sauce_handler
.extern legacyStructureSauceUsingOriginalTarget
.extern oldStructureSauce
.extern sauceWithOrderAt46Latch
.extern bi_from_i64
.extern bi_cmp
.extern bi_eq_u64

# rdi=S23*, rsi=S23*. eax=1 equal / 0 different.
.type stage41SauceEqual,@function
stage41SauceEqual:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Ls41se_no
    test r13,r13
    je .Ls41se_no
    mov rax,qword ptr [r12+S23_FINAL_BOWLS]
    mov rdx,qword ptr [r13+S23_FINAL_BOWLS]
    test rax,rax
    je .Ls41se_no
    test rdx,rdx
    je .Ls41se_no
    mov qword ptr [rbp-40],rax
    mov qword ptr [rbp-48],rdx
    xor ebx,ebx
.Ls41se_bowls:
    cmp ebx,6
    jae .Ls41se_orders_start
    mov rax,qword ptr [rbp-40]
    mov rdi,qword ptr [rax+rbx*8]
    mov rax,qword ptr [rbp-48]
    mov rsi,qword ptr [rax+rbx*8]
    test rdi,rdi
    je .Ls41se_no
    test rsi,rsi
    je .Ls41se_no
    call bi_cmp
    test eax,eax
    jne .Ls41se_no
    inc ebx
    jmp .Ls41se_bowls
.Ls41se_orders_start:
    mov r14,qword ptr [r12+S23_QUERY_ORDER]
    mov r12,qword ptr [r13+S23_QUERY_ORDER]
    test r14,r14
    je .Ls41se_no
    test r12,r12
    je .Ls41se_no
    xor ebx,ebx
.Ls41se_orders:
    cmp ebx,6
    jae .Ls41se_yes
    mov rax,qword ptr [r14+rbx*8]
    cmp rax,qword ptr [r12+rbx*8]
    jne .Ls41se_no
    inc ebx
    jmp .Ls41se_orders
.Ls41se_yes:
    mov eax,1
    jmp .Ls41se_done
.Ls41se_no:
    xor eax,eax
.Ls41se_done:
    add rsp,16
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage41SauceEqual,.-stage41SauceEqual

# Ⲡcase ⲉⲧⲉ ⲡoriginal target ϣⲟⲃⲉ ⲙⲛ year.firstDay: ghost ⲣϩⲱⲃ, ⲁⲗⲗⲁ ⲛϥⲣⲥⲉⲙⲛⲉ ⲁⲛ ⲙⲡauthoritative sauce.
.type stage41DifferentTargetCase,@function
stage41DifferentTargetCase:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8

    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls41dt_no
    mov r12,rax
    mov rdi,r12
    call monster_stage40_legacy_structure_sauce_handler
    cmp eax,1
    jne .Ls41dt_no

    cmp qword ptr [r12+CTX_STAGE40_SEEN],1
    jne .Ls41dt_no
    cmp qword ptr [r12+CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY],1
    jne .Ls41dt_no
    cmp qword ptr [r12+CTX_STAGE40_GHOST_USED_AS_SEMANTIC],0
    jne .Ls41dt_no
    cmp qword ptr [r12+CTX_STAGE41_GHOST_REUSE_EQUAL],0
    jne .Ls41dt_no
    cmp qword ptr [r12+CTX_STAGE41_ROUTE_GHOST_SEEN],1
    jne .Ls41dt_no
    cmp qword ptr [r12+CTX_STAGE41_PATCH_SEEN],1
    jne .Ls41dt_no

    mov r13,qword ptr [r12+CTX_STAGE40_YEAR]
    test r13,r13
    je .Ls41dt_no
    mov rdi,qword ptr [r13+YJ_NUMBER]
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Ls41dt_no

    mov rdi,-15056160
    call bi_from_i64
    test rax,rax
    je .Ls41dt_no
    mov rdi,rax
    mov rsi,qword ptr [r12+CTX_STAGE40_YEAR_FIRST_DAY]
    call bi_cmp
    test eax,eax
    jne .Ls41dt_no

    mov r14,qword ptr [r12+CTX_STAGE40_GHOST_SAUCE]
    mov r15,qword ptr [r12+CTX_STAGE41_ROUTE_GHOST]
    test r14,r14
    je .Ls41dt_no
    test r15,r15
    je .Ls41dt_no
    mov rdi,r14
    mov rsi,r15
    call stage41SauceEqual
    test eax,eax
    je .Ls41dt_no

    mov rbx,qword ptr [r12+CTX_STAGE40_ROUTE_SAUCE]
    test rbx,rbx
    je .Ls41dt_no
    mov rdi,rbx
    mov rsi,r15
    call stage41SauceEqual
    test eax,eax
    jne .Ls41dt_no

    mov rdi,-15055671
    mov rsi,-15056160
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Ls41dt_no
    mov rdi,rbx
    mov rsi,rax
    call stage41SauceEqual
    test eax,eax
    je .Ls41dt_no

    # Ⲡlegacy adapter scar ⲟⲩⲏϩ callable ⲁⲩⲱ ⲕⲧⲟ ⲉⲡsame old ghost.
    mov rdi,-15055671
    mov rsi,-15055671
    mov rdx,r13
    call legacyStructureSauceUsingOriginalTarget
    test rax,rax
    je .Ls41dt_no
    mov rdi,r14
    mov rsi,rax
    call stage41SauceEqual
    test eax,eax
    je .Ls41dt_no

    mov eax,1
    jmp .Ls41dt_done
.Ls41dt_no:
    xor eax,eax
.Ls41dt_done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage41DifferentTargetCase,.-stage41DifferentTargetCase

# Ⲡcase ⲉⲧⲉ originalTargetDay == year.firstDay: ⲡroute ϣϭⲙϭⲟⲙ ⲉreturn ⲙⲡghost ⲛⲧⲟϥ.
.type stage41EqualTargetCase,@function
stage41EqualTargetCase:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8

    mov rdi,-15055671
    mov rsi,-15056160
    call monster_context_new
    test rax,rax
    je .Ls41eq_no
    mov r12,rax
    mov rdi,r12
    call monster_stage40_legacy_structure_sauce_handler
    cmp eax,1
    jne .Ls41eq_no

    cmp qword ptr [r12+CTX_STAGE40_SEEN],1
    jne .Ls41eq_no
    cmp qword ptr [r12+CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY],0
    jne .Ls41eq_no
    cmp qword ptr [r12+CTX_STAGE40_GHOST_USED_AS_SEMANTIC],1
    jne .Ls41eq_no
    cmp qword ptr [r12+CTX_STAGE41_GHOST_REUSE_EQUAL],1
    jne .Ls41eq_no
    cmp qword ptr [r12+CTX_STAGE41_ROUTE_GHOST_SEEN],1
    jne .Ls41eq_no
    cmp qword ptr [r12+CTX_STAGE41_PATCH_SEEN],1
    jne .Ls41eq_no

    mov r13,qword ptr [r12+CTX_STAGE40_ROUTE_SAUCE]
    mov r14,qword ptr [r12+CTX_STAGE41_ROUTE_GHOST]
    test r13,r13
    je .Ls41eq_no
    test r14,r14
    je .Ls41eq_no
    cmp r13,r14
    jne .Ls41eq_no

    mov rdi,qword ptr [r12+CTX_STAGE40_GHOST_SAUCE]
    mov rsi,r13
    call stage41SauceEqual
    test eax,eax
    je .Ls41eq_no

    mov eax,1
    jmp .Ls41eq_done
.Ls41eq_no:
    xor eax,eax
.Ls41eq_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage41EqualTargetCase,.-stage41EqualTargetCase

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail

    call stage41DifferentTargetCase
    test eax,eax
    je .Lfail
    call stage41EqualTargetCase
    test eax,eax
    je .Lfail

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
    mov edi,41
    syscall
.size _start,.-_start
