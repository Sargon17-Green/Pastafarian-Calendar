.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24
.equ G_INDEX,0
.equ G_DAY,8
.equ G_PREV,16
.equ G_NEXT,24
.equ Y_NUMBER,0
.equ Y_OPEN,8
.equ Y_CLOSE,16
.equ Y_OPEN_DAY,24
.equ Y_CLOSE_DAY,32
.equ STREAM_FIRST,0
.equ STREAM_STEP,8
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
.equ WC_LENGTHS,0
.equ WC_M,8
.equ WC_TOTAL,16
.equ WC_STRIDE,24
.equ WC_TABLE,32
.equ WC_PROGRESS,40
.equ WC_ONE,48
.equ WC_SIZE,56

.section .text
.extern arena_alloc
.extern arena_mark
.extern arena_reset
.extern bi_zero
.extern bi_from_u64
.extern bi_clone
.extern bi_sub_abs_inplace
.extern bi_cmp
.extern bi_add
.extern bi_sub
.extern bi_mul
.extern bi_mul_u64
.extern bi_divmod_abs
.extern bi_divmod_u64_abs
.extern bi_is_zero
.extern oracle_binomial_u64
.extern oracle_falling_factorial_u64
.extern oracle_to_u64
.extern oracle_find_target_year
.extern oracle_exact_gate_node
.extern oracle_sauce
.extern oracle_ask_bowl
.extern oracle_choose_rank
.extern catalog_get_cutlet
.extern catalog_get_month

.global oracle_positive_comp_count
.global oracle_cutlet_partition_count
.global oracle_cutlet_partition_unrank
.global oracle_bounded_comp_count
.global oracle_bounded_comp_unrank
.global oracle_distinct_unrank
.global oracle_weaving_count_state
.global oracle_weaving_count
.global oracle_weaving_unrank
.global oracle_build_year_structure
.global oracle_calendar_date

.type oracle_positive_comp_count,@function
oracle_positive_comp_count:
    test rsi,rsi
    je .Lopc_slots_zero
    cmp rdi,rsi
    jb .Lopc_zero
    dec rdi
    dec rsi
    jmp oracle_binomial_u64
.Lopc_slots_zero:
    test rdi,rdi
    jne .Lopc_zero
    mov rdi,1
    jmp bi_from_u64
.Lopc_zero:
    jmp bi_zero
.size oracle_positive_comp_count,.-oracle_positive_comp_count

.type oracle_cutlet_partition_count,@function
oracle_cutlet_partition_count:
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
    mov r14,rdx
    test r13,r13
    je .Locpc_zero_slots
    cmp r12,r13
    jb .Locpc_zero
    test r14,r14
    jne .Locpc_required
    mov rdi,r12
    mov rsi,r13
    call oracle_positive_comp_count
    jmp .Locpc_done
.Locpc_required:
    cmp r14,r12
    jae .Locpc_zero
    mov rdi,0
    call bi_from_u64
    mov r15,rax
    mov rbx,1
.Locpc_h_loop:
    cmp rbx,r13
    jae .Locpc_return_sum
    cmp r14,rbx
    jb .Locpc_h_next
    mov rax,r12
    sub rax,r14
    mov rcx,r13
    sub rcx,rbx
    cmp rax,rcx
    jb .Locpc_h_next
    mov rdi,r14
    dec rdi
    mov rsi,rbx
    dec rsi
    call oracle_binomial_u64
    mov qword ptr [rbp-48],rax
    mov rdi,r12
    sub rdi,r14
    dec rdi
    mov rsi,r13
    sub rsi,rbx
    dec rsi
    call oracle_binomial_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-48]
    call bi_mul
    mov rsi,rax
    mov rdi,r15
    call bi_add
    mov r15,rax
.Locpc_h_next:
    inc rbx
    jmp .Locpc_h_loop
.Locpc_return_sum:
    mov rax,r15
    jmp .Locpc_done
.Locpc_zero_slots:
    test r12,r12
    jne .Locpc_zero
    test r14,r14
    jne .Locpc_zero
    mov rdi,1
    call bi_from_u64
    jmp .Locpc_done
.Locpc_zero:
    call bi_zero
.Locpc_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_cutlet_partition_count,.-oracle_cutlet_partition_count

.type oracle_cutlet_state_count,@function
oracle_cutlet_state_count:
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
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    test r13,r13
    jne .Locsc_nonzero_slots
    test r12,r12
    jne .Locsc_zero
    test r14,r14
    je .Locsc_one
    test rbx,rbx
    jne .Locsc_one
    jmp .Locsc_zero
.Locsc_nonzero_slots:
    cmp r12,r13
    jb .Locsc_zero
    test r14,r14
    je .Locsc_plain
    test rbx,rbx
    jne .Locsc_plain
    cmp r15,r14
    jae .Locsc_zero
    mov r9,r14
    sub r9,r15
    cmp r9,r12
    jae .Locsc_zero
    mov qword ptr [rbp-48],r9
    mov rdi,0
    call bi_from_u64
    mov qword ptr [rbp-56],rax
    mov rbx,1
.Locsc_h_loop:
    cmp rbx,r13
    jae .Locsc_sum_done
    mov r9,qword ptr [rbp-48]
    cmp r9,rbx
    jb .Locsc_h_next
    mov rax,r12
    sub rax,r9
    mov rcx,r13
    sub rcx,rbx
    cmp rax,rcx
    jb .Locsc_h_next
    mov rdi,r9
    dec rdi
    mov rsi,rbx
    dec rsi
    call oracle_binomial_u64
    mov qword ptr [rbp-64],rax
    mov rdi,r12
    sub rdi,qword ptr [rbp-48]
    dec rdi
    mov rsi,r13
    sub rsi,rbx
    dec rsi
    call oracle_binomial_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-64]
    call bi_mul
    mov rsi,rax
    mov rdi,qword ptr [rbp-56]
    call bi_add
    mov qword ptr [rbp-56],rax
.Locsc_h_next:
    inc rbx
    jmp .Locsc_h_loop
.Locsc_sum_done:
    mov rax,qword ptr [rbp-56]
    jmp .Locsc_done
.Locsc_plain:
    mov rdi,r12
    mov rsi,r13
    call oracle_positive_comp_count
    jmp .Locsc_done
