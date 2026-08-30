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
.equ CTX_PATCHED_DAYTAG_CALC_RESULT,200
.equ CTX_PATCHED_DAYTAG_TARGET_RESULT,208
.equ CTX_DAYTAG_PATCH_SEEN,216
.equ CTX_LEGACY_DISTANCE_RESULT,224
.equ CTX_DISTANCE_ROUTE_RESULT,232
.equ CTX_LEGACY_DISTANCE_SEEN,240
.equ CTX_DISTANCE_ROUTE_SEEN,248
.equ CTX_CHRONOLOGICAL_DISTANCE,256
.equ CTX_PATCHED_DISTANCE_RESULT,264
.equ CTX_DISTANCE_PATCH_SEEN,272
.equ CTX_LEGACY_STONE_ROW,280
.equ CTX_STONE_ROUTE_RESULT,288
.equ CTX_LEGACY_STONE_SEEN,296
.equ CTX_STONE_ROUTE_SEEN,304
.equ CTX_STONE_ITERATION,312
.equ CTX_STONE_PATCH_INPUT,320
.equ CTX_PATCHED_STONE_ROW,328
.equ CTX_STONE_PATCH_SEEN,336
.equ CTX_HIDDEN_BACKWARD,344
.equ CTX_HIDDEN_QUERY_K,352
.equ CTX_LEGACY_HIDDEN_QUERY_RESULT,360
.equ CTX_LEGACY_HIDDEN_STORAGE_SEEN,368
.equ CTX_LEGACY_HIDDEN_QUERY_SEEN,376
.equ CTX_PATCHED_HIDDEN_QUERY_RESULT,384
.equ CTX_HIDDEN_NEARNESS_PATCH_SEEN,392
.equ CTX_DROP_STORE,400
.equ CTX_PRIOR_I,408
.equ CTX_PRIOR_BACK,416
.equ CTX_LEGACY_PRIOR_RESULT,424
.equ CTX_PRIOR_ROUTE_RESULT,432
.equ CTX_LEGACY_PRIOR_SEEN,440
.equ CTX_PRIOR_ROUTE_SEEN,448
.equ CTX_PATCHED_PRIOR_RESULT,456
.equ CTX_PRIOR_PATCH_SEEN,464
.equ CTX_SIZE,472
.equ HCOUNTS_ACTION,0
.equ HCOUNTS_TARGET,8
.equ HCOUNTS_DISTANCE,16
.equ HCOUNTS_CONNECTION,24
.equ HCOUNTS_DIRECTION,32
.equ HCOUNTS_SIZE,40
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

.section .rodata
.align 8
legacy_hidden_coeff:
    .quad 3,4,6,8
    .quad 5,7,10,12
    .quad 7,10,14,16
    .quad 9,13,18,20
    .quad 11,16,22,24
    .quad 13,19,26,28
    .quad 15,22,30,32
legacy_hidden_stone_kind:
    .quad 1,2,3,4,5,1,2

.section .text
.extern arena_alloc
.extern bi_abs
.extern bi_mod_abs
.extern bi_is_zero
.extern bi_sub_abs
.extern bi_sub
.extern bi_mul_u64
.extern bi_mul_abs
.extern bi_add_abs
.extern bi_from_i64
.extern bi_from_u64
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
.global dayTagWithFoundationScar
.global monster_stage05_daytag_patch_wrapper
.global monster_daytag_route
.global monster_stage04_legacy_daytag_handler
.global oldDistance
.global distanceWithChronologicalScar
.global monster_stage07_distance_patch_wrapper
.global monster_distance_route
.global monster_stage06_legacy_distance_handler
.global mutateStonesWrong
.global monster_stone_mutation_route
.global monster_stage08_legacy_stone_handler
.global stonePatch
.global monster_stage09_stone_patch_wrapper
.global getStoneTableThroughLegacyBuilder
.global getHiddenStonePrefixThroughLegacyBuilder
.global makeHiddenLegacyStoredValue
.global buildHiddenWithBackwardStorage
.global legacyHiddenAtNearnessWrong
.global hiddenByNearness
.global monster_stage11_hidden_nearness_patch_wrapper
.global monster_hidden_route
.global monster_stage10_legacy_hidden_handler
.global legacyPrior
.global priorPatch
.global monster_stage13_prior_patch_wrapper
.global monster_prior_route
.global monster_stage12_legacy_prior_handler

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

