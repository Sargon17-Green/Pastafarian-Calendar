.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE08_DISCOVERY04_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE08_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE08_DISCOVERY04_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern arena_alloc
.extern bi_from_u64
.extern bi_eq_u64
.extern bi_cmp
.extern mutateStonesWrong
.extern monster_stone_mutation_route
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

.type require_row_u64,@function
require_row_u64:
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
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9

    mov rdi,qword ptr [r12]
    mov rsi,r13
    call bi_eq_u64
    test eax,eax
    je .Lrr_fail
    mov rdi,qword ptr [r12+8]
    mov rsi,r14
    call bi_eq_u64
    test eax,eax
    je .Lrr_fail
    mov rdi,qword ptr [r12+16]
    mov rsi,r15
    call bi_eq_u64
    test eax,eax
    je .Lrr_fail
    mov rdi,qword ptr [r12+24]
    mov rsi,qword ptr [rbp-48]
    call bi_eq_u64
    test eax,eax
    je .Lrr_fail
    mov rdi,qword ptr [r12+32]
    mov rsi,qword ptr [rbp-56]
    call bi_eq_u64
    test eax,eax
    je .Lrr_fail
    mov eax,1
    jmp .Lrr_done
.Lrr_fail:
    xor eax,eax
.Lrr_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_row_u64,.-require_row_u64

.type count_mismatches_with_oracle_row2,@function
count_mismatches_with_oracle_row2:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    call oracle_build_stones
    lea r13,[rax+40]
    xor r14d,r14d
    xor ecx,ecx
.Lcmp_loop:
    cmp rcx,5
    jae .Lcmp_done
    mov rdi,qword ptr [r12+rcx*8]
    mov rsi,qword ptr [r13+rcx*8]
    push rcx
    call bi_cmp
    pop rcx
    test eax,eax
    je .Lcmp_next
    inc r14
.Lcmp_next:
    inc rcx
    jmp .Lcmp_loop
.Lcmp_done:
    mov rax,r14
    pop r14
    pop r13
    pop r12
    leave
    ret
.size count_mismatches_with_oracle_row2,.-count_mismatches_with_oracle_row2

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    call make_seed
    mov r12,rax
    mov rdi,r12
    mov rsi,2
    call mutateStonesWrong
    cmp rax,r12
    jne .Lpattern

    mov rdi,r12
    mov rsi,378
    mov rdx,1434
    mov rcx,3780
    mov r8,9932
    mov r9,25047
    call require_row_u64
    test eax,eax
    je .Lpattern

    mov rdi,r12
    call count_mismatches_with_oracle_row2
    cmp rax,4
    jne .Lpattern

    call make_seed
    mov r13,rax
    mov rdi,r13
    mov rsi,2
    call monster_stone_mutation_route
    cmp rax,r13
    jne .Lpattern
    mov rdi,r13
    call count_mismatches_with_oracle_row2
    test rax,rax
    je .Lgreen
    cmp rax,4
    jne .Lpattern

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
    mov edi,8
    syscall
.size _start,.-_start
