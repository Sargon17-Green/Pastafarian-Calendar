.intel_syntax noprefix

.equ HCOUNTS_ACTION,0
.equ HCOUNTS_TARGET,8
.equ HCOUNTS_DISTANCE,16
.equ HCOUNTS_CONNECTION,24
.equ HCOUNTS_DIRECTION,32
.equ HCOUNTS_SIZE,40

.equ S23_BOWLS_AFTER_DROPS,0
.equ S23_FINAL_BOWLS,8
.equ S23_DROP46_DIAGNOSTIC,16
.equ S23_LEGACY_ORDER_MEMORY,24
.equ S23_LAST_POST_ORDER,32
.equ S23_QUERY_ORDER,40
.equ S23_DROPS,48
.equ S23_HIDDEN,56
.equ S23_ORDER_WRITE_COUNT,64
.equ S23_LAST_SOURCE_KIND,72
.equ S23_LAST_SOURCE_ORDINAL,80
.equ S23_ORDER46_LATCH,88
.equ S23_LATCH_WRITE_COUNT,96
.equ S23_LATCH_SOURCE_ORDINAL,104
.equ S23_LEGACY_DIAGNOSTIC_RESULT,112
.equ S56_OLD_RESULT,120
.equ S56_CORRECTED_RESULT,128
.equ S56_RAW_BOWL_SUM,136
.equ S56_SAVED_ORDER_NUMBER,144
.equ S56_STIR_INDEX,152
.equ S56_APPLIED_COUNT,160
.equ S56_APPLIED_FLAG,168
.equ S56_ORDER_GUARD,176
.equ S56_SIZE,184

.equ CTX_STAGE56_OLD_RESULT,2704
.equ CTX_STAGE56_CORRECTED_RESULT,2712
.equ CTX_STAGE56_RAW_BOWL_SUM,2720
.equ CTX_STAGE56_SAVED_ORDER_NUMBER,2728
.equ CTX_STAGE56_STIR_INDEX,2736
.equ CTX_STAGE56_APPLIED_COUNT,2744
.equ CTX_STAGE56_APPLIED_FLAG,2752
.equ CTX_STAGE56_ORDER_GUARD,2760

.section .bss
.align 8
.global stage56_ACTIVE_CONTEXT
stage56_ACTIVE_CONTEXT: .quad 0

.section .text
.extern arena_alloc
.extern bi_from_u64
.extern bi_from_i64
.extern bi_clone
.extern bi_add_abs
.extern bi_add_u64
.extern bi_mul_u64
.extern bi_mul_abs
.extern bi_cmp
.extern savePatch
.extern dayTagWithFoundationScar
.extern distanceWithChronologicalScar
.extern getStoneTableThroughLegacyBuilder
.extern buildHiddenWithBackwardStorage
.extern initialBowlsThroughStage22OldFactory
.extern monster_visible_drop_route
.extern orderPatchFromValue
.extern patchedPours
.extern stirOneDropViaShadow
.extern postStirOneOverwritingOrderMemoryStage22
.extern stage56_LEGACY_SAVED_ORDER_WITNESS
.extern stage56_LEGACY_POSTSTIR_CALL_COUNT

.global stage56ContextEnter
.global stage56ContextLeave
.global stage56PostStirRawBowlSumDetour
.global stage56SauceRawBowlSumCorrective

# Ⲡcontext ⲙⲡⲁⲧϣ 56 ⲕⲱ ⲙⲡⲉϥⲟⲩⲱϩ ⲉϩⲟⲩⲛ ⲁⲩⲱ ϥϯ ⲙⲡcontext ⲛϣⲟⲣⲡ ⲉⲃⲟⲗ.
.type stage56ContextEnter,@function
stage56ContextEnter:
    mov rax,qword ptr [rip+stage56_ACTIVE_CONTEXT]
    mov qword ptr [rip+stage56_ACTIVE_CONTEXT],rdi
    ret
.size stage56ContextEnter,.-stage56ContextEnter

# Ⲡcontext ⲙⲡⲁⲧϣ 56 ⲕⲧⲟ ⲉⲡcontext ⲛϣⲟⲣⲡ.
.type stage56ContextLeave,@function
stage56ContextLeave:
    mov qword ptr [rip+stage56_ACTIVE_CONTEXT],rdi
    ret
.size stage56ContextLeave,.-stage56ContextLeave