.Locsc_one:
    mov rdi,1
    call bi_from_u64
    jmp .Locsc_done
.Locsc_zero:
    call bi_zero
.Locsc_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_cutlet_state_count,.-oracle_cutlet_state_count

.type oracle_cutlet_partition_unrank,@function
oracle_cutlet_partition_unrank:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-72],r8
    mov qword ptr [rbp-48],0
    mov qword ptr [rbp-56],0
    mov qword ptr [rbp-64],0
.Locpu_pos:
    cmp qword ptr [rbp-48],r13
    jae .Locpu_done
    mov rax,r13
    sub rax,qword ptr [rbp-48]
    mov rbx,r12
    sub rbx,qword ptr [rbp-56]
    sub rbx,rax
    inc rbx
    mov qword ptr [rbp-80],1
.Locpu_x:
    mov rax,qword ptr [rbp-80]
    cmp rax,rbx
    ja .Locpu_fail
    mov r9,qword ptr [rbp-56]
    add r9,rax
    mov r10,qword ptr [rbp-64]
    test r14,r14
    je .Locpu_candidate_ok
    test r10,r10
    jne .Locpu_candidate_ok
    cmp r9,r14
    je .Locpu_hit
    ja .Locpu_x_next
    jmp .Locpu_candidate_ok
.Locpu_hit:
    mov r10,1
.Locpu_candidate_ok:
    mov rdi,r12
    sub rdi,qword ptr [rbp-56]
    sub rdi,qword ptr [rbp-80]
    mov rsi,r13
    sub rsi,qword ptr [rbp-48]
    dec rsi
    mov rdx,r14
    mov rcx,r9
    mov r8,r10
    push r9
    push r10
    call oracle_cutlet_state_count
    pop r10
    pop r9
    mov qword ptr [rbp-88],rax
    mov rdi,r15
    mov rsi,rax
    call bi_cmp
    cmp eax,0
    jle .Locpu_take
    mov rdi,r15
    mov rsi,qword ptr [rbp-88]
    call bi_sub
    mov r15,rax
.Locpu_x_next:
    inc qword ptr [rbp-80]
    jmp .Locpu_x
.Locpu_take:
    mov rax,qword ptr [rbp-72]
    mov rcx,qword ptr [rbp-48]
    mov rdx,qword ptr [rbp-80]
    mov qword ptr [rax+rcx*8],rdx
    add qword ptr [rbp-56],rdx
    mov qword ptr [rbp-64],r10
    inc qword ptr [rbp-48]
    jmp .Locpu_pos
.Locpu_done:
    mov rax,qword ptr [rbp-72]
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Locpu_fail:
    mov rax,60
    mov rdi,131
    syscall
.size oracle_cutlet_partition_unrank,.-oracle_cutlet_partition_unrank

.type oracle_bounded_comp_count,@function
oracle_bounded_comp_count:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    test r13,r13
    jne .Lobcc_slots
    test r12,r12
    jne .Lobcc_zero
    mov rdi,1
    call bi_from_u64
    jmp .Lobcc_done
.Lobcc_slots:
    mov rax,r13
    imul rax,r14
    cmp r12,rax
    jb .Lobcc_zero
    mov rax,r13
    imul rax,r15
    cmp r12,rax
    ja .Lobcc_zero
    mov rbx,r12
    mov rax,r13
    imul rax,r14
    sub rbx,rax
    mov qword ptr [rbp-48],rbx
    mov rax,r15
    sub rax,r14
    inc rax
    mov qword ptr [rbp-56],rax
    mov rdi,0
    call bi_from_u64
    mov qword ptr [rbp-64],rax
    mov qword ptr [rbp-72],0
.Lobcc_j:
    mov rax,qword ptr [rbp-72]
    imul rax,qword ptr [rbp-56]
    cmp rax,qword ptr [rbp-48]
    ja .Lobcc_sum
    mov rdi,r13
    mov rsi,qword ptr [rbp-72]
    call oracle_binomial_u64
    mov qword ptr [rbp-80],rax
    mov rdi,qword ptr [rbp-48]
    mov rax,qword ptr [rbp-72]
    imul rax,qword ptr [rbp-56]
    sub rdi,rax
    add rdi,r13
    dec rdi
    mov rsi,r13
    dec rsi
    call oracle_binomial_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-80]
    call bi_mul
    mov qword ptr [rbp-88],rax
    test qword ptr [rbp-72],1
    jnz .Lobcc_sub
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-88]
    call bi_add
    mov qword ptr [rbp-64],rax
    jmp .Lobcc_next
.Lobcc_sub:
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-88]
    call bi_sub
    mov qword ptr [rbp-64],rax
.Lobcc_next:
    inc qword ptr [rbp-72]
    jmp .Lobcc_j
.Lobcc_sum:
    mov rax,qword ptr [rbp-64]
    jmp .Lobcc_done
.Lobcc_zero:
    call bi_zero
.Lobcc_done:
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_bounded_comp_count,.-oracle_bounded_comp_count

.type oracle_bounded_comp_unrank,@function
oracle_bounded_comp_unrank:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,80
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-72],r8
    mov qword ptr [rbp-80],r9
    mov qword ptr [rbp-48],0
.Lobcu_pos:
    cmp qword ptr [rbp-48],r13
    jae .Lobcu_done
    mov rbx,r14
.Lobcu_x:
    cmp rbx,r15
    ja .Lobcu_fail
    cmp r12,rbx
    jb .Lobcu_next
    mov rdi,r12
    sub rdi,rbx
    mov rsi,r13
    sub rsi,qword ptr [rbp-48]
    dec rsi
    mov rdx,r14
    mov rcx,r15
    call oracle_bounded_comp_count
    mov qword ptr [rbp-88],rax
    mov rdi,qword ptr [rbp-72]
    mov rsi,rax
    call bi_cmp
    cmp eax,0
    jle .Lobcu_take
    mov rdi,qword ptr [rbp-72]
    mov rsi,qword ptr [rbp-88]
    call bi_sub
    mov qword ptr [rbp-72],rax
.Lobcu_next:
    inc rbx
    jmp .Lobcu_x
