.intel_syntax noprefix
.equ RING_FIRST,0
.equ RING_STEP,8
.equ ORACLE_RING_FIRST,0
.equ ORACLE_RING_STEP,8

.section .rodata
ok_token: .ascii "STAGE27_PATCH13_GREEN\n"
ok_len = . - ok_token
fail_token: .ascii "STAGE27_PATCH13_FAIL\n"
fail_len = . - fail_token

.section .text
.extern bi_from_i64
.extern bi_from_u64
.extern bi_clone
.extern bi_sub
.extern bi_cmp
.extern bi_eq_u64
.extern answerRingThroughPatchedNextBowl
.extern ringAnswer
.extern biasedLegacyPick
.extern legacyBiasedSelectionBeforeRejection
.extern patchedSmallPick
.extern monster_biased_selection_route
.extern sauceWithOrderAt46Latch
.extern oracle_sauce
.extern oracle_ask_bowl
.extern oracle_choose_rank_short
.extern legacy_remainder_M
.extern calendarDateSpaghetti
.global _start

.type check_patch_ring,@function
check_patch_ring:
    # rdi=patched sauce, rsi=oracle sauce, rdx=queried ID, rcx=seal.
    # return 1 on exact Stage27 repair, 0 on any wrong pattern.
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
    mov r15,rcx

    mov rdi,r12
    mov rsi,r14
    mov rdx,r15
    call answerRingThroughPatchedNextBowl
    test rax,rax
    je .Lcpr_fail
    mov qword ptr [rbp-40],rax
    cmp qword ptr [rax+RING_STEP],-1
    jne .Lcpr_fail

    # Ⲡring ⲛproduction ⲧⲱⲛ ⲙⲛ ⲡsame-line oracle.
    mov rdi,r13
    mov rsi,r14
    mov rdx,r15
    call oracle_ask_bowl
    test rax,rax
    je .Lcpr_fail
    mov qword ptr [rbp-48],rax
    cmp qword ptr [rax+ORACLE_RING_STEP],-1
    jne .Lcpr_fail
    mov rdx,qword ptr [rbp-40]
    mov rdi,qword ptr [rdx+RING_FIRST]
    mov rsi,qword ptr [rax+ORACLE_RING_FIRST]
    call bi_cmp
    test eax,eax
    jne .Lcpr_fail

    # N=first-1.
    mov rdi,1
    call bi_from_u64
    test rax,rax
    je .Lcpr_fail
    mov rsi,rax
    mov rdx,qword ptr [rbp-40]
    mov rdi,qword ptr [rdx+RING_FIRST]
    call bi_sub
    test rax,rax
    je .Lcpr_fail
    mov qword ptr [rbp-56],rax

    # Ⲡlegacy direct call ⲟⲩⲏϩ ⲉϥϯ 1.
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-56]
    call legacyBiasedSelectionBeforeRejection
    test rax,rax
    je .Lcpr_fail
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lcpr_fail

    # ⲠPATCH 13: first answer rejected, answer offset 1 accepted.
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-56]
    call patchedSmallPick
    test rax,rax
    je .Lcpr_fail
    mov qword ptr [rbp-64],rax
    mov qword ptr [rbp-72],rdx
    mov qword ptr [rbp-80],r8
    cmp rcx,1
    jne .Lcpr_fail

    # limit=N in these witnesses.
    mov rdi,qword ptr [rbp-80]
    mov rsi,qword ptr [rbp-56]
    call bi_cmp
    test eax,eax
    jne .Lcpr_fail

    # accepted x=N.
    mov rdi,qword ptr [rbp-72]
    mov rsi,qword ptr [rbp-56]
    call bi_cmp
    test eax,eax
    jne .Lcpr_fail

    # biasedLegacyPick is called only after acceptance and returns N here.
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-56]
    call bi_cmp
    test eax,eax
    jne .Lcpr_fail

    # route == patched helper.
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-56]
    call monster_biased_selection_route
    test rax,rax
    je .Lcpr_fail
    mov rdi,rax
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jne .Lcpr_fail

    # same-line oracle short rejection == patched result.
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call oracle_choose_rank_short
    test rax,rax
    je .Lcpr_fail
    mov rdi,rax
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jne .Lcpr_fail

    mov eax,1
    jmp .Lcpr_done
