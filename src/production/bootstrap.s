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
.equ CTX_LEGACY_REMAINDER_INPUT,120
.equ CTX_LEGACY_REMAINDER_RESULT,128
.equ CTX_LEGACY_REMAINDER_SEEN,136
.equ CTX_PATCHED_REMAINDER_RESULT,144
.equ CTX_SAVE_PATCH_SEEN,152
.equ CTX_DAYTAG_CALC_INPUT,160
.equ CTX_LEGACY_DAYTAG_CALC_RESULT,168
.equ CTX_DAYTAG_TARGET_INPUT,176
.equ CTX_LEGACY_DAYTAG_TARGET_RESULT,184
.equ CTX_LEGACY_DAYTAG_SEEN,192
.equ CTX_SIZE,200
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24

.section .data.rel.ro
.align 8
.global legacy_remainder_M
legacy_remainder_M:
    .quad 1
    .quad 2
    .quad 2
    .quad legacy_remainder_M_limbs
legacy_remainder_M_limbs:
    .quad 0xffffffffffffffff
    .quad 0x7fffffffffffffff

.section .text
.extern arena_alloc
.extern bi_abs
.extern bi_mod_abs
.extern bi_is_zero
.extern bi_sub_abs
.extern bi_sub
.extern bi_mul_u64
.extern bi_from_i64
.extern bi_clone
.global monster_context_new
.global monster_validate_base
.global monster_metrics_bump
.global monster_dispatch_base
.global calendarDateSpaghetti
.global oldRemainder
.global savePatch
.global monster_stage03_save_patch_wrapper
.global monster_stage02_legacy_remainder_handler
.global monster_remainder_route
.global oldDayTag
.global monster_daytag_route
.global monster_stage04_legacy_daytag_handler

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


.type oldRemainder,@function
oldRemainder:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,qword ptr [r12+BI_SIGN]
    mov rdi,r12
    call bi_abs
    mov rdi,rax
    lea rsi,[rip+legacy_remainder_M]
    call bi_mod_abs
    mov r14,rax
    test r13,r13
    jge .Lor_done_value
    mov rdi,r14
    call bi_is_zero
    test eax,eax
    jne .Lor_done_value
    lea rdi,[rip+legacy_remainder_M]
    mov rsi,r14
    call bi_sub_abs
    jmp .Lor_done
.Lor_done_value:
    mov rax,r14
.Lor_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oldRemainder,.-oldRemainder

# Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ϯ 0 ϩⲓ ⲛⲡⲟⲗⲗⲁⲡⲗⲁⲥⲓⲟⲛ ⲙⲡ M. Ⲙⲡⲟⲩϣⲓⲃⲉ ⲙⲙⲟϥ ϫⲉ ⲟⲩϣⲟⲩⲱⲃⲉ ⲛⲧⲉⲡϩⲓⲥⲧⲟⲣⲓⲁ ⲡⲉ.
# Ⲡ savePatch ⲕⲱ M ⲉϩⲣⲁⲓ ⲉϣϫⲉ ⲡ oldRemainder ϯ 0. Ⲡⲁⲓ ⲧⲱⲛ ⲙⲛ SAVE ⲁⲩⲱ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲛⲟⲩⲕⲉⲁⲡⲟⲕⲣⲓⲥⲓⲥ.
.type savePatch,@function
savePatch:
    push rbp
    mov rbp,rsp
    push r12
    call oldRemainder
    mov r12,rax
    mov rdi,r12
    call bi_is_zero
    test eax,eax
    je .Lsp_old_value
    lea rdi,[rip+legacy_remainder_M]
    call bi_clone
    jmp .Lsp_done
.Lsp_old_value:
    mov rax,r12
.Lsp_done:
    pop r12
    leave
    ret
.size savePatch,.-savePatch

.type monster_stage03_save_patch_wrapper,@function
monster_stage03_save_patch_wrapper:
    jmp savePatch
.size monster_stage03_save_patch_wrapper,.-monster_stage03_save_patch_wrapper

.type monster_remainder_route,@function
monster_remainder_route:
    jmp monster_stage03_save_patch_wrapper
.size monster_remainder_route,.-monster_remainder_route

.type monster_stage02_legacy_remainder_handler,@function
monster_stage02_legacy_remainder_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms02_fail
    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_LEGACY_REMAINDER_INPUT],r13
    mov rdi,r13
    call oldRemainder
    mov qword ptr [r12+CTX_LEGACY_REMAINDER_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_REMAINDER_SEEN]
    mov rdi,r13
    call monster_remainder_route
    mov qword ptr [r12+CTX_PATCHED_REMAINDER_RESULT],rax
    inc qword ptr [r12+CTX_SAVE_PATCH_SEEN]
    mov eax,1
    jmp .Lms02_done
.Lms02_fail:
    xor eax,eax
.Lms02_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage02_legacy_remainder_handler,.-monster_stage02_legacy_remainder_handler


# Ⲡⲣⲱⲧⲉ ⲛⲗⲉⲅⲁⲥⲓ ⲉⲧⲉⲓ ⲙⲡⲉϥⲡⲱⲣϫ ⲙⲙⲟⲥ ϫⲉ ⲛⲉϩⲟⲟⲩ ⲙⲛⲛⲥⲁ ⲡϩⲟⲟⲩ ⲛⲧⲉⲥⲛⲧⲉ ⲥⲉϣⲟⲟⲡ ⲛⲕⲟⲧ ⲛⲟⲩⲱⲧ. Ⲙⲡⲟⲩⲕⲱ ⲉϩⲣⲁⲓ ⲛⲟⲩⲡⲁⲧϣ ϩⲙ ⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ.
.type oldDayTag,@function
oldDayTag:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    mov rdi,-15055671
    call bi_from_i64
    mov rsi,rax
    mov rdi,r12
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov rdi,rax
    mov rsi,2
    call bi_mul_u64
    pop r12
    leave
    ret
.size oldDayTag,.-oldDayTag

.type monster_daytag_route,@function
monster_daytag_route:
    jmp oldDayTag
.size monster_daytag_route,.-monster_daytag_route

.type monster_stage04_legacy_daytag_handler,@function
monster_stage04_legacy_daytag_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    test r12,r12
    je .Lms04_fail

    mov rdi,qword ptr [r12+CTX_CALCULATION_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_DAYTAG_CALC_INPUT],r13
    mov rdi,r13
    call monster_daytag_route
    mov qword ptr [r12+CTX_LEGACY_DAYTAG_CALC_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DAYTAG_SEEN]

    mov rdi,qword ptr [r12+CTX_TARGET_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_DAYTAG_TARGET_INPUT],r13
    mov rdi,r13
    call monster_daytag_route
    mov qword ptr [r12+CTX_LEGACY_DAYTAG_TARGET_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DAYTAG_SEEN]

    mov eax,1
    jmp .Lms04_done
.Lms04_fail:
    xor eax,eax
.Lms04_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage04_legacy_daytag_handler,.-monster_stage04_legacy_daytag_handler

.type calendarDateSpaghetti,@function
calendarDateSpaghetti:
    push rbp
    mov rbp,rsp
    push r12
    call monster_context_new
    mov r12,rax
    mov rdi,r12
    call monster_validate_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage02_legacy_remainder_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage04_legacy_daytag_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov eax,2
    jmp .Lcds_done
.Lcds_fail:
    xor eax,eax
.Lcds_done:
    pop r12
    leave
    ret
.size calendarDateSpaghetti,.-calendarDateSpaghetti
