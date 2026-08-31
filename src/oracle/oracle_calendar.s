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
.equ STREAM_FIRST,0
.equ STREAM_STEP,8
.equ YEAR_MIN,252
.equ YEAR_MAX,5778
.equ YEAR_BUCKETS,5527

.section .bss
.align 8
.global oracle_GATE_ZERO
.global oracle_GATE_MIN
.global oracle_GATE_MAX
oracle_GATE_ZERO: .quad 0
oracle_GATE_MIN: .quad 0
oracle_GATE_MAX: .quad 0

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
.extern bi_abs
.extern bi_add_u64
.extern bi_mul_u64
.extern oracle_init
.extern oracle_FOUNDATION
.extern oracle_sauce
.extern oracle_ask_bowl
.extern oracle_choose_rank
.extern oracle_to_u64
.extern oracle_STONES
.extern oracle_build_stones

.global oracle_gate_init
.global oracle_gate_gap
.global oracle_gate_extend_positive
.global oracle_gate_extend_negative
.global oracle_ensure_gates_cover_day
.global oracle_gate_node_at_or_before
.global oracle_gate_node_at_or_after
.global oracle_exact_gate_node
.global oracle_year5000
.global oracle_next_year
.global oracle_previous_year
.global oracle_find_target_year

.type oracle_audit_big_to_i64,@function
oracle_audit_big_to_i64:
    test rdi,rdi
    je .Loabti_fail
    mov rcx,qword ptr [rdi+BI_SIGN]
    test rcx,rcx
    je .Loabti_zero
    cmp qword ptr [rdi+BI_LEN],1
    jne .Loabti_fail
    mov rdx,qword ptr [rdi+BI_DATA]
    test rdx,rdx
    je .Loabti_fail
    mov rax,qword ptr [rdx]
    cmp rcx,1
    je .Loabti_pos
    cmp rcx,-1
    jne .Loabti_fail
    movabs rdx,0x8000000000000000
    cmp rax,rdx
    ja .Loabti_fail
    neg rax
    mov edx,1
    ret
.Loabti_pos:
    movabs rdx,0x7fffffffffffffff
    cmp rax,rdx
    ja .Loabti_fail
    mov edx,1
    ret
.Loabti_zero:
    xor eax,eax
    mov edx,1
    ret
.Loabti_fail:
    xor eax,eax
    xor edx,edx
    ret
.size oracle_audit_big_to_i64,.-oracle_audit_big_to_i64

.type oracle_audit_scrub_arena,@function
oracle_audit_scrub_arena:
    cmp rsi,rdi
    jbe .Loasa_done
    mov rdx,qword ptr [rip+oracle_STONES]
    test rdx,rdx
    je .Loasa_zero
    cmp rdx,rdi
    jb .Loasa_zero
    cmp rdx,rsi
    jae .Loasa_zero
    mov qword ptr [rip+oracle_STONES],0
.Loasa_zero:
    mov rcx,rsi
    sub rcx,rdi
    shr rcx,3
    xor eax,eax
    rep stosq
.Loasa_done:
    ret
.size oracle_audit_scrub_arena,.-oracle_audit_scrub_arena

.type oracle_gate_init,@function
oracle_gate_init:
    push r12
    cmp qword ptr [rip+oracle_GATE_ZERO],0
    jne .Logi_done
    call oracle_init
    call oracle_build_stones
    mov rdi,G_SIZE
    call arena_alloc
    mov r12,rax
    mov rdi,0
    call bi_from_u64
    mov qword ptr [r12+G_INDEX],rax
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    call bi_clone
    mov qword ptr [r12+G_DAY],rax
    mov qword ptr [r12+G_PREV],0
    mov qword ptr [r12+G_NEXT],0
    mov qword ptr [rip+oracle_GATE_ZERO],r12
    mov qword ptr [rip+oracle_GATE_MIN],r12
    mov qword ptr [rip+oracle_GATE_MAX],r12
.Logi_done:
    pop r12
    ret
.size oracle_gate_init,.-oracle_gate_init

.type oracle_gate_gap,@function
oracle_gate_gap:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    call oracle_gate_init
    test r13,r13
    js .Logg_neg
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,r12
    call bi_add
    jmp .Logg_target
.Logg_neg:
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,r12
    call bi_sub
.Logg_target:
    mov r14,rax
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,r14
    call oracle_sauce
    mov r15,rax
    mov rdi,r15
    mov rsi,1
    mov rdx,1
    call oracle_ask_bowl
    mov r14,rax
    mov rdi,922
    call bi_from_u64
    mov rsi,rax
    mov rdi,r14
    call oracle_choose_rank
    mov rdi,rax
    call oracle_to_u64
    add rax,41
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_gate_gap,.-oracle_gate_gap

