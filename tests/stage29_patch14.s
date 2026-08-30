.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8

.section .rodata
green_token: .ascii "STAGE29_PATCH14_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE29_PATCH14_FAIL\n"
fail_len = . - fail_token

.section .text
.extern bi_add_u64
.extern bi_mul_abs
.extern bi_cmp
.extern bi_eq_u64
.extern legacy_remainder_M
.extern legacySelectionAssumingNLeM
.extern patchedSmallPick
.extern wideDetour
.extern selectionPatch14
.extern monster_wide_selection_route
.extern oracle_choose_rank_wide
.extern sauceWithOrderAt46Latch
.extern answerRingThroughPatchedNextBowl
.extern calendarDateSpaghetti
.global _start

.type require_wide_case,@function
require_wide_case:
    # rdi=ring, rsi=N, rdx=expected places. return 1 pass, 0 fail.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,48
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx

    # Ⲡlegacy scar ϣⲉ ⲉⲧⲣⲉϥⲟ ⲛunsupported.
    mov rdi,r12
    mov rsi,r13
    call legacySelectionAssumingNLeM
    test rax,rax
    jne .Lrwc_fail

    # Ⲡsame-line oracle.
    mov rdi,r12
    mov rsi,r13
    call oracle_choose_rank_wide
    test rax,rax
    je .Lrwc_fail
    mov r15,rax

    # Ⲡwide detour direct ⲙⲛ trace.
    mov rdi,r12
    mov rsi,r13
    call wideDetour
    test rax,rax
    je .Lrwc_fail
    mov qword ptr [rbp-48],rax
    mov qword ptr [rbp-56],rdx
    mov qword ptr [rbp-64],r8
    mov qword ptr [rbp-72],r9
    cmp rcx,r14
    jne .Lrwc_fail
    mov rdi,rax
    mov rsi,r15
    call bi_cmp
    test eax,eax
    jne .Lrwc_fail

    # space>=N; accepted<=limit; limit<=space; rank<=N.
    mov rdi,qword ptr [rbp-64]
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jl .Lrwc_fail
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rbp-72]
    call bi_cmp
    test eax,eax
    jg .Lrwc_fail
    mov rdi,qword ptr [rbp-72]
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jg .Lrwc_fail
    mov rdi,qword ptr [rbp-48]
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jg .Lrwc_fail

    # Ⲡroute ⲙⲛ dispatcher ϣⲉ ⲉⲧⲣⲉⲩⲧⲱⲛ ⲙⲛ ⲡoracle.
    mov rdi,r12
    mov rsi,r13
    call monster_wide_selection_route
    test rax,rax
    je .Lrwc_fail
    mov rdi,rax
    mov rsi,r15
    call bi_cmp
    test eax,eax
    jne .Lrwc_fail

    mov rdi,r12
    mov rsi,r13
    call selectionPatch14
    test rax,rax
    je .Lrwc_fail
    mov rdi,rax
    mov rsi,r15
    call bi_cmp
    test eax,eax
    jne .Lrwc_fail

    mov eax,1
    jmp .Lrwc_done
.Lrwc_fail:
    xor eax,eax
.Lrwc_done:
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_wide_case,.-require_wide_case

.type require_short_dispatch,@function
require_short_dispatch:
    # rdi=ring, rsi=N.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    sub rsp,8
    mov rdi,r12
    mov rsi,r13
    call patchedSmallPick
    test rax,rax
    je .Lrsd_fail
    mov r14,rax
    mov rdi,r12
    mov rsi,r13
    call selectionPatch14
    test rax,rax
    je .Lrsd_fail
    mov rdi,rax
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lrsd_fail
    mov eax,1
    jmp .Lrsd_done
.Lrsd_fail:
    xor eax,eax
.Lrsd_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_short_dispatch,.-require_short_dispatch

.type _start,@function
_start:
    # Ⲡreal state-machine ⲛStage 29 ϣⲉ ⲉⲧⲣⲉϥⲟ ⲛvalid.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail

    mov rdi,-15055671
    mov rsi,-15055671
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Lfail
    mov r12,rax
    mov rdi,r12
    mov esi,1
    mov edx,1
    call answerRingThroughPatchedNextBowl
    test rax,rax
    je .Lfail
    mov r13,rax

    # Ⲡshort boundary N=M_OLD ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡshort path.
    mov rdi,r13
    lea rsi,[rip+legacy_remainder_M]
    call require_short_dispatch
    test eax,eax
    je .Lfail

    # N=M_OLD+1 -> places=2.
    lea rdi,[rip+legacy_remainder_M]
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Lfail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    mov edx,2
    call require_wide_case
    test eax,eax
    je .Lfail

    # N=M_OLD^2 -> places=2.
    lea rdi,[rip+legacy_remainder_M]
    lea rsi,[rip+legacy_remainder_M]
    call bi_mul_abs
    test rax,rax
    je .Lfail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    mov edx,2
    call require_wide_case
    test eax,eax
    je .Lfail

    # N=M_OLD^3 -> places=3.
    mov rdi,r14
    lea rsi,[rip+legacy_remainder_M]
    call bi_mul_abs
    test rax,rax
    je .Lfail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    mov edx,3
    call require_wide_case
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
    mov edi,29
    syscall
.size _start,.-_start