.Lobcu_take:
    mov rax,qword ptr [rbp-80]
    mov rcx,qword ptr [rbp-48]
    mov qword ptr [rax+rcx*8],rbx
    sub r12,rbx
    inc qword ptr [rbp-48]
    jmp .Lobcu_pos
.Lobcu_done:
    mov rax,qword ptr [rbp-80]
    add rsp,80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lobcu_fail:
    mov rax,60
    mov rdi,132
    syscall
.size oracle_bounded_comp_unrank,.-oracle_bounded_comp_unrank

.type oracle_distinct_unrank,@function
oracle_distinct_unrank:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,448
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    cmp r13,r12
    ja .Lodun_fail
    lea r8,[rbp-488]
    xor ecx,ecx
.Lodun_init:
    cmp rcx,r12
    jae .Lodun_pos_start
    lea rax,[rcx+1]
    mov qword ptr [r8+rcx*8],rax
    inc rcx
    jmp .Lodun_init
.Lodun_pos_start:
    mov qword ptr [rbp-48],r12
    mov qword ptr [rbp-56],0
.Lodun_pos:
    cmp qword ptr [rbp-56],r13
    jae .Lodun_done
    mov rdi,qword ptr [rbp-48]
    dec rdi
    mov rsi,r13
    sub rsi,qword ptr [rbp-56]
    dec rsi
    call oracle_falling_factorial_u64
    mov qword ptr [rbp-64],rax
    mov qword ptr [rbp-72],0
.Lodun_candidate:
    mov rax,qword ptr [rbp-72]
    cmp rax,qword ptr [rbp-48]
    jae .Lodun_fail
    mov rdi,r14
    mov rsi,qword ptr [rbp-64]
    call bi_cmp
    cmp eax,0
    jle .Lodun_choose
    mov rdi,r14
    mov rsi,qword ptr [rbp-64]
    call bi_sub
    mov r14,rax
    inc qword ptr [rbp-72]
    jmp .Lodun_candidate
.Lodun_choose:
    lea r8,[rbp-488]
    mov rcx,qword ptr [rbp-72]
    mov rax,qword ptr [r8+rcx*8]
    mov rdx,qword ptr [rbp-56]
    mov qword ptr [r15+rdx*8],rax
.Lodun_shift:
    mov rax,qword ptr [rbp-72]
    inc rax
    cmp rax,qword ptr [rbp-48]
    jae .Lodun_shift_done
    lea r8,[rbp-488]
    mov rcx,qword ptr [rbp-72]
    mov rdx,qword ptr [r8+rcx*8+8]
    mov qword ptr [r8+rcx*8],rdx
    inc qword ptr [rbp-72]
    jmp .Lodun_shift
.Lodun_shift_done:
    dec qword ptr [rbp-48]
    inc qword ptr [rbp-56]
    jmp .Lodun_pos
.Lodun_done:
    mov rax,r15
    add rsp,448
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lodun_fail:
    mov rax,60
    mov rdi,133
    syscall
.size oracle_distinct_unrank,.-oracle_distinct_unrank

.type oracle_binomial_step_down,@function
oracle_binomial_step_down:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    cmp r13,r14
    jbe .Lobsd_zero
    mov rsi,r13
    sub rsi,r14
    mov rdi,r12
    call bi_mul_u64
    mov r15,rax
    mov rdi,r15
    mov rsi,r13
    call bi_divmod_u64_abs
    mov r15,rax
    test rdx,rdx
    jne .Lobsd_fail
    mov rax,r15
    jmp .Lobsd_done
.Lobsd_zero:
    call bi_zero
    jmp .Lobsd_done
.Lobsd_fail:
    mov rax,60
    mov rdi,138
    syscall
.Lobsd_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_binomial_step_down,.-oracle_binomial_step_down

.type oracle_weaving_count_state,@function
oracle_weaving_count_state:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,100000
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    mov rdi,1
    call bi_from_u64
    mov qword ptr [rbp-48],rax
    mov qword ptr [rbp-56],0
    mov qword ptr [rbp-64],rbx
.Lowcs_active:
    mov rax,qword ptr [rbp-64]
    cmp rax,r15
    jae .Lowcs_active_done
    mov rcx,qword ptr [r13+rax*8]
    test rcx,rcx
    je .Lowcs_fail
    mov rdi,qword ptr [rbp-56]
    add rdi,rcx
    dec rdi
    mov rsi,rcx
    dec rsi
    call oracle_binomial_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-48]
    call bi_mul
    mov qword ptr [rbp-48],rax
    mov rax,qword ptr [rbp-64]
    mov rcx,qword ptr [r13+rax*8]
    add qword ptr [rbp-56],rcx
    inc qword ptr [rbp-64]
    jmp .Lowcs_active
.Lowcs_active_done:
    cmp r15,r14
    jae .Lowcs_return_active
    mov rdi,rsp
    xor eax,eax
    mov rcx,6144
    rep stosq
    lea rdi,[rsp+49152]
    xor eax,eax
    mov rcx,6144
    rep stosq
    mov r10,rsp
    lea r11,[rsp+49152]
    mov qword ptr [rbp-72],r10
    mov qword ptr [rbp-80],r11
    mov rax,r15
    mov rcx,qword ptr [r12+rax*8]
    mov qword ptr [rbp-88],rcx
    dec rcx
    mov qword ptr [rbp-96],rcx
    mov qword ptr [rbp-104],1
    mov rdi,qword ptr [rbp-56]
    dec rdi
    add rdi,qword ptr [rbp-96]
    mov qword ptr [rbp-136],rdi
    mov rsi,qword ptr [rbp-96]
    dec rsi
    mov qword ptr [rbp-144],rsi
    call oracle_binomial_u64
    mov qword ptr [rbp-128],rax
.Lowcs_first_p:
    mov rax,qword ptr [rbp-104]
    mov rcx,qword ptr [rbp-56]
    inc rcx
    cmp rax,rcx
    ja .Lowcs_first_done
    mov rsi,qword ptr [rbp-128]
    mov rdi,qword ptr [rbp-48]
    call bi_mul
    mov rdx,qword ptr [rbp-72]
    mov rcx,qword ptr [rbp-104]
    mov qword ptr [rdx+rcx*8],rax
    mov rax,qword ptr [rbp-104]
    mov rcx,qword ptr [rbp-56]
    inc rcx
    cmp rax,rcx
    jae .Lowcs_first_advance
    mov rdi,qword ptr [rbp-128]
    mov rsi,qword ptr [rbp-136]
    mov rdx,qword ptr [rbp-144]
    call oracle_binomial_step_down
    mov qword ptr [rbp-128],rax
    dec qword ptr [rbp-136]
