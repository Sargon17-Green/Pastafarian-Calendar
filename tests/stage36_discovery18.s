.intel_syntax noprefix
.equ CTX_STAGE36_ANCHOR,1448
.equ CTX_STAGE36_TARGET_DAY,1456
.equ CTX_STAGE36_DELTA_FROM_FIRST,1464
.equ CTX_STAGE36_LEGACY_GUESS,1472
.equ CTX_STAGE36_ROUTE_GUESS,1480
.equ CTX_STAGE36_LEGACY_SEEN,1488
.equ CTX_STAGE36_ROUTE_SEEN,1496
.equ CTX_STAGE36_GUESS_USED_AS_SEMANTIC,1504
.equ CTX_STAGE36_ANCHOR_LENGTH,1512
.equ YJ_NUMBER,0
.equ YJ_OPEN_DAY,8
.equ YJ_FIRST_DAY,16
.equ YJ_CLOSE_DAY,24

.section .rodata
red_token: .ascii "STAGE36_DISCOVERY18_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE36_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE36_DISCOVERY18_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern oldJumpGuess
.extern monster_year_jump_route
.extern monster_stage36_legacy_year_jump_handler
.extern bi_add_u64
.extern bi_sub
.extern bi_eq_u64
.extern bi_cmp

# Ⲡanchor ⲙⲡtest ⲡⲉ ⲡsame-line Year-5000 probe ⲉϥⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡPATCH 17 selected candidate.
.type require_anchor_shape,@function
require_anchor_shape:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    mov r12,rax
    test r12,r12
    je .Lras_no
    mov rdi,qword ptr [r12+YJ_NUMBER]
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lras_no
    mov rdi,qword ptr [r12+YJ_OPEN_DAY]
    mov esi,1
    call bi_add_u64
    mov r13,rax
    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_FIRST_DAY]
    call bi_cmp
    test eax,eax
    jne .Lras_no
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    mov esi,490
    call bi_eq_u64
    test eax,eax
    je .Lras_no
    mov rax,r12
    jmp .Lras_done
.Lras_no:
    xor eax,eax
.Lras_done:
    add rsp,8
    pop r13
    pop r12
    leave
    ret
.size require_anchor_shape,.-require_anchor_shape

# rdi=anchor, rsi=target, rdx=expected positive year number. return 0 match, 1 mismatch, -1 malformed.
.type route_case_mismatch,@function
route_case_mismatch:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,8
    mov r12,rdx
    call monster_year_jump_route
    test rax,rax
    je .Lrcm_bad
    mov rdi,rax
    mov rsi,r12
    call bi_eq_u64
    xor eax,1
    movzx eax,al
    jmp .Lrcm_done
.Lrcm_bad:
    mov rax,-1
.Lrcm_done:
    add rsp,8
    pop r13
    pop r12
    leave
    ret
.size route_case_mismatch,.-route_case_mismatch

# Ⲡlegacy scar ⲙⲟⲟϣⲉ ⲕⲁⲧⲁ floor((target-first)/365), ⲙⲛ negative floor ⲉϥⲧⲱⲛ.
.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    call require_anchor_shape
    mov r12,rax
    test r12,r12
    je .Lrls_no

    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call oldJumpGuess
    mov rdi,rax
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrls_no

    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_FIRST_DAY]
    call oldJumpGuess
    mov rdi,rax
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrls_no

    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,364
    call bi_add_u64
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call oldJumpGuess
    mov rdi,rax
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrls_no

    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    call oldJumpGuess
    mov rdi,rax
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lrls_no

    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    call oldJumpGuess
    mov rdi,rax
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lrls_no

    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov esi,1
    call bi_add_u64
    mov r15,rax
    mov rdi,r12
    mov rsi,r15
    call oldJumpGuess
    mov rdi,rax
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lrls_no

    mov eax,1
    jmp .Lrls_done
.Lrls_no:
    xor eax,eax
.Lrls_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

# Ⲡreference ⲙⲡtest ϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡinterval ownership ⲉⲧⲟⲩⲟⲛϩ: (open,close] ⲟ ⲛYear 5000, close+1 ⲡⲉ ⲡfirst day ⲙⲡ5001.
.type count_route_mismatches,@function
count_route_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    call require_anchor_shape
    mov r12,rax
    test r12,r12
    je .Lcrm_pattern
    xor r13d,r13d

    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    mov edx,4999
    call route_case_mismatch
    cmp rax,-1
    je .Lcrm_pattern
    add r13,rax

    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_FIRST_DAY]
    mov edx,5000
    call route_case_mismatch
    cmp rax,-1
    je .Lcrm_pattern
    add r13,rax

    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,364
    call bi_add_u64
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    mov edx,5000
    call route_case_mismatch
    cmp rax,-1
    je .Lcrm_pattern
    add r13,rax

    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    mov edx,5000
    call route_case_mismatch
    cmp rax,-1
    je .Lcrm_pattern
    add r13,rax

    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    mov edx,5000
    call route_case_mismatch
    cmp rax,-1
    je .Lcrm_pattern
    add r13,rax

    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov esi,1
    call bi_add_u64
    mov r15,rax
    mov rdi,r12
    mov rsi,r15
    mov edx,5001
    call route_case_mismatch
    cmp rax,-1
    je .Lcrm_pattern
    add r13,rax

    mov rax,r13
    jmp .Lcrm_done
.Lcrm_pattern:
    mov rax,-1
.Lcrm_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size count_route_mismatches,.-count_route_mismatches

.type count_context_mismatches,@function
count_context_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    mov r12,rax
    test r12,r12
    je .Lccm_pattern
    mov rdi,r12
    call monster_stage36_legacy_year_jump_handler
    cmp eax,1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE36_ANCHOR_LENGTH],490
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE36_LEGACY_SEEN],1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE36_ROUTE_SEEN],1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE36_GUESS_USED_AS_SEMANTIC],1
    jne .Lccm_pattern
    mov rdi,qword ptr [r12+CTX_STAGE36_DELTA_FROM_FIRST]
    mov esi,365
    call bi_eq_u64
    test eax,eax
    je .Lccm_pattern
    mov rdi,qword ptr [r12+CTX_STAGE36_LEGACY_GUESS]
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lccm_pattern
    mov rdi,qword ptr [r12+CTX_STAGE36_ROUTE_GUESS]
    mov esi,5000
    call bi_eq_u64
    xor eax,1
    movzx eax,al
    jmp .Lccm_done
.Lccm_pattern:
    mov rax,-1
.Lccm_done:
    add rsp,8
    pop r12
    leave
    ret
.size count_context_mismatches,.-count_context_mismatches

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call require_legacy_scar
    test eax,eax
    je .Lpattern
    call count_route_mismatches
    cmp rax,-1
    je .Lpattern
    mov r12,rax
    call count_context_mismatches
    cmp rax,-1
    je .Lpattern
    add r12,rax
    cmp r12,3
    je .Lred
    test r12,r12
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
    mov edi,36
    syscall
.size _start,.-_start
