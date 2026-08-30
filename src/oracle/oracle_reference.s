.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24
.equ BI_HEADER,32
.equ COUNTS_ACTION,0
.equ COUNTS_TARGET,8
.equ COUNTS_DISTANCE,16
.equ COUNTS_CONNECTION,24
.equ COUNTS_DIRECTION,32
.equ COUNTS_SIZE,40
.equ STREAM_FIRST,0
.equ STREAM_STEP,8
.equ STREAM_SIZE,16

.section .bss
.align 8
.global oracle_M
.global oracle_FOUNDATION
.global oracle_TABLETS
.global oracle_ZERO
.global oracle_ONE
oracle_M: .quad 0
oracle_FOUNDATION: .quad 0
oracle_TABLETS: .quad 0
oracle_ZERO: .quad 0
oracle_ONE: .quad 0
oracle_initialized: .quad 0

.section .rodata
.align 8
factorial_0_6: .quad 1,1,2,6,24,120,720

.section .text
.extern arena_alloc
.extern bi_new
.extern bi_zero
.extern bi_from_u64
.extern bi_from_i64
.extern bi_clone
.extern bi_normalize
.extern bi_cmp_abs
.extern bi_cmp
.extern bi_add_abs
.extern bi_sub_abs
.extern bi_add
.extern bi_neg
.extern bi_sub
.extern bi_mul_abs
.extern bi_mul
.extern bi_mul_u64
.extern bi_add_u64
.extern bi_divmod_abs
.extern bi_divmod_u64_abs
.extern bi_mod_abs
.extern bi_eq_u64
.extern bi_is_zero
.extern bi_abs

.global oracle_init
.global oracle_regular_mod
.global oracle_SAVE
.global oracle_day_count
.global oracle_work_counts
.global oracle_binomial_u64
.global oracle_falling_factorial_u64
.global oracle_permutation_unrank6
.global oracle_bowl_order_from_value
.global oracle_ring_step_bound
.global oracle_choose_rank_short
.global oracle_choose_rank_wide
.global oracle_choose_rank
.global oracle_to_u64

.type oracle_init,@function
oracle_init:
    cmp qword ptr [rip+oracle_initialized],0
    jne .Loi_done
    call bi_zero
    mov qword ptr [rip+oracle_ZERO],rax
    mov rdi,1
    call bi_from_u64
    mov qword ptr [rip+oracle_ONE],rax
    mov rdi,2
    call bi_new
    mov qword ptr [rax+BI_SIGN],1
    mov qword ptr [rax+BI_LEN],2
    mov rcx,qword ptr [rax+BI_DATA]
    mov qword ptr [rcx],-1
    mov rdx,0x7fffffffffffffff
    mov qword ptr [rcx+8],rdx
    mov qword ptr [rip+oracle_M],rax
    mov rdi,-15055671
    call bi_from_i64
    mov qword ptr [rip+oracle_FOUNDATION],rax
    mov rdi,-278522
    call bi_from_i64
    mov qword ptr [rip+oracle_TABLETS],rax
    mov qword ptr [rip+oracle_initialized],1
.Loi_done:
    ret
.size oracle_init,.-oracle_init

.type oracle_to_u64,@function
oracle_to_u64:
    cmp qword ptr [rdi+BI_SIGN],0
    jl .Lot64_fail
    mov rcx,qword ptr [rdi+BI_LEN]
    test rcx,rcx
    je .Lot64_zero
    cmp rcx,1
    jne .Lot64_fail
    mov rdx,qword ptr [rdi+BI_DATA]
    mov rax,qword ptr [rdx]
    ret
.Lot64_zero:
    xor eax,eax
    ret
.Lot64_fail:
    mov rax,60
    mov rdi,110
    syscall
.size oracle_to_u64,.-oracle_to_u64

.type oracle_regular_mod,@function
oracle_regular_mod:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    cmp qword ptr [r13+BI_SIGN],1
    jne .Lorm_fail
    cmp qword ptr [r13+BI_LEN],0
    je .Lorm_fail
    mov r14,qword ptr [r12+BI_SIGN]
    mov rdi,r12
    call bi_abs
    mov rdi,rax
    mov rsi,r13
    call bi_mod_abs
    mov r15,rax
    test r14,r14
    jge .Lorm_positive
    mov rdi,r15
    call bi_is_zero
    test eax,eax
    jne .Lorm_positive
    mov rdi,r13
    mov rsi,r15
    call bi_sub_abs
    jmp .Lorm_done
.Lorm_positive:
    mov rax,r15
    jmp .Lorm_done
.Lorm_fail:
    mov rax,60
    mov rdi,112
    syscall
.Lorm_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_regular_mod,.-oracle_regular_mod

.type oracle_SAVE,@function
oracle_SAVE:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi
    call oracle_init
    mov rdi,r12
    mov rsi,qword ptr [rip+oracle_ONE]
    call bi_sub
    mov rdi,rax
    mov rsi,qword ptr [rip+oracle_M]
    call oracle_regular_mod
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    pop r12
    leave
    ret
.size oracle_SAVE,.-oracle_SAVE

.type oracle_day_count,@function
oracle_day_count:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call oracle_init
    mov rdi,r12
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call bi_cmp
    test eax,eax
    je .Lodc_equal
    jg .Lodc_after
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,r12
    call bi_sub
    mov rdi,rax
    mov rsi,2
    call bi_mul_u64
    jmp .Lodc_done