# Ⲡⲁⲓ ⲕⲁⲑⲁⲣⲓⲍⲉ ⲛⲛstate ⲙⲡⲁⲧϣ 56 ϩⲙⲡcontext ⲉⲧⲟⲛϩ.
.type stage56ContextReset,@function
stage56ContextReset:
    mov rax,qword ptr [rip+stage56_ACTIVE_CONTEXT]
    test rax,rax
    je .Ls56cr_done
    mov qword ptr [rax+CTX_STAGE56_OLD_RESULT],0
    mov qword ptr [rax+CTX_STAGE56_CORRECTED_RESULT],0
    mov qword ptr [rax+CTX_STAGE56_RAW_BOWL_SUM],0
    mov qword ptr [rax+CTX_STAGE56_SAVED_ORDER_NUMBER],0
    mov qword ptr [rax+CTX_STAGE56_STIR_INDEX],0
    mov qword ptr [rax+CTX_STAGE56_APPLIED_COUNT],0
    mov qword ptr [rax+CTX_STAGE56_APPLIED_FLAG],0
    mov qword ptr [rax+CTX_STAGE56_ORDER_GUARD],0
.Ls56cr_done:
    ret
.size stage56ContextReset,.-stage56ContextReset

# Ⲡrdi ϫⲓ `oldGhostBowls`, ⲡrsi `correctedBowls`, ⲡrdx `rawBowlSum`, ⲡrcx `savedOrderNumber`, ⲡr8 `stir`.
.type stage56ContextRecord,@function
stage56ContextRecord:
    mov rax,qword ptr [rip+stage56_ACTIVE_CONTEXT]
    test rax,rax
    je .Ls56crec_done
    mov qword ptr [rax+CTX_STAGE56_OLD_RESULT],rdi
    mov qword ptr [rax+CTX_STAGE56_CORRECTED_RESULT],rsi
    mov qword ptr [rax+CTX_STAGE56_RAW_BOWL_SUM],rdx
    mov qword ptr [rax+CTX_STAGE56_SAVED_ORDER_NUMBER],rcx
    mov qword ptr [rax+CTX_STAGE56_STIR_INDEX],r8
    inc qword ptr [rax+CTX_STAGE56_APPLIED_COUNT]
    mov qword ptr [rax+CTX_STAGE56_APPLIED_FLAG],1
    mov qword ptr [rax+CTX_STAGE56_ORDER_GUARD],1
.Ls56crec_done:
    ret
.size stage56ContextRecord,.-stage56ContextRecord

# Ⲡrdi ϫⲓ ⲙⲡ`orderA`, ⲡrsi ⲙⲡ`orderB`; ⲡeax ⲕⲧⲟ 1 ⲏ 0.
.type stage56SameOrder,@function
stage56SameOrder:
    xor ecx,ecx
.Ls56so_loop:
    cmp rcx,6
    jae .Ls56so_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Ls56so_no
    inc rcx
    jmp .Ls56so_loop
.Ls56so_yes:
    mov eax,1
    ret
.Ls56so_no:
    xor eax,eax
    ret
.size stage56SameOrder,.-stage56SameOrder

# Ⲡⲁⲓ ⲣϩⲱⲃ ⲙⲡscar ⲛϣⲟⲣⲡ, ⲉⲓⲧⲁ ϥⲕⲧⲟ ⲛⲟⲩⲱⲧ ⲉⲧⲉ rawBowlSum ⲡⲉ ϩⲙⲡu.
# Ⲡrdi ϫⲓ ⲛ`authoritativeBowls[6]`, ⲡrsi ⲙⲡ`stir 1..12`; ⲡrax ⲕⲧⲟ ⲙⲡbowls ⲏ 0.
.type stage56PostStirRawBowlSumDetour,@function
stage56PostStirRawBowlSumDetour:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,152
    mov r12,rdi
    mov r13,rsi
    mov qword ptr [rbp-128],rdx
    mov qword ptr [rbp-136],rcx
    test r12,r12
    je .Ls56ps_fail
    cmp r13,1
    jb .Ls56ps_fail
    cmp r13,12
    ja .Ls56ps_fail

    # Ⲡsnapshot ⲙⲡcorrected old bowls ⲟⲩⲏϩ ⲉϥⲧⲁϫⲣⲟ ϩⲁⲑⲏ ⲙⲡscar.
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56ps_fail
    mov r14,rax
    xor ebx,ebx
.Ls56ps_copy_ghost:
    cmp rbx,6
    jae .Ls56ps_old_order
    mov rax,qword ptr [r12+rbx*8]
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [r14+rbx*8],rax
    inc rbx
    jmp .Ls56ps_copy_ghost