.Lcpr_fail:
    xor eax,eax
.Lcpr_done:
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size check_patch_ring,.-check_patch_ring

.type check_n_equals_m,@function
check_n_equals_m:
    # rdi=LegacyAnswerRing*. With N=M, limit=M and offset 0 must be accepted.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,16
    mov r12,rdi
    lea rdi,[rip+legacy_remainder_M]
    call bi_clone
    test rax,rax
    je .Lcnm_fail
    mov r13,rax

    mov rdi,r12
    mov rsi,r13
    call patchedSmallPick
    test rax,rax
    je .Lcnm_fail
    mov qword ptr [rbp-24],rax
    mov qword ptr [rbp-32],rdx
    test rcx,rcx
    jne .Lcnm_fail

    mov rdi,r8
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jne .Lcnm_fail

    mov rdi,qword ptr [rbp-32]
    mov rsi,qword ptr [r12+RING_FIRST]
    call bi_cmp
    test eax,eax
    jne .Lcnm_fail

    # With N=M and x in 1..M, biasedLegacyPick(x,M)=x.
    mov rdi,qword ptr [rbp-24]
    mov rsi,qword ptr [r12+RING_FIRST]
    call bi_cmp
    test eax,eax
    jne .Lcnm_fail
    mov eax,1
    jmp .Lcnm_done
.Lcnm_fail:
    xor eax,eax
.Lcnm_done:
    add rsp,16
    pop r13
    pop r12
    leave
    ret
.size check_n_equals_m,.-check_n_equals_m

.type check_invalid_short_boundaries,@function
check_invalid_short_boundaries:
    # rdi=LegacyAnswerRing*. N=0 and null ring are deterministic failures.
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi

    xor edi,edi
    call bi_from_u64
    test rax,rax
    je .Lcisb_fail
    mov rdi,r12
    mov rsi,rax
    call patchedSmallPick
    test rax,rax
    jne .Lcisb_fail

    lea rsi,[rip+legacy_remainder_M]
    xor edi,edi
    call patchedSmallPick
    test rax,rax
    jne .Lcisb_fail

    mov eax,1
    jmp .Lcisb_done
.Lcisb_fail:
    xor eax,eax
.Lcisb_done:
    pop r12
    leave
    ret
.size check_invalid_short_boundaries,.-check_invalid_short_boundaries

.type _start,@function
_start:
    # Ⲡreal calendar route ⲙⲟⲩⲧⲉ ⲉPATCH 13 handler.
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

    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lfail
    mov r13,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lfail
    mov rdi,r13
    mov rsi,rax
    call oracle_sauce
    test rax,rax
    je .Lfail
    mov r13,rax

    mov rdi,r12
    mov rsi,r13
    mov edx,1
    mov ecx,21
    call check_patch_ring
    test eax,eax
    je .Lfail

    mov rdi,r12
    mov rsi,r13
    mov edx,2
    mov ecx,21
    call check_patch_ring
    test eax,eax
    je .Lfail

    mov rdi,r12
    mov rsi,r13
    mov edx,3
    mov ecx,3
    call check_patch_ring
    test eax,eax
    je .Lfail

    # N=M boundary on a real answer ring.
    mov rdi,r12
    mov esi,1
    mov edx,21
    call answerRingThroughPatchedNextBowl
    test rax,rax
    je .Lfail
    mov r12,rax
    mov rdi,r12
    call check_n_equals_m
    test eax,eax
    je .Lfail
    mov rdi,r12
    call check_invalid_short_boundaries
    test eax,eax
    je .Lfail

    mov eax,1
    mov edi,1
    lea rsi,[rip+ok_token]
    mov edx,ok_len
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
    mov edi,27
    syscall
.size _start,.-_start
