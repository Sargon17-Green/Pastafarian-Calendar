.intel_syntax noprefix
.equ CTX_CALCULATION_DAY,0
.equ CTX_TARGET_DAY,8
.equ CTX_PHASE,16
.equ CTX_SUBPHASE,24
.equ CTX_MODE,32
.equ CTX_STATUS,40
.equ CTX_RETRY_BUDGET,48
.equ CTX_RECOVERY_DEPTH,56
.equ CTX_CURRENT_HANDLER,64
.equ CTX_PREVIOUS_HANDLER,72
.equ CTX_BRANCH_COUNT,80
.equ CTX_METRIC_COUNT,88
.equ CTX_LOG_COUNT,96
.equ CTX_LAST_ERROR,104
.equ CTX_VALIDATION_FAILURES,112
.equ CTX_SIZE,128

.section .text
.extern arena_alloc
.global monster_context_new
.global monster_validate_base
.global monster_metrics_bump
.global monster_dispatch_base
.global calendarDateSpaghetti

.type monster_context_new,@function
monster_context_new:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,CTX_SIZE
    call arena_alloc
    mov r8,rax
    mov rdi,r8
    xor eax,eax
    mov rcx,CTX_SIZE/8
    rep stosq
    mov qword ptr [r8+CTX_CALCULATION_DAY],r12
    mov qword ptr [r8+CTX_TARGET_DAY],r13
    mov qword ptr [r8+CTX_MODE],1
    mov qword ptr [r8+CTX_STATUS],1
    mov rax,r8
    pop r13
    pop r12
    leave
    ret
.size monster_context_new,.-monster_context_new

.type monster_validate_base,@function
monster_validate_base:
    test rdi,rdi
    je .Lmvb_fail
    cmp qword ptr [rdi+CTX_CALCULATION_DAY],0
    je .Lmvb_fail_count
    cmp qword ptr [rdi+CTX_TARGET_DAY],0
    je .Lmvb_fail_count
    mov eax,1
    ret
.Lmvb_fail_count:
    inc qword ptr [rdi+CTX_VALIDATION_FAILURES]
.Lmvb_fail:
    xor eax,eax
    ret
.size monster_validate_base,.-monster_validate_base

.type monster_metrics_bump,@function
monster_metrics_bump:
    test rdi,rdi
    je .Lmmb_done
    inc qword ptr [rdi+CTX_METRIC_COUNT]
.Lmmb_done:
    ret
.size monster_metrics_bump,.-monster_metrics_bump

.type monster_dispatch_base,@function
monster_dispatch_base:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lmdb_fail
    test r13,r13
    je .Lmdb_fail
    mov rax,qword ptr [r12+CTX_CURRENT_HANDLER]
    mov qword ptr [r12+CTX_PREVIOUS_HANDLER],rax
    mov qword ptr [r12+CTX_CURRENT_HANDLER],r13
    inc qword ptr [r12+CTX_BRANCH_COUNT]
    mov rdi,r12
    call r13
    jmp .Lmdb_done
.Lmdb_fail:
    xor eax,eax
.Lmdb_done:
    pop r13
    pop r12
    leave
    ret
.size monster_dispatch_base,.-monster_dispatch_base

.type calendarDateSpaghetti,@function
calendarDateSpaghetti:
    push rbp
    mov rbp,rsp
    call monster_context_new
    mov rdi,rax
    call monster_validate_base
    test eax,eax
    je .Lcds_fail
    mov eax,2
    leave
    ret
.Lcds_fail:
    xor eax,eax
    leave
    ret
.size calendarDateSpaghetti,.-calendarDateSpaghetti