.Ls56ps_old_order:
    mov rax,qword ptr [rbp-128]
    test rax,rax
    jne .Ls56ps_old_order_ready
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56ps_fail
.Ls56ps_old_order_ready:
    mov qword ptr [rbp-48],rax
    mov rdi,r14
    mov rsi,r13
    mov rdx,rax
    call postStirOneOverwritingOrderMemoryStage22
    test rax,rax
    je .Ls56ps_fail
    mov rax,qword ptr [rip+stage56_LEGACY_SAVED_ORDER_WITNESS]
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-144],rax

    # Ⲡraw bowl sum ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙⲡsnapshot ⲛⲟⲩⲱⲧ.
    xor edi,edi
    call bi_from_u64
    test rax,rax
    je .Ls56ps_fail
    mov r15,rax
    xor ebx,ebx
.Ls56ps_sum_loop:
    cmp rbx,6
    jae .Ls56ps_order_number
    mov rdi,r15
    mov rsi,qword ptr [r12+rbx*8]
    call bi_add_abs
    test rax,rax
    je .Ls56ps_fail
    mov r15,rax
    inc rbx
    jmp .Ls56ps_sum_loop

.Ls56ps_order_number:
    mov qword ptr [rbp-56],r15
    mov rax,r13
    imul rax,149
    mov rdi,r15
    mov rsi,rax
    call bi_add_u64
    test rax,rax
    je .Ls56ps_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-64],rax

    # Ⲡwitness ⲛⲟⲩⲱⲧ ⲕⲱ ⲙⲡsaved order number ⲛⲕⲉⲥⲟⲡ ⲁⲩⲱ ϥⲧⲁϫⲣⲟ ⲙⲡguard.
    mov rax,r13
    imul rax,149
    mov rdi,qword ptr [rbp-56]
    mov rsi,rax
    call bi_add_u64
    test rax,rax
    je .Ls56ps_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-72],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-72]
    call bi_cmp
    test eax,eax
    jne .Ls56ps_fail
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-144]
    call bi_cmp
    test eax,eax
    jne .Ls56ps_fail

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-80],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,rax
    call orderPatchFromValue
    test rax,rax
    je .Ls56ps_fail
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-80]
    call stage56SameOrder
    test eax,eax
    je .Ls56ps_fail

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-88],rax
    xor ebx,ebx
.Ls56ps_bowl_loop:
    cmp rbx,6
    jae .Ls56ps_validate
    mov rdx,qword ptr [rbp-80]
    mov rax,qword ptr [rdx+rbx*8]
    cmp rax,1
    jb .Ls56ps_fail
    cmp rax,6
    ja .Ls56ps_fail
    mov qword ptr [rbp-96],rax
    mov rcx,rbx
    add rcx,5
    cmp rcx,6
    jb .Ls56ps_prev_ready
    sub rcx,6
.Ls56ps_prev_ready:
    mov rax,qword ptr [rdx+rcx*8]
    mov qword ptr [rbp-104],rax
    mov rcx,rbx
    inc rcx
    cmp rcx,6
    jb .Ls56ps_next_ready
    xor ecx,ecx
.Ls56ps_next_ready:
    mov rax,qword ptr [rdx+rcx*8]
    mov qword ptr [rbp-112],rax

    mov rax,qword ptr [rbp-96]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    call bi_clone
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-120],rax

    mov rax,qword ptr [rbp-104]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,3
    call bi_mul_u64
    test rax,rax
    je .Ls56ps_fail
    mov rdi,qword ptr [rbp-120]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-120],rax

    mov rax,qword ptr [rbp-112]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,5
    call bi_mul_u64
    test rax,rax
    je .Ls56ps_fail
    mov rdi,qword ptr [rbp-120]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-120],rax

    # Ⲡoperand ⲡⲁⲓ ⲡⲉ ⲡraw bowl sum; ⲡsaved order number ⲟⲩⲏϩ ⲉⲡpermutation ⲙⲙⲁⲧⲉ.
    mov rdi,qword ptr [rbp-120]
    mov rsi,qword ptr [rbp-56]
    call bi_add_abs
    test rax,rax
    je .Ls56ps_fail
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    test rax,rax
    je .Ls56ps_fail
    mov rcx,rbx
    inc rcx
    imul rcx,rcx
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Ls56ps_fail
    mov rdi,rax
    mov rsi,rax
    call bi_mul_abs
    test rax,rax
    je .Ls56ps_fail
    mov qword ptr [rbp-120],rax

    mov rax,qword ptr [rbp-104]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov rax,qword ptr [rbp-112]
    dec rax
    mov rsi,qword ptr [r12+rax*8]
    call bi_mul_abs
    test rax,rax
    je .Ls56ps_fail
    mov rdi,rax
    mov esi,7
    call bi_mul_u64
    test rax,rax
    je .Ls56ps_fail
    mov rdi,qword ptr [rbp-120]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Ls56ps_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Ls56ps_fail
    mov rcx,qword ptr [rbp-96]
    dec rcx
    mov rdx,qword ptr [rbp-88]
    mov qword ptr [rdx+rcx*8],rax
    inc rbx
    jmp .Ls56ps_bowl_loop