# Ⲡ oldDayTag ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲙⲛ ⲡⲉϥⲡⲗⲁⲛⲏ. Ⲡⲡⲁⲧϣ ⲉⲧⲛⲏⲩ ⲛϥϣⲓⲃⲉ ⲁⲛ ⲙⲙⲟϥ; ⲛϥⲟⲩⲱϩ ⲙⲙⲁⲧⲉ ⲉϫⲱϥ.
# Ⲡ guard ⲙⲡ FOUNDATION ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲟⲩϣⲟⲩⲱⲃⲉ ⲛⲧⲉⲡϩⲓⲥⲧⲟⲣⲓⲁ, ϩⲟⲡⲟⲩ ⲡ +1 ⲛϣⲟⲣⲡ ⲧⲁⲙⲓⲟ ⲙⲡ 1.
.type dayTagWithFoundationScar,@function
dayTagWithFoundationScar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    call oldDayTag
    mov r13,rax

    mov rdi,-15055671
    call bi_from_i64
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jl .Ldtfs_done

    mov rdi,r13
    mov rsi,1
    call bi_add_u64
    mov r13,rax

    mov rdi,r12
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Ldtfs_done
    mov rdi,r13
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    jne .Ldtfs_done
    mov rdi,1
    call bi_from_u64
    mov r13,rax
.Ldtfs_done:
    mov rax,r13
    pop r14
    pop r13
    pop r12
    leave
    ret
.size dayTagWithFoundationScar,.-dayTagWithFoundationScar

.type monster_stage05_daytag_patch_wrapper,@function
monster_stage05_daytag_patch_wrapper:
    jmp dayTagWithFoundationScar
.size monster_stage05_daytag_patch_wrapper,.-monster_stage05_daytag_patch_wrapper

.type monster_daytag_route,@function
monster_daytag_route:
    jmp monster_stage05_daytag_patch_wrapper
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
    call oldDayTag
    mov qword ptr [r12+CTX_LEGACY_DAYTAG_CALC_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DAYTAG_SEEN]
    mov rdi,r13
    call monster_daytag_route
    mov qword ptr [r12+CTX_PATCHED_DAYTAG_CALC_RESULT],rax
    inc qword ptr [r12+CTX_DAYTAG_PATCH_SEEN]

    mov rdi,qword ptr [r12+CTX_TARGET_DAY]
    call bi_from_i64
    mov r13,rax
    mov qword ptr [r12+CTX_DAYTAG_TARGET_INPUT],r13
    mov rdi,r13
    call oldDayTag
    mov qword ptr [r12+CTX_LEGACY_DAYTAG_TARGET_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DAYTAG_SEEN]
    mov rdi,r13
    call monster_daytag_route
    mov qword ptr [r12+CTX_PATCHED_DAYTAG_TARGET_RESULT],rax
    inc qword ptr [r12+CTX_DAYTAG_PATCH_SEEN]

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

# Ⲡ oldDistance ⲥⲱⲟⲩϩ ⲙⲡⲟⲩⲱϣⲃ ⲛⲛⲧⲁⲅ ⲛⲛϩⲟⲟⲩ, ⲛⲧⲟϥ ⲇⲉ ⲛϥϣⲓⲛⲉ ⲁⲛ ⲛⲥⲁ ⲡⲟⲩⲁϩⲥⲁϩⲛⲉ ⲛⲛϩⲟⲟⲩ ϩⲛ ⲡⲉⲩⲧⲁⲝⲓⲥ.
# Ⲡⲣⲱⲧⲉ ⲡⲁⲓ ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲛⲗⲉⲅⲁⲥⲓ; ⲙⲛ ⲡⲁⲧϣ ⲉϥϣⲟⲟⲡ ϩⲙ ⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ.
.type oldDistance,@function
oldDistance:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call dayTagWithFoundationScar
    mov r14,rax
    mov rdi,r13
    call dayTagWithFoundationScar
    mov rsi,rax
    mov rdi,r14
    call bi_sub
    mov rdi,rax
    call bi_abs
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oldDistance,.-oldDistance

# Ⲡ oldDistance ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲙⲛ ⲡⲉϥⲡⲗⲁⲛⲏ. Ⲡⲡⲁⲧϣ ⲙⲉⲧⲣⲉ ⲙⲡⲙⲁⲕⲣⲟⲛ ⲛⲧⲉⲛϩⲟⲟⲩ, ⲁⲩⲱ ⲛϥϣⲓⲃⲉ ⲙⲡlegacy ⲙⲙⲁⲧⲉ ⲉϣϫⲉ ⲛⲥⲉⲧⲱⲛ ⲁⲛ.
# Ⲙⲛⲛⲥⲱⲥ ⲛϥⲟⲩⲱϩ 1. Ⲙⲡⲟⲩϥⲱϫⲉ ⲙⲡ oldDistance, ⲁⲩⲱ ⲙⲛ fallback ⲉϥⲥⲟⲡⲥⲡ ⲉϥϣⲟⲟⲡ.
.type distanceWithChronologicalScar,@function
distanceWithChronologicalScar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi

    mov rdi,r12
    mov rsi,r13
    call oldDistance
    mov r14,rax

    mov rdi,r13
    mov rsi,r12
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov r15,rax

    mov rdi,r14
    mov rsi,r15
    call bi_cmp
    test eax,eax
    je .Ldwcs_keep_legacy
    mov r14,r15
.Ldwcs_keep_legacy:
    mov rdi,r14
    mov rsi,1
    call bi_add_u64

    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size distanceWithChronologicalScar,.-distanceWithChronologicalScar

