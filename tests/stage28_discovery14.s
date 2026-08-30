.intel_syntax noprefix
.equ RING_FIRST,0
.equ RING_STEP,8

.section .rodata
red_token: .ascii "STAGE28_DISCOVERY14_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE28_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE28_DISCOVERY14_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern bi_add_u64
.extern bi_mul_abs
.extern bi_cmp
.extern legacy_remainder_M
.extern legacySelectionAssumingNLeM
.extern monster_wide_selection_route
.extern oracle_choose_rank_wide
.extern sauceWithOrderAt46Latch
.extern answerRingThroughPatchedNextBowl
.extern calendarDateSpaghetti
.global _start

.type compare_wide_family,@function
compare_wide_family:
    # rdi=ring, rsi=N. Ⲡreturn ⲡⲉ 1 ⲉϣϫⲉ ⲡshort-only route ϣⲟⲃⲉ ⲙⲛ ⲡsame-line oracle; 0 ⲉϣϫⲉ ⲛⲥⲉⲧⲱⲛ; -1 ⲛⲟⲩpattern ⲉϥϣⲟⲃⲉ.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lcwf_bad
    test r13,r13
    je .Lcwf_bad

    # Ⲡscar ⲛⲧⲟϥ: ⲡlegacy direct short-only call ⲛϥϯ ⲁⲛ ⲛⲟⲩrank ϩⲓ N>M_OLD.
    mov rdi,r12
    mov rsi,r13
    call legacySelectionAssumingNLeM
    test rax,rax
    jne .Lcwf_bad

    # Ⲡsame-line oracle ⲛwide ϯ ⲛⲟⲩrank ⲛⲧⲟϣ.
    mov rdi,r12
    mov rsi,r13
    call oracle_choose_rank_wide
    test rax,rax
    je .Lcwf_bad
    mov r14,rax

    # Ⲡroute ⲙⲡStage 28 ⲟⲩⲏϩ ⲉϥⲟ ⲛshort-only; ⲡStage 29 ⲛⲁϣⲓⲃⲉ ⲙⲡroute ⲙⲙⲁⲧⲉ.
    mov rdi,r12
    mov rsi,r13
    call monster_wide_selection_route
    test rax,rax
    je .Lcwf_mismatch
    mov r15,rax
    mov rdi,r15
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lcwf_mismatch
    xor eax,eax
    jmp .Lcwf_done
.Lcwf_mismatch:
    mov eax,1
    jmp .Lcwf_done
.Lcwf_bad:
    mov rax,-1
.Lcwf_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size compare_wide_family,.-compare_wide_family

.type _start,@function
_start:
    # Ⲡreal state-machine ⲙⲟⲩⲧⲉ ⲉⲡStage 28 handler ⲁⲩⲱ ⲛϥⲟⲩⲏϩ valid.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    # Ⲧⲁⲙⲓⲟ ⲙⲡFoundation sauce ⲙⲛ ⲟⲩanswer ring ⲛⲧⲉ bowl 1 / seal 1.
    mov rdi,-15055671
    mov rsi,-15055671
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Lpattern
    mov r12,rax
    mov rdi,r12
    mov esi,1
    mov edx,1
    call answerRingThroughPatchedNextBowl
    test rax,rax
    je .Lpattern
    mov r13,rax

    xor r14d,r14d

    # N = M_OLD + 1.
    lea rdi,[rip+legacy_remainder_M]
    mov esi,1
    call bi_add_u64
    test rax,rax
    je .Lpattern
    mov r15,rax
    mov rdi,r13
    mov rsi,r15
    call compare_wide_family
    cmp rax,1
    ja .Lpattern
    add r14,rax

    # N = M_OLD^2.
    lea rdi,[rip+legacy_remainder_M]
    lea rsi,[rip+legacy_remainder_M]
    call bi_mul_abs
    test rax,rax
    je .Lpattern
    mov r15,rax
    mov rdi,r13
    mov rsi,r15
    call compare_wide_family
    cmp rax,1
    ja .Lpattern
    add r14,rax

    # N = M_OLD^3.
    mov rdi,r15
    lea rsi,[rip+legacy_remainder_M]
    call bi_mul_abs
    test rax,rax
    je .Lpattern
    mov r15,rax
    mov rdi,r13
    mov rsi,r15
    call compare_wide_family
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
    mov edi,28
    syscall
.size _start,.-_start