.Lowcs_first_advance:
    inc qword ptr [rbp-104]
    jmp .Lowcs_first_p
.Lowcs_first_done:
    mov rax,qword ptr [rbp-88]
    add qword ptr [rbp-56],rax
    inc r15
.Lowcs_chain_loop:
    cmp r15,r14
    jae .Lowcs_sum
    mov rdi,qword ptr [rbp-80]
    xor eax,eax
    mov rcx,6144
    rep stosq
    call bi_zero
    mov qword ptr [rbp-112],rax
    mov rax,r15
    mov rcx,qword ptr [r12+rax*8]
    mov qword ptr [rbp-88],rcx
    dec rcx
    mov qword ptr [rbp-96],rcx
    mov qword ptr [rbp-104],1
    mov rdi,qword ptr [rbp-56]
    dec rdi
    add rdi,qword ptr [rbp-96]
    mov qword ptr [rbp-136],rdi
    mov rsi,qword ptr [rbp-96]
    dec rsi
    mov qword ptr [rbp-144],rsi
    call oracle_binomial_u64
    mov qword ptr [rbp-128],rax
.Lowcs_next_p:
    mov rax,qword ptr [rbp-104]
    mov rcx,qword ptr [rbp-56]
    inc rcx
    cmp rax,rcx
    ja .Lowcs_next_done
    mov rdx,qword ptr [rbp-72]
    mov rcx,rax
    dec rcx
    mov rsi,qword ptr [rdx+rcx*8]
    test rsi,rsi
    je .Lowcs_prefix_ready
    mov rdi,qword ptr [rbp-112]
    call bi_add
    mov qword ptr [rbp-112],rax
.Lowcs_prefix_ready:
    mov rsi,qword ptr [rbp-128]
    mov rdi,qword ptr [rbp-112]
    call bi_mul
    mov rdx,qword ptr [rbp-80]
    mov rcx,qword ptr [rbp-104]
    mov qword ptr [rdx+rcx*8],rax
    mov rax,qword ptr [rbp-104]
    mov rcx,qword ptr [rbp-56]
    inc rcx
    cmp rax,rcx
    jae .Lowcs_next_advance
    mov rdi,qword ptr [rbp-128]
    mov rsi,qword ptr [rbp-136]
    mov rdx,qword ptr [rbp-144]
    call oracle_binomial_step_down
    mov qword ptr [rbp-128],rax
    dec qword ptr [rbp-136]
.Lowcs_next_advance:
    inc qword ptr [rbp-104]
    jmp .Lowcs_next_p
.Lowcs_next_done:
    mov rax,qword ptr [rbp-88]
    add qword ptr [rbp-56],rax
    mov rax,qword ptr [rbp-72]
    xchg rax,qword ptr [rbp-80]
    mov qword ptr [rbp-72],rax
    inc r15
    jmp .Lowcs_chain_loop
.Lowcs_sum:
    call bi_zero
    mov qword ptr [rbp-120],rax
    mov qword ptr [rbp-104],1
.Lowcs_sum_loop:
    mov rax,qword ptr [rbp-104]
    cmp rax,qword ptr [rbp-56]
    ja .Lowcs_sum_done
    mov rdx,qword ptr [rbp-72]
    mov rsi,qword ptr [rdx+rax*8]
    test rsi,rsi
    je .Lowcs_sum_next
    mov rdi,qword ptr [rbp-120]
    call bi_add
    mov qword ptr [rbp-120],rax
.Lowcs_sum_next:
    inc qword ptr [rbp-104]
    jmp .Lowcs_sum_loop
.Lowcs_sum_done:
    mov rax,qword ptr [rbp-120]
    jmp .Lowcs_done
.Lowcs_return_active:
    mov rax,qword ptr [rbp-48]
.Lowcs_done:
    add rsp,100000
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lowcs_fail:
    mov rax,60
    mov rdi,134
    syscall
.size oracle_weaving_count_state,.-oracle_weaving_count_state


.type oracle_weaving_prepare,@function
oracle_weaving_prepare:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
    xor ebx,ebx
.Lowp_sum:
    cmp rbx,r13
    jae .Lowp_sum_done
    add r14,qword ptr [r12+rbx*8]
    inc rbx
    jmp .Lowp_sum
.Lowp_sum_done:
    mov rdi,WC_SIZE
    call arena_alloc
    mov r15,rax
    mov qword ptr [r15+WC_LENGTHS],r12
    mov qword ptr [r15+WC_M],r13
    mov qword ptr [r15+WC_TOTAL],r14
    lea rax,[r14+1]
    mov qword ptr [r15+WC_STRIDE],rax
    mov rcx,r13
    inc rcx
    imul rcx,rax
    mov rdi,rcx
    shl rdi,3
    call arena_alloc
    mov qword ptr [r15+WC_TABLE],rax
    mov rdi,rax
    xor eax,eax
    mov rcx,qword ptr [r15+WC_M]
    inc rcx
    imul rcx,qword ptr [r15+WC_STRIDE]
    rep stosq
    mov rdi,qword ptr [r15+WC_M]
    inc rdi
    shl rdi,3
    call arena_alloc
    mov qword ptr [r15+WC_PROGRESS],rax
    mov rdi,rax
    xor eax,eax
    mov rcx,qword ptr [r15+WC_M]
    inc rcx
    rep stosq
    mov rdi,1
    call bi_from_u64
    mov qword ptr [r15+WC_ONE],rax
    mov rax,r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_weaving_prepare,.-oracle_weaving_prepare


.type oracle_weaving_persist_scratch,@function
oracle_weaving_persist_scratch:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,4480
    mov r12,rdi
    mov r13,rsi
    mov r14,qword ptr [r12+BI_SIGN]
    mov r15,qword ptr [r12+BI_LEN]
    cmp r15,560
    ja .Lowps_fail
    mov rsi,qword ptr [r12+BI_DATA]
    mov rdi,rsp
    mov rcx,r15
    rep movsq
    mov rdi,r13
    call arena_reset
    mov rdi,r15
    test rdi,rdi
    jne .Lowps_cap
    mov rdi,1
