.intel_syntax noprefix

.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24
.equ G_INDEX,0
.equ G_DAY,8
.equ G_PREV,16
.equ G_NEXT,24
.equ G_SIZE,32
.equ Y_NUMBER,0
.equ Y_OPEN,8
.equ Y_CLOSE,16
.equ Y_OPEN_DAY,24
.equ Y_CLOSE_DAY,32
.equ Y_SIZE,40
.equ C_OPEN,0
.equ C_CLOSE,8
.equ C_NEXT,16
.equ C_SIZE,24
.equ YEAR_MIN,252
.equ YEAR_MAX,5778
.equ YEAR_BUCKETS,5527
.equ CUT_FIRST,0
.equ CUT_LAST,8
.equ CUT_NAME_ID,16
.equ CUT_SIZE,24
.equ YS_YEAR,0
.equ YS_FIRST_DAY,8
.equ YS_CUTLET_COUNT,16
.equ YS_PARTITION,24
.equ YS_CUTLET_NAMES,32
.equ YS_CUTLETS,40
.equ YS_MONTH_COUNT,48
.equ YS_MONTH_LENGTHS,56
.equ YS_WEAVE,64
.equ YS_MONTH_NAMES,72
.equ YS_SIZE,80
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.equ RES_SIZE,40
.equ CTX_STAGE54_PHASE,2608
.equ CTX_STAGE54_PENDING,2616
.equ CTX_STAGE54_COMMITTED,2624
.equ CTX_STAGE54_RESULT,2632
.equ CTX_STAGE54_YEAR,2640
.equ CTX_STAGE54_STRUCTURE,2648
.equ CTX_STAGE54_RETRY,2656
.equ CTX_STAGE54_VALIDATIONS,2664
.equ CTX_STAGE54_METRICS,2672
.equ CTX_STAGE54_LOGS,2680
.equ CTX_STAGE54_LEGACY_STATUS,2688
.equ CTX_STAGE54_SEEN,2696

.section .bss
.align 8
.global stage54_GATE_ZERO
.global stage54_GATE_MIN
.global stage54_GATE_MAX
.global stage54_FOUNDATION
stage54_GATE_ZERO: .quad 0
stage54_GATE_MIN: .quad 0
stage54_GATE_MAX: .quad 0
stage54_FOUNDATION: .quad 0

.section .text
.extern arena_alloc
.extern arena_mark
.extern arena_reset
.extern bi_zero
.extern bi_from_u64
.extern bi_from_i64
.extern bi_clone
.extern bi_cmp
.extern bi_add
.extern bi_sub
.extern bi_add_u64
.extern bi_mul_u64
.extern bi_divmod_u64_abs
.extern monster_context_new
.extern calendarDateSpaghettiLegacyDiagnostic
.extern sauceWithOrderAt46Latch
.extern oldStructureSauce
.extern answerRingThroughPatchedNextBowl
.extern ringAnswer
.extern selectionPatch14
.extern filteredCutletPartitionFamilyCount
.extern monster_cutlet_partition_route
.extern namePatch22FallingBig
.extern monster_cutlet_names_route
.extern monster_month_length_family_route
.extern virtualMonthLengthListCount
.extern virtualMonthLengthListItemAt1Big
.extern CountWeavingsByDP
.extern monster_month_weaving_route
.extern monster_month_names_route_big
.extern monster_day_in_month_route
.extern catalog_get_cutlet
.extern catalog_get_month

.global sauceWithScars
.global calendarDateSpaghetti
.global stage54_find_target_year
.global stage54BuildYearStructure
.global stage54FinalizeFiveFields

# Ⲡⲁⲓ ϫⲓ ⲙⲡBigInt ⲉⲩⲧⲓⲙⲏ ⲛ64-bit.
.type stage54BigToU64,@function
stage54BigToU64:
    test rdi,rdi
    je .Ls54btu_fail
    cmp qword ptr [rdi+BI_SIGN],0
    je .Ls54btu_zero
    cmp qword ptr [rdi+BI_SIGN],1
    jne .Ls54btu_fail
    cmp qword ptr [rdi+BI_LEN],1
    jne .Ls54btu_fail
    mov rdx,qword ptr [rdi+BI_DATA]
    test rdx,rdx
    je .Ls54btu_fail
    mov rax,qword ptr [rdx]
    ret
.Ls54btu_zero:
    xor eax,eax
    ret
.Ls54btu_fail:
    xor eax,eax
    mov rdx,-1
    ret
.size stage54BigToU64,.-stage54BigToU64

# Ⲡⲁⲓ ϫⲓ ⲙⲡBigInt ⲉⲩⲏⲙⲉⲣⲁ ⲛ64-bit.
.type stage54BigToI64,@function
stage54BigToI64:
    test rdi,rdi
    je .Ls54bti_fail
    mov rcx,qword ptr [rdi+BI_SIGN]
    test rcx,rcx
    je .Ls54bti_zero
    cmp qword ptr [rdi+BI_LEN],1
    jne .Ls54bti_fail
    mov rdx,qword ptr [rdi+BI_DATA]
    test rdx,rdx
    je .Ls54bti_fail
    mov rax,qword ptr [rdx]
    cmp rcx,1
    je .Ls54bti_pos
    cmp rcx,-1
    jne .Ls54bti_fail
    movabs rdx,0x8000000000000000
    cmp rax,rdx
    ja .Ls54bti_fail
    neg rax
    mov edx,1
    ret
.Ls54bti_pos:
    movabs rdx,0x7fffffffffffffff
    cmp rax,rdx
    ja .Ls54bti_fail
    mov edx,1
    ret
.Ls54bti_zero:
    xor eax,eax
    mov edx,1
    ret
.Ls54bti_fail:
    xor eax,eax
    xor edx,edx
    ret
.size stage54BigToI64,.-stage54BigToI64

# Ⲡstage54AskRing ⲙⲟⲟϣⲉ ϩⲓⲧⲛ answerRingThroughPatchedNextBowl.
.type stage54AskRing,@function
stage54AskRing:
    jmp answerRingThroughPatchedNextBowl
.size stage54AskRing,.-stage54AskRing

# ⲠsauceWithScars ⲙⲟⲟϣⲉ ϩⲓⲧⲛ sauceWithOrderAt46Latch ⲙⲛ ⲛscar ⲉⲧϩⲁⲑⲏ.
.type sauceWithScars,@function
sauceWithScars:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov qword ptr [rbp-48],2
    mov qword ptr [rbp-56],0
.Ls54s_state_validate:
    test r12,r12
    je .Ls54s_recover
    test r13,r13
    je .Ls54s_recover
    mov rdi,r12
    call stage54BigToI64
    test rdx,rdx
    je .Ls54s_recover
    mov r14,rax
    mov rdi,r13
    call stage54BigToI64
    test rdx,rdx
    je .Ls54s_recover
    mov r15,rax
    inc qword ptr [rbp-56]