.Lodc_after:
    mov rdi,r12
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call bi_sub
    mov rdi,rax
    mov rsi,2
    call bi_mul_u64
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    jmp .Lodc_done
.Lodc_equal:
    mov rdi,1
    call bi_from_u64
.Lodc_done:
    pop r13
    pop r12
    leave
    ret
.size oracle_day_count,.-oracle_day_count

.type oracle_work_counts,@function
oracle_work_counts:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call oracle_day_count
    mov r14,rax
    mov rdi,r13
    call oracle_day_count
    mov r15,rax
    mov rdi,r13
    mov rsi,r12
    call bi_sub
    mov rdi,rax
    call bi_abs
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    mov rbx,rax
    mov rdi,r14
    mov rsi,r15
    call bi_add
    push rax
    mov rdi,r13
    mov rsi,r12
    call bi_cmp
    mov ecx,2
    test eax,eax
    je .Lowc_direction
    mov ecx,1
    jl .Lowc_direction
    mov ecx,3
.Lowc_direction:
    mov rdi,rcx
    call bi_from_u64
    push rax
    mov rdi,COUNTS_SIZE
    call arena_alloc
    mov r10,rax
    pop r11
    pop rdx
    mov qword ptr [r10+COUNTS_ACTION],r14
    mov qword ptr [r10+COUNTS_TARGET],r15
    mov qword ptr [r10+COUNTS_DISTANCE],rbx
    mov qword ptr [r10+COUNTS_CONNECTION],rdx
    mov qword ptr [r10+COUNTS_DIRECTION],r11
    mov rax,r10
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_work_counts,.-oracle_work_counts

.type oracle_binomial_u64,@function
oracle_binomial_u64:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    cmp r13,r12
    ja .Lobu_zero
    mov rax,r12
    sub rax,r13
    cmp r13,rax
    jbe .Lobu_k_ready
    mov r13,rax
.Lobu_k_ready:
    mov rdi,1
    call bi_from_u64
    mov r15,rax
    mov r14,1
.Lobu_loop:
    cmp r14,r13
    ja .Lobu_done
    mov rbx,r12
    sub rbx,r13
    add rbx,r14
    mov rdi,r15
    mov rsi,rbx
    call bi_mul_u64
    mov r15,rax
    mov rdi,r15
    mov rsi,r14
    call bi_divmod_u64_abs
    mov r15,rax
    test rdx,rdx
    jne .Lobu_fail
    inc r14
    jmp .Lobu_loop
.Lobu_zero:
    call bi_zero
    jmp .Lobu_exit
.Lobu_fail:
    mov rax,60
    mov rdi,113
    syscall
.Lobu_done:
    mov rax,r15
.Lobu_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_binomial_u64,.-oracle_binomial_u64

.type oracle_falling_factorial_u64,@function
oracle_falling_factorial_u64:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    cmp r13,r12
    ja .Loff_zero
    mov rdi,1
    call bi_from_u64
    mov r15,rax
    xor r14d,r14d
.Loff_loop:
    cmp r14,r13
    jae .Loff_done
    mov rsi,r12
    sub rsi,r14
    mov rdi,r15
    call bi_mul_u64
    mov r15,rax
    inc r14
    jmp .Loff_loop
.Loff_zero:
    call bi_zero
    jmp .Loff_exit
.Loff_done:
    mov rax,r15
.Loff_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_falling_factorial_u64,.-oracle_falling_factorial_u64

.type oracle_permutation_unrank6,@function
oracle_permutation_unrank6:
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
    cmp r12,1
    jb .Lopu_fail
    cmp r12,720
    ja .Lopu_fail
    dec r12
    lea r8,[rbp-104]
    mov qword ptr [r8],1
    mov qword ptr [r8+8],2
    mov qword ptr [r8+16],3
    mov qword ptr [r8+24],4
    mov qword ptr [r8+32],5
    mov qword ptr [r8+40],6
    mov r14,6
    xor r15d,r15d
.Lopu_slot:
    test r14,r14
    je .Lopu_done
    lea r9,[rip+factorial_0_6]
    mov rbx,qword ptr [r9+r14*8-8]
    mov rax,r12
    xor edx,edx
    div rbx
    mov r12,rdx
    mov rcx,rax
    mov rax,qword ptr [r8+rcx*8]
    mov qword ptr [r13+r15*8],rax
    mov rdx,rcx
.Lopu_remove:
    lea rax,[rdx+1]
    cmp rax,r14
    jae .Lopu_removed
    mov rbx,qword ptr [r8+rax*8]
    mov qword ptr [r8+rdx*8],rbx
    inc rdx
    jmp .Lopu_remove
.Lopu_removed:
    dec r14
    inc r15
    jmp .Lopu_slot
.Lopu_done:
    mov eax,1
    jmp .Lopu_exit
.Lopu_fail:
    xor eax,eax
.Lopu_exit:
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_permutation_unrank6,.-oracle_permutation_unrank6

.type oracle_bowl_order_from_value,@function
oracle_bowl_order_from_value:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call oracle_init
    mov rdi,r12
    mov rsi,qword ptr [rip+oracle_ONE]
    call bi_sub
    mov r12,rax
    mov rdi,720
    call bi_from_u64
    mov rsi,rax
    mov rdi,r12
    call oracle_regular_mod
    mov rdi,rax
    call oracle_to_u64
    inc rax
    mov rdi,rax
    mov rsi,r13
    call oracle_permutation_unrank6
    pop r13
    pop r12
    leave
    ret