.type monster_stage07_distance_patch_wrapper,@function
monster_stage07_distance_patch_wrapper:
    jmp distanceWithChronologicalScar
.size monster_stage07_distance_patch_wrapper,.-monster_stage07_distance_patch_wrapper

.type monster_distance_route,@function
monster_distance_route:
    jmp monster_stage07_distance_patch_wrapper
.size monster_distance_route,.-monster_distance_route

.type monster_stage06_legacy_distance_handler,@function
monster_stage06_legacy_distance_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    test r12,r12
    je .Lms06_fail
    mov r13,qword ptr [r12+CTX_DAYTAG_CALC_INPUT]
    mov r14,qword ptr [r12+CTX_DAYTAG_TARGET_INPUT]
    test r13,r13
    je .Lms06_fail
    test r14,r14
    je .Lms06_fail

    mov rdi,r13
    mov rsi,r14
    call oldDistance
    mov qword ptr [r12+CTX_LEGACY_DISTANCE_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_DISTANCE_SEEN]

    mov rdi,r14
    mov rsi,r13
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov qword ptr [r12+CTX_CHRONOLOGICAL_DISTANCE],rax

    mov rdi,r13
    mov rsi,r14
    call monster_distance_route
    mov qword ptr [r12+CTX_DISTANCE_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_DISTANCE_RESULT],rax
    inc qword ptr [r12+CTX_DISTANCE_ROUTE_SEEN]
    inc qword ptr [r12+CTX_DISTANCE_PATCH_SEEN]

    mov eax,1
    jmp .Lms06_done
.Lms06_fail:
    xor eax,eax
.Lms06_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage06_legacy_distance_handler,.-monster_stage06_legacy_distance_handler



# Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲛϣⲟⲙⲛⲧ ⲛⲉⲣⲅⲁⲥⲓⲁ ⲙⲡⲉⲓⲙⲁ ⲛⲁϣⲱⲡⲉ ⲛⲟⲩⲱⲧ ϩⲛ ⲟⲩⲥⲱⲙⲁ ⲛ state. Ⲡ mutateStonesWrong ϣⲓⲃⲉ ⲙⲡⲉϥⲥⲱⲙⲁ ϩⲛ ⲟⲩⲧⲁⲝⲓⲥ, ⲁⲩⲱ ⲛϥϫⲓ ⲛⲛⲉⲁⲡⲟⲕⲣⲓⲥⲓⲥ ⲛⲃⲣⲣⲉ ϩⲛ ⲛⲗⲟⲅⲓⲥⲙⲟⲥ ⲉⲧⲛⲏⲩ.
# Ⲙⲛ snapshot ⲛⲕⲁⲛⲱⲛ ⲉϥϣⲟⲟⲡ ϩⲙ ⲡⲃⲁⲑⲙⲟⲥ ⲡⲁⲓ. Ⲡⲡⲗⲁⲛⲏ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲙⲡⲣⲱⲧⲉ.
.type mutateStonesWrong,@function
mutateStonesWrong:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lmsw_fail

    # w = SAVE(w*w + 3*b + i)
    mov rdi,qword ptr [r12]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+8]
    mov rsi,3
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov qword ptr [r12],rax

    # b = SAVE(b*b + 5*s + w) ; w ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+8]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+16]
    mov rsi,5
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+8],rax

    # s = SAVE(s*s + 7*m + b) ; b ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+16]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+24]
    mov rsi,7
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12+8]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+16],rax

    # m = SAVE(m*m + 11*r + s) ; s ⲡⲉ ⲡⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+24]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+32]
    mov rsi,11
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12+16]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+24],rax

    # r = SAVE(r*r + 13*w + m) ; w ⲙⲛ m ⲛⲉ ⲛⲟⲩⲱϣⲃ ⲛⲃⲣⲣⲉ.
    mov rdi,qword ptr [r12+32]
    mov rsi,rdi
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12]
    mov rsi,13
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r14
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r12+24]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r12+32],rax

    mov rax,r12
    jmp .Lmsw_done
.Lmsw_fail:
    xor eax,eax
.Lmsw_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size mutateStonesWrong,.-mutateStonesWrong