.Ls54s_state_build:
    mov rdi,r14
    mov rsi,r15
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Ls54s_recover
    mov rbx,rax
    mov rax,qword ptr [rbx+8]
    test rax,rax
    je .Ls54s_recover
    mov rax,qword ptr [rbx+40]
    test rax,rax
    je .Ls54s_recover
    cmp qword ptr [rbx+96],1
    jne .Ls54s_recover
    mov rax,rbx
    jmp .Ls54s_done
.Ls54s_recover:
    dec qword ptr [rbp-48]
    js .Ls54s_fail
    inc qword ptr [rbp-56]
    cmp qword ptr [rbp-48],0
    je .Ls54s_state_validate
    jmp .Ls54s_state_validate
.Ls54s_fail:
    xor eax,eax
.Ls54s_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size sauceWithScars,.-sauceWithScars

.type stage54_gate_init,@function
stage54_gate_init:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    cmp qword ptr [rip+stage54_GATE_ZERO],0
    jne .Ls54gi_done
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Ls54gi_fail
    mov qword ptr [rip+stage54_FOUNDATION],rax
    mov r13,rax
    mov rdi,G_SIZE
    call arena_alloc
    test rax,rax
    je .Ls54gi_fail
    mov r12,rax
    xor edi,edi
    call bi_from_u64
    mov qword ptr [r12+G_INDEX],rax
    mov rdi,r13
    call bi_clone
    mov qword ptr [r12+G_DAY],rax
    mov qword ptr [r12+G_PREV],0
    mov qword ptr [r12+G_NEXT],0
    mov qword ptr [rip+stage54_GATE_ZERO],r12
    mov qword ptr [rip+stage54_GATE_MIN],r12
    mov qword ptr [rip+stage54_GATE_MAX],r12
.Ls54gi_done:
    mov eax,1
    jmp .Ls54gi_exit
.Ls54gi_fail:
    xor eax,eax
.Ls54gi_exit:
    pop r13
    pop r12
    leave
    ret
.size stage54_gate_init,.-stage54_gate_init
.type stage54_gate_gap,@function
stage54_gate_gap:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    call stage54_gate_init
    test r13,r13
    js .Logg_neg
    mov rdi,qword ptr [rip+stage54_FOUNDATION]
    mov rsi,r12
    call bi_add
    jmp .Logg_target
.Logg_neg:
    mov rdi,qword ptr [rip+stage54_FOUNDATION]
    mov rsi,r12
    call bi_sub
.Logg_target:
    mov r14,rax
    mov rdi,qword ptr [rip+stage54_FOUNDATION]
    mov rsi,r14
    call sauceWithScars
    mov r15,rax
    mov rdi,r15
    mov rsi,1
    mov rdx,1
    call stage54AskRing
    mov r14,rax
    mov rdi,922
    call bi_from_u64
    mov rsi,rax
    mov rdi,r14
    call selectionPatch14
    mov rdi,rax
    call stage54BigToU64
    add rax,41
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54_gate_gap,.-stage54_gate_gap

.type stage54_gate_extend_positive,@function
stage54_gate_extend_positive:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    call stage54_gate_init
    mov r12,qword ptr [rip+stage54_GATE_MAX]
    mov rdi,qword ptr [r12+G_INDEX]
    mov rsi,1
    call bi_add_u64
    mov r13,rax
    mov rdi,r13
    mov rsi,1
    call stage54_gate_gap
    mov r14,rax
    mov rdi,qword ptr [r12+G_DAY]
    mov rsi,r14
    call bi_add_u64
    push rax
    mov rdi,G_SIZE
    call arena_alloc
    mov r14,rax
    pop rax
    mov qword ptr [r14+G_INDEX],r13
    mov qword ptr [r14+G_DAY],rax
    mov qword ptr [r14+G_PREV],r12
    mov qword ptr [r14+G_NEXT],0
    mov qword ptr [r12+G_NEXT],r14
    mov qword ptr [rip+stage54_GATE_MAX],r14
    mov rax,r14
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage54_gate_extend_positive,.-stage54_gate_extend_positive

.type stage54_gate_extend_negative,@function
stage54_gate_extend_negative:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    call stage54_gate_init
    mov r12,qword ptr [rip+stage54_GATE_MIN]
    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r12+G_INDEX]
    call bi_sub
    mov r13,rax
    mov rdi,r13
    call bi_abs
    mov rsi,-1
    mov rdi,rax
    call stage54_gate_gap
    mov r14,rax
    mov rdi,r14
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r12+G_DAY]
    call bi_sub
    push rax
    mov rdi,G_SIZE
    call arena_alloc
    mov r14,rax
    pop rax
    mov qword ptr [r14+G_INDEX],r13
    mov qword ptr [r14+G_DAY],rax
    mov qword ptr [r14+G_PREV],0
    mov qword ptr [r14+G_NEXT],r12
    mov qword ptr [r12+G_PREV],r14
    mov qword ptr [rip+stage54_GATE_MIN],r14
    mov rax,r14
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage54_gate_extend_negative,.-stage54_gate_extend_negative