.size oracle_bowl_order_from_value,.-oracle_bowl_order_from_value

.type oracle_ring_step_bound,@function
oracle_ring_step_bound:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    cmp r13,0
    jl .Lorsb_minus
    mov rdi,r12
    mov rsi,r14
    call bi_cmp
    test eax,eax
    je .Lorsb_plus_wrap
    mov rdi,r12
    mov rsi,1
    call bi_add_u64
    jmp .Lorsb_done
.Lorsb_plus_wrap:
    mov rdi,1
    call bi_from_u64
    jmp .Lorsb_done
.Lorsb_minus:
    mov rdi,r12
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    jne .Lorsb_minus_wrap
    mov rdi,r12
    mov rsi,qword ptr [rip+oracle_ONE]
    call bi_sub
    jmp .Lorsb_done
.Lorsb_minus_wrap:
    mov rdi,r14
    call bi_clone
.Lorsb_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_ring_step_bound,.-oracle_ring_step_bound

.type oracle_choose_rank_short,@function
oracle_choose_rank_short:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    call oracle_init
    mov rdi,qword ptr [rip+oracle_M]
    mov rsi,r13
    call bi_divmod_abs
    mov rdi,rax
    mov rsi,r13
    call bi_mul_abs
    mov r14,rax
    mov rdi,qword ptr [r12+STREAM_FIRST]
    call bi_clone
    mov r15,rax
.Locrs_loop:
    mov rdi,r15
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jle .Locrs_accept
    mov rdi,r15
    mov rsi,qword ptr [r12+STREAM_STEP]
    mov rdx,qword ptr [rip+oracle_M]
    call oracle_ring_step_bound
    mov r15,rax
    jmp .Locrs_loop
.Locrs_accept:
    mov rdi,r15
    mov rsi,qword ptr [rip+oracle_ONE]
    call bi_sub
    mov rdi,rax
    mov rsi,r13
    call oracle_regular_mod
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_choose_rank_short,.-oracle_choose_rank_short

.type oracle_choose_rank_wide,@function
oracle_choose_rank_wide:
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
    call oracle_init
    mov rdi,qword ptr [rip+oracle_M]
    call bi_clone
    mov r14,rax
    mov rbx,1
.Locrw_power:
    mov rdi,r14
    mov rsi,r13
    call bi_cmp
    test eax,eax
    jge .Locrw_power_done
    mov rdi,r14
    mov rsi,qword ptr [rip+oracle_M]
    call bi_mul_abs
    mov r14,rax
    inc rbx
    jmp .Locrw_power
.Locrw_power_done:
    mov qword ptr [rbp-48],r14
    mov rdi,1
    call bi_from_u64
    mov r14,rax
    mov rdi,1
    call bi_from_u64
    mov r15,rax
    mov rdi,qword ptr [r12+STREAM_FIRST]
    call bi_clone
    mov qword ptr [rbp-56],rax
    xor ecx,ecx
.Locrw_digits:
    cmp rcx,rbx
    jae .Locrw_digits_done
    push rcx
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [rip+oracle_ONE]
    call bi_sub
    mov rdi,rax
    mov rsi,r15
    call bi_mul_abs
    mov rdi,r14
    mov rsi,rax
    call bi_add_abs
    mov r14,rax
    mov rdi,r15
    mov rsi,qword ptr [rip+oracle_M]
    call bi_mul_abs
    mov r15,rax
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [r12+STREAM_STEP]
    mov rdx,qword ptr [rip+oracle_M]
    call oracle_ring_step_bound
    mov qword ptr [rbp-56],rax
    pop rcx
    inc rcx
    jmp .Locrw_digits
.Locrw_digits_done:
    mov rdi,qword ptr [rbp-48]
    mov rsi,r13
    call bi_divmod_abs
    mov rdi,rax
    mov rsi,r13
    call bi_mul_abs
    mov r15,rax
.Locrw_reject:
    mov rdi,r14
    mov rsi,r15
    call bi_cmp
    test eax,eax
    jle .Locrw_accept
    mov rdi,r14
    mov rsi,qword ptr [r12+STREAM_STEP]
    mov rdx,qword ptr [rbp-48]
    call oracle_ring_step_bound
    mov r14,rax
    jmp .Locrw_reject
.Locrw_accept:
    mov rdi,r14
    mov rsi,qword ptr [rip+oracle_ONE]
    call bi_sub
    mov rdi,rax
    mov rsi,r13
    call oracle_regular_mod
    mov rdi,rax
    mov rsi,1
    call bi_add_u64
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_choose_rank_wide,.-oracle_choose_rank_wide

.type oracle_choose_rank,@function
oracle_choose_rank:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call oracle_init
    mov rdi,r13
    mov rsi,qword ptr [rip+oracle_M]
    call bi_cmp
    test eax,eax
    jg .Locr_wide
    mov rdi,r12
    mov rsi,r13
    call oracle_choose_rank_short
    jmp .Locr_done
.Locr_wide:
    mov rdi,r12
    mov rsi,r13
    call oracle_choose_rank_wide
.Locr_done:
    pop r13
    pop r12
    leave
    ret
