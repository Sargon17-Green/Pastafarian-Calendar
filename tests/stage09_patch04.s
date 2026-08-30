.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE09_PATCH04_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE09_PATCH04_FAIL\n"
fail_len = . - fail_token

.section .text
.extern arena_alloc
.extern bi_from_u64
.extern bi_eq_u64
.extern bi_cmp
.extern mutateStonesWrong
.extern stonePatch
.extern monster_stone_mutation_route
.extern getStoneTableThroughLegacyBuilder
.extern oracle_build_stones
.extern calendarDateSpaghetti
.global _start

.type make_seed,@function
make_seed:
    push rbp
    mov rbp,rsp
    push r12
    mov rdi,40
    call arena_alloc
    mov r12,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r12],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r12+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r12+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r12+32],rax
    mov rax,r12
    pop r12
    leave
    ret
.size make_seed,.-make_seed

.type require_seed_unchanged,@function
require_seed_unchanged:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    mov rdi,qword ptr [r12]
    mov rsi,17
    call bi_eq_u64
    test eax,eax
    je .Lrsu_fail
    mov rdi,qword ptr [r12+8]
    mov rsi,29
    call bi_eq_u64
    test eax,eax
    je .Lrsu_fail
    mov rdi,qword ptr [r12+16]
    mov rsi,43
    call bi_eq_u64
    test eax,eax
    je .Lrsu_fail
    mov rdi,qword ptr [r12+24]
    mov rsi,71
    call bi_eq_u64
    test eax,eax
    je .Lrsu_fail
    mov rdi,qword ptr [r12+32]
    mov rsi,101
    call bi_eq_u64
    test eax,eax
    je .Lrsu_fail
    mov eax,1
    jmp .Lrsu_done
.Lrsu_fail:
    xor eax,eax
.Lrsu_done:
    pop r12
    leave
    ret
.size require_seed_unchanged,.-require_seed_unchanged

.type require_row2_normative,@function
require_row2_normative:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    mov rdi,qword ptr [r12]
    mov rsi,378
    call bi_eq_u64
    test eax,eax
    je .Lr2n_fail
    mov rdi,qword ptr [r12+8]
    mov rsi,1073
    call bi_eq_u64
    test eax,eax
    je .Lr2n_fail
    mov rdi,qword ptr [r12+16]
    mov rsi,2375
    call bi_eq_u64
    test eax,eax
    je .Lr2n_fail
    mov rdi,qword ptr [r12+24]
    mov rsi,6195
    call bi_eq_u64
    test eax,eax
    je .Lr2n_fail
    mov rdi,qword ptr [r12+32]
    mov rsi,10493
    call bi_eq_u64
    test eax,eax
    je .Lr2n_fail
    mov eax,1
    jmp .Lr2n_done
.Lr2n_fail:
    xor eax,eax
.Lr2n_done:
    pop r12
    leave
    ret
.size require_row2_normative,.-require_row2_normative

.type require_row2_legacy_scar,@function
require_row2_legacy_scar:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    mov rdi,qword ptr [r12]
    mov rsi,378
    call bi_eq_u64
    test eax,eax
    je .Lr2l_fail
    mov rdi,qword ptr [r12+8]
    mov rsi,1434
    call bi_eq_u64
    test eax,eax
    je .Lr2l_fail
    mov rdi,qword ptr [r12+16]
    mov rsi,3780
    call bi_eq_u64
    test eax,eax
    je .Lr2l_fail
    mov rdi,qword ptr [r12+24]
    mov rsi,9932
    call bi_eq_u64
    test eax,eax
    je .Lr2l_fail
    mov rdi,qword ptr [r12+32]
    mov rsi,25047
    call bi_eq_u64
    test eax,eax
    je .Lr2l_fail
    mov eax,1
    jmp .Lr2l_done
.Lr2l_fail:
    xor eax,eax
.Lr2l_done:
    pop r12
    leave
    ret
.size require_row2_legacy_scar,.-require_row2_legacy_scar

.type compare_full_tables,@function
compare_full_tables:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
.Lcft_loop:
    cmp r14,230
    jae .Lcft_ok
    mov rdi,qword ptr [r12+r14*8]
    mov rsi,qword ptr [r13+r14*8]
    call bi_cmp
    test eax,eax
    jne .Lcft_fail
    inc r14
    jmp .Lcft_loop
.Lcft_ok:
    mov eax,1
    jmp .Lcft_done
.Lcft_fail:
    xor eax,eax
.Lcft_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size compare_full_tables,.-compare_full_tables

.type _start,@function
_start:
    # Ⲡlegacy ⲟⲩⲏϩ ⲉϥϯ ⲡgarbage ⲛStage 8.
    call make_seed
    mov r12,rax
    mov rdi,r12
    mov rsi,2
    call mutateStonesWrong
    test rax,rax
    je .Lfail
    mov rdi,rax
    call require_row2_legacy_scar
    test eax,eax
    je .Lfail

    # ⲠstonePatch ⲙⲟⲩⲧⲉ ⲉⲡlegacy ϩⲓ clone ⲁⲩⲱ ⲛϥⲕⲱ ⲛ5 ⲛⲧⲓⲙⲏ ⲉⲃⲟⲗ ϩⲙⲡsnapshot.
    call make_seed
    mov r13,rax
    mov rdi,r13
    mov rsi,2
    call stonePatch
    test rax,rax
    je .Lfail
    mov r14,rax
    cmp r14,r13
    je .Lfail
    mov rdi,r13
    call require_seed_unchanged
    test eax,eax
    je .Lfail
    mov rdi,r14
    call require_row2_normative
    test eax,eax
    je .Lfail

    # Ⲡroute ⲙⲡⲙⲟⲛⲥⲧⲉⲣ ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡwrapper ⲙⲡStage 9.
    call make_seed
    mov r15,rax
    mov rdi,r15
    mov rsi,2
    call monster_stone_mutation_route
    test rax,rax
    je .Lfail
    mov rdi,rax
    call require_row2_normative
    test eax,eax
    je .Lfail

    # Ⲡbuilder ⲛ46 ⲛrows ⲧⲱⲛ ⲙⲛ ⲡoracle ⲛⲟⲩⲱⲧ ϩⲓ 230 ⲛBigInt.
    call getStoneTableThroughLegacyBuilder
    test rax,rax
    je .Lfail
    mov r12,rax
    call oracle_build_stones
    test rax,rax
    je .Lfail
    mov rdi,r12
    mov rsi,rax
    call compare_full_tables
    test eax,eax
    je .Lfail

    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
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
    mov edi,9
    syscall
.size _start,.-_start
