.intel_syntax noprefix
.equ COUNTS_DISTANCE,16
.section .rodata
red_token: .ascii "STAGE06_DISCOVERY03_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE06_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE06_DISCOVERY03_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern bi_from_i64
.extern bi_eq_u64
.extern bi_cmp
.extern oldDistance
.extern monster_distance_route
.extern oracle_work_counts
.extern calendarDateSpaghetti
.global _start

.type require_old_distance_value,@function
require_old_distance_value:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdx
    call oldDistance
    mov rdi,rax
    mov rsi,r12
    call bi_eq_u64
    pop r13
    pop r12
    leave
    ret
.size require_old_distance_value,.-require_old_distance_value

.type compare_route_to_oracle_distance,@function
compare_route_to_oracle_distance:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    mov rsi,r13
    call monster_distance_route
    mov r14,rax
    mov rdi,r12
    mov rsi,r13
    call oracle_work_counts
    mov rsi,qword ptr [rax+COUNTS_DISTANCE]
    mov rdi,r14
    call bi_cmp
    test eax,eax
    setne al
    movzx eax,al
    pop r14
    pop r13
    pop r12
    leave
    ret
.size compare_route_to_oracle_distance,.-compare_route_to_oracle_distance

.type one_case,@function
one_case:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rdi,r12
    call bi_from_i64
    mov r15,rax
    mov rdi,r13
    call bi_from_i64
    mov r13,rax
    mov rdi,r15
    mov rsi,r13
    mov rdx,r14
    call require_old_distance_value
    test eax,eax
    je .Loc_bad
    mov rdi,r15
    mov rsi,r13
    call compare_route_to_oracle_distance
    jmp .Loc_done
.Loc_bad:
    mov eax,-1
.Loc_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size one_case,.-one_case

.type _start,@function
_start:
    xor r12d,r12d

    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    mov rdi,-15055671
    mov rsi,-15055671
    xor edx,edx
    call one_case
    cmp eax,-1
    je .Lpattern
    add r12,rax

    mov rdi,-15055671
    mov rsi,-15055670
    mov edx,2
    call one_case
    cmp eax,-1
    je .Lpattern
    add r12,rax

    mov rdi,-15055670
    mov rsi,-15055669
    mov edx,2
    call one_case
    cmp eax,-1
    je .Lpattern
    add r12,rax

    mov rdi,-15055671
    mov rsi,-15055669
    mov edx,4
    call one_case
    cmp eax,-1
    je .Lpattern
    add r12,rax

    mov rdi,-15055672
    mov rsi,-15055670
    mov edx,1
    call one_case
    cmp eax,-1
    je .Lpattern
    add r12,rax

    test r12,r12
    je .Lgreen
    cmp r12,3
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
    mov edi,6
    syscall
.size _start,.-_start