# Ⲡ mutateStonesWrong ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ ⲁⲩⲱ ⲡ stonePatch ⲙⲟⲩⲧⲉ ⲉⲣⲟϥ ϩⲓ ⲟⲩclone. Ⲡgarbage ⲛⲗⲉⲅⲁⲥⲓ ⲛϥⲃⲱⲗ ⲁⲛ ⲉⲃⲟⲗ; ⲁⲗⲗⲁ ⲛ5 ⲛⲧⲓⲙⲏ ⲥⲉⲥϩⲁⲓ ⲛⲕⲉⲥⲟⲡ ⲉⲃⲟⲗ ϩⲙⲡsnapshot ⲛϣⲟⲣⲡ.
# Ⲡsnapshot ⲙⲛ ⲡgarbage ⲛⲉ 40 bytes ⲙⲡⲟⲓⲛⲧⲉⲣ. ⲚBigInt ⲥⲉⲟ ⲛimmutable ϩⲙⲡⲉⲓⲣⲱⲧⲉ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲡclone ⲛⲧⲉⲡrow ⲧⲁϫⲣⲏⲩ.
.type stonePatch,@function
stonePatch:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lsp4_fail

    # old = clone(S)
    mov rdi,40
    call arena_alloc
    mov r14,rax
    mov rax,qword ptr [r12]
    mov qword ptr [r14],rax
    mov rax,qword ptr [r12+8]
    mov qword ptr [r14+8],rax
    mov rax,qword ptr [r12+16]
    mov qword ptr [r14+16],rax
    mov rax,qword ptr [r12+24]
    mov qword ptr [r14+24],rax
    mov rax,qword ptr [r12+32]
    mov qword ptr [r14+32],rax

    # garbage = mutateStonesWrong(i, clone(S))
    mov rdi,40
    call arena_alloc
    mov r15,rax
    mov rax,qword ptr [r12]
    mov qword ptr [r15],rax
    mov rax,qword ptr [r12+8]
    mov qword ptr [r15+8],rax
    mov rax,qword ptr [r12+16]
    mov qword ptr [r15+16],rax
    mov rax,qword ptr [r12+24]
    mov qword ptr [r15+24],rax
    mov rax,qword ptr [r12+32]
    mov qword ptr [r15+32],rax
    mov rdi,r15
    mov rsi,r13
    call mutateStonesWrong
    test rax,rax
    je .Lsp4_fail
    mov r15,rax

    # w = SAVE(old.w*old.w + 3*old.b + i)
    mov rdi,qword ptr [r14]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+8]
    mov rsi,3
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov qword ptr [r15],rax

    # b = SAVE(old.b*old.b + 5*old.s + old.w)
    mov rdi,qword ptr [r14+8]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+16]
    mov rsi,5
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+8],rax

    # s = SAVE(old.s*old.s + 7*old.m + old.b)
    mov rdi,qword ptr [r14+16]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+24]
    mov rsi,7
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14+8]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+16],rax

    # m = SAVE(old.m*old.m + 11*old.r + old.s)
    mov rdi,qword ptr [r14+24]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14+32]
    mov rsi,11
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14+16]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+24],rax

    # r = SAVE(old.r*old.r + 13*old.w + old.m)
    mov rdi,qword ptr [r14+32]
    mov rsi,rdi
    call bi_mul_abs
    mov rbx,rax
    mov rdi,qword ptr [r14]
    mov rsi,13
    call bi_mul_u64
    mov rsi,rax
    mov rdi,rbx
    call bi_add_abs
    mov rdi,rax
    mov rsi,qword ptr [r14+24]
    call bi_add_abs
    mov rdi,rax
    call savePatch
    mov qword ptr [r15+32],rax

    mov rax,r15
    jmp .Lsp4_done
.Lsp4_fail:
    xor eax,eax
.Lsp4_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stonePatch,.-stonePatch

# Ⲡwrapper ϩⲁⲣⲉϩ ⲉⲡcontract ⲙⲡroute ⲛⲗⲉⲅⲁⲥⲓ: ⲡpointer ⲉⲧⲃⲱⲕ ⲉϩⲟⲩⲛ ⲡⲉ ⲡpointer ⲉⲧⲛⲏⲩ ⲉⲃⲟⲗ. Ⲡ stonePatch ⲛⲧⲟϥ ⲟⲩⲏϩ ⲉϥⲕⲱ ⲙⲡgarbage clone ⲉⲃⲟⲗ.
.type monster_stage09_stone_patch_wrapper,@function
monster_stage09_stone_patch_wrapper:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call stonePatch
    test rax,rax
    je .Lms09w_fail
    mov r13,rax
    mov rax,qword ptr [r13]
    mov qword ptr [r12],rax
    mov rax,qword ptr [r13+8]
    mov qword ptr [r12+8],rax
    mov rax,qword ptr [r13+16]
    mov qword ptr [r12+16],rax
    mov rax,qword ptr [r13+24]
    mov qword ptr [r12+24],rax
    mov rax,qword ptr [r13+32]
    mov qword ptr [r12+32],rax
    mov rax,r12
    jmp .Lms09w_done
.Lms09w_fail:
    xor eax,eax
.Lms09w_done:
    pop r13
    pop r12
    leave
    ret
.size monster_stage09_stone_patch_wrapper,.-monster_stage09_stone_patch_wrapper

.type monster_stone_mutation_route,@function
monster_stone_mutation_route:
    jmp monster_stage09_stone_patch_wrapper
.size monster_stone_mutation_route,.-monster_stone_mutation_route

