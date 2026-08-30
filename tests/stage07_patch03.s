.intel_syntax noprefix
.equ COUNTS_DISTANCE,16
.section .rodata
green_token: .ascii "STAGE07_PATCH03_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE07_PATCH03_FAIL\n"
fail_len = . - fail_token

.section .text
.extern bi_from_i64
.extern bi_eq_u64
.extern bi_cmp
.extern oldDistance
.extern distanceWithChronologicalScar
.extern monster_distance_route
.extern oracle_work_counts
.extern calendarDateSpaghetti
.global _start

.type one_case,@function
one_case:
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
    call bi_from_i64
    mov qword ptr [rbp-48],rax
    mov rdi,r13
    call bi_from_i64
    mov qword ptr [rbp-56],rax

    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call oldDistance
    mov rdi,rax
    mov rsi,r14
    call bi_eq_u64
    test eax,eax
    je .Loc_fail

    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call distanceWithChronologicalScar
    mov rdi,rax
    mov rsi,r15
    call bi_eq_u64
    test eax,eax
    je .Loc_fail

    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call monster_distance_route
    mov qword ptr [rbp-64],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,r15
    call bi_eq_u64
    test eax,eax
    je .Loc_fail

    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call oracle_work_counts
    mov rsi,qword ptr [rax+COUNTS_DISTANCE]
    mov rdi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jne .Loc_fail

    mov eax,1
    jmp .Loc_done
.Loc_fail:
    xor eax,eax
.Loc_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size one_case,.-one_case

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail

    mov rdi,-15055671
    mov rsi,-15055671
    xor edx,edx
    mov ecx,1
    call one_case
    test eax,eax
    je .Lfail

    mov rdi,-15055671
    mov rsi,-15055670
    mov edx,2
    mov ecx,2
    call one_case
    test eax,eax
    je .Lfail

    mov rdi,-15055670
    mov rsi,-15055669
    mov edx,2
    mov ecx,2
    call one_case
    test eax,eax
    je .Lfail

    mov rdi,-15055671
    mov rsi,-15055669
    mov edx,4
    mov ecx,3
    call one_case
    test eax,eax
    je .Lfail

    mov rdi,-15055672
    mov rsi,-15055670
    mov edx,1
    mov ecx,3
    call one_case
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
    mov edi,7
    syscall
.size _start,.-_start