.size oracle_choose_rank,.-oracle_choose_rank

.section .bss
.align 8
.global oracle_STONES
oracle_STONES: .quad 0

.section .rodata
.align 8
hidden_coeff:
.quad 3,4,6,8
.quad 5,7,10,12
.quad 7,10,14,16
.quad 9,13,18,20
.quad 11,16,22,24
.quad 13,19,26,28
.quad 15,22,30,32
hidden_stone_kind: .quad 1,2,3,4,5,1,2
visible_grinds:
.quad 3,5,7,11,1
.quad 5,7,11,13,2
.quad 7,11,13,17,3
.quad 11,13,17,19,4
.quad 13,17,19,23,5
.quad 17,19,23,29,1
.quad 19,23,29,31,2
.quad 23,29,31,37,3
.quad 29,31,37,41,4
.quad 31,37,41,43,5
.quad 37,41,43,47,1
bowl_prime: .quad 17,19,23,29,31,37
bowl_stone_by_position: .quad 1,2,3,4,5,1

.section .text
.global oracle_build_stones
.global oracle_build_hidden
.global oracle_build_visible
.global oracle_initial_bowls
.global oracle_apply_drops_to_bowls
.global oracle_post_stir12
.global oracle_sauce
.global oracle_ask_bowl

.type oracle_square,@function
oracle_square:
    mov rsi,rdi
    jmp bi_mul_abs
.size oracle_square,.-oracle_square

.type oracle_add_scaled,@function
oracle_add_scaled:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,r13
    mov rsi,rdx
    call bi_mul_u64
    mov rsi,rax
    mov rdi,r12
    call bi_add_abs
    pop r13
    pop r12
    leave
    ret
.size oracle_add_scaled,.-oracle_add_scaled

.type oracle_add_product_scaled,@function
oracle_add_product_scaled:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rcx
    mov rdi,rsi
    mov rsi,rdx
    call bi_mul_abs
    cmp r13,1
    je .Loaps_add
    mov rdi,rax
    mov rsi,r13
    call bi_mul_u64
.Loaps_add:
    mov rsi,rax
    mov rdi,r12
    call bi_add_abs
    pop r14
    pop r13
    pop r12
    leave
    ret
.size oracle_add_product_scaled,.-oracle_add_product_scaled

.type oracle_build_stones,@function
oracle_build_stones:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    cmp qword ptr [rip+oracle_STONES],0
    jne .Lobs_cached
    call oracle_init
    mov rdi,1840
    call arena_alloc
    mov r12,rax
    mov qword ptr [rip+oracle_STONES],r12
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
.Lobs_row:
    cmp r13,46
    ja .Lobs_done
    mov rax,r13
    sub rax,2
    imul rax,40
    lea r14,[r12+rax]
    mov rax,r13
    dec rax
    imul rax,40
    lea r15,[r12+rax]

    mov rdi,qword ptr [r14]
    call oracle_square
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [r14+8]
    mov rdx,3
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [r15],rax

    mov rdi,qword ptr [r14+8]
    call oracle_square
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [r14+16]
    mov rdx,5
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,qword ptr [r14]
    call bi_add_abs
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [r15+8],rax

    mov rdi,qword ptr [r14+16]
    call oracle_square
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [r14+24]
    mov rdx,7
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,qword ptr [r14+8]
    call bi_add_abs
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [r15+16],rax

    mov rdi,qword ptr [r14+24]
    call oracle_square
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [r14+32]
    mov rdx,11
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,qword ptr [r14+16]
    call bi_add_abs
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [r15+24],rax

    mov rdi,qword ptr [r14+32]
    call oracle_square
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [r14]
    mov rdx,13
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,qword ptr [r14+24]
    call bi_add_abs
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [r15+32],rax

    inc r13
    jmp .Lobs_row
.Lobs_done:
    mov rax,r12
    jmp .Lobs_exit
.Lobs_cached:
    mov rax,qword ptr [rip+oracle_STONES]
.Lobs_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_build_stones,.-oracle_build_stones

.type oracle_build_hidden,@function
oracle_build_hidden:
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
    mov rdi,56
    call arena_alloc
    mov qword ptr [rbp-48],rax
    mov r14,1
.Lobh_k:
    cmp r14,7
    ja .Lobh_done
    mov rdi,qword ptr [r12+COUNTS_ACTION]
    call bi_clone
    mov r15,rax
    mov rax,r14
    dec rax
    imul rax,32
    lea rbx,[rip+hidden_coeff]
    add rbx,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_TARGET]
    mov rdx,qword ptr [rbx]
    call oracle_add_scaled
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_DISTANCE]
    mov rdx,qword ptr [rbx+8]
    call oracle_add_scaled
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_CONNECTION]
    mov rdx,qword ptr [rbx+16]
    call oracle_add_scaled
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_DIRECTION]
    mov rdx,qword ptr [rbx+24]
    call oracle_add_scaled
    mov r15,rax
    mov rax,r14
    dec rax
    imul rax,40
    lea rbx,[r13+rax]
    xor ecx,ecx
.Lobh_stone_sum:
    cmp rcx,5
    jae .Lobh_first_save
    push rcx
    mov rdi,r15
    mov rsi,qword ptr [rbx+rcx*8]
    call bi_add_abs
    mov r15,rax
    pop rcx
    inc rcx
    jmp .Lobh_stone_sum
