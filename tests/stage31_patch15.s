.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE31_PATCH15_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE31_PATCH15_FAIL\n"
fail_len = . - fail_token

.section .text
.extern bi_from_i64
.extern bi_cmp
.extern oldGateQuestionDay
.extern legacyGateQuestionDayFromSignedStepWrong
.extern gateQuestionDayPatch15
.extern monster_gate_question_day_route
.extern monster_context_new
.extern monster_stage30_legacy_gate_question_handler
.extern monster_stage31_gate_question_patch_handler
.global _start

.equ CTX_STAGE30_SIGNED_STEP,1224
.equ CTX_STAGE30_ABS_STEP,1232
.equ CTX_STAGE30_LEGACY_RESULT,1240
.equ CTX_STAGE30_ROUTE_RESULT,1248
.equ CTX_STAGE30_LEGACY_SEEN,1256
.equ CTX_STAGE30_ROUTE_SEEN,1264
.equ CTX_STAGE31_PATCHED_RESULT,1272
.equ CTX_STAGE31_PATCH_SEEN,1280

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

.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8

    mov rdi,-10
    call bi_from_i64
    test rax,rax
    je .Lrls_fail
    mov rdi,rax
    call legacyGateQuestionDayFromSignedStepWrong
    test rax,rax
    je .Lrls_fail
    mov rdi,rax
    mov rsi,-15055661
    call big_eq_i64
    test eax,eax
    je .Lrls_fail

    mov edi,10
    call bi_from_i64
    test rax,rax
    je .Lrls_fail
    mov rdi,rax
    call oldGateQuestionDay
    test rax,rax
    je .Lrls_fail
    mov rdi,rax
    mov rsi,-15055661
    call big_eq_i64
    test eax,eax
    je .Lrls_fail

    mov eax,1
    jmp .Lrls_done
.Lrls_fail:
    xor eax,eax
.Lrls_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type patch_case,@function
patch_case:
    # rdi=signed step, rsi=expected day.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call bi_from_i64
    test rax,rax
    je .Lpc_fail
    mov r12,rax

    mov rdi,r12
    call gateQuestionDayPatch15
    test rax,rax
    je .Lpc_fail
    mov rdi,rax
    mov rsi,r13
    call big_eq_i64
    test eax,eax
    je .Lpc_fail

    mov rdi,r12
    call monster_gate_question_day_route
    test rax,rax
    je .Lpc_fail
    mov rdi,rax
    mov rsi,r13
    call big_eq_i64
    test eax,eax
    je .Lpc_fail

    mov eax,1
    jmp .Lpc_done
.Lpc_fail:
    xor eax,eax
.Lpc_done:
    pop r13
    pop r12
    leave
    ret
.size patch_case,.-patch_case

.type require_cases,@function
require_cases:
    push rbp
    mov rbp,rsp
    mov rdi,-1
    mov rsi,-15055672
    call patch_case
    test eax,eax
    je .Lrc_fail
    mov rdi,-2
    mov rsi,-15055673
    call patch_case
    test eax,eax
    je .Lrc_fail
    mov rdi,-10
    mov rsi,-15055681
    call patch_case
    test eax,eax
    je .Lrc_fail
    xor edi,edi
    mov rsi,-15055671
    call patch_case
    test eax,eax
    je .Lrc_fail
    mov edi,1
    mov rsi,-15055670
    call patch_case
    test eax,eax
    je .Lrc_fail
    mov eax,1
    leave
    ret
.Lrc_fail:
    xor eax,eax
    leave
    ret
.size require_cases,.-require_cases

.type require_context_trace,@function
require_context_trace:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055681
    mov rsi,-15055681
    call monster_context_new
    test rax,rax
    je .Lrct_fail
    mov r12,rax
    mov rdi,r12
    call monster_stage30_legacy_gate_question_handler
    test eax,eax
    je .Lrct_fail
    mov rdi,r12
    call monster_stage31_gate_question_patch_handler
    test eax,eax
    je .Lrct_fail

    mov rdi,qword ptr [r12+CTX_STAGE30_SIGNED_STEP]
    mov rsi,-10
    call big_eq_i64
    test eax,eax
    je .Lrct_fail
    mov rdi,qword ptr [r12+CTX_STAGE30_ABS_STEP]
    mov rsi,10
    call big_eq_i64
    test eax,eax
    je .Lrct_fail
    mov rdi,qword ptr [r12+CTX_STAGE30_LEGACY_RESULT]
    mov rsi,-15055661
    call big_eq_i64
    test eax,eax
    je .Lrct_fail
    mov rdi,qword ptr [r12+CTX_STAGE30_ROUTE_RESULT]
    mov rsi,-15055681
    call big_eq_i64
    test eax,eax
    je .Lrct_fail
    mov rdi,qword ptr [r12+CTX_STAGE31_PATCHED_RESULT]
    mov rsi,-15055681
    call big_eq_i64
    test eax,eax
    je .Lrct_fail

    cmp qword ptr [r12+CTX_STAGE30_LEGACY_SEEN],1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE30_ROUTE_SEEN],1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE31_PATCH_SEEN],1
    jne .Lrct_fail

    mov eax,1
    jmp .Lrct_done
.Lrct_fail:
    xor eax,eax
.Lrct_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_context_trace,.-require_context_trace

.type _start,@function
_start:
    call require_legacy_scar
    test eax,eax
    je .Lfail
    call require_cases
    test eax,eax
    je .Lfail
    call require_context_trace
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
    mov edi,31
    syscall
.size _start,.-_start