.Ls56ps_validate:
    xor ebx,ebx
.Ls56ps_validate_loop:
    cmp rbx,6
    jae .Ls56ps_commit
    mov rax,qword ptr [rbp-88]
    cmp qword ptr [rax+rbx*8],0
    je .Ls56ps_fail
    inc rbx
    jmp .Ls56ps_validate_loop
.Ls56ps_commit:
    xor ebx,ebx
.Ls56ps_commit_loop:
    cmp rbx,6
    jae .Ls56ps_record
    mov rax,qword ptr [rbp-88]
    mov rdx,qword ptr [rax+rbx*8]
    mov qword ptr [r12+rbx*8],rdx
    inc rbx
    jmp .Ls56ps_commit_loop
.Ls56ps_record:
    mov rax,qword ptr [rbp-136]
    test rax,rax
    je .Ls56ps_record_context
    mov qword ptr [rax+S56_OLD_RESULT],r14
    mov qword ptr [rax+S56_CORRECTED_RESULT],r12
    mov rdx,qword ptr [rbp-56]
    mov qword ptr [rax+S56_RAW_BOWL_SUM],rdx
    mov rdx,qword ptr [rbp-64]
    mov qword ptr [rax+S56_SAVED_ORDER_NUMBER],rdx
    mov qword ptr [rax+S56_STIR_INDEX],r13
    inc qword ptr [rax+S56_APPLIED_COUNT]
    mov qword ptr [rax+S56_APPLIED_FLAG],1
    mov qword ptr [rax+S56_ORDER_GUARD],1
.Ls56ps_record_context:
    mov rdi,r14
    mov rsi,r12
    mov rdx,qword ptr [rbp-56]
    mov rcx,qword ptr [rbp-64]
    mov r8,r13
    call stage56ContextRecord
    mov rax,r12
    jmp .Ls56ps_done
.Ls56ps_fail:
    xor eax,eax
.Ls56ps_done:
    add rsp,152
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage56PostStirRawBowlSumDetour,.-stage56PostStirRawBowlSumDetour

# Ⲡsauce ⲙⲡⲁⲧϣ 56 ⲥⲱⲟⲩϩ ⲛⲛ46 drop ⲕⲁⲧⲁ ⲛscar ⲉⲧϣⲟⲟⲡ, ⲉⲓⲧⲁ ϥⲣ 12 ⲛscar+detour ⲛⲟⲩⲱⲧ ⲛⲟⲩⲱⲧ.
# Ⲡrdi ϫⲓ ⲙⲡ`calculation i64`, ⲡrsi ⲙⲡ`target i64`; ⲡrax ⲕⲧⲟ ⲙⲡ`S56*` ⲉϥϩⲁⲣⲉϩ ⲉⲡ`S23` prefix.
.type stage56SauceRawBowlSumCorrective,@function
stage56SauceRawBowlSumCorrective:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,184
    mov qword ptr [rbp-48],rdi
    mov qword ptr [rbp-56],rsi
    call stage56ContextReset

    mov edi,S56_SIZE
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov r12,rax
    mov rdi,r12
    xor eax,eax
    mov ecx,S56_SIZE/8
    rep stosq

    mov edi,HCOUNTS_SIZE
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov r13,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_i64
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-64],rax
    mov rdi,rax
    call dayTagWithFoundationScar
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r13+HCOUNTS_ACTION],rax
    mov rdi,qword ptr [rbp-56]
    call bi_from_i64
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-72],rax
    mov rdi,rax
    call dayTagWithFoundationScar
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r13+HCOUNTS_TARGET],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-72]
    call distanceWithChronologicalScar
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r13+HCOUNTS_DISTANCE],rax
    mov rdi,qword ptr [r13+HCOUNTS_ACTION]
    mov rsi,qword ptr [r13+HCOUNTS_TARGET]
    call bi_add_abs
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r13+HCOUNTS_CONNECTION],rax
    mov rax,qword ptr [rbp-56]
    cmp rax,qword ptr [rbp-48]
    jl .Ls56s_dir1
    je .Ls56s_dir2
    mov edi,3
    jmp .Ls56s_dir_make