.type stage54_ensure_gates_cover_day,@function
stage54_ensure_gates_cover_day:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    call stage54_gate_init
.Logc_low:
    mov rax,qword ptr [rip+stage54_GATE_MIN]
    mov rdi,qword ptr [rax+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jle .Logc_high
    call stage54_gate_extend_negative
    jmp .Logc_low
.Logc_high:
    mov rax,qword ptr [rip+stage54_GATE_MAX]
    mov rdi,qword ptr [rax+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jge .Logc_done
    call stage54_gate_extend_positive
    jmp .Logc_high
.Logc_done:
    pop r12
    leave
    ret
.size stage54_ensure_gates_cover_day,.-stage54_ensure_gates_cover_day

.type stage54_gate_node_at_or_before,@function
stage54_gate_node_at_or_before:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov rdi,r12
    call stage54_ensure_gates_cover_day
    mov r13,qword ptr [rip+stage54_GATE_ZERO]
    mov rdi,r12
    mov rsi,qword ptr [r13+G_DAY]
    call bi_cmp
    test eax,eax
    jl .Logb_backward
.Logb_forward:
    mov rax,qword ptr [r13+G_NEXT]
    test rax,rax
    je .Logb_done
    mov rdi,qword ptr [rax+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jg .Logb_done
    mov r13,qword ptr [r13+G_NEXT]
    jmp .Logb_forward
.Logb_backward:
    mov rdi,qword ptr [r13+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jle .Logb_done
    mov r13,qword ptr [r13+G_PREV]
    jmp .Logb_backward
.Logb_done:
    mov rax,r13
    pop r13
    pop r12
    leave
    ret
.size stage54_gate_node_at_or_before,.-stage54_gate_node_at_or_before

.type stage54_gate_node_at_or_after,@function
stage54_gate_node_at_or_after:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call stage54_gate_node_at_or_before
    mov r13,rax
    mov rdi,qword ptr [r13+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    je .Loga_done
    mov r13,qword ptr [r13+G_NEXT]
.Loga_done:
    mov rax,r13
    pop r13
    pop r12
    leave
    ret
.size stage54_gate_node_at_or_after,.-stage54_gate_node_at_or_after

.type stage54_exact_gate_node,@function
stage54_exact_gate_node:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call stage54_gate_node_at_or_before
    mov r13,rax
    mov rdi,qword ptr [r13+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    je .Loge_done
    xor r13d,r13d
.Loge_done:
    mov rax,r13
    pop r13
    pop r12
    leave
    ret
.size stage54_exact_gate_node,.-stage54_exact_gate_node

.type stage54_make_year,@function
stage54_make_year:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rdi,Y_SIZE
    call arena_alloc
    mov qword ptr [rax+Y_NUMBER],r12
    mov qword ptr [rax+Y_OPEN],r13
    mov qword ptr [rax+Y_CLOSE],r14
    mov rdx,qword ptr [r13+G_DAY]
    mov qword ptr [rax+Y_OPEN_DAY],rdx
    mov rdx,qword ptr [r14+G_DAY]
    mov qword ptr [rax+Y_CLOSE_DAY],rdx
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage54_make_year,.-stage54_make_year

# Ⲡⲡⲓⲛⲁⲝ ⲛⲛyear candidates ⲥϩⲁⲓ ⲛ0 ⲉϩⲟⲩⲛ, ϫⲉ arena_reset ⲛϥⲃⲱⲗ ⲁⲛ ⲛⲛⲉⲧⲁⲩⲥϩⲁⲓ.
.type stage54_bucket_new,@function
stage54_bucket_new:
    push rbp
    mov rbp,rsp
    mov rdi,YEAR_BUCKETS*16
    call arena_alloc
    test rax,rax
    je .Ls54bn_done
    mov rdx,rax
    mov rdi,rax
    xor eax,eax
    mov ecx,YEAR_BUCKETS*2
    rep stosq
    mov rax,rdx
.Ls54bn_done:
    leave
    ret
.size stage54_bucket_new,.-stage54_bucket_new

.type stage54_bucket_append,@function
stage54_bucket_append:
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
    sub r15,YEAR_MIN
    mov rdi,C_SIZE
    call arena_alloc
    mov qword ptr [rax+C_OPEN],r13
    mov qword ptr [rax+C_CLOSE],r14
    mov qword ptr [rax+C_NEXT],0
    lea rdx,[r12+r15*8]
    lea rcx,[r12+YEAR_BUCKETS*8+r15*8]
    cmp qword ptr [rdx],0
    jne .Loba_nonempty
    mov qword ptr [rdx],rax
    mov qword ptr [rcx],rax
    jmp .Loba_done
.Loba_nonempty:
    mov rsi,qword ptr [rcx]
    mov qword ptr [rsi+C_NEXT],rax
    mov qword ptr [rcx],rax
.Loba_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage54_bucket_append,.-stage54_bucket_append

.type stage54_bucket_select,@function
stage54_bucket_select:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
.Lobs_len:
    cmp r14,YEAR_BUCKETS
    jae .Lobs_fail
    mov rax,qword ptr [r12+r14*8]
.Lobs_node:
    test rax,rax
    je .Lobs_next_len
    dec r13
    je .Lobs_found
    mov rax,qword ptr [rax+C_NEXT]
    jmp .Lobs_node
.Lobs_next_len:
    inc r14
    jmp .Lobs_len
.Lobs_found:
    pop r14
    pop r13
    pop r12
    leave
    ret
.Lobs_fail:
    mov rax,60
    mov rdi,126
    syscall
.size stage54_bucket_select,.-stage54_bucket_select

.type stage54_year5000,@function
stage54_year5000:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    call stage54_gate_init
    mov rdi,r12
    mov rsi,YEAR_MAX
    call bi_add_u64
    mov qword ptr [rbp-56],rax
    mov rdi,YEAR_MAX
    call bi_from_u64
    mov rsi,rax
    mov rdi,r12
    call bi_sub
    mov qword ptr [rbp-64],rax
    mov rdi,qword ptr [rbp-56]
    call stage54_ensure_gates_cover_day
    mov rdi,qword ptr [rbp-64]
    call stage54_ensure_gates_cover_day
    call stage54_bucket_new
    mov r13,rax
    mov qword ptr [rbp-72],0
    mov rdi,qword ptr [rbp-64]
    call stage54_gate_node_at_or_before
    mov r14,rax
    mov rdi,qword ptr [r14+G_DAY]
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    test eax,eax
    jge .Loy5_i_loop
    mov r14,qword ptr [r14+G_NEXT]
.Loy5_i_loop:
    test r14,r14
    je .Loy5_choose
    mov rdi,qword ptr [r14+G_DAY]
    mov rsi,qword ptr [rbp-56]
    call bi_cmp
    test eax,eax
    jg .Loy5_choose
    mov r15,qword ptr [r14+G_NEXT]
    mov rbx,1
.Loy5_j_loop:
    test r15,r15
    je .Loy5_next_i
    mov rdi,qword ptr [r15+G_DAY]
    mov rsi,qword ptr [r14+G_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    mov qword ptr [rbp-80],rax
    cmp rax,YEAR_MAX
    ja .Loy5_next_i
    cmp rbx,6
    jb .Loy5_advance_j
    cmp rax,YEAR_MIN
    jb .Loy5_advance_j
    mov rdi,qword ptr [r14+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jge .Loy5_advance_j
    mov rdi,r12
    mov rsi,qword ptr [r15+G_DAY]
    call bi_cmp
    test eax,eax
    jg .Loy5_advance_j
    mov rdi,r13
    mov rsi,r14
    mov rdx,r15
    mov rcx,qword ptr [rbp-80]
    call stage54_bucket_append
    inc qword ptr [rbp-72]
.Loy5_advance_j:
    mov r15,qword ptr [r15+G_NEXT]
    inc rbx
    jmp .Loy5_j_loop
.Loy5_next_i:
    mov r14,qword ptr [r14+G_NEXT]
    jmp .Loy5_i_loop
.Loy5_choose:
    cmp qword ptr [rbp-72],0
    je .Loy5_fail
    mov rdi,r12
    mov rsi,r12
    call sauceWithScars
    mov rdi,rax
    mov rsi,1
    mov rdx,10
    call stage54AskRing
    mov r14,rax
    mov rdi,qword ptr [rbp-72]
    call bi_from_u64
    mov rsi,rax
    mov rdi,r14
    call selectionPatch14
    mov rdi,rax
    call stage54BigToU64
    mov rsi,rax
    mov rdi,r13
    call stage54_bucket_select
    mov r14,rax
    mov rdi,5000
    call bi_from_u64
    mov rdi,rax
    mov rsi,qword ptr [r14+C_OPEN]
    mov rdx,qword ptr [r14+C_CLOSE]
    call stage54_make_year
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Loy5_fail:
    mov rax,60
    mov rdi,127
    syscall
.size stage54_year5000,.-stage54_year5000

.type stage54_next_year,@function
stage54_next_year:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    call stage54_bucket_new
    mov r14,rax
    mov qword ptr [rbp-48],0
    mov r15,qword ptr [r13+Y_CLOSE]
    mov rbx,qword ptr [r15+G_NEXT]
    mov rcx,1
.Lony_scan:
    test rbx,rbx
    jne .Lony_have
    call stage54_gate_extend_positive
    mov rbx,rax
.Lony_have:
    mov rdi,qword ptr [rbx+G_DAY]
    mov rsi,qword ptr [r15+G_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    mov qword ptr [rbp-56],rax
    cmp rax,YEAR_MAX
    ja .Lony_choose
    cmp rcx,6
    jb .Lony_advance
    cmp rax,YEAR_MIN
    jb .Lony_advance
    push rcx
    mov rdi,r14
    mov rsi,r15
    mov rdx,rbx
    mov rcx,qword ptr [rbp-56]
    call stage54_bucket_append
    pop rcx
    inc qword ptr [rbp-48]
.Lony_advance:
    mov rbx,qword ptr [rbx+G_NEXT]
    inc rcx
    jmp .Lony_scan
.Lony_choose:
    mov rdi,r12
    mov rsi,qword ptr [r15+G_DAY]
    call sauceWithScars
    mov rdi,rax
    mov rsi,1
    mov rdx,11
    call stage54AskRing
    mov rbx,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_u64
    mov rsi,rax
    mov rdi,rbx
    call selectionPatch14
    mov rdi,rax
    call stage54BigToU64
    mov rsi,rax
    mov rdi,r14
    call stage54_bucket_select
    mov r14,rax
    mov rdi,qword ptr [r13+Y_NUMBER]
    mov rsi,1
    call bi_add_u64
    mov rdi,rax
    mov rsi,qword ptr [r14+C_OPEN]
    mov rdx,qword ptr [r14+C_CLOSE]
    call stage54_make_year
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54_next_year,.-stage54_next_year

.type stage54_previous_year,@function
stage54_previous_year:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov r13,rsi
    call stage54_bucket_new
    mov r14,rax
    mov qword ptr [rbp-48],0
    mov r15,qword ptr [r13+Y_OPEN]
    mov rbx,qword ptr [r15+G_PREV]
    mov rcx,1
.Lopy_scan:
    test rbx,rbx
    jne .Lopy_have
    call stage54_gate_extend_negative
    mov rbx,rax
.Lopy_have:
    mov rdi,qword ptr [r15+G_DAY]
    mov rsi,qword ptr [rbx+G_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    mov qword ptr [rbp-56],rax
    cmp rax,YEAR_MAX
    ja .Lopy_choose
    cmp rcx,6
    jb .Lopy_advance
    cmp rax,YEAR_MIN
    jb .Lopy_advance
    push rcx
    mov rdi,r14
    mov rsi,rbx
    mov rdx,r15
    mov rcx,qword ptr [rbp-56]
    call stage54_bucket_append
    pop rcx
    inc qword ptr [rbp-48]
.Lopy_advance:
    mov rbx,qword ptr [rbx+G_PREV]
    inc rcx
    jmp .Lopy_scan
.Lopy_choose:
    mov rdi,r12
    mov rsi,qword ptr [r15+G_DAY]
    call sauceWithScars
    mov rdi,rax
    mov rsi,1
    mov rdx,12
    call stage54AskRing
    mov rbx,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_u64
    mov rsi,rax
    mov rdi,rbx
    call selectionPatch14
    mov rdi,rax
    call stage54BigToU64
    mov rsi,rax
    mov rdi,r14
    call stage54_bucket_select
    mov r14,rax
    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r13+Y_NUMBER]
    call bi_sub
    mov rdi,rax
    mov rsi,qword ptr [r14+C_OPEN]
    mov rdx,qword ptr [r14+C_CLOSE]
    call stage54_make_year
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54_previous_year,.-stage54_previous_year

.type stage54_find_target_year,@function
stage54_find_target_year:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call stage54_year5000
    mov r14,rax
.Lofty_forward:
    mov rdi,r13
    mov rsi,qword ptr [r14+Y_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jle .Lofty_backward
    mov rdi,r12
    mov rsi,r14
    call stage54_next_year
    mov r14,rax
    jmp .Lofty_forward
.Lofty_backward:
    mov rdi,r13
    mov rsi,qword ptr [r14+Y_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jg .Lofty_done
    mov rdi,r12
    mov rsi,r14
    call stage54_previous_year
    mov r14,rax
    jmp .Lofty_backward
.Lofty_done:
    mov rax,r14
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage54_find_target_year,.-stage54_find_target_year
# Ⲡstage54SelectFromSauce ⲙⲟⲟϣⲉ ϩⲓⲧⲛ answerRingThroughPatchedNextBowl ⲙⲛ selectionPatch14.
# rdi=sauce,rsi=bowl,rdx=seal,rcx=N BigInt*; rax=rank BigInt*.
.type stage54SelectFromSauce,@function
stage54SelectFromSauce:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rcx
    call stage54AskRing
    test rax,rax
    je .Ls54sfs_fail
    mov rdi,rax
    mov rsi,r12
    call selectionPatch14
    jmp .Ls54sfs_done
.Ls54sfs_fail:
    xor eax,eax
.Ls54sfs_done:
    pop r12
    leave
    ret
.size stage54SelectFromSauce,.-stage54SelectFromSauce

# Ⲡstage54StructureSauce ⲙⲟⲩⲧⲉ ⲉoldStructureSauce ⲛϣⲟⲣⲡ; ⲡⲉⲧϣⲟⲟⲡ ⲛⲕⲩⲣⲓⲟⲥ ϫⲓ ⲙⲡyear.firstDay.
# rdi=calculation BigInt*,rsi=original target BigInt*,rdx=Y*; rax=sauce,rdx=ghost,rcx=reused.
.type stage54StructureSauce,@function
stage54StructureSauce:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Ls54ss_fail
    test r13,r13
    je .Ls54ss_fail
    test r14,r14
    je .Ls54ss_fail
    mov rdi,r12
    call stage54BigToI64
    test rdx,rdx
    je .Ls54ss_fail
    mov r15,rax
    mov rdi,r13
    call stage54BigToI64
    test rdx,rdx
    je .Ls54ss_fail
    mov rbx,rax
    mov rdi,r15
    mov rsi,rbx
    call oldStructureSauce
    test rax,rax
    je .Ls54ss_fail
    mov qword ptr [rbp-48],rax
    mov rdi,qword ptr [r14+Y_OPEN_DAY]
    mov rsi,1
    call bi_add_u64
    test rax,rax
    je .Ls54ss_fail
    mov qword ptr [rbp-56],rax
    mov rdi,r13
    mov rsi,rax
    call bi_cmp
    test eax,eax
    jne .Ls54ss_correct
    mov rax,qword ptr [rbp-48]
    mov rdx,rax
    mov ecx,1
    jmp .Ls54ss_done
.Ls54ss_correct:
    mov rdi,r12
    mov rsi,qword ptr [rbp-56]
    call sauceWithScars
    test rax,rax
    je .Ls54ss_fail
    mov rdx,qword ptr [rbp-48]
    xor ecx,ecx
    jmp .Ls54ss_done
.Ls54ss_fail:
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
.Ls54ss_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54StructureSauce,.-stage54StructureSauce

# Ⲡstage54WeavingWithGhost ⲱϣ ⲙⲡanswer ring ⲁⲩⲱ ⲙⲟⲩⲧⲉ ⲉmonster_month_weaving_route.
# rdi=sauce,rsi=lengths*,rdx=m,rcx=rank BigInt*,r8=out.
.type stage54WeavingWithGhost,@function
stage54WeavingWithGhost:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,72
    mov qword ptr [rbp-48],rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    test r12,r12
    je .Ls54wwg_fail
    test r13,r13
    je .Ls54wwg_fail
    test r14,r14
    je .Ls54wwg_fail
    test r15,r15
    je .Ls54wwg_fail
    xor ebx,ebx
    xor ecx,ecx
.Ls54wwg_sum:
    cmp rcx,r13
    jae .Ls54wwg_sum_done
    mov rax,qword ptr [r12+rcx*8]
    test rax,rax
    je .Ls54wwg_fail
    add rbx,rax
    jc .Ls54wwg_fail
    inc rcx
    jmp .Ls54wwg_sum
.Ls54wwg_sum_done:
    mov qword ptr [rbp-56],rbx
    mov rdi,qword ptr [rbp-48]
    mov esi,4
    mov edx,32
    call stage54AskRing
    test rax,rax
    je .Ls54wwg_fail
    mov qword ptr [rbp-64],rax
    mov rdi,rbx
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Ls54wwg_fail
    mov qword ptr [rbp-72],rax
    mov qword ptr [rbp-80],0
.Ls54wwg_answers:
    mov rcx,qword ptr [rbp-80]
    cmp rcx,qword ptr [rbp-56]
    jae .Ls54wwg_route
    mov rdi,qword ptr [rbp-64]
    mov rsi,rcx
    call ringAnswer
    test rax,rax
    je .Ls54wwg_fail
    mov qword ptr [rbp-88],rax
    mov edi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-88]
    call bi_sub
    test rax,rax
    je .Ls54wwg_fail
    mov rdi,rax
    mov rsi,r13
    call bi_divmod_u64_abs
    mov rax,rdx
    inc rax
    mov rcx,qword ptr [rbp-80]
    mov rdx,qword ptr [rbp-72]
    mov qword ptr [rdx+rcx*8],rax
    inc qword ptr [rbp-80]
    jmp .Ls54wwg_answers
.Ls54wwg_route:
    mov rdi,r12
    mov rsi,r13
    mov rdx,qword ptr [rbp-72]
    mov rcx,qword ptr [rbp-56]
    mov r8,r14
    mov r9,r15
    call monster_month_weaving_route
    test rax,rax
    je .Ls54wwg_fail
    mov rax,r15
    jmp .Ls54wwg_done
.Ls54wwg_fail:
    xor eax,eax
.Ls54wwg_done:
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54WeavingWithGhost,.-stage54WeavingWithGhost

# Ⲡstage54BuildYearStructure ⲥⲱⲟⲩϩ ⲙⲡstage54StructureSauce ⲙⲛ ⲛroute ⲛⲧⲉ cutlet, month, weaving ⲙⲛ name.
# rdi=calculation BigInt*,rsi=target BigInt*,rdx=Y*; rax=YS*.
.type stage54BuildYearStructure,@function
stage54BuildYearStructure:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,248
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    test r12,r12
    je .Ls54bys_fail
    test r13,r13
    je .Ls54bys_fail
    test r14,r14
    je .Ls54bys_fail
    mov qword ptr [rbp-48],r12
    mov qword ptr [rbp-56],r13
    mov qword ptr [rbp-64],r14
    mov rdi,YS_SIZE
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov r15,rax
    mov qword ptr [rbp-72],rax
    mov qword ptr [r15+YS_YEAR],r14
    mov rdi,qword ptr [r14+Y_OPEN_DAY]
    mov rsi,1
    call bi_add_u64
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_FIRST_DAY],rax
    mov qword ptr [rbp-80],rax

    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call stage54StructureSauce
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-88],rax

    mov rax,qword ptr [r14+Y_CLOSE]
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r14+Y_OPEN]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_sub
    test rax,rax
    je .Ls54bys_fail
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54bys_fail
    mov qword ptr [rbp-96],rax
    mov rbx,rax
    cmp rbx,17
    jbe .Ls54bys_kmax_ok
    mov rbx,17
.Ls54bys_kmax_ok:
    cmp rbx,6
    jb .Ls54bys_fail
    mov rdi,rbx
    sub rdi,5
    call bi_from_u64
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,2
    mov edx,20
    call stage54SelectFromSauce
    test rax,rax
    je .Ls54bys_fail
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54bys_fail
    add rax,5
    mov qword ptr [r15+YS_CUTLET_COUNT],rax
    mov qword ptr [rbp-104],rax

    mov qword ptr [rbp-112],0
    mov rdi,r12
    call stage54_exact_gate_node
    test rax,rax
    je .Ls54bys_required_done
    mov qword ptr [rbp-240],rax
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r14+Y_OPEN]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_cmp
    cmp eax,0
    jle .Ls54bys_required_done
    mov rax,qword ptr [rbp-240]
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r14+Y_CLOSE]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_cmp
    cmp eax,0
    jge .Ls54bys_required_done
    mov rax,qword ptr [rbp-240]
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r14+Y_OPEN]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54bys_fail
    mov qword ptr [rbp-112],rax
.Ls54bys_required_done:

    mov rdi,qword ptr [rbp-96]
    mov rsi,qword ptr [rbp-104]
    mov rdx,qword ptr [rbp-112]
    call filteredCutletPartitionFamilyCount
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-120],rax
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,2
    mov edx,21
    call stage54SelectFromSauce
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-128],rax
    mov rdi,qword ptr [rbp-104]
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_PARTITION],rax
    mov r8,rax
    mov rdi,qword ptr [rbp-96]
    mov rsi,qword ptr [rbp-104]
    mov rdx,qword ptr [rbp-112]
    mov rcx,qword ptr [rbp-128]
    call monster_cutlet_partition_route
    test rax,rax
    je .Ls54bys_fail
    cmp rdx,1
    jne .Ls54bys_fail

    mov edi,17
    mov rsi,qword ptr [rbp-104]
    call namePatch22FallingBig
    test rax,rax
    je .Ls54bys_fail
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,5
    mov edx,22
    call stage54SelectFromSauce
    test rax,rax
    je .Ls54bys_fail
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54bys_fail
    mov qword ptr [rbp-248],rax
    mov rdi,qword ptr [rbp-104]
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_CUTLET_NAMES],rax
    mov rdx,rax
    mov rdi,qword ptr [rbp-248]
    mov rsi,qword ptr [rbp-104]
    call monster_cutlet_names_route
    test rax,rax
    je .Ls54bys_fail

    mov rdi,qword ptr [rbp-104]
    imul rdi,CUT_SIZE
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_CUTLETS],rax
    mov qword ptr [rbp-136],rax
    mov rax,qword ptr [r14+Y_OPEN]
    mov qword ptr [rbp-144],rax
    mov qword ptr [rbp-152],0
