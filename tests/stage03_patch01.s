.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE03_PATCH01_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE03_PATCH01_FAIL\n"
fail_len = . - fail_token

.section .text
.extern legacy_remainder_M
.extern oldRemainder
.extern savePatch
.extern monster_remainder_route
.extern oracle_SAVE
.extern bi_mul_u64
.extern bi_add_u64
.extern bi_cmp
.extern bi_eq_u64
.extern bi_is_zero
.global _start

.type check_patch_against_oracle,@function
check_patch_against_oracle:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call savePatch
    mov r13,rax
    mov rdi,r12
    call oracle_SAVE
    mov rsi,rax
    mov rdi,r13
    call bi_cmp
    test eax,eax
    sete al
    movzx eax,al
    pop r13
    pop r12
    leave
    ret
.size check_patch_against_oracle,.-check_patch_against_oracle

.type _start,@function
_start:
    lea rdi,[rip+legacy_remainder_M]
    call oldRemainder
    mov rdi,rax
    call bi_is_zero
    test eax,eax
    je .Lfail

    lea rdi,[rip+legacy_remainder_M]
    call check_patch_against_oracle
    test eax,eax
    je .Lfail

    lea rdi,[rip+legacy_remainder_M]
    call monster_remainder_route
    mov rdi,rax
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    jne .Lfail

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,2
    call bi_mul_u64
    mov r12,rax
    mov rdi,r12
    call check_patch_against_oracle
    test eax,eax
    je .Lfail
    mov rdi,r12
    call monster_remainder_route
    mov rdi,rax
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    jne .Lfail

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,3
    call bi_mul_u64
    mov r12,rax
    mov rdi,r12
    call check_patch_against_oracle
    test eax,eax
    je .Lfail
    mov rdi,r12
    call monster_remainder_route
    mov rdi,rax
    lea rsi,[rip+legacy_remainder_M]
    call bi_cmp
    test eax,eax
    jne .Lfail

    lea rdi,[rip+legacy_remainder_M]
    mov rsi,1
    call bi_add_u64
    mov r12,rax
    mov rdi,r12
    call check_patch_against_oracle
    test eax,eax
    je .Lfail
    mov rdi,r12
    call monster_remainder_route
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
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
    mov edi,3
    syscall
.size _start,.-_start