.Lobh_first_save:
    mov rdi,r15
    call oracle_SAVE
    mov r15,rax
    mov qword ptr [rbp-56],rbx
    mov rbx,1
.Lobh_grind:
    cmp rbx,7
    ja .Lobh_store
    mov rdi,r15
    call oracle_square
    mov qword ptr [rbp-64],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,r15
    mov rdx,3
    call oracle_add_scaled
    mov r15,rax
    lea r8,[rip+hidden_stone_kind]
    mov rax,qword ptr [r8+rbx*8-8]
    dec rax
    mov r8,qword ptr [rbp-56]
    mov rdi,r15
    mov rsi,qword ptr [r8+rax*8]
    call bi_add_abs
    mov rdi,rax
    mov rsi,rbx
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov r15,rax
    inc rbx
    jmp .Lobh_grind
.Lobh_store:
    mov r8,qword ptr [rbp-48]
    mov qword ptr [r8+r14*8-8],r15
    inc r14
    jmp .Lobh_k
.Lobh_done:
    mov rax,qword ptr [rbp-48]
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_build_hidden,.-oracle_build_hidden

.type oracle_build_visible,@function
oracle_build_visible:
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
    mov qword ptr [rbp-48],rdx
    mov rdi,424
    call arena_alloc
    mov r15,rax
    mov rdi,r15
    xor eax,eax
    mov rcx,53
    rep stosq
    mov r8,qword ptr [rbp-48]
    mov rcx,1
.Lobv_seed:
    cmp rcx,7
    ja .Lobv_start
    mov rax,7
    sub rax,rcx
    mov rdx,qword ptr [r8+rcx*8-8]
    mov qword ptr [r15+rax*8],rdx
    inc rcx
    jmp .Lobv_seed
.Lobv_start:
    mov r14,1
.Lobv_drop:
    cmp r14,46
    ja .Lobv_done
    mov rax,r14
    add rax,5
    mov r8,qword ptr [r15+rax*8]
    mov qword ptr [rbp-56],r8
    mov rax,r14
    add rax,3
    mov r8,qword ptr [r15+rax*8]
    mov qword ptr [rbp-64],r8
    mov rax,r14
    dec rax
    mov r8,qword ptr [r15+rax*8]
    mov qword ptr [rbp-72],r8
    mov rax,r14
    dec rax
    imul rax,40
    lea r8,[r13+rax]
    mov qword ptr [rbp-80],r8

    mov rdi,qword ptr [rip+oracle_ZERO]
    call bi_clone
    mov rbx,rax
    mov r8,qword ptr [rbp-80]
    mov rdi,rbx
    mov rsi,qword ptr [r8]
    mov rdx,qword ptr [r12+COUNTS_ACTION]
    mov rcx,1
    call oracle_add_product_scaled
    mov rbx,rax
    mov r8,qword ptr [rbp-80]
    mov rdi,rbx
    mov rsi,qword ptr [r8+8]
    mov rdx,qword ptr [r12+COUNTS_TARGET]
    mov rcx,1
    call oracle_add_product_scaled
    mov rbx,rax
    mov r8,qword ptr [rbp-80]
    mov rdi,rbx
    mov rsi,qword ptr [r8+16]
    mov rdx,qword ptr [r12+COUNTS_DISTANCE]
    mov rcx,1
    call oracle_add_product_scaled
    mov rbx,rax
    mov r8,qword ptr [rbp-80]
    mov rdi,rbx
    mov rsi,qword ptr [r8+24]
    mov rdx,qword ptr [r12+COUNTS_CONNECTION]
    mov rcx,1
    call oracle_add_product_scaled
    mov rbx,rax
    mov r8,qword ptr [rbp-80]
    mov rdi,rbx
    mov rsi,qword ptr [r8+32]
    mov rdx,qword ptr [r12+COUNTS_DIRECTION]
    mov rcx,1
    call oracle_add_product_scaled
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [rbp-56]
    call bi_add_abs
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [rbp-64]
    mov rdx,3
    call oracle_add_scaled
    mov rbx,rax
    mov rdi,rbx
    mov rsi,qword ptr [rbp-72]
    mov rdx,5
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov rbx,rax

    mov qword ptr [rbp-88],r14
    xor r14d,r14d
.Lobv_grind:
    cmp r14,11
    jae .Lobv_grind_done
    lea r8,[rip+visible_grinds]
    mov rax,r14
    imul rax,40
    add r8,rax
    mov qword ptr [rbp-96],r8
    mov rdi,rbx
    call oracle_square
    mov r9,rax
    mov r8,qword ptr [rbp-96]
    mov rdi,r9
    mov rsi,rbx
    mov rdx,qword ptr [r8]
    call oracle_add_scaled
    mov r9,rax
    mov r8,qword ptr [rbp-96]
    mov rdi,r9
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [r8+8]
    call oracle_add_scaled
    mov r9,rax
    mov r8,qword ptr [rbp-96]
    mov rdi,r9
    mov rsi,qword ptr [rbp-64]
    mov rdx,qword ptr [r8+16]
    call oracle_add_scaled
    mov r9,rax
    mov r8,qword ptr [rbp-96]
    mov rdi,r9
    mov rsi,qword ptr [rbp-72]
    mov rdx,qword ptr [r8+24]
    call oracle_add_scaled
    mov r9,rax
    mov r8,qword ptr [rbp-96]
    mov rax,qword ptr [r8+32]
    dec rax
    mov r8,qword ptr [rbp-80]
    mov rdi,r9
    mov rsi,qword ptr [r8+rax*8]
    call bi_add_abs
    mov rdi,rax
    call oracle_SAVE
    mov rbx,rax
    inc r14
    jmp .Lobv_grind