.Ls54bys_cutlet_loop:
    mov rax,qword ptr [rbp-152]
    cmp rax,qword ptr [rbp-104]
    jae .Ls54bys_months
    mov rcx,qword ptr [r15+YS_PARTITION]
    mov rcx,qword ptr [rcx+rax*8]
    mov qword ptr [rbp-256],rcx
    mov qword ptr [rbp-264],0
.Ls54bys_gate_step:
    mov rcx,qword ptr [rbp-264]
    cmp rcx,qword ptr [rbp-256]
    jae .Ls54bys_gate_step_done
    mov rax,qword ptr [rbp-144]
    mov rax,qword ptr [rax+G_NEXT]
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-144],rax
    inc qword ptr [rbp-264]
    jmp .Ls54bys_gate_step
.Ls54bys_gate_step_done:
    mov rax,qword ptr [rbp-152]
    imul rax,CUT_SIZE
    mov rdx,qword ptr [rbp-136]
    add rdx,rax
    mov rax,qword ptr [rbp-144]
    mov rcx,qword ptr [rax+G_DAY]
    mov qword ptr [rdx+CUT_LAST],rcx
    mov rcx,qword ptr [rbp-152]
    mov rax,qword ptr [r15+YS_CUTLET_NAMES]
    mov rax,qword ptr [rax+rcx*8]
    mov qword ptr [rdx+CUT_NAME_ID],rax
    mov rax,qword ptr [rbp-152]
    test rax,rax
    jne .Ls54bys_first_prev
    mov rdi,qword ptr [r14+Y_OPEN_DAY]
    mov rsi,1
    call bi_add_u64
    jmp .Ls54bys_first_store
