.intel_syntax noprefix
.equ RING_FIRST,0
.equ RING_STEP,8
.equ ORING_FIRST,0
.equ ORING_STEP,8
.section .rodata
ok_token: .ascii "STAGE55_SHORT_EDGES_GREEN\n"
ok_len = . - ok_token
fail_token: .ascii "STAGE55_SHORT_EDGES_FAIL\n"
fail_len = . - fail_token
.section .text
.extern bi_from_i64
.extern bi_from_u64
.extern bi_clone
.extern bi_cmp
.extern sauceWithOrderAt46Latch
.extern answerRingThroughPatchedNextBowl
.extern selectionPatch14
.extern oracle_sauce
.extern oracle_ask_bowl
.extern oracle_choose_rank_short
.extern legacy_remainder_M
.global _start

.type check_n,@function
check_n:
    # rdi=production ring, rsi=oracle ring, rdx=N.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rdi,r12
    mov rsi,r14
    call selectionPatch14
    test rax,rax
    je .Lcn_fail
    mov r12,rax
    mov rdi,r13
    mov rsi,r14
    call oracle_choose_rank_short
    test rax,rax
    je .Lcn_fail
    mov rdi,r12
    mov rsi,rax
    call bi_cmp
    test eax,eax
    jne .Lcn_fail
    mov eax,1
    jmp .Lcn_done
.Lcn_fail:
    xor eax,eax
.Lcn_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size check_n,.-check_n

.type check_ring,@function
check_ring:
    # rdi=production sauce, rsi=oracle sauce, rdx=bowl, rcx=seal.
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
    je .Lcr_fail
    mov qword ptr [rbp-40],rax
    mov rdi,r13
    mov rsi,r14
    mov rdx,r15
    call oracle_ask_bowl
    test rax,rax
    je .Lcr_fail
    mov qword ptr [rbp-48],rax
    mov rdx,qword ptr [rbp-40]
    mov rdi,qword ptr [rdx+RING_FIRST]
    mov rsi,qword ptr [rax+ORING_FIRST]
    call bi_cmp
    test eax,eax
    jne .Lcr_fail
    mov rdx,qword ptr [rbp-40]
    mov rax,qword ptr [rdx+RING_STEP]
    mov rdx,qword ptr [rbp-48]
    cmp rax,qword ptr [rdx+ORING_STEP]
    jne .Lcr_fail

    mov rdi,1
    call bi_from_u64
    mov r14,rax
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-48]
    mov rdx,r14
    call check_n
    test eax,eax
    je .Lcr_fail

    mov rdi,7
    call bi_from_u64
    mov r14,rax
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-48]
    mov rdx,r14
    call check_n
    test eax,eax
    je .Lcr_fail

    lea rdi,[rip+legacy_remainder_M]
    call bi_clone
    mov r14,rax
    mov rdi,qword ptr [rbp-40]
    mov rsi,qword ptr [rbp-48]
    mov rdx,r14
    call check_n
    test eax,eax
    je .Lcr_fail
    mov eax,1
    jmp .Lcr_done
.Lcr_fail:
    xor eax,eax
.Lcr_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size check_ring,.-check_ring

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Lfail
    mov r12,rax
    mov rdi,-15055671
    call bi_from_i64
    mov r13,rax
    mov rdi,-15055671
    call bi_from_i64
    mov rdi,r13
    mov rsi,rax
    call oracle_sauce
    test rax,rax
    je .Lfail
    mov r13,rax

    # Ⲛring ⲙⲡbowl 1 ⲙⲛ 2 ⲥⲉϯ ⲛⲛdirection ⲙⲙⲛⲧⲣⲉ ⲙⲡshort path.
    mov rdi,r12
    mov rsi,r13
    mov edx,1
    mov ecx,21
    call check_ring
    test eax,eax
    je .Lfail
    mov rdi,r12
    mov rsi,r13
    mov edx,2
    mov ecx,21
    call check_ring
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
    mov edi,55
    syscall
.size _start,.-_start