.Lobv_grind_done:
    mov r14,qword ptr [rbp-88]
    mov rax,r14
    add rax,6
    mov qword ptr [r15+rax*8],rbx
    inc r14
    jmp .Lobv_drop
.Lobv_done:
    lea rax,[r15+56]
    add rsp,64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_build_visible,.-oracle_build_visible

.type oracle_initial_bowls,@function
oracle_initial_bowls:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov rdi,48
    call arena_alloc
    mov r13,rax
    mov r14,1
.Loib_loop:
    cmp r14,6
    ja .Loib_done
    mov rdi,qword ptr [r12+COUNTS_ACTION]
    call bi_clone
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_TARGET]
    mov rdx,r14
    call oracle_add_scaled
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_DISTANCE]
    call bi_add_abs
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_CONNECTION]
    call bi_add_abs
    mov r15,rax
    mov rdi,r15
    mov rsi,qword ptr [r12+COUNTS_DIRECTION]
    call bi_add_abs
    mov r15,rax
    lea r8,[rip+bowl_prime]
    mov rax,qword ptr [r8+r14*8-8]
    imul rax,rax
    mov rdi,r15
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    call oracle_square
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [r13+r14*8-8],rax
    inc r14
    jmp .Loib_loop
.Loib_done:
    mov rax,r13
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_initial_bowls,.-oracle_initial_bowls

.type oracle_apply_drops_to_bowls,@function
oracle_apply_drops_to_bowls:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,272
    mov r12,rdi
    mov r13,rsi
    mov qword ptr [rbp-248],rdx
    mov qword ptr [rbp-256],rcx
    lea r15,[rbp-96]
    mov r14,1
.Loadb_drop:
    cmp r14,46
    ja .Loadb_done
    mov rax,qword ptr [r13+r14*8-8]
    mov qword ptr [rbp-264],rax
    mov rdi,rax
    mov rsi,r15
    call oracle_bowl_order_from_value
    xor ecx,ecx
.Loadb_copy_old:
    cmp rcx,6
    jae .Loadb_pours
    mov rax,qword ptr [r12+rcx*8]
    mov qword ptr [rbp-144+rcx*8],rax
    inc rcx
    jmp .Loadb_copy_old
.Loadb_pours:
    mov rax,r14
    dec rax
    imul rax,40
    mov r8,qword ptr [rbp-248]
    add r8,rax
    mov qword ptr [rbp-272],r8
    xor ebx,ebx
.Loadb_pour_loop:
    cmp rbx,3
    jae .Loadb_zero_pours
    mov rdi,qword ptr [rbp-264]
    call oracle_square
    mov r9,rax
    mov rax,qword ptr [r15+rbx*8]
    dec rax
    mov r10,qword ptr [rbp-144+rax*8]
    mov r8,qword ptr [rbp-272]
    mov r11,qword ptr [r8+rbx*8]
    mov rdi,r9
    mov rsi,r11
    mov rdx,r10
    mov rcx,1
    call oracle_add_product_scaled
    mov r9,rax
    mov rax,rbx
    cmp rax,0
    jne .Loadb_pour_not1
    mov rax,3
    jmp .Loadb_pour_const
.Loadb_pour_not1:
    cmp rax,1
    jne .Loadb_pour3
    mov rax,5
    jmp .Loadb_pour_const
.Loadb_pour3:
    mov rax,7
.Loadb_pour_const:
    imul rax,r14
    mov rdi,r9
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [rbp-192+rbx*8],rax
    inc rbx
    jmp .Loadb_pour_loop
.Loadb_zero_pours:
    mov rax,qword ptr [rip+oracle_ZERO]
    mov qword ptr [rbp-168],rax
    mov qword ptr [rbp-160],rax
    mov qword ptr [rbp-152],rax
    xor ebx,ebx
.Loadb_stir_loop:
    cmp rbx,6
    jae .Loadb_commit
    mov rax,qword ptr [r15+rbx*8]
    mov qword ptr [rbp-280],rax
    mov rcx,rbx
    test rcx,rcx
    jne .Loadb_prev_normal
    mov rcx,5
    jmp .Loadb_prev_ready
.Loadb_prev_normal:
    dec rcx
.Loadb_prev_ready:
    mov rax,qword ptr [r15+rcx*8]
    mov qword ptr [rbp-288],rax
    mov rcx,rbx
    cmp rcx,5
    jne .Loadb_next_normal
    xor ecx,ecx
    jmp .Loadb_next_ready
.Loadb_next_normal:
    inc rcx