.Lowps_cap:
    call bi_new
    mov rbx,rax
    mov qword ptr [rbx+BI_SIGN],r14
    mov qword ptr [rbx+BI_LEN],r15
    test r15,r15
    je .Lowps_done_copy
    mov rsi,rsp
    mov rdi,qword ptr [rbx+BI_DATA]
    mov rcx,r15
    rep movsq
.Lowps_done_copy:
    mov rax,rbx
    add rsp,4480
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lowps_fail:
    mov rax,60
    mov rdi,143
    syscall
.size oracle_weaving_persist_scratch,.-oracle_weaving_persist_scratch

.type oracle_weaving_suffix_get,@function
oracle_weaving_suffix_get:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,48
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    cmp r13,qword ptr [r12+WC_M]
    ja .Lowf_fail
    cmp r14,qword ptr [r12+WC_TOTAL]
    ja .Lowf_fail
    cmp r13,qword ptr [r12+WC_M]
    jne .Lowf_not_base
    mov rax,qword ptr [r12+WC_ONE]
    jmp .Lowf_done
.Lowf_not_base:
    mov rax,r13
    imul rax,qword ptr [r12+WC_STRIDE]
    add rax,r14
    mov rdx,qword ptr [r12+WC_TABLE]
    mov rax,qword ptr [rdx+rax*8]
    test rax,rax
    jne .Lowf_done
    mov rdx,qword ptr [r12+WC_PROGRESS]
    mov r15,qword ptr [rdx+r13*8]
    test r15,r15
    jne .Lowf_extend
    mov rax,qword ptr [r12+WC_LENGTHS]
    mov rbx,qword ptr [rax+r13*8]
    mov rdi,r12
    lea rsi,[r13+1]
    lea rdx,[rbx-1]
    call oracle_weaving_suffix_get
    mov rcx,r13
    imul rcx,qword ptr [r12+WC_STRIDE]
    mov rdx,qword ptr [r12+WC_TABLE]
    mov qword ptr [rdx+rcx*8],rax
    mov rdx,qword ptr [r12+WC_PROGRESS]
    mov qword ptr [rdx+r13*8],1
    mov r15,1
.Lowf_extend:
    cmp r15,r14
    ja .Lowf_fetch
    mov qword ptr [rbp-48],r15
    mov rax,qword ptr [r12+WC_LENGTHS]
    mov rbx,qword ptr [rax+r13*8]
    mov rdi,r12
    lea rsi,[r13+1]
    mov rdx,r15
    add rdx,rbx
    dec rdx
    call oracle_weaving_suffix_get
    mov qword ptr [rbp-56],rax
    call arena_mark
    mov qword ptr [rbp-72],rax
    mov rdi,r15
    add rdi,rbx
    sub rdi,2
    mov rsi,rbx
    sub rsi,2
    call oracle_binomial_u64
    mov rdi,rax
    mov rsi,qword ptr [rbp-56]
    call bi_mul
    mov qword ptr [rbp-64],rax
    mov rax,r13
    imul rax,qword ptr [r12+WC_STRIDE]
    add rax,r15
    dec rax
    mov rdx,qword ptr [r12+WC_TABLE]
    mov rdi,qword ptr [rdx+rax*8]
    mov rsi,qword ptr [rbp-64]
    call bi_add
    mov rdi,rax
    mov rsi,qword ptr [rbp-72]
    call oracle_weaving_persist_scratch
    mov r15,qword ptr [rbp-48]
    mov rcx,r13
    imul rcx,qword ptr [r12+WC_STRIDE]
    add rcx,r15
    mov rdx,qword ptr [r12+WC_TABLE]
    mov qword ptr [rdx+rcx*8],rax
    inc r15
    mov rdx,qword ptr [r12+WC_PROGRESS]
    mov qword ptr [rdx+r13*8],r15
    jmp .Lowf_extend
.Lowf_fetch:
    mov rax,r13
    imul rax,qword ptr [r12+WC_STRIDE]
    add rax,r14
    mov rdx,qword ptr [r12+WC_TABLE]
    mov rax,qword ptr [rdx+rax*8]
    test rax,rax
    je .Lowf_fail
.Lowf_done:
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lowf_fail:
    mov rax,60
    mov rdi,140
    syscall
.size oracle_weaving_suffix_get,.-oracle_weaving_suffix_get

.type oracle_weaving_active_product,@function
oracle_weaving_active_product:
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
    mov rdi,1
    call bi_from_u64
    mov r15,rax
    xor ebx,ebx
.Lowa_loop:
    cmp r14,r13
    jae .Lowa_done
    mov rcx,qword ptr [r12+r14*8]
    test rcx,rcx
    je .Lowa_fail
    mov rdi,rbx
    add rdi,rcx
    dec rdi
    mov rsi,rcx
    dec rsi
    call oracle_binomial_u64
    mov rdi,r15
    mov rsi,rax
    call bi_mul
    mov r15,rax
    add rbx,qword ptr [r12+r14*8]
    inc r14
    jmp .Lowa_loop
.Lowa_done:
    mov rax,r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lowa_fail:
    mov rax,60
    mov rdi,141
    syscall
.size oracle_weaving_active_product,.-oracle_weaving_active_product

.type oracle_weaving_unrank_prepared,@function
oracle_weaving_unrank_prepared:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,128
    mov r12,rdi
    mov r15,rdx
    mov rdi,rsi
    call bi_clone
    mov r14,rax
    mov r13,qword ptr [r12+WC_M]
    mov rdi,r13
    shl rdi,3
    call arena_alloc
    mov qword ptr [rbp-48],rax
    mov rdx,qword ptr [r12+WC_LENGTHS]
    xor ecx,ecx
    xor ebx,ebx
.Lowup_init:
    cmp rcx,r13
    jae .Lowup_init_done
    mov rax,qword ptr [rdx+rcx*8]
    mov r8,qword ptr [rbp-48]
    mov qword ptr [r8+rcx*8],rax
    add rbx,rax
    inc rcx
    jmp .Lowup_init
.Lowup_init_done:
    mov qword ptr [rbp-56],0
    mov qword ptr [rbp-64],0
    mov qword ptr [rbp-72],0