.Ls56s_dir1:
    mov edi,1
    jmp .Ls56s_dir_make
.Ls56s_dir2:
    mov edi,2
.Ls56s_dir_make:
    call bi_from_u64
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r13+HCOUNTS_DIRECTION],rax

    call getStoneTableThroughLegacyBuilder
    test rax,rax
    je .Ls56s_fail
    mov r14,rax
    mov rdi,r13
    mov rsi,r14
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Ls56s_fail
    mov r15,rax
    mov qword ptr [r12+S23_HIDDEN],r15

    mov edi,424
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-80],rax
    mov rdi,rax
    xor eax,eax
    mov ecx,53
    rep stosq
    mov rax,qword ptr [rbp-80]
    add rax,48
    mov qword ptr [rbp-88],rax
    mov qword ptr [r12+S23_DROPS],rax

    mov rdi,r13
    call initialBowlsThroughStage22OldFactory
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-96],rax

    mov edi,144
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-104],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-112],rcx
    lea rcx,[rax+96]
    mov qword ptr [rbp-120],rcx
    mov qword ptr [r12+S23_LEGACY_ORDER_MEMORY],rax
    mov rcx,qword ptr [rbp-112]
    mov qword ptr [r12+S23_DROP46_DIAGNOSTIC],rcx
    mov rcx,qword ptr [rbp-120]
    mov qword ptr [r12+S23_LAST_POST_ORDER],rcx

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-128],rax
    mov qword ptr [r12+S23_ORDER46_LATCH],rax

    mov rbx,1
.Ls56s_drop_loop:
    cmp rbx,46
    ja .Ls56s_after_drops
    mov rdi,r13
    mov rsi,r14
    mov rdx,qword ptr [rbp-88]
    mov rcx,r15
    mov r8,rbx
    call monster_visible_drop_route
    test rax,rax
    je .Ls56s_fail
    mov rdx,qword ptr [rbp-88]
    mov qword ptr [rdx+rbx*8],rax
    mov qword ptr [rbp-136],rax

    mov edi,72
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [rbp-144],rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-152],rcx
    mov rdi,qword ptr [rbp-136]
    mov rsi,qword ptr [rbp-144]
    call orderPatchFromValue
    test rax,rax
    je .Ls56s_fail

    mov rax,rbx
    dec rax
    imul rax,40
    lea rcx,[r14+rax]
    mov rdi,qword ptr [rbp-136]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-96]
    mov r8,qword ptr [rbp-144]
    mov r9,qword ptr [rbp-152]
    call patchedPours
    test rax,rax
    je .Ls56s_fail

    mov rax,rbx
    dec rax
    imul rax,40
    lea rcx,[r14+rax]
    mov rdi,qword ptr [rbp-96]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-136]
    mov r8,qword ptr [rbp-144]
    mov r9,qword ptr [rbp-152]
    call stirOneDropViaShadow
    test rax,rax
    je .Ls56s_fail

    xor ecx,ecx
.Ls56s_write_drop_order:
    cmp rcx,6
    jae .Ls56s_drop_written
    mov rax,qword ptr [rbp-144]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Ls56s_write_drop_order
.Ls56s_drop_written:
    inc qword ptr [r12+S23_ORDER_WRITE_COUNT]
    mov qword ptr [r12+S23_LAST_SOURCE_KIND],1
    mov qword ptr [r12+S23_LAST_SOURCE_ORDINAL],rbx
    cmp rbx,46
    jne .Ls56s_next_drop

    xor ecx,ecx
.Ls56s_copy46_diag:
    cmp rcx,6
    jae .Ls56s_copy46_latch
    mov rax,qword ptr [rbp-144]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-112]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Ls56s_copy46_diag
.Ls56s_copy46_latch:
    xor ecx,ecx
.Ls56s_copy46_latch_loop:
    cmp rcx,6
    jae .Ls56s_latch_done
    mov rax,qword ptr [rbp-144]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-128]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Ls56s_copy46_latch_loop