.Ls54bys_first_prev:
    dec rax
    imul rax,CUT_SIZE
    mov rcx,qword ptr [rbp-136]
    mov rdi,qword ptr [rcx+rax+CUT_LAST]
    mov rsi,1
    call bi_add_u64
.Ls54bys_first_store:
    mov rcx,qword ptr [rbp-152]
    imul rcx,CUT_SIZE
    mov rdx,qword ptr [rbp-136]
    mov qword ptr [rdx+rcx+CUT_FIRST],rax
    inc qword ptr [rbp-152]
    jmp .Ls54bys_cutlet_loop

.Ls54bys_months:
    mov rdi,qword ptr [r14+Y_CLOSE_DAY]
    mov rsi,qword ptr [r14+Y_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54bys_fail
    mov qword ptr [rbp-160],rax
    mov rbx,rax
    add rax,122
    xor edx,edx
    mov rcx,123
    div rcx
    mov qword ptr [rbp-168],rax
    mov rax,rbx
    xor edx,edx
    mov rcx,4
    div rcx
    cmp rax,47
    jbe .Ls54bys_hi_ok
    mov rax,47
.Ls54bys_hi_ok:
    mov qword ptr [rbp-176],rax
    mov rcx,rax
    sub rcx,qword ptr [rbp-168]
    inc rcx
    mov rdi,rcx
    call bi_from_u64
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,3
    mov edx,30
    call stage54SelectFromSauce
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54bys_fail
    dec rax
    add rax,qword ptr [rbp-168]
    mov qword ptr [r15+YS_MONTH_COUNT],rax
    mov qword ptr [rbp-184],rax

    mov rdi,qword ptr [rbp-160]
    mov rsi,qword ptr [rbp-184]
    call monster_month_length_family_route
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-192],rax
    mov rdi,rax
    call virtualMonthLengthListCount
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-200],rax
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,3
    mov edx,31
    call stage54SelectFromSauce
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-208],rax
    mov rdi,qword ptr [rbp-184]
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_MONTH_LENGTHS],rax
    mov rdx,rax
    mov rdi,qword ptr [rbp-192]
    mov rsi,qword ptr [rbp-208]
    call virtualMonthLengthListItemAt1Big
    test rax,rax
    je .Ls54bys_fail

    mov rdi,qword ptr [r15+YS_MONTH_LENGTHS]
    mov rsi,qword ptr [rbp-184]
    call CountWeavingsByDP
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-216],rax
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,4
    mov edx,32
    call stage54SelectFromSauce
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-224],rax
    mov rdi,qword ptr [rbp-160]
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_WEAVE],rax
    mov r8,rax
    mov rdi,qword ptr [rbp-88]
    mov rsi,qword ptr [r15+YS_MONTH_LENGTHS]
    mov rdx,qword ptr [rbp-184]
    mov rcx,qword ptr [rbp-224]
    call stage54WeavingWithGhost
    test rax,rax
    je .Ls54bys_fail

    mov edi,47
    mov rsi,qword ptr [rbp-184]
    call namePatch22FallingBig
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-232],rax
    mov rcx,rax
    mov rdi,qword ptr [rbp-88]
    mov esi,5
    mov edx,33
    call stage54SelectFromSauce
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [rbp-240],rax
    mov rdi,qword ptr [rbp-184]
    shl rdi,3
    call arena_alloc
    test rax,rax
    je .Ls54bys_fail
    mov qword ptr [r15+YS_MONTH_NAMES],rax
    mov rdx,rax
    mov rdi,qword ptr [rbp-240]
    mov rsi,qword ptr [rbp-184]
    call monster_month_names_route_big
    test rax,rax
    je .Ls54bys_fail

    mov rax,r15
    jmp .Ls54bys_done