# Ⲡbuilder ⲛⲗⲉⲅⲁⲥⲓ ⲕⲱ ⲉϩⲣⲁⲓ ⲛ46 ⲛrows. Ⲛrow 2..46 ⲥⲉⲛⲏⲩ ϩⲓⲧⲛ stonePatch, ⲉⲣⲉ mutateStonesWrong ⲙⲟⲟϣⲉ ⲙⲙⲏⲛⲉ ϩⲙⲡⲁⲧϣ.
.type getStoneTableThroughLegacyBuilder,@function
getStoneTableThroughLegacyBuilder:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov rdi,1840
    call arena_alloc
    mov r12,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r12],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r12+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r12+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r12+32],rax
    mov r13,2
.Lgst_loop:
    cmp r13,47
    jae .Lgst_done_rows
    mov rax,r13
    sub rax,2
    imul rax,40
    lea r14,[r12+rax]
    mov rdi,r14
    mov rsi,r13
    call stonePatch
    test rax,rax
    je .Lgst_fail
    mov r15,rax
    mov rax,r13
    dec rax
    imul rax,40
    lea r14,[r12+rax]
    mov rax,qword ptr [r15]
    mov qword ptr [r14],rax
    mov rax,qword ptr [r15+8]
    mov qword ptr [r14+8],rax
    mov rax,qword ptr [r15+16]
    mov qword ptr [r14+16],rax
    mov rax,qword ptr [r15+24]
    mov qword ptr [r14+24],rax
    mov rax,qword ptr [r15+32]
    mov qword ptr [r14+32],rax
    inc r13
    jmp .Lgst_loop
.Lgst_done_rows:
    mov rax,r12
    jmp .Lgst_done
.Lgst_fail:
    xor eax,eax
.Lgst_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size getStoneTableThroughLegacyBuilder,.-getStoneTableThroughLegacyBuilder

.type monster_stage08_legacy_stone_handler,@function
monster_stage08_legacy_stone_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    test r12,r12
    je .Lms08_fail

    # Ⲡrow ⲛϣⲟⲣⲡ ⲃⲱⲕ ⲉ mutateStonesWrong ⲙⲙⲁⲧⲉ, ⲉⲧⲣⲉ ⲡgarbage ⲟⲩⲱⲛϩ ⲉⲃⲟⲗ ϩⲙⲡcontext.
    mov rdi,40
    call arena_alloc
    mov r13,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r13],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r13+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r13+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r13+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r13+32],rax
    mov rdi,r13
    mov rsi,2
    call mutateStonesWrong
    test rax,rax
    je .Lms08_fail
    mov qword ptr [r12+CTX_LEGACY_STONE_ROW],rax
    inc qword ptr [r12+CTX_LEGACY_STONE_SEEN]

    # Ⲡrow ⲛⲥⲛⲁⲩ ⲃⲱⲕ ϩⲓⲧⲛ ⲡroute ⲙⲡⲁⲧϣ.
    mov rdi,40
    call arena_alloc
    mov r14,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r14],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r14+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r14+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r14+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r14+32],rax
    mov qword ptr [r12+CTX_STONE_ITERATION],2
    mov qword ptr [r12+CTX_STONE_PATCH_INPUT],r14
    mov rdi,r14
    mov rsi,2
    call monster_stone_mutation_route
    test rax,rax
    je .Lms08_fail
    mov qword ptr [r12+CTX_STONE_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_STONE_ROW],rax
    inc qword ptr [r12+CTX_STONE_ROUTE_SEEN]
    inc qword ptr [r12+CTX_STONE_PATCH_SEEN]
    mov eax,1
    jmp .Lms08_done
.Lms08_fail:
    xor eax,eax
.Lms08_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage08_legacy_stone_handler,.-monster_stage08_legacy_stone_handler



# Ⲛhidden ⲥⲉϫⲓ ⲙⲙⲁⲧⲉ ⲛⲛrow 1..7 ⲛⲧⲉⲛⲱⲛⲉ. Ⲡbuilder ⲡⲁⲓ ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ stonePatch ⲁⲩⲱ ⲛϥⲕⲱ ⲛⲥⲱϥ ⲛrow 8..46 ⲉⲧⲉ ⲛⲥⲉϫⲓ ⲙⲙⲟⲟⲩ ⲁⲛ ϩⲙⲡⲉⲓⲧⲟϣ.
.type getHiddenStonePrefixThroughLegacyBuilder,@function
getHiddenStonePrefixThroughLegacyBuilder:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov rdi,280
    call arena_alloc
    mov r12,rax
    mov rdi,17
    call bi_from_u64
    mov qword ptr [r12],rax
    mov rdi,29
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov rdi,43
    call bi_from_u64
    mov qword ptr [r12+16],rax
    mov rdi,71
    call bi_from_u64
    mov qword ptr [r12+24],rax
    mov rdi,101
    call bi_from_u64
    mov qword ptr [r12+32],rax
    mov r13,2