.Ls56s_latch_done:
    inc qword ptr [r12+S23_LATCH_WRITE_COUNT]
    mov qword ptr [r12+S23_LATCH_SOURCE_ORDINAL],46
.Ls56s_next_drop:
    inc rbx
    jmp .Ls56s_drop_loop

.Ls56s_after_drops:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r12+S23_BOWLS_AFTER_DROPS],rax
    xor ecx,ecx
.Ls56s_copy_after_drops:
    cmp rcx,6
    jae .Ls56s_post_begin
    mov rdx,qword ptr [rbp-96]
    mov rdx,qword ptr [rdx+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Ls56s_copy_after_drops

.Ls56s_post_begin:
    mov qword ptr [rip+stage56_LEGACY_POSTSTIR_CALL_COUNT],0
    mov rbx,1
.Ls56s_post_loop:
    cmp rbx,12
    ja .Ls56s_finish
    mov rdi,qword ptr [rbp-96]
    mov rsi,rbx
    mov rdx,qword ptr [rbp-120]
    mov rcx,r12
    call stage56PostStirRawBowlSumDetour
    test rax,rax
    je .Ls56s_fail

    # Ⲡlegacy order memory ⲟⲩⲏϩ ⲉϥⲥϩⲁⲓ ⲙⲡorder ⲙⲡscar ⲙⲡstir ⲡⲁⲓ.
    xor ecx,ecx
.Ls56s_post_order_copy:
    cmp rcx,6
    jae .Ls56s_post_count
    mov rax,qword ptr [rbp-120]
    mov rdx,qword ptr [rax+rcx*8]
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Ls56s_post_order_copy
.Ls56s_post_count:
    inc qword ptr [r12+S23_ORDER_WRITE_COUNT]
    mov qword ptr [r12+S23_LAST_SOURCE_KIND],2
    mov qword ptr [r12+S23_LAST_SOURCE_ORDINAL],rbx
    inc rbx
    jmp .Ls56s_post_loop

.Ls56s_finish:
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls56s_fail
    mov qword ptr [r12+S23_FINAL_BOWLS],rax
    mov qword ptr [r12+S56_CORRECTED_RESULT],rax
    xor ecx,ecx
.Ls56s_final_copy:
    cmp rcx,6
    jae .Ls56s_validate
    mov rdx,qword ptr [rbp-96]
    mov rdx,qword ptr [rdx+rcx*8]
    mov qword ptr [rax+rcx*8],rdx
    inc rcx
    jmp .Ls56s_final_copy
.Ls56s_validate:
    mov rax,qword ptr [rbp-128]
    mov qword ptr [r12+S23_QUERY_ORDER],rax
    cmp qword ptr [r12+S23_LATCH_WRITE_COUNT],1
    jne .Ls56s_fail
    cmp qword ptr [r12+S23_LATCH_SOURCE_ORDINAL],46
    jne .Ls56s_fail
    cmp qword ptr [r12+S23_ORDER_WRITE_COUNT],58
    jne .Ls56s_fail
    cmp qword ptr [r12+S23_LAST_SOURCE_KIND],2
    jne .Ls56s_fail
    cmp qword ptr [r12+S23_LAST_SOURCE_ORDINAL],12
    jne .Ls56s_fail
    cmp qword ptr [r12+S56_APPLIED_COUNT],12
    jne .Ls56s_fail
    cmp qword ptr [rip+stage56_LEGACY_POSTSTIR_CALL_COUNT],12
    jne .Ls56s_fail
    mov rax,qword ptr [r12+S56_OLD_RESULT]
    mov qword ptr [r12+S23_LEGACY_DIAGNOSTIC_RESULT],rax
    cmp qword ptr [r12+S56_APPLIED_FLAG],1
    jne .Ls56s_fail
    cmp qword ptr [r12+S56_ORDER_GUARD],1
    jne .Ls56s_fail
    mov rax,qword ptr [rip+stage56_ACTIVE_CONTEXT]
    test rax,rax
    je .Ls56s_ok
    mov rdx,qword ptr [r12+S23_FINAL_BOWLS]
    mov qword ptr [rax+CTX_STAGE56_CORRECTED_RESULT],rdx
.Ls56s_ok:
    mov rax,r12
    jmp .Ls56s_done
.Ls56s_fail:
    xor eax,eax
.Ls56s_done:
    add rsp,184
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage56SauceRawBowlSumCorrective,.-stage56SauceRawBowlSumCorrective