.Ls54bys_fail:
    xor eax,eax
.Ls54bys_done:
    add rsp,248
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54BuildYearStructure,.-stage54BuildYearStructure

# Ⲡstage54ValidatePendingStructure ⲥⲙⲓⲛⲉ ⲙⲡpending structure ⲛⲕⲉⲥⲟⲡ ⲁϫⲛ ⲟⲩⲥϩⲁⲓ ⲉⲡⲉⲧⲟⲩϫⲓ ⲙⲙⲟϥ.
# rdi=YS*,rsi=Y*; eax=1/0.
.type stage54ValidatePendingStructure,@function
stage54ValidatePendingStructure:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Ls54vps_fail
    test r13,r13
    je .Ls54vps_fail
    mov rax,qword ptr [r12+YS_CUTLET_COUNT]
    cmp rax,6
    jb .Ls54vps_fail
    cmp rax,17
    ja .Ls54vps_fail
    mov rax,qword ptr [r12+YS_MONTH_COUNT]
    test rax,rax
    je .Ls54vps_fail
    cmp rax,47
    ja .Ls54vps_fail
    mov rbx,rax
    mov rdx,qword ptr [r12+YS_MONTH_LENGTHS]
    test rdx,rdx
    je .Ls54vps_fail
    xor eax,eax
    xor ecx,ecx