.Lghsp_loop:
    cmp r13,8
    jae .Lghsp_ok
    mov rax,r13
    sub rax,2
    imul rax,40
    lea r14,[r12+rax]
    mov rdi,r14
    mov rsi,r13
    call stonePatch
    test rax,rax
    je .Lghsp_fail
    mov r15,rax
    mov rax,r13
    dec rax
    imul rax,40
    lea r14,[r12+rax]
    mov rax,qword ptr [r15]
    mov qword ptr [r14],rax
    mov rax,qword ptr [r15+8]
    mov qword ptr [r14+8],rax
    mov rax,qword ptr [r15+16]
    mov qword ptr [r14+16],rax
    mov rax,qword ptr [r15+24]
    mov qword ptr [r14+24],rax
    mov rax,qword ptr [r15+32]
    mov qword ptr [r14+32],rax
    inc r13
    jmp .Lghsp_loop
.Lghsp_ok:
    mov rax,r12
    jmp .Lghsp_done
.Lghsp_fail:
    xor eax,eax
.Lghsp_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size getHiddenStonePrefixThroughLegacyBuilder,.-getHiddenStonePrefixThroughLegacyBuilder

# Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡarray ⲛⲛhidden ⲉϥⲥϩⲟⲩⲟⲣⲧ ⲉϥⲟⲩⲱϩ ⲉⲃⲟⲗ ϩⲛ ⲧⲉⲩⲧⲁⲝⲓⲥ ⲛⲟⲩⲱⲧ. Ⲡlegacy ⲇⲉ ⲥϩⲁⲓ ⲙⲡ hidden7 ⲛϣⲟⲣⲡ ⲙⲛ hidden1 ϩⲙⲡϩⲁⲉ.
# Ⲡⲡⲁⲧϣ ⲛStage 11 ⲙⲡϥⲕⲧⲟ ⲙⲡarray. Ⲛϥⲙⲉⲧⲁⲅⲣⲁⲫⲉ ⲙⲙⲁⲧⲉ ⲙⲡk ⲉⲡposition 8-k, ⲉⲣⲉ ⲡstorage ⲛⲥⲁϩⲟⲩ ⲟⲩⲏϩ ⲉϥϣⲟⲟⲡ.
.type makeHiddenLegacyStoredValue,@function
makeHiddenLegacyStoredValue:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Lmhlv_fail
    test r13,r13
    je .Lmhlv_fail
    cmp r14,1
    jb .Lmhlv_fail
    cmp r14,7
    ja .Lmhlv_fail

    mov rdi,qword ptr [r12+HCOUNTS_ACTION]
    call bi_clone
    mov r15,rax

    mov rax,r14
    dec rax
    imul rax,32
    lea rbx,[rip+legacy_hidden_coeff]
    add rbx,rax

    mov rdi,qword ptr [r12+HCOUNTS_TARGET]
    mov rsi,qword ptr [rbx]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rdi,qword ptr [r12+HCOUNTS_DISTANCE]
    mov rsi,qword ptr [rbx+8]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rdi,qword ptr [r12+HCOUNTS_CONNECTION]
    mov rsi,qword ptr [rbx+16]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rdi,qword ptr [r12+HCOUNTS_DIRECTION]
    mov rsi,qword ptr [rbx+24]
    call bi_mul_u64
    mov rdi,r15
    mov rsi,rax
    call bi_add_abs
    mov r15,rax

    mov rax,r14
    dec rax
    imul rax,40
    lea rbx,[r13+rax]
    xor r14d,r14d
.Lmhlv_stone_sum:
    cmp r14,5
    jae .Lmhlv_first_save
    mov rdi,r15
    mov rsi,qword ptr [rbx+r14*8]
    call bi_add_abs
    mov r15,rax
    inc r14
    jmp .Lmhlv_stone_sum

.Lmhlv_first_save:
    mov rdi,r15
    call savePatch
    mov r15,rax
    mov r14,1
.Lmhlv_grind:
    cmp r14,7
    ja .Lmhlv_ok
    mov rdi,r15
    mov rsi,r15
    call bi_mul_abs
    mov r12,rax
    mov rdi,r15
    mov rsi,3
    call bi_mul_u64
    mov rdi,r12
    mov rsi,rax
    call bi_add_abs
    mov r12,rax
    lea r10,[rip+legacy_hidden_stone_kind]
    mov rax,qword ptr [r10+r14*8-8]
    dec rax
    mov rdi,r12
    mov rsi,qword ptr [rbx+rax*8]
    call bi_add_abs
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call savePatch
    mov r15,rax
    inc r14
    jmp .Lmhlv_grind
.Lmhlv_ok:
    mov rax,r15
    jmp .Lmhlv_done
.Lmhlv_fail:
    xor eax,eax
.Lmhlv_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size makeHiddenLegacyStoredValue,.-makeHiddenLegacyStoredValue

.type buildHiddenWithBackwardStorage,@function
buildHiddenWithBackwardStorage:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lbhbs_fail
    test r13,r13
    je .Lbhbs_fail
    mov rdi,56
    call arena_alloc
    mov r15,rax
    mov r14,1
.Lbhbs_loop:
    cmp r14,7
    ja .Lbhbs_ok
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call makeHiddenLegacyStoredValue
    test rax,rax
    je .Lbhbs_fail
    mov rdx,7
    sub rdx,r14
    mov qword ptr [r15+rdx*8],rax
    inc r14
    jmp .Lbhbs_loop