.type oracle_gate_extend_positive,@function
oracle_gate_extend_positive:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    call oracle_gate_init
    mov r12,qword ptr [rip+oracle_GATE_MAX]
    mov rdi,G_SIZE
    call arena_alloc
    mov r15,rax
    call arena_mark
    mov qword ptr [rbp-40],rax

    mov rdi,qword ptr [r12+G_INDEX]
    mov rsi,1
    call bi_add_u64
    mov r13,rax
    mov rdi,r13
    call oracle_audit_big_to_i64
    test rdx,rdx
    je .Loagep_fail
    mov qword ptr [rbp-48],rax

    mov rdi,r13
    mov rsi,1
    call oracle_gate_gap
    mov r14,rax
    mov rdi,qword ptr [r12+G_DAY]
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call oracle_audit_big_to_i64
    test rdx,rdx
    je .Loagep_fail
    mov qword ptr [rbp-56],rax

    call arena_mark
    mov rsi,rax
    mov rdi,qword ptr [rbp-40]
    call oracle_audit_scrub_arena
    mov rdi,qword ptr [rbp-40]
    call arena_reset

    mov rdi,qword ptr [rbp-48]
    call bi_from_i64
    mov qword ptr [r15+G_INDEX],rax
    mov rdi,qword ptr [rbp-56]
    call bi_from_i64
    mov qword ptr [r15+G_DAY],rax
    mov qword ptr [r15+G_PREV],r12
    mov qword ptr [r15+G_NEXT],0
    mov qword ptr [r12+G_NEXT],r15
    mov qword ptr [rip+oracle_GATE_MAX],r15
    mov rax,r15
    jmp .Loagep_done
.Loagep_fail:
    xor eax,eax
.Loagep_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_gate_extend_positive,.-oracle_gate_extend_positive

.type oracle_gate_extend_negative,@function
oracle_gate_extend_negative:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    call oracle_gate_init
    mov r12,qword ptr [rip+oracle_GATE_MIN]
    mov rdi,G_SIZE
    call arena_alloc
    mov r15,rax
    call arena_mark
    mov qword ptr [rbp-40],rax

    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r12+G_INDEX]
    call bi_sub
    mov r13,rax
    mov rdi,r13
    call oracle_audit_big_to_i64
    test rdx,rdx
    je .Loagen_fail
    mov qword ptr [rbp-48],rax

    mov rdi,r13
    call bi_abs
    mov rsi,-1
    mov rdi,rax
    call oracle_gate_gap
    mov r14,rax
    mov rdi,r14
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r12+G_DAY]
    call bi_sub
    mov rdi,rax
    call oracle_audit_big_to_i64
    test rdx,rdx
    je .Loagen_fail
    mov qword ptr [rbp-56],rax

    call arena_mark
    mov rsi,rax
    mov rdi,qword ptr [rbp-40]
    call oracle_audit_scrub_arena
    mov rdi,qword ptr [rbp-40]
    call arena_reset

    mov rdi,qword ptr [rbp-48]
    call bi_from_i64
    mov qword ptr [r15+G_INDEX],rax
    mov rdi,qword ptr [rbp-56]
    call bi_from_i64
    mov qword ptr [r15+G_DAY],rax
    mov qword ptr [r15+G_PREV],0
    mov qword ptr [r15+G_NEXT],r12
    mov qword ptr [r12+G_PREV],r15
    mov qword ptr [rip+oracle_GATE_MIN],r15
    mov rax,r15
    jmp .Loagen_done
.Loagen_fail:
    xor eax,eax
.Loagen_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_gate_extend_negative,.-oracle_gate_extend_negative