.Lowup_position:
    cmp qword ptr [rbp-72],rbx
    jae .Lowup_done
    mov qword ptr [rbp-80],0
.Lowup_candidate:
    mov rax,qword ptr [rbp-80]
    cmp rax,r13
    jae .Lowup_fail
    mov rdx,qword ptr [rbp-48]
    mov rcx,qword ptr [rdx+rax*8]
    test rcx,rcx
    je .Lowup_next_candidate
    mov r9,rax
    inc r9
    mov r10,qword ptr [rbp-56]
    mov r11,qword ptr [rbp-64]
    cmp r9,r10
    jbe .Lowup_opened
    lea rax,[r10+1]
    cmp r9,rax
    jne .Lowup_next_candidate
    jmp .Lowup_open_rule_ok
.Lowup_opened:
    mov rax,qword ptr [r12+WC_LENGTHS]
    mov rax,qword ptr [rax+r9*8-8]
    cmp rcx,rax
    jne .Lowup_open_rule_ok
    mov rax,qword ptr [rbp-56]
    inc rax
    cmp r9,rax
    jne .Lowup_next_candidate
.Lowup_open_rule_ok:
    cmp rcx,1
    jne .Lowup_legal
    mov rax,qword ptr [rbp-64]
    inc rax
    cmp r9,rax
    jne .Lowup_next_candidate
.Lowup_legal:
    mov qword ptr [rbp-88],rcx
    mov qword ptr [rbp-96],r10
    mov qword ptr [rbp-104],r11
    mov rax,qword ptr [rbp-80]
    mov rdx,qword ptr [rbp-48]
    dec qword ptr [rdx+rax*8]
    mov rax,qword ptr [rbp-80]
    mov rcx,qword ptr [r12+WC_LENGTHS]
    mov rcx,qword ptr [rcx+rax*8]
    cmp qword ptr [rbp-88],rcx
    jne .Lowup_after_open_update
    inc qword ptr [rbp-56]
.Lowup_after_open_update:
    cmp qword ptr [rbp-88],1
    jne .Lowup_after_close_update
    inc qword ptr [rbp-64]
.Lowup_after_close_update:
    mov rax,qword ptr [rbp-64]
    xor r10d,r10d
.Lowup_total_loop:
    cmp rax,qword ptr [rbp-56]
    jae .Lowup_total_done
    mov rdx,qword ptr [rbp-48]
    add r10,qword ptr [rdx+rax*8]
    inc rax
    jmp .Lowup_total_loop
.Lowup_total_done:
    mov qword ptr [rbp-112],r10
    mov rdi,r12
    mov rsi,qword ptr [rbp-56]
    mov rdx,r10
    call oracle_weaving_suffix_get
    mov qword ptr [rbp-120],rax
    call arena_mark
    mov qword ptr [rbp-128],rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-64]
    call oracle_weaving_active_product
    mov rdi,rax
    mov rsi,qword ptr [rbp-120]
    call bi_mul
    mov qword ptr [rbp-136],rax
    mov rdi,r14
    mov rsi,rax
    call bi_cmp
    cmp eax,0
    jle .Lowup_take
    mov rdi,r14
    mov rsi,qword ptr [rbp-136]
    call bi_sub_abs_inplace
    mov rdi,qword ptr [rbp-128]
    call arena_reset
    mov rax,qword ptr [rbp-80]
    mov rdx,qword ptr [rbp-48]
    mov rcx,qword ptr [rbp-88]
    mov qword ptr [rdx+rax*8],rcx
    mov rax,qword ptr [rbp-96]
    mov qword ptr [rbp-56],rax
    mov rax,qword ptr [rbp-104]
    mov qword ptr [rbp-64],rax
.Lowup_next_candidate:
    inc qword ptr [rbp-80]
    jmp .Lowup_candidate
.Lowup_take:
    mov rdi,qword ptr [rbp-128]
    call arena_reset
    mov rax,qword ptr [rbp-80]
    inc rax
    mov rcx,qword ptr [rbp-72]
    mov qword ptr [r15+rcx*8],rax
    inc qword ptr [rbp-72]
    jmp .Lowup_position
.Lowup_done:
    mov rax,r15
    add rsp,128
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lowup_fail:
    mov rax,60
    mov rdi,142
    syscall
.size oracle_weaving_unrank_prepared,.-oracle_weaving_unrank_prepared

.type oracle_weaving_count,@function
oracle_weaving_count:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rsi
    call oracle_weaving_prepare
    mov rdi,rax
    xor esi,esi
    xor edx,edx
    call oracle_weaving_suffix_get
    pop r12
    leave
    ret
.size oracle_weaving_count,.-oracle_weaving_count

.type oracle_weaving_unrank,@function
oracle_weaving_unrank:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdx
    mov r13,rcx
    call oracle_weaving_prepare
    mov rdi,rax
    mov rsi,r12
    mov rdx,r13
    call oracle_weaving_unrank_prepared
    pop r13
    pop r12
    leave
    ret
.size oracle_weaving_unrank,.-oracle_weaving_unrank

.extern bi_add_u64

.type oracle_build_year_structure,@function
oracle_build_year_structure:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,208
    mov r12,rdi
    mov r13,rsi
    mov rdi,YS_SIZE
    call arena_alloc
    mov r14,rax
    mov qword ptr [r14+YS_YEAR],r13
    mov rdi,qword ptr [r13+Y_OPEN_DAY]
    mov rsi,1
    call bi_add_u64
    mov qword ptr [r14+YS_FIRST_DAY],rax
    mov rdi,r12
    mov rsi,rax
    call oracle_sauce
    mov r15,rax
    mov rdi,qword ptr [r13+Y_CLOSE]
    mov rdi,qword ptr [rdi+G_INDEX]
    mov rax,qword ptr [r13+Y_OPEN]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    mov qword ptr [rbp-48],rax
    mov rbx,rax
    cmp rbx,17
    jbe .Lobys_kmax
    mov rbx,17
