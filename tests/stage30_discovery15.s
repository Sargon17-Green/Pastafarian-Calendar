.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE30_DISCOVERY15_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE30_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE30_DISCOVERY15_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern bi_from_i64
.extern bi_cmp
.extern oldGateQuestionDay
.extern legacyGateQuestionDayFromSignedStepWrong
.extern monster_gate_question_day_route
.extern monster_context_new
.extern monster_stage30_legacy_gate_question_handler
.global _start

.equ CTX_STAGE30_SIGNED_STEP,1224
.equ CTX_STAGE30_ABS_STEP,1232
.equ CTX_STAGE30_LEGACY_RESULT,1240
.equ CTX_STAGE30_ROUTE_RESULT,1248
.equ CTX_STAGE30_LEGACY_SEEN,1256
.equ CTX_STAGE30_ROUTE_SEEN,1264

.type big_eq_i64,@function
big_eq_i64:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lbei_no
    mov rdi,r13
    call bi_from_i64
    test rax,rax
    je .Lbei_no
    mov rdi,r12
    mov rsi,rax
    call bi_cmp
    test eax,eax
    sete al
    movzx eax,al
    jmp .Lbei_done
.Lbei_no:
    xor eax,eax
.Lbei_done:
    pop r13
    pop r12
    leave
    ret
.size big_eq_i64,.-big_eq_i64

.type require_old_scar,@function
require_old_scar:
    push rbp
    mov rbp,rsp
    push r12

    mov edi,1
    call bi_from_i64
    mov rdi,rax
    call oldGateQuestionDay
    mov rdi,rax
    mov rsi,-15055670
    call big_eq_i64
    test eax,eax
    je .Lros_fail

    mov edi,2
    call bi_from_i64
    mov rdi,rax
    call oldGateQuestionDay
    mov rdi,rax
    mov rsi,-15055669
    call big_eq_i64
    test eax,eax
    je .Lros_fail

    mov edi,10
    call bi_from_i64
    mov rdi,rax
    call oldGateQuestionDay
    mov rdi,rax
    mov rsi,-15055661
    call big_eq_i64
    test eax,eax
    je .Lros_fail

    xor edi,edi
    call bi_from_i64
    mov rdi,rax
    call oldGateQuestionDay
    mov rdi,rax
    mov rsi,-15055671
    call big_eq_i64
    test eax,eax
    je .Lros_fail

    mov eax,1
    jmp .Lros_done
.Lros_fail:
    xor eax,eax
.Lros_done:
    pop r12
    leave
    ret
.size require_old_scar,.-require_old_scar

.type route_case,@function
route_case:
    # rdi=signed step, rsi=expected day; return 1 mismatch, 0 match, -1 internal.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call bi_from_i64
    test rax,rax
    je .Lrc_bad
    mov rdi,rax
    call monster_gate_question_day_route
    test rax,rax
    je .Lrc_bad
    mov rdi,rax
    mov rsi,r13
    call big_eq_i64
    xor eax,1
    jmp .Lrc_done
.Lrc_bad:
    mov rax,-1
.Lrc_done:
    pop r13
    pop r12
    leave
    ret
.size route_case,.-route_case

.type count_route_mismatches,@function
count_route_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    xor r12d,r12d

    mov rdi,-1
    mov rsi,-15055672
    call route_case
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov rdi,-2
    mov rsi,-15055673
    call route_case
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov rdi,-10
    mov rsi,-15055681
    call route_case
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov rdi,1
    mov rsi,-15055670
    call route_case
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    xor edi,edi
    mov rsi,-15055671
    call route_case
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov rax,r12
    jmp .Lcrm_done
.Lcrm_bad:
    mov rax,-1
.Lcrm_done:
    pop r12
    leave
    ret
.size count_route_mismatches,.-count_route_mismatches

.type require_handler_scar,@function
require_handler_scar:
    push rbp
    mov rbp,rsp
    push r12
    mov rdi,-15055681
    mov rsi,-15055681
    call monster_context_new
    test rax,rax
    je .Lrhs_fail
    mov r12,rax
    mov rdi,r12
    call monster_stage30_legacy_gate_question_handler
    test eax,eax
    je .Lrhs_fail

    mov rdi,qword ptr [r12+CTX_STAGE30_SIGNED_STEP]
    mov rsi,-10
    call big_eq_i64
    test eax,eax
    je .Lrhs_fail

    mov rdi,qword ptr [r12+CTX_STAGE30_ABS_STEP]
    mov rsi,10
    call big_eq_i64
    test eax,eax
    je .Lrhs_fail

    mov rdi,qword ptr [r12+CTX_STAGE30_LEGACY_RESULT]
    mov rsi,-15055661
    call big_eq_i64
    test eax,eax
    je .Lrhs_fail

    cmp qword ptr [r12+CTX_STAGE30_LEGACY_SEEN],1
    jne .Lrhs_fail
    cmp qword ptr [r12+CTX_STAGE30_ROUTE_SEEN],1
    jne .Lrhs_fail

    mov eax,1
    jmp .Lrhs_done
.Lrhs_fail:
    xor eax,eax
.Lrhs_done:
    pop r12
    leave
    ret
.size require_handler_scar,.-require_handler_scar

.type _start,@function
_start:
    call require_old_scar
    test eax,eax
    je .Lpattern

    call require_handler_scar
    test eax,eax
    je .Lpattern

    call count_route_mismatches
    cmp rax,3
    je .Lred
    test rax,rax
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
    mov edi,30
    syscall
.size _start,.-_start