.Lbhbs_ok:
    mov rax,r15
    jmp .Lbhbs_done
.Lbhbs_fail:
    xor eax,eax
.Lbhbs_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size buildHiddenWithBackwardStorage,.-buildHiddenWithBackwardStorage

.type legacyHiddenAtNearnessWrong,@function
legacyHiddenAtNearnessWrong:
    test rdi,rdi
    je .Llhaw_fail
    cmp rsi,1
    jb .Llhaw_fail
    cmp rsi,7
    ja .Llhaw_fail
    mov rax,qword ptr [rdi+rsi*8-8]
    ret
.Llhaw_fail:
    xor eax,eax
    ret
.size legacyHiddenAtNearnessWrong,.-legacyHiddenAtNearnessWrong

.type hiddenByNearness,@function
hiddenByNearness:
    test rdi,rdi
    je .Lhbn_fail
    cmp rsi,1
    jb .Lhbn_fail
    cmp rsi,7
    ja .Lhbn_fail
    mov rax,7
    sub rax,rsi
    mov rax,qword ptr [rdi+rax*8]
    ret
.Lhbn_fail:
    xor eax,eax
    ret
.size hiddenByNearness,.-hiddenByNearness

.type monster_stage11_hidden_nearness_patch_wrapper,@function
monster_stage11_hidden_nearness_patch_wrapper:
    jmp hiddenByNearness
.size monster_stage11_hidden_nearness_patch_wrapper,.-monster_stage11_hidden_nearness_patch_wrapper

.type monster_hidden_route,@function
monster_hidden_route:
    jmp monster_stage11_hidden_nearness_patch_wrapper
.size monster_hidden_route,.-monster_hidden_route

.type monster_stage10_legacy_hidden_handler,@function
monster_stage10_legacy_hidden_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms10_fail

    mov rdi,HCOUNTS_SIZE
    call arena_alloc
    mov r13,rax
    mov rax,qword ptr [r12+CTX_PATCHED_DAYTAG_CALC_RESULT]
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r13+HCOUNTS_ACTION],rax
    mov rax,qword ptr [r12+CTX_PATCHED_DAYTAG_TARGET_RESULT]
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r13+HCOUNTS_TARGET],rax
    mov rax,qword ptr [r12+CTX_PATCHED_DISTANCE_RESULT]
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r13+HCOUNTS_DISTANCE],rax

    mov rdi,qword ptr [r13+HCOUNTS_ACTION]
    mov rsi,qword ptr [r13+HCOUNTS_TARGET]
    call bi_add_abs
    mov qword ptr [r13+HCOUNTS_CONNECTION],rax

    mov rax,qword ptr [r12+CTX_TARGET_DAY]
    cmp rax,qword ptr [r12+CTX_CALCULATION_DAY]
    jl .Lms10_dir1
    je .Lms10_dir2
    mov edi,3
    jmp .Lms10_make_dir
.Lms10_dir1:
    mov edi,1
    jmp .Lms10_make_dir
.Lms10_dir2:
    mov edi,2
.Lms10_make_dir:
    call bi_from_u64
    mov qword ptr [r13+HCOUNTS_DIRECTION],rax

    call getHiddenStonePrefixThroughLegacyBuilder
    test rax,rax
    je .Lms10_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lms10_fail
    mov r15,rax
    mov qword ptr [r12+CTX_HIDDEN_BACKWARD],r15
    inc qword ptr [r12+CTX_LEGACY_HIDDEN_STORAGE_SEEN]
    mov qword ptr [r12+CTX_HIDDEN_QUERY_K],1

    # Ⲡlegacy call ⲟⲩⲏϩ ⲉϥⲣϩⲱⲃ ⲛⲟⲩCOPY_DIAGNOSTIC: k=1 ⲙⲟⲩⲧⲉ ⲉhidden7.
    mov rdi,r15
    mov esi,1
    call legacyHiddenAtNearnessWrong
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r12+CTX_LEGACY_HIDDEN_QUERY_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_HIDDEN_QUERY_SEEN]

    # Ⲡroute ⲛⲕⲁⲛⲱⲛ ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡtranslator 8-k, ⲁϫⲛ ⲧⲣⲉϥⲕⲧⲟ ⲙⲡstorage.
    mov rdi,r15
    mov esi,1
    call monster_hidden_route
    test rax,rax
    je .Lms10_fail
    mov qword ptr [r12+CTX_PATCHED_HIDDEN_QUERY_RESULT],rax
    inc qword ptr [r12+CTX_HIDDEN_NEARNESS_PATCH_SEEN]
    mov eax,1
    jmp .Lms10_done
.Lms10_fail:
    xor eax,eax
.Lms10_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage10_legacy_hidden_handler,.-monster_stage10_legacy_hidden_handler