.Loadb_next_ready:
    mov rax,qword ptr [r15+rcx*8]
    mov qword ptr [rbp-296],rax
    mov rax,qword ptr [rbp-280]
    dec rax
    mov rdi,qword ptr [rbp-144+rax*8]
    call bi_clone
    mov r9,rax
    mov rax,qword ptr [rbp-288]
    dec rax
    mov r10,qword ptr [rbp-144+rax*8]
    mov qword ptr [rbp-304],r10
    mov rdi,r9
    mov rsi,qword ptr [rbp-304]
    mov rdx,2
    call oracle_add_scaled
    mov r9,rax
    mov rax,qword ptr [rbp-296]
    dec rax
    mov r11,qword ptr [rbp-144+rax*8]
    mov qword ptr [rbp-312],r11
    mov rdi,r9
    mov rsi,r11
    mov rdx,3
    call oracle_add_scaled
    mov r9,rax
    mov rdi,r9
    mov rsi,qword ptr [rbp-192+rbx*8]
    call bi_add_abs
    mov r9,rax
    mov rdi,r9
    mov rsi,qword ptr [rbp-264]
    call bi_add_abs
    mov r9,rax
    lea r8,[rip+bowl_stone_by_position]
    mov rax,qword ptr [r8+rbx*8]
    dec rax
    mov r8,qword ptr [rbp-272]
    mov rdi,r9
    mov rsi,qword ptr [r8+rax*8]
    call bi_add_abs
    mov rdi,rax
    call oracle_square
    mov r9,rax
    mov rdi,r9
    mov rsi,qword ptr [rbp-304]
    mov rdx,qword ptr [rbp-312]
    mov rcx,5
    call oracle_add_product_scaled
    mov r9,rax
    mov rax,rbx
    inc rax
    imul rax,r14
    mov rdi,r9
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov rdx,qword ptr [rbp-280]
    dec rdx
    mov qword ptr [rbp-240+rdx*8],rax
    inc rbx
    jmp .Loadb_stir_loop
.Loadb_commit:
    xor ecx,ecx
.Loadb_commit_loop:
    cmp rcx,6
    jae .Loadb_latch
    mov rax,qword ptr [rbp-240+rcx*8]
    mov qword ptr [r12+rcx*8],rax
    inc rcx
    jmp .Loadb_commit_loop
.Loadb_latch:
    cmp r14,46
    jne .Loadb_next_drop
    mov r8,qword ptr [rbp-256]
    xor ecx,ecx
.Loadb_latch_loop:
    cmp rcx,6
    jae .Loadb_next_drop
    mov rax,qword ptr [r15+rcx*8]
    mov qword ptr [r8+rcx*8],rax
    inc rcx
    jmp .Loadb_latch_loop
.Loadb_next_drop:
    inc r14
    jmp .Loadb_drop
.Loadb_done:
    mov rax,r12
    add rsp,272
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_apply_drops_to_bowls,.-oracle_apply_drops_to_bowls

.type oracle_post_stir12,@function
oracle_post_stir12:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,208
    mov r12,rdi
    mov r13,1
    lea r15,[rbp-96]
.Lops_stir:
    cmp r13,12
    ja .Lops_done
    xor ecx,ecx
.Lops_copy_old:
    cmp rcx,6
    jae .Lops_sum
    mov rax,qword ptr [r12+rcx*8]
    mov qword ptr [rbp-144+rcx*8],rax
    inc rcx
    jmp .Lops_copy_old
.Lops_sum:
    mov rdi,qword ptr [rip+oracle_ZERO]
    call bi_clone
    mov r14,rax
    xor ebx,ebx
.Lops_sum_loop:
    cmp rbx,6
    jae .Lops_sum_saved
    mov rdi,r14
    mov rsi,qword ptr [rbp-144+rbx*8]
    call bi_add_abs
    mov r14,rax
    inc rbx
    jmp .Lops_sum_loop
.Lops_sum_saved:
    mov rax,r13
    imul rax,149
    mov rdi,r14
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov r14,rax
    mov qword ptr [rbp-200],r14
    mov rdi,r14
    mov rsi,r15
    call oracle_bowl_order_from_value
    xor ebx,ebx
.Lops_bowl:
    cmp rbx,6
    jae .Lops_commit
    mov rax,qword ptr [r15+rbx*8]
    mov qword ptr [rbp-208],rax
    mov rcx,rbx
    test rcx,rcx
    jne .Lops_prev_normal
    mov rcx,5
    jmp .Lops_prev_ready
.Lops_prev_normal:
    dec rcx
.Lops_prev_ready:
    mov rax,qword ptr [r15+rcx*8]
    mov qword ptr [rbp-216],rax
    mov rcx,rbx
    cmp rcx,5
    jne .Lops_next_normal
    xor ecx,ecx
    jmp .Lops_next_ready
.Lops_next_normal:
    inc rcx
.Lops_next_ready:
    mov rax,qword ptr [r15+rcx*8]
    mov qword ptr [rbp-224],rax
    mov rax,qword ptr [rbp-208]
    dec rax
    mov rdi,qword ptr [rbp-144+rax*8]
    call bi_clone
    mov r14,rax
    mov rax,qword ptr [rbp-216]
    dec rax
    mov r10,qword ptr [rbp-144+rax*8]
    mov qword ptr [rbp-232],r10
    mov rdi,r14
    mov rsi,r10
    mov rdx,3
    call oracle_add_scaled
    mov r14,rax
    mov rax,qword ptr [rbp-224]
    dec rax
    mov r11,qword ptr [rbp-144+rax*8]
    mov qword ptr [rbp-240],r11
    mov rdi,r14
    mov rsi,r11
    mov rdx,5
    call oracle_add_scaled
    mov r14,rax
    mov rdi,r14
    mov rsi,qword ptr [rbp-200]
    call bi_add_abs
    mov r14,rax
    mov rdi,r14
    mov rsi,r13
    call bi_add_u64
    mov r14,rax
    mov rax,rbx
    inc rax
    imul rax,rax
    mov rdi,r14
    mov rsi,rax
    call bi_add_u64
    mov rdi,rax
    call oracle_square
    mov r14,rax
    mov rdi,r14
    mov rsi,qword ptr [rbp-232]
    mov rdx,qword ptr [rbp-240]
    mov rcx,7
    call oracle_add_product_scaled
    mov rdi,rax
    call oracle_SAVE
    mov rdx,qword ptr [rbp-208]
    dec rdx
    mov qword ptr [rbp-192+rdx*8],rax
    inc rbx
    jmp .Lops_bowl
