.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE04_DISCOVERY02_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE04_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE04_DISCOVERY02_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern bi_from_i64
.extern bi_eq_u64
.extern bi_cmp
.extern oldDayTag
.extern monster_daytag_route
.extern oracle_day_count
.extern calendarDateSpaghetti
.global _start

.type compare_route_to_oracle,@function
compare_route_to_oracle:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov rdi,r12
    call monster_daytag_route
    mov r13,rax
    mov rdi,r12
    call oracle_day_count
    mov rsi,rax
    mov rdi,r13
    call bi_cmp
    test eax,eax
    setne al
    movzx eax,al
    pop r13
    pop r12
    leave
    ret
.size compare_route_to_oracle,.-compare_route_to_oracle

.type require_old_value,@function
require_old_value:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rsi
    call oldDayTag
    mov rdi,rax
    mov rsi,r12
    call bi_eq_u64
    pop r12
    leave
    ret
.size require_old_value,.-require_old_value

.type _start,@function
_start:
    xor r12d,r12d

    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    mov rdi,-15055672
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    mov rsi,2
    call require_old_value
    test eax,eax
    je .Lpattern
    mov rdi,r13
    call compare_route_to_oracle
    test eax,eax
    je .Lfminus_done
    inc r12
.Lfminus_done:

    mov rdi,-15055671
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    xor esi,esi
    call require_old_value
    test eax,eax
    je .Lpattern
    mov rdi,r13
    call compare_route_to_oracle
    test eax,eax
    je .Lfoundation_done
    inc r12
.Lfoundation_done:

    mov rdi,-15055670
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    mov rsi,2
    call require_old_value
    test eax,eax
    je .Lpattern
    mov rdi,r13
    call compare_route_to_oracle
    test eax,eax
    je .Lfplus1_done
    inc r12
.Lfplus1_done:

    mov rdi,-15055669
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    mov rsi,4
    call require_old_value
    test eax,eax
    je .Lpattern
    mov rdi,r13
    call compare_route_to_oracle
    test eax,eax
    je .Lfplus2_done
    inc r12
.Lfplus2_done:

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
    mov edi,4
    syscall
.size _start,.-_start