.Lobys_kmax:
    cmp rbx,6
    jb .Lobys_fail
    mov rdi,r15
    mov rsi,2
    mov rdx,20
    call oracle_ask_bowl
    mov qword ptr [rbp-56],rax
    mov rdi,rbx
    sub rdi,5
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-56]
    call oracle_choose_rank
    mov rdi,rax
    call oracle_to_u64
    add rax,5
    mov qword ptr [r14+YS_CUTLET_COUNT],rax
    mov qword ptr [rbp-64],rax
    mov qword ptr [rbp-72],0
    mov rdi,r12
    call oracle_exact_gate_node
    test rax,rax
    je .Lobys_required_done
    mov qword ptr [rbp-80],rax
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r13+Y_OPEN]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_cmp
    cmp eax,0
    jle .Lobys_required_done
    mov rax,qword ptr [rbp-80]
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r13+Y_CLOSE]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_cmp
    cmp eax,0
    jge .Lobys_required_done
    mov rax,qword ptr [rbp-80]
    mov rdi,qword ptr [rax+G_INDEX]
    mov rax,qword ptr [r13+Y_OPEN]
    mov rsi,qword ptr [rax+G_INDEX]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    mov qword ptr [rbp-72],rax
.Lobys_required_done:
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-64]
    mov rdx,qword ptr [rbp-72]
    call oracle_cutlet_partition_count
    mov qword ptr [rbp-88],rax
    mov rdi,r15
    mov rsi,2
    mov rdx,21
    call oracle_ask_bowl
    mov rdi,rax
    mov rsi,qword ptr [rbp-88]
    call oracle_choose_rank
    mov qword ptr [rbp-96],rax
    mov rdi,qword ptr [rbp-64]
    shl rdi,3
    call arena_alloc
    mov qword ptr [r14+YS_PARTITION],rax
    mov r8,rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-64]
    mov rdx,qword ptr [rbp-72]
    mov rcx,qword ptr [rbp-96]
    call oracle_cutlet_partition_unrank
    mov rdi,17
    mov rsi,qword ptr [rbp-64]
    call oracle_falling_factorial_u64
    mov qword ptr [rbp-104],rax
    mov rdi,r15
    mov rsi,5
    mov rdx,22
    call oracle_ask_bowl
    mov rdi,rax
    mov rsi,qword ptr [rbp-104]
    call oracle_choose_rank
    mov qword ptr [rbp-112],rax
    mov rdi,qword ptr [rbp-64]
    shl rdi,3
    call arena_alloc
    mov qword ptr [r14+YS_CUTLET_NAMES],rax
    mov rcx,rax
    mov rdi,17
    mov rsi,qword ptr [rbp-64]
    mov rdx,qword ptr [rbp-112]
    call oracle_distinct_unrank
    mov rdi,qword ptr [rbp-64]
    imul rdi,CUT_SIZE
    call arena_alloc
    mov qword ptr [r14+YS_CUTLETS],rax
    mov qword ptr [rbp-120],rax
    mov rax,qword ptr [r13+Y_OPEN]
    mov qword ptr [rbp-128],rax
    mov qword ptr [rbp-136],0
.Lobys_cutlet_loop:
    mov rax,qword ptr [rbp-136]
    cmp rax,qword ptr [rbp-64]
    jae .Lobys_months
    mov rdx,qword ptr [r14+YS_PARTITION]
    mov rcx,qword ptr [rdx+rax*8]
    mov qword ptr [rbp-144],rcx
    mov qword ptr [rbp-152],0
.Lobys_gate_step:
    mov rax,qword ptr [rbp-152]
    cmp rax,qword ptr [rbp-144]
    jae .Lobys_gate_step_done
    mov rax,qword ptr [rbp-128]
    mov rax,qword ptr [rax+G_NEXT]
    test rax,rax
    je .Lobys_fail
    mov qword ptr [rbp-128],rax
    inc qword ptr [rbp-152]
    jmp .Lobys_gate_step
.Lobys_gate_step_done:
    mov rax,qword ptr [rbp-136]
    imul rax,CUT_SIZE
    mov rdx,qword ptr [rbp-120]
    add rdx,rax
    mov rax,qword ptr [rbp-128]
    mov rcx,qword ptr [rax+G_DAY]
    mov qword ptr [rdx+CUT_LAST],rcx
    mov rcx,qword ptr [rbp-136]
    mov rax,qword ptr [r14+YS_CUTLET_NAMES]
    mov rax,qword ptr [rax+rcx*8]
    mov qword ptr [rdx+CUT_NAME_ID],rax
    mov rax,qword ptr [rbp-136]
    test rax,rax
    jne .Lobys_first_from_prev
    mov rdi,qword ptr [r13+Y_OPEN_DAY]
    mov rsi,1
    call bi_add_u64
    jmp .Lobys_store_first
.Lobys_first_from_prev:
    dec rax
    imul rax,CUT_SIZE
    mov rcx,qword ptr [rbp-120]
    mov rdi,qword ptr [rcx+rax+CUT_LAST]
    mov rsi,1
    call bi_add_u64
.Lobys_store_first:
    mov rcx,qword ptr [rbp-136]
    imul rcx,CUT_SIZE
    mov rdx,qword ptr [rbp-120]
    mov qword ptr [rdx+rcx+CUT_FIRST],rax
    inc qword ptr [rbp-136]
    jmp .Lobys_cutlet_loop