.type oracle_ensure_gates_cover_day,@function
oracle_ensure_gates_cover_day:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    call oracle_gate_init
.Logc_low:
    mov rax,qword ptr [rip+oracle_GATE_MIN]
    mov rdi,qword ptr [rax+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jle .Logc_high
    call oracle_gate_extend_negative
    jmp .Logc_low
.Logc_high:
    mov rax,qword ptr [rip+oracle_GATE_MAX]
    mov rdi,qword ptr [rax+G_DAY]
    mov rsi,r12
    call bi_cmp
    test eax,eax
    jge .Logc_done
    call oracle_gate_extend_positive
    jmp .Logc_high
.Logc_done:
    pop r12
    leave
    ret
.size oracle_ensure_gates_cover_day,.-oracle_ensure_gates_cover_day

.type oracle_gate_node_at_or_before,@function
oracle_gate_node_at_or_before:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov rdi,r12
    call oracle_ensure_gates_cover_day
    mov r13,qword ptr [rip+oracle_GATE_ZERO]
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
.size oracle_gate_node_at_or_before,.-oracle_gate_node_at_or_before

.type oracle_gate_node_at_or_after,@function
oracle_gate_node_at_or_after:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call oracle_gate_node_at_or_before
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
.size oracle_gate_node_at_or_after,.-oracle_gate_node_at_or_after

.type oracle_exact_gate_node,@function
oracle_exact_gate_node:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call oracle_gate_node_at_or_before
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
.size oracle_exact_gate_node,.-oracle_exact_gate_node

.type oracle_make_year,@function
oracle_make_year:
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
.size oracle_make_year,.-oracle_make_year

.type oracle_bucket_new,@function
oracle_bucket_new:
    push rbp
    mov rbp,rsp
    mov rdi,YEAR_BUCKETS*16
    call arena_alloc
    test rax,rax
    je .Loabn_done
    mov rdx,rax
    mov rdi,rax
    xor eax,eax
    mov ecx,YEAR_BUCKETS*2
    rep stosq
    mov rax,rdx
.Loabn_done:
    leave
    ret
.size oracle_bucket_new,.-oracle_bucket_new

.type oracle_bucket_append,@function
oracle_bucket_append:
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
.size oracle_bucket_append,.-oracle_bucket_append

.type oracle_bucket_select,@function
oracle_bucket_select:
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
.size oracle_bucket_select,.-oracle_bucket_select

.type oracle_year5000,@function
oracle_year5000:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    call oracle_gate_init
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
    call oracle_ensure_gates_cover_day
    mov rdi,qword ptr [rbp-64]
    call oracle_ensure_gates_cover_day
    call arena_mark
    mov qword ptr [rbp-88],rax
    call oracle_bucket_new
    mov r13,rax
    mov qword ptr [rbp-72],0
    mov rdi,qword ptr [rbp-64]
    call oracle_gate_node_at_or_before
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
    call oracle_to_u64
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
    call oracle_bucket_append
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
    call oracle_sauce
    mov rdi,rax
    mov rsi,1
    mov rdx,10
    call oracle_ask_bowl
    mov r14,rax
    mov rdi,qword ptr [rbp-72]
    call bi_from_u64
    mov rsi,rax
    mov rdi,r14
    call oracle_choose_rank
    mov rdi,rax
    call oracle_to_u64
    mov rsi,rax
    mov rdi,r13
    call oracle_bucket_select
    mov r14,rax
    mov rax,qword ptr [r14+C_OPEN]
    mov qword ptr [rbp-96],rax
    mov rax,qword ptr [r14+C_CLOSE]
    mov qword ptr [rbp-104],rax
    call arena_mark
    mov rsi,rax
    mov rdi,qword ptr [rbp-88]
    call oracle_audit_scrub_arena
    mov rdi,qword ptr [rbp-88]
    call arena_reset
    mov rdi,5000
    call bi_from_u64
    mov rdi,rax
    mov rsi,qword ptr [rbp-96]
    mov rdx,qword ptr [rbp-104]
    call oracle_make_year
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
.size oracle_year5000,.-oracle_year5000

.type oracle_next_year,@function
oracle_next_year:
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
    mov r15,qword ptr [r13+Y_CLOSE]

    mov rdi,qword ptr [r15+G_DAY]
    mov rsi,YEAR_MAX
    call bi_add_u64
    mov rdi,rax
    call oracle_ensure_gates_cover_day

    call arena_mark
    mov qword ptr [rbp-72],rax
    call oracle_bucket_new
    mov r14,rax
    mov qword ptr [rbp-48],0
    mov rbx,qword ptr [r15+G_NEXT]
    mov qword ptr [rbp-64],1
.Lony_scan:
    test rbx,rbx
    je .Lony_choose
    mov rdi,qword ptr [rbx+G_DAY]
    mov rsi,qword ptr [r15+G_DAY]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    mov qword ptr [rbp-56],rax
    cmp rax,YEAR_MAX
    ja .Lony_choose
    cmp qword ptr [rbp-64],6
    jb .Lony_advance
    cmp rax,YEAR_MIN
    jb .Lony_advance
    mov rdi,r14
    mov rsi,r15
    mov rdx,rbx
    mov rcx,qword ptr [rbp-56]
    call oracle_bucket_append
    inc qword ptr [rbp-48]
.Lony_advance:
    mov rbx,qword ptr [rbx+G_NEXT]
    inc qword ptr [rbp-64]
    jmp .Lony_scan
.Lony_choose:
    cmp qword ptr [rbp-48],0
    je .Loany_fail
    mov rdi,r12
    mov rsi,qword ptr [r15+G_DAY]
    call oracle_sauce
    mov rdi,rax
    mov rsi,1
    mov rdx,11
    call oracle_ask_bowl
    mov rbx,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_u64
    mov rsi,rax
    mov rdi,rbx
    call oracle_choose_rank
    mov rdi,rax
    call oracle_to_u64
    mov rsi,rax
    mov rdi,r14
    call oracle_bucket_select
    mov r14,rax
    mov rax,qword ptr [r14+C_OPEN]
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [r14+C_CLOSE]
    mov qword ptr [rbp-88],rax
    call arena_mark
    mov rsi,rax
    mov rdi,qword ptr [rbp-72]
    call oracle_audit_scrub_arena
    mov rdi,qword ptr [rbp-72]
    call arena_reset

    mov rdi,qword ptr [r13+Y_NUMBER]
    mov rsi,1
    call bi_add_u64
    mov rdi,rax
    mov rsi,qword ptr [rbp-80]
    mov rdx,qword ptr [rbp-88]
    call oracle_make_year
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Loany_fail:
    xor eax,eax
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_next_year,.-oracle_next_year

.type oracle_previous_year,@function
oracle_previous_year:
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
    mov r15,qword ptr [r13+Y_OPEN]

    mov rdi,YEAR_MAX
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r15+G_DAY]
    call bi_sub
    mov rdi,rax
    call oracle_ensure_gates_cover_day

    call arena_mark
    mov qword ptr [rbp-72],rax
    call oracle_bucket_new
    mov r14,rax
    mov qword ptr [rbp-48],0
    mov rbx,qword ptr [r15+G_PREV]
    mov qword ptr [rbp-64],1