# Ⲛⲉⲩⲙⲉⲉⲩⲉ ϫⲉ ⲡdropStore ⲙⲁⲩⲁⲁϥ ⲛⲁϣϩⲁⲣⲉϩ ⲉⲡhistory ⲛⲓⲙ.
# Ⲡ legacyPrior ⲇⲉ ϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡslot i-back ϩⲙⲡdropStore; ⲛϥⲥⲟⲟⲩⲛ ⲁⲛ ⲙⲡhidden storage.
.type legacyPrior,@function
legacyPrior:
    test rdi,rdi
    je .Llp_fail
    mov rax,rsi
    sub rax,rdx
    mov rax,qword ptr [rdi+rax*8]
    ret
.Llp_fail:
    xor eax,eax
    ret
.size legacyPrior,.-legacyPrior

.type priorPatch,@function
priorPatch:
    # rdi=dropStore(logical slot 0), rsi=hiddenBackward, rdx=i, rcx=back.
    # Ⲡslot ⲉϥⲟ ⲛ1 ⲏ ⲉϥⲛⲁⲁⲁϥ ϫⲓ ⲙⲡlegacy; ⲡslot ⲛ0 ϣⲁ -6 ϫⲓ ⲙⲡhidden ⲕⲁⲧⲁ k=1-slot.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rax,r14
    sub rax,r15
    cmp rax,1
    jl .Lpp_hidden
    mov rdi,r12
    mov rsi,r14
    mov rdx,r15
    call legacyPrior
    jmp .Lpp_done
.Lpp_hidden:
    mov rcx,1
    sub rcx,rax
    cmp rcx,1
    jb .Lpp_fail
    cmp rcx,7
    ja .Lpp_fail
    mov rdi,r13
    mov rsi,rcx
    call hiddenByNearness
    jmp .Lpp_done
.Lpp_fail:
    xor eax,eax
.Lpp_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size priorPatch,.-priorPatch

.type monster_stage13_prior_patch_wrapper,@function
monster_stage13_prior_patch_wrapper:
    jmp priorPatch
.size monster_stage13_prior_patch_wrapper,.-monster_stage13_prior_patch_wrapper

.type monster_prior_route,@function
monster_prior_route:
    jmp monster_stage13_prior_patch_wrapper
.size monster_prior_route,.-monster_prior_route

.type monster_stage12_legacy_prior_handler,@function
monster_stage12_legacy_prior_handler:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    test r12,r12
    je .Lms12_fail
    mov r13,qword ptr [r12+CTX_HIDDEN_BACKWARD]
    test r13,r13
    je .Lms12_fail

    # Ⲡbuffer ⲕⲱ ⲛlogical slot -6..8. Ⲛslot ⲙⲡⲥⲁ ⲛⲥⲁϩⲟⲩ ⲥⲉⲟ ⲛ0, ϫⲉ ⲡlegacy ⲛϥⲥⲟⲟⲩⲛ ⲁⲛ ⲙⲡhidden.
    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lms12_fail
    mov r14,rax
    mov rdi,r14
    xor eax,eax
    mov ecx,15
    rep stosq
    lea r15,[r14+48]
    mov qword ptr [r12+CTX_DROP_STORE],r15

    mov edi,111
    call bi_from_u64
    test rax,rax
    je .Lms12_fail
    mov qword ptr [r15+8],rax

    mov qword ptr [r12+CTX_PRIOR_I],1
    mov qword ptr [r12+CTX_PRIOR_BACK],1

    # COPY_DIAGNOSTIC: slot 0 ⲙⲡdropStore ⲟ ⲛ0, ⲉⲣⲉ hidden1 ϣⲟⲟⲡ ϩⲙⲡstorage ⲉⲧⲕⲟⲟϩ.
    mov rdi,r15
    mov esi,1
    mov edx,1
    call legacyPrior
    mov qword ptr [r12+CTX_LEGACY_PRIOR_RESULT],rax
    inc qword ptr [r12+CTX_LEGACY_PRIOR_SEEN]

    # Ⲡroute ⲙⲡDISCOVERY ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡlegacy ⲁϫⲛ ⲟⲩdetour.
    mov rdi,r15
    mov rsi,r13
    mov edx,1
    mov ecx,1
    call monster_prior_route
    mov qword ptr [r12+CTX_PRIOR_ROUTE_RESULT],rax
    mov qword ptr [r12+CTX_PATCHED_PRIOR_RESULT],rax
    inc qword ptr [r12+CTX_PRIOR_ROUTE_SEEN]
    inc qword ptr [r12+CTX_PRIOR_PATCH_SEEN]
    mov eax,1
    jmp .Lms12_done
.Lms12_fail:
    xor eax,eax
.Lms12_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size monster_stage12_legacy_prior_handler,.-monster_stage12_legacy_prior_handler

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
    mov rdi,r12
    lea rsi,[rip+monster_stage06_legacy_distance_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage08_legacy_stone_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage10_legacy_hidden_handler]
    call monster_dispatch_base
    test eax,eax
    je .Lcds_fail
    mov rdi,r12
    lea rsi,[rip+monster_stage12_legacy_prior_handler]
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