.Lobys_months:
    mov rdi,qword ptr [r13+Y_CLOSE_DAY]
    mov rsi,qword ptr [r13+Y_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    mov qword ptr [rbp-160],rax
    mov rax,qword ptr [rbp-160]
    add rax,122
    xor edx,edx
    mov rcx,123
    div rcx
    mov qword ptr [rbp-168],rax
    mov rax,qword ptr [rbp-160]
    xor edx,edx
    mov rcx,4
    div rcx
    cmp rax,47
    jbe .Lobys_hi_ok
    mov rax,47
.Lobys_hi_ok:
    mov qword ptr [rbp-176],rax
    mov rcx,rax
    sub rcx,qword ptr [rbp-168]
    inc rcx
    mov qword ptr [rbp-240],rcx
    mov rdi,r15
    mov rsi,3
    mov rdx,30
    call oracle_ask_bowl
    mov qword ptr [rbp-184],rax
    mov rdi,qword ptr [rbp-240]
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [rbp-184]
    call oracle_choose_rank
    mov rdi,rax
    call oracle_to_u64
    dec rax
    add rax,qword ptr [rbp-168]
    mov qword ptr [r14+YS_MONTH_COUNT],rax
    mov qword ptr [rbp-184],rax
    mov rdi,qword ptr [rbp-160]
    mov rsi,qword ptr [rbp-184]
    mov rdx,4
    mov rcx,123
    call oracle_bounded_comp_count
    mov qword ptr [rbp-192],rax
    mov rdi,r15
    mov rsi,3
    mov rdx,31
    call oracle_ask_bowl
    mov rdi,rax
    mov rsi,qword ptr [rbp-192]
    call oracle_choose_rank
    mov qword ptr [rbp-200],rax
    mov rdi,qword ptr [rbp-184]
    shl rdi,3
    call arena_alloc
    mov qword ptr [r14+YS_MONTH_LENGTHS],rax
    mov r9,rax
    mov rdi,qword ptr [rbp-160]
    mov rsi,qword ptr [rbp-184]
    mov rdx,4
    mov rcx,123
    mov r8,qword ptr [rbp-200]
    call oracle_bounded_comp_unrank
    mov rdi,qword ptr [r14+YS_MONTH_LENGTHS]
    mov rsi,qword ptr [rbp-184]
    call oracle_weaving_prepare
    mov qword ptr [rbp-248],rax
    mov rdi,rax
    xor esi,esi
    xor edx,edx
    call oracle_weaving_suffix_get
    mov qword ptr [rbp-208],rax
    mov rdi,r15
    mov rsi,4
    mov rdx,32
    call oracle_ask_bowl
    mov rdi,rax
    mov rsi,qword ptr [rbp-208]
    call oracle_choose_rank
    mov qword ptr [rbp-216],rax
    mov rdi,qword ptr [rbp-160]
    shl rdi,3
    call arena_alloc
    mov qword ptr [r14+YS_WEAVE],rax
    mov rdx,rax
    mov rdi,qword ptr [rbp-248]
    mov rsi,qword ptr [rbp-216]
    call oracle_weaving_unrank_prepared
    mov rdi,47
    mov rsi,qword ptr [rbp-184]
    call oracle_falling_factorial_u64
    mov qword ptr [rbp-224],rax
    mov rdi,r15
    mov rsi,5
    mov rdx,33
    call oracle_ask_bowl
    mov rdi,rax
    mov rsi,qword ptr [rbp-224]
    call oracle_choose_rank
    mov qword ptr [rbp-232],rax
    mov rdi,qword ptr [rbp-184]
    shl rdi,3
    call arena_alloc
    mov qword ptr [r14+YS_MONTH_NAMES],rax
    mov rcx,rax
    mov rdi,47
    mov rsi,qword ptr [rbp-184]
    mov rdx,qword ptr [rbp-232]
    call oracle_distinct_unrank
    mov rax,r14
    add rsp,208
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lobys_fail:
    mov rax,60
    mov rdi,136
    syscall
.size oracle_build_year_structure,.-oracle_build_year_structure

.type oracle_calendar_date,@function
oracle_calendar_date:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,64
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    mov rsi,r13
    call oracle_find_target_year
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    call oracle_build_year_structure
    mov r15,rax
    mov qword ptr [rbp-48],0
.Locd_cutlet_scan:
    mov rax,qword ptr [rbp-48]
    cmp rax,qword ptr [r15+YS_CUTLET_COUNT]
    jae .Locd_fail
    imul rax,CUT_SIZE
    mov rdx,qword ptr [r15+YS_CUTLETS]
    add rdx,rax
    mov qword ptr [rbp-56],rdx
    mov rdi,r13
    mov rsi,qword ptr [rdx+CUT_FIRST]
    call bi_cmp
    cmp eax,0
    jl .Locd_cutlet_next
    mov rdx,qword ptr [rbp-56]
    mov rdi,r13
    mov rsi,qword ptr [rdx+CUT_LAST]
    call bi_cmp
    cmp eax,0
    jle .Locd_cutlet_found
.Locd_cutlet_next:
    inc qword ptr [rbp-48]
    jmp .Locd_cutlet_scan
.Locd_cutlet_found:
    mov rdx,qword ptr [rbp-56]
    mov rdi,r13
    mov rsi,qword ptr [rdx+CUT_FIRST]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    inc rax
    mov qword ptr [rbp-64],rax
    mov rdi,r13
    mov rsi,qword ptr [r15+YS_FIRST_DAY]
    call bi_sub
    mov rdi,rax
    call oracle_to_u64
    mov qword ptr [rbp-72],rax
    mov rdx,qword ptr [r15+YS_WEAVE]
    mov rcx,qword ptr [rbp-72]
    mov rbx,qword ptr [rdx+rcx*8]
    mov qword ptr [rbp-80],0
    xor ecx,ecx
.Locd_occurrence:
    cmp rcx,qword ptr [rbp-72]
    ja .Locd_occurrence_done
    mov rdx,qword ptr [r15+YS_WEAVE]
    cmp qword ptr [rdx+rcx*8],rbx
    jne .Locd_occurrence_next
    inc qword ptr [rbp-80]
.Locd_occurrence_next:
    inc rcx
    jmp .Locd_occurrence
.Locd_occurrence_done:
    mov rdi,RES_SIZE
    call arena_alloc
    mov r12,rax
    mov rax,qword ptr [r14+Y_NUMBER]
    mov qword ptr [r12+RES_YEAR],rax
    mov rdx,qword ptr [rbp-56]
    mov rdi,qword ptr [rdx+CUT_NAME_ID]
    call catalog_get_cutlet
    mov qword ptr [r12+RES_CUTLET_NAME],rax
    mov rax,qword ptr [rbp-64]
    mov qword ptr [r12+RES_DAY_IN_CUTLET],rax
    mov rdx,qword ptr [r15+YS_MONTH_NAMES]
    mov rdi,qword ptr [rdx+rbx*8-8]
    call catalog_get_month
    mov qword ptr [r12+RES_MONTH_NAME],rax
    mov rax,qword ptr [rbp-80]
    mov qword ptr [r12+RES_DAY_IN_MONTH],rax
    mov rax,r12
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Locd_fail:
    mov rax,60
    mov rdi,137
    syscall
.size oracle_calendar_date,.-oracle_calendar_date