.Lops_commit:
    xor ecx,ecx
.Lops_commit_loop:
    cmp rcx,6
    jae .Lops_next_stir
    mov rax,qword ptr [rbp-192+rcx*8]
    mov qword ptr [r12+rcx*8],rax
    inc rcx
    jmp .Lops_commit_loop
.Lops_next_stir:
    inc r13
    jmp .Lops_stir
.Lops_done:
    mov rax,r12
    add rsp,208
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_post_stir12,.-oracle_post_stir12

.type oracle_sauce,@function
oracle_sauce:
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
    mov rdi,r12
    mov rsi,r13
    call oracle_work_counts
    mov qword ptr [rbp-48],rax
    call oracle_build_stones
    mov qword ptr [rbp-56],rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    call oracle_build_hidden
    mov qword ptr [rbp-64],rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [rbp-56]
    mov rdx,qword ptr [rbp-64]
    call oracle_build_visible
    mov qword ptr [rbp-72],rax
    mov rdi,qword ptr [rbp-48]
    call oracle_initial_bowls
    mov qword ptr [rbp-80],rax
    mov rdi,48
    call arena_alloc
    mov qword ptr [rbp-88],rax
    mov rdi,qword ptr [rbp-80]
    mov rsi,qword ptr [rbp-72]
    mov rdx,qword ptr [rbp-56]
    mov rcx,qword ptr [rbp-88]
    call oracle_apply_drops_to_bowls
    mov rdi,rax
    call oracle_post_stir12
    mov qword ptr [rbp-80],rax
    mov rdi,96
    call arena_alloc
    mov r14,rax
    xor ebx,ebx
.Los_copy_bowls:
    cmp rbx,6
    jae .Los_copy_order
    mov r15,qword ptr [rbp-80]
    mov rax,qword ptr [r15+rbx*8]
    mov qword ptr [r14+rbx*8],rax
    inc rbx
    jmp .Los_copy_bowls
.Los_copy_order:
    xor ebx,ebx
.Los_copy_order_loop:
    cmp rbx,6
    jae .Los_done
    mov r15,qword ptr [rbp-88]
    mov rax,qword ptr [r15+rbx*8]
    mov qword ptr [r14+48+rbx*8],rax
    inc rbx
    jmp .Los_copy_order_loop
.Los_done:
    mov rax,r14
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_sauce,.-oracle_sauce

.type oracle_ask_bowl,@function
oracle_ask_bowl:
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
    xor ebx,ebx
.Loab_find:
    cmp rbx,6
    jae .Loab_fail
    cmp qword ptr [r12+48+rbx*8],r13
    je .Loab_found
    inc rbx
    jmp .Loab_find
.Loab_found:
    mov rax,rbx
    inc rax
    cmp rax,6
    jb .Loab_next_ready
    xor eax,eax
.Loab_next_ready:
    mov r15,qword ptr [r12+48+rax*8]
    mov rax,r13
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov rsi,r14
    add rsi,181
    call bi_add_u64
    mov rdi,rax
    call oracle_square
    mov qword ptr [rbp-48],rax
    mov rax,r15
    dec rax
    mov rdi,qword ptr [rbp-48]
    mov rsi,qword ptr [r12+rax*8]
    mov rdx,179
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,r14
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov qword ptr [rbp-56],rax
    mov rdi,qword ptr [rbp-56]
    mov rsi,r14
    add rsi,194
    call bi_add_u64
    mov rdi,rax
    call oracle_square
    mov qword ptr [rbp-64],rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,qword ptr [rbp-56]
    mov rdx,193
    call oracle_add_scaled
    mov rdi,rax
    mov rsi,qword ptr [r12+40]
    mov rdx,197
    call oracle_add_scaled
    mov rdi,rax
    call oracle_SAVE
    mov r15,rax
    mov rdi,2
    call bi_from_u64
    mov rsi,rax
    mov rdi,r15
    call bi_mod_abs
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    jne .Loab_positive
    mov r15,-1
    jmp .Loab_stream
.Loab_positive:
    mov r15,1
.Loab_stream:
    mov rdi,STREAM_SIZE
    call arena_alloc
    mov rbx,rax
    mov rax,qword ptr [rbp-56]
    mov qword ptr [rbx+STREAM_FIRST],rax
    mov qword ptr [rbx+STREAM_STEP],r15
    mov rax,rbx
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Loab_fail:
    mov rax,60
    mov rdi,122
    syscall
.size oracle_ask_bowl,.-oracle_ask_bowl