.Lopy_scan:
    test rbx,rbx
    je .Lopy_choose
    mov rdi,qword ptr [r15+G_DAY]
    mov rsi,qword ptr [rbx+G_DAY]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    mov qword ptr [rbp-56],rax
    cmp rax,YEAR_MAX
    ja .Lopy_choose
    cmp qword ptr [rbp-64],6
    jb .Lopy_advance
    cmp rax,YEAR_MIN
    jb .Lopy_advance
    mov rdi,r14
    mov rsi,rbx
    mov rdx,r15
    mov rcx,qword ptr [rbp-56]
    call oracle_bucket_append
    inc qword ptr [rbp-48]
.Lopy_advance:
    mov rbx,qword ptr [rbx+G_PREV]
    inc qword ptr [rbp-64]
    jmp .Lopy_scan
.Lopy_choose:
    cmp qword ptr [rbp-48],0
    je .Loapy_fail
    mov rdi,r12
    mov rsi,qword ptr [r15+G_DAY]
    call oracle_sauce
    mov rdi,rax
    mov rsi,1
    mov rdx,12
    call oracle_ask_bowl
    mov rbx,rax
    mov rdi,qword ptr [rbp-48]
    call bi_from_u64
    mov rsi,rax
    mov rdi,rbx
    call oracle_choose_rank
    mov rdi,rax
    call oracle_to_u64
    mov rsi,rax
    mov rdi,r14
    call oracle_bucket_select
    mov r14,rax
    mov rax,qword ptr [r14+C_OPEN]
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [r14+C_CLOSE]
    mov qword ptr [rbp-88],rax
    call arena_mark
    mov rsi,rax
    mov rdi,qword ptr [rbp-72]
    call oracle_audit_scrub_arena
    mov rdi,qword ptr [rbp-72]
    call arena_reset

    mov rdi,1
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r13+Y_NUMBER]
    call bi_sub
    mov rdi,rax
    mov rsi,qword ptr [rbp-80]
    mov rdx,qword ptr [rbp-88]
    call oracle_make_year
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Loapy_fail:
    xor eax,eax
    add rsp,72
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_previous_year,.-oracle_previous_year

.type oracle_find_target_year,@function
oracle_find_target_year:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call oracle_year5000
    mov r14,rax
.Lofty_forward:
    mov rdi,r13
    mov rsi,qword ptr [r14+Y_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jle .Lofty_backward
    mov rdi,r12
    mov rsi,r14
    call oracle_next_year
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
    call oracle_previous_year
    mov r14,rax
    jmp .Lofty_backward
.Lofty_done:
    mov rax,r14
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_find_target_year,.-oracle_find_target_year