.Ls54vps_sum:
    cmp rcx,rbx
    jae .Ls54vps_sum_done
    mov r8,qword ptr [rdx+rcx*8]
    cmp r8,4
    jb .Ls54vps_fail
    cmp r8,123
    ja .Ls54vps_fail
    add rax,r8
    inc rcx
    jmp .Ls54vps_sum
.Ls54vps_sum_done:
    mov rdi,qword ptr [r13+Y_CLOSE_DAY]
    mov rsi,qword ptr [r13+Y_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54vps_fail
    mov rbx,rax
    xor eax,eax
    mov rdx,qword ptr [r12+YS_MONTH_LENGTHS]
    xor ecx,ecx
.Ls54vps_sum2:
    cmp rcx,qword ptr [r12+YS_MONTH_COUNT]
    jae .Ls54vps_check
    add rax,qword ptr [rdx+rcx*8]
    inc rcx
    jmp .Ls54vps_sum2
.Ls54vps_check:
    cmp rax,rbx
    jne .Ls54vps_fail
    mov eax,1
    jmp .Ls54vps_done
.Ls54vps_fail:
    xor eax,eax
.Ls54vps_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54ValidatePendingStructure,.-stage54ValidatePendingStructure

# Ⲡstage54FinalizeFiveFields ⲱϣ ⲙⲡcutlet ⲙⲛ month ⲁⲩⲱ ⲙⲟⲩⲧⲉ ⲉmonster_day_in_month_route.
# rdi=calculation BigInt*,rsi=target BigInt*,rdx=Y*,rcx=YS*; rax=RES*.
.type stage54FinalizeFiveFields,@function
stage54FinalizeFiveFields:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,72
    mov qword ptr [rbp-48],rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    test r12,r12
    je .Ls54fff_fail
    test r13,r13
    je .Ls54fff_fail
    test r14,r14
    je .Ls54fff_fail
    mov qword ptr [rbp-56],0
.Ls54fff_cut_scan:
    mov rax,qword ptr [rbp-56]
    cmp rax,qword ptr [r14+YS_CUTLET_COUNT]
    jae .Ls54fff_fail
    imul rax,CUT_SIZE
    mov rdx,qword ptr [r14+YS_CUTLETS]
    add rdx,rax
    mov qword ptr [rbp-64],rdx
    mov rdi,r12
    mov rsi,qword ptr [rdx+CUT_FIRST]
    call bi_cmp
    cmp eax,0
    jl .Ls54fff_cut_next
    mov rdx,qword ptr [rbp-64]
    mov rdi,r12
    mov rsi,qword ptr [rdx+CUT_LAST]
    call bi_cmp
    cmp eax,0
    jle .Ls54fff_cut_found
.Ls54fff_cut_next:
    inc qword ptr [rbp-56]
    jmp .Ls54fff_cut_scan
.Ls54fff_cut_found:
    mov rdx,qword ptr [rbp-64]
    mov rdi,r12
    mov rsi,qword ptr [rdx+CUT_FIRST]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54fff_fail
    inc rax
    mov qword ptr [rbp-72],rax
    mov rdi,r12
    mov rsi,qword ptr [r14+YS_FIRST_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54fff_fail
    mov qword ptr [rbp-80],rax
    mov rdx,qword ptr [r14+YS_WEAVE]
    mov rcx,qword ptr [rbp-80]
    mov rbx,qword ptr [rdx+rcx*8]
    test rbx,rbx
    je .Ls54fff_fail

    mov rdi,qword ptr [r13+Y_CLOSE_DAY]
    mov rsi,qword ptr [r13+Y_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    call stage54BigToU64
    cmp rdx,-1
    je .Ls54fff_fail
    mov qword ptr [rbp-88],rax
    mov rdi,qword ptr [r14+YS_FIRST_DAY]
    call stage54BigToI64
    test rdx,rdx
    je .Ls54fff_fail
    mov qword ptr [rbp-96],rax
    mov rdi,r12
    call stage54BigToI64
    test rdx,rdx
    je .Ls54fff_fail
    mov qword ptr [rbp-104],rax
    mov rdi,qword ptr [r14+YS_WEAVE]
    mov rsi,qword ptr [rbp-88]
    mov rdx,qword ptr [rbp-96]
    mov rcx,qword ptr [rbp-104]
    call monster_day_in_month_route
    test rax,rax
    je .Ls54fff_fail
    mov qword ptr [rbp-112],rax

    mov rdi,RES_SIZE
    call arena_alloc
    test rax,rax
    je .Ls54fff_fail
    mov r15,rax
    mov rax,qword ptr [r13+Y_NUMBER]
    mov qword ptr [r15+RES_YEAR],rax
    mov rdx,qword ptr [rbp-64]
    mov rdi,qword ptr [rdx+CUT_NAME_ID]
    call catalog_get_cutlet
    test rax,rax
    je .Ls54fff_fail
    mov qword ptr [r15+RES_CUTLET_NAME],rax
    mov rax,qword ptr [rbp-72]
    mov qword ptr [r15+RES_DAY_IN_CUTLET],rax
    mov rdx,qword ptr [r14+YS_MONTH_NAMES]
    mov rdi,qword ptr [rdx+rbx*8-8]
    call catalog_get_month
    test rax,rax
    je .Ls54fff_fail
    mov qword ptr [r15+RES_MONTH_NAME],rax
    mov rax,qword ptr [rbp-112]
    mov qword ptr [r15+RES_DAY_IN_MONTH],rax
    mov rax,r15
    jmp .Ls54fff_done
.Ls54fff_fail:
    xor eax,eax
.Ls54fff_done:
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage54FinalizeFiveFields,.-stage54FinalizeFiveFields

# Ⲡstage54ScrubGhostArena ⲥϩⲁⲓ ⲛ0 ⲉⲡⲧⲟⲡⲟⲥ ⲛⲧⲁⲡghost ⲥϩⲁⲓ ⲙⲙⲟϥ ϩⲁⲑⲏ ⲙⲡarena_reset.
# rdi=start, rsi=end.
.type stage54ScrubGhostArena,@function
stage54ScrubGhostArena:
    cmp rsi,rdi
    jbe .Ls54sga_done
    mov rcx,rsi
    sub rcx,rdi
    shr rcx,3
    xor eax,eax
    rep stosq
.Ls54sga_done:
    ret
.size stage54ScrubGhostArena,.-stage54ScrubGhostArena

# ⲠcalendarDateSpaghetti ⲡⲉ ⲡstate-machine ⲛⲕⲩⲣⲓⲟⲥ; eax=2, rdx=RES*.
.type calendarDateSpaghetti,@function
calendarDateSpaghetti:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,72
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    mov rsi,r13
    call monster_context_new
    test rax,rax
    je .Ls54cd_fail
    mov r14,rax
    mov qword ptr [r14+CTX_STAGE54_PHASE],1
    mov qword ptr [r14+CTX_STAGE54_RETRY],2
    mov edi,0
    add rdi,r12
    call bi_from_i64
    test rax,rax
    je .Ls54cd_recover
    mov r15,rax
    mov rdi,r13
    call bi_from_i64
    test rax,rax
    je .Ls54cd_recover
    mov rbx,rax

.Ls54cd_legacy_manager:
    mov qword ptr [r14+CTX_STAGE54_PHASE],10
    call arena_mark
    mov qword ptr [rbp-48],rax
    mov rdi,r12
    mov rsi,r13
    call calendarDateSpaghettiLegacyDiagnostic
    mov qword ptr [r14+CTX_STAGE54_LEGACY_STATUS],rax
    mov qword ptr [rbp-80],rax
    call arena_mark
    mov qword ptr [rbp-88],rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-88]
    call stage54ScrubGhostArena
    mov rdi,qword ptr [rbp-48]
    call arena_reset
    mov rax,qword ptr [rbp-80]
    cmp eax,2
    jne .Ls54cd_legacy_fail
    inc qword ptr [r14+CTX_STAGE54_METRICS]
    inc qword ptr [r14+CTX_STAGE54_LOGS]
    jmp .Ls54cd_year_manager
.Ls54cd_legacy_fail:
    jmp .Ls54cd_recover

.Ls54cd_year_manager:
    mov qword ptr [r14+CTX_STAGE54_PHASE],20
    mov rdi,r15
    mov rsi,rbx
    call stage54_find_target_year
    test rax,rax
    je .Ls54cd_recover
    mov qword ptr [r14+CTX_STAGE54_YEAR],rax
    mov qword ptr [rbp-56],rax
    inc qword ptr [r14+CTX_STAGE54_METRICS]

.Ls54cd_structure_manager:
    mov qword ptr [r14+CTX_STAGE54_PHASE],30
    mov rdi,r15
    mov rsi,rbx
    mov rdx,qword ptr [rbp-56]
    call stage54BuildYearStructure
    test rax,rax
    je .Ls54cd_recover
    mov qword ptr [r14+CTX_STAGE54_PENDING],rax
    mov qword ptr [rbp-64],rax
    inc qword ptr [r14+CTX_STAGE54_LOGS]

.Ls54cd_validator_manager:
    mov qword ptr [r14+CTX_STAGE54_PHASE],40
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-56]
    call stage54ValidatePendingStructure
    test eax,eax
    je .Ls54cd_recover
    inc qword ptr [r14+CTX_STAGE54_VALIDATIONS]
    mov rax,qword ptr [r14+CTX_STAGE54_PENDING]
    mov qword ptr [r14+CTX_STAGE54_COMMITTED],rax
    mov qword ptr [r14+CTX_STAGE54_STRUCTURE],rax

.Ls54cd_result_manager:
    mov qword ptr [r14+CTX_STAGE54_PHASE],50
    mov rdi,r15
    mov rsi,rbx
    mov rdx,qword ptr [rbp-56]
    mov rcx,qword ptr [r14+CTX_STAGE54_COMMITTED]
    call stage54FinalizeFiveFields
    test rax,rax
    je .Ls54cd_recover
    mov qword ptr [r14+CTX_STAGE54_RESULT],rax
    mov qword ptr [rbp-72],rax

.Ls54cd_final_validator:
    mov qword ptr [r14+CTX_STAGE54_PHASE],60
    mov rax,qword ptr [rbp-72]
    test qword ptr [rax+RES_YEAR],-1
    je .Ls54cd_recover
    test qword ptr [rax+RES_CUTLET_NAME],-1
    je .Ls54cd_recover
    cmp qword ptr [rax+RES_DAY_IN_CUTLET],0
    je .Ls54cd_recover
    test qword ptr [rax+RES_MONTH_NAME],-1
    je .Ls54cd_recover
    cmp qword ptr [rax+RES_DAY_IN_MONTH],0
    je .Ls54cd_recover
    inc qword ptr [r14+CTX_STAGE54_VALIDATIONS]
    inc qword ptr [r14+CTX_STAGE54_SEEN]
    mov qword ptr [r14+CTX_STAGE54_PHASE],90
    mov rdx,qword ptr [rbp-72]
    mov eax,2
    jmp .Ls54cd_done

.Ls54cd_recover:
    mov qword ptr [r14+CTX_STAGE54_PHASE],80
    dec qword ptr [r14+CTX_STAGE54_RETRY]
    js .Ls54cd_fail
    inc qword ptr [r14+CTX_STAGE54_LOGS]
    mov qword ptr [r14+CTX_STAGE54_PENDING],0
    mov qword ptr [r14+CTX_STAGE54_COMMITTED],0
    cmp qword ptr [r14+CTX_STAGE54_RETRY],0
    je .Ls54cd_year_manager
    jmp .Ls54cd_year_manager
.Ls54cd_fail:
    xor eax,eax
    xor edx,edx
.Ls54cd_done:
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size calendarDateSpaghetti,.-calendarDateSpaghetti
