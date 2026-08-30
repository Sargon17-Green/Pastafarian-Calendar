.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE05_PATCH02_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE05_PATCH02_FAIL\n"
fail_len = . - fail_token

.section .text
.extern bi_from_i64
.extern bi_eq_u64
.extern bi_cmp
.extern oldDayTag
.extern dayTagWithFoundationScar
.extern monster_daytag_route
.extern oracle_day_count
.extern calendarDateSpaghetti
.global _start

.type require_route_equals_oracle,@function
require_route_equals_oracle:
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
    sete al
    movzx eax,al
    pop r13
    pop r12
    leave
    ret
.size require_route_equals_oracle,.-require_route_equals_oracle

.type require_scar_value,@function
require_scar_value:
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
.size require_scar_value,.-require_scar_value

.type require_patch_value,@function
require_patch_value:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rsi
    call dayTagWithFoundationScar
    mov rdi,rax
    mov rsi,r12
    call bi_eq_u64
    pop r12
    leave
    ret
.size require_patch_value,.-require_patch_value

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail

    mov rdi,-15055672
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    mov rsi,2
    call require_scar_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    mov rsi,2
    call require_patch_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    call require_route_equals_oracle
    test eax,eax
    je .Lfail

    mov rdi,-15055671
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    xor esi,esi
    call require_scar_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    mov rsi,1
    call require_patch_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    call require_route_equals_oracle
    test eax,eax
    je .Lfail

    mov rdi,-15055670
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    mov rsi,2
    call require_scar_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    mov rsi,3
    call require_patch_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    call require_route_equals_oracle
    test eax,eax
    je .Lfail

    mov rdi,-15055669
    call bi_from_i64
    mov r13,rax
    mov rdi,r13
    mov rsi,4
    call require_scar_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    mov rsi,5
    call require_patch_value
    test eax,eax
    je .Lfail
    mov rdi,r13
    call require_route_equals_oracle
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
    mov edi,5
    syscall
.size _start,.-_start
