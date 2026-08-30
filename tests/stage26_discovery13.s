.intel_syntax noprefix
.equ RING_FIRST,0
.equ RING_STEP,8
.equ ORACLE_RING_FIRST,0
.equ ORACLE_RING_STEP,8

.section .rodata
red_token: .ascii "STAGE26_DISCOVERY13_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE26_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE26_DISCOVERY13_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern arena_alloc
.extern bi_from_i64
.extern bi_from_u64
.extern bi_clone
.extern bi_sub
.extern bi_cmp
.extern bi_eq_u64
.extern bi_shr1_inplace
.extern sauceWithOrderAt46Latch
.extern answerRingThroughPatchedNextBowl
.extern ringAnswer
.extern biasedLegacyPick
.extern legacyBiasedSelectionBeforeRejection
.extern monster_biased_selection_route
.extern calendarDateSpaghetti
.extern legacy_remainder_M
.extern oracle_sauce
.extern oracle_ask_bowl
.extern oracle_choose_rank_short
.global _start

.type check_one_ring,@function
check_one_ring:
    # rdi=patched sauce, rsi=oracle sauce, rdx=queried ID, rcx=seal.
    # return 1 for the exact biased mismatch, 0 only if already repaired, -1 for wrong pattern.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx

    mov rdi,r12
    mov rsi,r14
    mov rdx,r15
    call answerRingThroughPatchedNextBowl
    test rax,rax
    je .Lcor_bad
    mov qword ptr [rbp-40],rax
    cmp qword ptr [rax+RING_STEP],-1
    jne .Lcor_bad

    # Ⲡring ⲛproduction ⲧⲱⲛ ⲙⲛ ⲡsame-line oracle ϩⲓ first ⲙⲛ direction.
    mov rdi,r13
    mov rsi,r14
    mov rdx,r15
    call oracle_ask_bowl
    test rax,rax
    je .Lcor_bad
    mov qword ptr [rbp-48],rax
    cmp qword ptr [rax+ORACLE_RING_STEP],-1
    jne .Lcor_bad
    mov rdi,qword ptr [rbp-40]
    mov rdi,qword ptr [rdi+RING_FIRST]
    mov rsi,qword ptr [rax+ORACLE_RING_FIRST]
    call bi_cmp
    test eax,eax
    jne .Lcor_bad

    # Ⲡfirst ϣⲟⲟⲡ ⲉϩⲣⲁⲓ ⲉ M/2; ⲡN ⲙⲡwitness ⲡⲉ first-1.
    lea rdi,[rip+legacy_remainder_M]
    call bi_clone
    test rax,rax
    je .Lcor_bad
    mov rdi,rax
    call bi_shr1_inplace
    mov rdx,qword ptr [rbp-40]
    mov rdi,qword ptr [rdx+RING_FIRST]
    mov rsi,rax
    call bi_cmp
    test eax,eax
    jle .Lcor_bad

    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdx,qword ptr [rbp-40]
    mov rdi,qword ptr [rdx+RING_FIRST]
    call bi_sub
    test rax,rax
    je .Lcor_bad
    mov qword ptr [rbp-56],rax

    # answerAt(0)=first; answerAt(1)=N in the descending witness ring.
    mov rdi,qword ptr [rbp-40]
    xor esi,esi
    call ringAnswer
    test rax,rax
    je .Lcor_bad
    mov rdx,qword ptr [rbp-40]
    mov rdi,rax
    mov rsi,qword ptr [rdx+RING_FIRST]
    call bi_cmp
    test eax,eax
    jne .Lcor_bad

    mov rdi,qword ptr [rbp-40]
    mov esi,1
    call ringAnswer
    test rax,rax
    je .Lcor_bad
    mov rdi,rax
    mov rsi,qword ptr [rbp-56]
    call bi_cmp
    test eax,eax
    jne .Lcor_bad

    # Ⲡlegacy direct call ⲟⲩⲏϩ ⲉϥⲙⲟⲩⲧⲉ ⲉbiasedLegacyPick ϩⲓ answerAt(0) ⲁϫⲛ rejection; ⲛϥϯ 1.
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-56]
    call legacyBiasedSelectionBeforeRejection
    test rax,rax
    je .Lcor_bad
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lcor_bad

    # Ⲡroute ⲡⲉ ⲡsemantic path ⲉⲧⲣⲉⲡPATCH ⲛⲁϣ ⲉⲕⲧⲟϥ ⲉGREEN ⲁϫⲛ ⲧⲣⲉⲡlegacy scar ⲟⲩⲱϣϥ.
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-56]
    call monster_biased_selection_route
    test rax,rax
    je .Lcor_bad
    mov qword ptr [rbp-64],rax

    # Ⲡsame-line oracle ⲣrejection ϩⲙⲡring ⲛⲟⲩⲱⲧ; ⲡanswer ⲙⲙⲁϩ2 ⲡⲉ N.
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call oracle_choose_rank_short
    test rax,rax
    je .Lcor_bad
    mov qword ptr [rbp-48],rax
    mov rdi,rax
    mov rsi,qword ptr [rbp-56]
    call bi_cmp
    test eax,eax
    jne .Lcor_bad

    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-48]
    call bi_cmp
    test eax,eax
    je .Lcor_equal
    mov eax,1
    jmp .Lcor_done
.Lcor_equal:
    xor eax,eax
    jmp .Lcor_done
.Lcor_bad:
    mov rax,-1
.Lcor_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size check_one_ring,.-check_one_ring

.type _start,@function
_start:
    # Ⲡreal calendar route ⲙⲟⲩⲧⲉ ⲉDISCOVERY 13 handler.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    # Ⲧⲁⲙⲓⲟ ⲛⲥⲁⲩⲥ ⲛproduction ⲙⲛ ⲟⲩoracle sauce ⲛⲧⲉⲡline ⲛⲟⲩⲱⲧ.
    mov rdi,-15055671
    mov rsi,-15055671
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Lpattern
    mov r12,rax

    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lpattern
    mov r13,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lpattern
    mov rdi,r13
    mov rsi,rax
    call oracle_sauce
    test rax,rax
    je .Lpattern
    mov r13,rax

    xor r14d,r14d

    mov rdi,r12
    mov rsi,r13
    mov edx,1
    mov ecx,21
    call check_one_ring
    cmp rax,1
    ja .Lpattern
    add r14,rax

    mov rdi,r12
    mov rsi,r13
    mov edx,2
    mov ecx,21
    call check_one_ring
    cmp rax,1
    ja .Lpattern
    add r14,rax

    mov rdi,r12
    mov rsi,r13
    mov edx,3
    mov ecx,3
    call check_one_ring
    cmp rax,1
    ja .Lpattern
    add r14,rax

    cmp r14,3
    je .Lred
    test r14,r14
    je .Lgreen
    jmp .Lpattern

.Lred:
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
    mov edi,26
    syscall
.size _start,.-_start
