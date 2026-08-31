.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_CAP,16
.equ BI_DATA,24
.equ BI_HEADER,32

.section .text
.extern arena_alloc
.global bi_new
.global bi_reserve
.global bi_zero
.global bi_from_u64
.global bi_from_i64
.global bi_clone
.global bi_normalize
.global bi_cmp_abs
.global bi_cmp
.global bi_add_abs
.global bi_sub_abs
.global bi_sub_abs_inplace
.global bi_add
.global bi_neg
.global bi_sub
.global bi_mul_abs
.global bi_mul
.global bi_mul_u64
.global bi_add_u64
.global bi_shl1_inplace
.global bi_shr1_inplace
.global bi_bit_length
.global bi_set_bit_inplace
.global bi_divmod_abs
.global bi_divmod_u64_abs
.global bi_mod_abs
.global bi_eq_u64
.global bi_is_zero
.global bi_abs

.type bi_new,@function
bi_new:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    mov r12, rdi
    test r12, r12
    jne .Lbn_cap_ok
    mov r12, 1
.Lbn_cap_ok:
    mov rax, r12
    shl rax, 3
    add rax, BI_HEADER
    mov rdi, rax
    call arena_alloc
    mov rbx, rax
    mov qword ptr [rbx+BI_SIGN], 0
    mov qword ptr [rbx+BI_LEN], 0
    mov qword ptr [rbx+BI_CAP], r12
    lea rdx, [rbx+BI_HEADER]
    mov qword ptr [rbx+BI_DATA], rdx
    xor rax, rax
    mov rcx, r12
    mov rdi, rdx
    rep stosq
    mov rax, rbx
    pop r12
    pop rbx
    leave
    ret
.size bi_new,.-bi_new

.type bi_reserve,@function
bi_reserve:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    mov rbx, rdi
    mov r12, rsi
    mov r13, qword ptr [rbx+BI_CAP]
    cmp r13, r12
    jae .Lbires_done
    test r13, r13
    jne .Lbires_grow
    mov r13, 1
.Lbires_grow:
    cmp r13, r12
    jae .Lbires_allocate
    shl r13, 1
    jc .Lbires_soft_fail
    jmp .Lbires_grow
.Lbires_allocate:
    mov rdi, r13
    shl rdi, 3
    jc .Lbires_soft_fail
    call arena_alloc
    mov r14, rax
    mov rdi, r14
    xor eax, eax
    mov rcx, r13
    rep stosq
    mov rcx, qword ptr [rbx+BI_LEN]
    test rcx, rcx
    je .Lbires_publish
    mov rsi, qword ptr [rbx+BI_DATA]
    mov rdi, r14
    rep movsq
.Lbires_publish:
    mov qword ptr [rbx+BI_DATA], r14
    mov qword ptr [rbx+BI_CAP], r13
.Lbires_done:
    mov rax, rbx
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lbires_soft_fail:
    # Ⲡsoft-failure detour ⲙⲡreserve ⲕⲧⲟ ⲛNULL ⲉⲙⲛ sys_exit.
    xor eax,eax
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Lbires_fail:
    # Ⲡlegacy abort scar ⲙⲡreserve.
    mov rax, 60
    mov rdi, 103
    syscall
.size bi_reserve,.-bi_reserve

.type bi_zero,@function
bi_zero:
    mov rdi, 1
    jmp bi_new
.size bi_zero,.-bi_zero

.type bi_from_u64,@function
bi_from_u64:
    push rbp
    mov rbp, rsp
    push rbx
    mov rbx, rdi
    mov rdi, 1
    call bi_new
    test rbx, rbx
    je .Lbfu_done
    mov qword ptr [rax+BI_SIGN], 1
    mov qword ptr [rax+BI_LEN], 1
    mov rcx, qword ptr [rax+BI_DATA]
    mov qword ptr [rcx], rbx
.Lbfu_done:
    pop rbx
    leave
    ret
.size bi_from_u64,.-bi_from_u64

.type bi_from_i64,@function
bi_from_i64:
    push rbp
    mov rbp, rsp
    push rbx
    mov rbx, rdi
    test rbx, rbx
    jge .Lbfi_nonneg
    neg rdi
    call bi_from_u64
    mov qword ptr [rax+BI_SIGN], -1
    jmp .Lbfi_done
.Lbfi_nonneg:
    call bi_from_u64
.Lbfi_done:
    pop rbx
    leave
    ret
.size bi_from_i64,.-bi_from_i64

.type bi_clone,@function
bi_clone:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    mov rbx, rdi
    mov r12, qword ptr [rbx+BI_LEN]
    mov rdi, r12
    test rdi, rdi
    jne .Lbc_cap
    mov rdi, 1
.Lbc_cap:
    call bi_new
    mov rdx, qword ptr [rbx+BI_SIGN]
    mov qword ptr [rax+BI_SIGN], rdx
    mov qword ptr [rax+BI_LEN], r12
    test r12, r12
    je .Lbc_done
    mov rsi, qword ptr [rbx+BI_DATA]
    mov rdi, qword ptr [rax+BI_DATA]
    mov rcx, r12
    push rax
    rep movsq
    pop rax
.Lbc_done:
    pop r12
    pop rbx
    leave
    ret
.size bi_clone,.-bi_clone

.type bi_normalize,@function
bi_normalize:
    mov rcx, qword ptr [rdi+BI_LEN]
    test rcx, rcx
    je .Lbnorm_zero
    mov rdx, qword ptr [rdi+BI_DATA]
.Lbnorm_loop:
    test rcx, rcx
    je .Lbnorm_zero
    mov rax, qword ptr [rdx+rcx*8-8]
    test rax, rax
    jne .Lbnorm_set
    dec rcx
    jmp .Lbnorm_loop
.Lbnorm_set:
    mov qword ptr [rdi+BI_LEN], rcx
    cmp qword ptr [rdi+BI_SIGN], 0
    jne .Lbnorm_ret
    mov qword ptr [rdi+BI_SIGN], 1
.Lbnorm_ret:
    mov rax, rdi
    ret
.Lbnorm_zero:
    mov qword ptr [rdi+BI_LEN], 0
    mov qword ptr [rdi+BI_SIGN], 0
    mov rax, rdi
    ret
.size bi_normalize,.-bi_normalize

.type bi_is_zero,@function
bi_is_zero:
    xor eax, eax
    cmp qword ptr [rdi+BI_LEN], 0
    sete al
    ret
.size bi_is_zero,.-bi_is_zero

.type bi_abs,@function
bi_abs:
    push rbp
    mov rbp, rsp
    call bi_clone
    cmp qword ptr [rax+BI_LEN], 0
    je .Lbiabs_done
    mov qword ptr [rax+BI_SIGN], 1
.Lbiabs_done:
    leave
    ret
.size bi_abs,.-bi_abs

.type bi_cmp_abs,@function
bi_cmp_abs:
    mov rax, qword ptr [rdi+BI_LEN]
    mov rcx, qword ptr [rsi+BI_LEN]
    cmp rax, rcx
    ja .Lbca_gt
    jb .Lbca_lt
    test rax, rax
    je .Lbca_eq
    mov r8, qword ptr [rdi+BI_DATA]
    mov r9, qword ptr [rsi+BI_DATA]
    mov rcx, rax
.Lbca_loop:
    mov rdx, qword ptr [r8+rcx*8-8]
    mov rax, qword ptr [r9+rcx*8-8]
    cmp rdx, rax
    ja .Lbca_gt
    jb .Lbca_lt
    dec rcx
    jne .Lbca_loop
.Lbca_eq:
    xor eax, eax
    ret
.Lbca_gt:
    mov eax, 1
    ret
.Lbca_lt:
    mov eax, -1
    ret
.size bi_cmp_abs,.-bi_cmp_abs

.type bi_cmp,@function
bi_cmp:
    mov rax, qword ptr [rdi+BI_SIGN]
    mov rcx, qword ptr [rsi+BI_SIGN]
    cmp rax, rcx
    jg .Lbcmp_gt
    jl .Lbcmp_lt
    test rax, rax
    je .Lbcmp_eq
    push rax
    call bi_cmp_abs
    pop rcx
    cmp rcx, 0
    jg .Lbcmp_ret
    neg eax
.Lbcmp_ret:
    ret
.Lbcmp_eq:
    xor eax, eax
    ret
.Lbcmp_gt:
    mov eax, 1
    ret
.Lbcmp_lt:
    mov eax, -1
    ret
.size bi_cmp,.-bi_cmp

.type bi_add_abs,@function
bi_add_abs:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, qword ptr [r12+BI_LEN]
    mov r15, qword ptr [r13+BI_LEN]
    mov rbx, r14
    cmp r15, rbx
    cmova rbx, r15
    lea rdi, [rbx+1]
    call bi_new
    mov r10, rax
    mov r8, qword ptr [r12+BI_DATA]
    mov r9, qword ptr [r13+BI_DATA]
    mov r11, qword ptr [r10+BI_DATA]
    xor ecx, ecx
    xor esi, esi
.Lbaa_loop:
    cmp rcx, rbx
    jae .Lbaa_carry
    xor eax, eax
    xor edx, edx
    cmp rcx, r14
    jae .Lbaa_no_a
    mov rax, qword ptr [r8+rcx*8]
.Lbaa_no_a:
    cmp rcx, r15
    jae .Lbaa_no_b
    mov rdx, qword ptr [r9+rcx*8]
.Lbaa_no_b:
    xor edi, edi
    add rax, rdx
    adc rdi, 0
    add rax, rsi
    adc rdi, 0
    mov qword ptr [r11+rcx*8], rax
    mov rsi, rdi
    inc rcx
    jmp .Lbaa_loop
.Lbaa_carry:
    mov qword ptr [r11+rbx*8], rsi
    add rbx, rsi
    mov qword ptr [r10+BI_LEN], rbx
    test rbx, rbx
    je .Lbaa_zero
    mov qword ptr [r10+BI_SIGN], 1
.Lbaa_zero:
    mov rax, r10
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size bi_add_abs,.-bi_add_abs

.type bi_sub_abs,@function
bi_sub_abs:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, qword ptr [r12+BI_LEN]
    mov rdi, r14
    test rdi, rdi
    jne .Lbsa_cap
    mov rdi, 1
.Lbsa_cap:
    call bi_new
    mov rbx, rax
    mov r8, qword ptr [r12+BI_DATA]
    mov r9, qword ptr [r13+BI_DATA]
    mov r10, qword ptr [rbx+BI_DATA]
    mov r11, qword ptr [r13+BI_LEN]
    xor ecx, ecx
    xor r15d, r15d
.Lbsa_loop:
    cmp rcx, r14
    jae .Lbsa_done_loop
    mov rax, qword ptr [r8+rcx*8]
    xor edx, edx
    cmp rcx, r11
    jae .Lbsa_no_b
    mov rdx, qword ptr [r9+rcx*8]
.Lbsa_no_b:
    mov rsi, r15
    sub rax, rdx
    sbb r15, r15
    and r15, 1
    sub rax, rsi
    sbb rdi, rdi
    and rdi, 1
    or r15, rdi
    mov qword ptr [r10+rcx*8], rax
    inc rcx
    jmp .Lbsa_loop
.Lbsa_done_loop:
    mov qword ptr [rbx+BI_LEN], r14
    mov qword ptr [rbx+BI_SIGN], 1
    mov rdi, rbx
    call bi_normalize
    mov rax, rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size bi_sub_abs,.-bi_sub_abs

.type bi_sub_abs_inplace,@function
bi_sub_abs_inplace:
    push r12
    push r13
    push r14
    mov r8, qword ptr [rdi+BI_DATA]
    mov r9, qword ptr [rsi+BI_DATA]
    mov r10, qword ptr [rdi+BI_LEN]
    mov r11, qword ptr [rsi+BI_LEN]
    xor ecx, ecx
    xor r12d, r12d
.Lbsai_loop:
    cmp rcx, r10
    jae .Lbsai_norm
    mov rax, qword ptr [r8+rcx*8]
    xor edx, edx
    cmp rcx, r11
    jae .Lbsai_no_b
    mov rdx, qword ptr [r9+rcx*8]
.Lbsai_no_b:
    mov r13, r12
    sub rax, rdx
    sbb r12, r12
    and r12, 1
    sub rax, r13
    sbb r14, r14
    and r14, 1
    or r12, r14
    mov qword ptr [r8+rcx*8], rax
    inc rcx
    jmp .Lbsai_loop
.Lbsai_norm:
    call bi_normalize
    pop r14
    pop r13
    pop r12
    ret
.size bi_sub_abs_inplace,.-bi_sub_abs_inplace

.type bi_neg,@function
bi_neg:
    push rbp
    mov rbp, rsp
    call bi_clone
    mov rcx, qword ptr [rax+BI_SIGN]
    neg rcx
    mov qword ptr [rax+BI_SIGN], rcx
    leave
    ret
.size bi_neg,.-bi_neg

.type bi_add,@function
bi_add:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rax, qword ptr [r12+BI_SIGN]
    mov rcx, qword ptr [r13+BI_SIGN]
    test rax, rax
    jne .Lba_a_nonzero
    mov rdi, r13
    call bi_clone
    jmp .Lba_done
.Lba_a_nonzero:
    test rcx, rcx
    jne .Lba_b_nonzero
    mov rdi, r12
    call bi_clone
    jmp .Lba_done
.Lba_b_nonzero:
    cmp rax, rcx
    jne .Lba_diff_sign
    mov rdi, r12
    mov rsi, r13
    call bi_add_abs
    mov rcx, qword ptr [r12+BI_SIGN]
    mov qword ptr [rax+BI_SIGN], rcx
    jmp .Lba_done
.Lba_diff_sign:
    mov rdi, r12
    mov rsi, r13
    call bi_cmp_abs
    test eax, eax
    je .Lba_equal_abs
    jg .Lba_abs_a_gt
    mov rdi, r13
    mov rsi, r12
    call bi_sub_abs
    mov rcx, qword ptr [r13+BI_SIGN]
    mov qword ptr [rax+BI_SIGN], rcx
    jmp .Lba_done
.Lba_abs_a_gt:
    mov rdi, r12
    mov rsi, r13
    call bi_sub_abs
    mov rcx, qword ptr [r12+BI_SIGN]
    mov qword ptr [rax+BI_SIGN], rcx
    jmp .Lba_done
.Lba_equal_abs:
    call bi_zero
.Lba_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size bi_add,.-bi_add

.type bi_sub,@function
bi_sub:
    push rbp
    mov rbp, rsp
    push rbx
    mov rbx, rdi
    mov rdi, rsi
    call bi_neg
    mov rsi, rax
    mov rdi, rbx
    call bi_add
    pop rbx
    leave
    ret
.size bi_sub,.-bi_sub

.type bi_mul_abs,@function
bi_mul_abs:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, qword ptr [r12+BI_LEN]
    mov r15, qword ptr [r13+BI_LEN]
    test r14, r14
    je .Lbma_zero
    test r15, r15
    je .Lbma_zero
    mov rdi, r14
    add rdi, r15
    add rdi, 1
    call bi_new
    mov rbx, rax
    mov r8, qword ptr [r12+BI_DATA]
    mov r9, qword ptr [r13+BI_DATA]
    mov r10, qword ptr [rbx+BI_DATA]
    xor r11d, r11d
.Lbma_outer:
    cmp r11, r14
    jae .Lbma_finish
    xor rsi, rsi
    xor edi, edi
.Lbma_inner:
    cmp rdi, r15
    jae .Lbma_store_carry
    mov rax, qword ptr [r8+r11*8]
    mul qword ptr [r9+rdi*8]
    lea rcx, [r11+rdi]
    add rax, qword ptr [r10+rcx*8]
    adc rdx, 0
    add rax, rsi
    adc rdx, 0
    mov qword ptr [r10+rcx*8], rax
    mov rsi, rdx
    inc rdi
    jmp .Lbma_inner
.Lbma_store_carry:
    lea rcx, [r11+r15]
    mov rax, qword ptr [r10+rcx*8]
    add rax, rsi
    mov qword ptr [r10+rcx*8], rax
    jnc .Lbma_next_outer
    inc rcx
.Lbma_prop:
    add qword ptr [r10+rcx*8], 1
    jnc .Lbma_next_outer
    inc rcx
    jmp .Lbma_prop
.Lbma_next_outer:
    inc r11
    jmp .Lbma_outer
.Lbma_finish:
    mov rax, r14
    add rax, r15
    add rax, 1
    mov qword ptr [rbx+BI_LEN], rax
    mov qword ptr [rbx+BI_SIGN], 1
    mov rdi, rbx
    call bi_normalize
    mov rax, rbx
    jmp .Lbma_done
.Lbma_zero:
    call bi_zero
.Lbma_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size bi_mul_abs,.-bi_mul_abs

.type bi_mul,@function
bi_mul:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    call bi_mul_abs
    cmp qword ptr [rax+BI_LEN], 0
    je .Lbm_done
    mov rcx, qword ptr [r12+BI_SIGN]
    imul rcx, qword ptr [r13+BI_SIGN]
    mov qword ptr [rax+BI_SIGN], rcx
.Lbm_done:
    pop r13
    pop r12
    leave
    ret
.size bi_mul,.-bi_mul

.type bi_mul_u64,@function
bi_mul_u64:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    mov r12, rdi
    mov rbx, rsi
    test rbx, rbx
    je .Lbmu_zero
    cmp qword ptr [r12+BI_LEN], 0
    je .Lbmu_zero
    mov rdi, rbx
    call bi_from_u64
    mov rsi, rax
    mov rdi, r12
    call bi_mul
    jmp .Lbmu_done
.Lbmu_zero:
    call bi_zero
.Lbmu_done:
    pop r12
    pop rbx
    leave
    ret
.size bi_mul_u64,.-bi_mul_u64

.type bi_add_u64,@function
bi_add_u64:
    push rbp
    mov rbp, rsp
    push rbx
    mov rbx, rdi
    mov rdi, rsi
    call bi_from_u64
    mov rsi, rax
    mov rdi, rbx
    call bi_add
    pop rbx
    leave
    ret
.size bi_add_u64,.-bi_add_u64

.type bi_shl1_inplace,@function
bi_shl1_inplace:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    mov r12, rdi
    mov r13, qword ptr [r12+BI_LEN]
    test r13, r13
    je .Lbshl_done
    lea rsi, [r13+1]
    mov rdi, r12
    call bi_reserve
    mov r8, qword ptr [r12+BI_DATA]
    xor r9d, r9d
    xor r10d, r10d
.Lbshl_loop:
    cmp r10, r13
    jae .Lbshl_carry
    mov rax, qword ptr [r8+r10*8]
    mov rdx, rax
    shr rdx, 63
    shl rax, 1
    or rax, r9
    mov qword ptr [r8+r10*8], rax
    mov r9, rdx
    inc r10
    jmp .Lbshl_loop
.Lbshl_carry:
    test r9, r9
    je .Lbshl_done
    mov qword ptr [r8+r13*8], r9
    inc r13
    mov qword ptr [r12+BI_LEN], r13
.Lbshl_done:
    mov rax, r12
    pop r13
    pop r12
    leave
    ret
.size bi_shl1_inplace,.-bi_shl1_inplace

.type bi_shr1_inplace,@function
bi_shr1_inplace:
    mov rcx, qword ptr [rdi+BI_LEN]
    test rcx, rcx
    je .Lbshr_done
    mov r8, qword ptr [rdi+BI_DATA]
    xor r9d, r9d
.Lbshr_loop:
    test rcx, rcx
    je .Lbshr_norm
    mov rax, qword ptr [r8+rcx*8-8]
    mov rdx, rax
    and rdx, 1
    shr rax, 1
    test r9, r9
    je .Lbshr_no_top
    bts rax, 63
.Lbshr_no_top:
    mov qword ptr [r8+rcx*8-8], rax
    mov r9, rdx
    dec rcx
    jmp .Lbshr_loop
.Lbshr_norm:
    call bi_normalize
.Lbshr_done:
    mov rax, rdi
    ret
.size bi_shr1_inplace,.-bi_shr1_inplace

.type bi_bit_length,@function
bi_bit_length:
    mov rcx, qword ptr [rdi+BI_LEN]
    test rcx, rcx
    je .Lbbl_zero
    mov rdx, qword ptr [rdi+BI_DATA]
    mov rax, qword ptr [rdx+rcx*8-8]
    bsr r8, rax
    dec rcx
    shl rcx, 6
    lea rax, [rcx+r8+1]
    ret
.Lbbl_zero:
    xor eax, eax
    ret
.size bi_bit_length,.-bi_bit_length

.type bi_set_bit_inplace,@function
bi_set_bit_inplace:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rax, r13
    shr rax, 6
    lea rsi, [rax+1]
    mov rdi, r12
    call bi_reserve
    mov rcx, r13
    and rcx, 63
    mov rdx, 1
    shl rdx, cl
    mov r8, qword ptr [r12+BI_DATA]
    mov rcx, r13
    shr rcx, 6
    or qword ptr [r8+rcx*8], rdx
    inc rcx
    cmp rcx, qword ptr [r12+BI_LEN]
    jbe .Lbsb_sign
    mov qword ptr [r12+BI_LEN], rcx
.Lbsb_sign:
    mov qword ptr [r12+BI_SIGN], 1
    mov rax, r12
    pop r13
    pop r12
    leave
    ret
.size bi_set_bit_inplace,.-bi_set_bit_inplace


.type bi_divmod_u64_abs,@function
bi_divmod_u64_abs:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    test r13,r13
    je .Lbd64_soft_fail
    mov rdi,qword ptr [r12+BI_LEN]
    test rdi,rdi
    jne .Lbd64_cap_ok
    mov rdi,1
.Lbd64_cap_ok:
    call bi_new
    mov r14,rax
    mov rcx,qword ptr [r12+BI_LEN]
    mov qword ptr [r14+BI_LEN],rcx
    test rcx,rcx
    je .Lbd64_zero
    mov qword ptr [r14+BI_SIGN],1
    mov r15,qword ptr [r12+BI_DATA]
    mov rbx,qword ptr [r14+BI_DATA]
    xor edx,edx
.Lbd64_loop:
    mov rax,qword ptr [r15+rcx*8-8]
    div r13
    mov qword ptr [rbx+rcx*8-8],rax
    dec rcx
    jne .Lbd64_loop
    mov r12,rdx
    mov rdi,r14
    call bi_normalize
    mov rax,r14
    mov rdx,r12
    jmp .Lbd64_done
.Lbd64_zero:
    xor edx,edx
    mov rax,r14
    jmp .Lbd64_done
.Lbd64_soft_fail:
    # Ⲡzero-divisor detour ⲕⲧⲟ ⲛ(NULL,0); ⲡlegacy scar ⲥⲱϫⲡ.
    xor eax,eax
    xor edx,edx
    jmp .Lbd64_done
.Lbd64_fail:
    # Ⲡlegacy abort scar ⲙⲡu64 division.
    mov rax,60
    mov rdi,139
    syscall
.Lbd64_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size bi_divmod_u64_abs,.-bi_divmod_u64_abs

.type bi_divmod_abs,@function
bi_divmod_abs:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    cmp qword ptr [r13+BI_LEN], 0
    jne .Lbda_nonzero_div
    jmp .Lbda_soft_fail
.Lbda_fail:
    # Ⲡlegacy abort scar ⲙⲡBigInt division.
    mov rax, 60
    mov rdi, 102
    syscall
.Lbda_soft_fail:
    # Ⲡzero-divisor detour ⲕⲧⲟ ⲛ(NULL,NULL) ⲉⲡcaller.
    xor eax,eax
    xor edx,edx
    jmp .Lbda_done
.Lbda_nonzero_div:
    mov rdi, r12
    mov rsi, r13
    call bi_cmp_abs
    test eax, eax
    jge .Lbda_general
    call bi_zero
    mov rbx, rax
    mov rdi, r12
    call bi_abs
    mov rdx, rax
    mov rax, rbx
    jmp .Lbda_done
.Lbda_general:
    mov rdi, r12
    call bi_bit_length
    mov r14, rax
    mov rdi, r13
    call bi_bit_length
    mov r15, rax
    mov rbx, r14
    sub rbx, r15
    mov rdi, r14
    add rdi, 63
    shr rdi, 6
    add rdi, 1
    call bi_new
    mov qword ptr [rbp-48], rax
    mov rdi, r12
    call bi_abs
    mov qword ptr [rbp-56], rax
    mov rdi, r13
    call bi_abs
    mov r14, rax
    mov r15, rbx
.Lbda_shift_loop:
    test r15, r15
    je .Lbda_loop_start
    mov rdi, r14
    call bi_shl1_inplace
    dec r15
    jmp .Lbda_shift_loop
.Lbda_loop_start:
.Lbda_loop:
    mov rdi, qword ptr [rbp-56]
    mov rsi, r14
    call bi_cmp_abs
    test eax, eax
    jl .Lbda_skip_sub
    mov rdi, qword ptr [rbp-56]
    mov rsi, r14
    call bi_sub_abs_inplace
    mov rdi, qword ptr [rbp-48]
    mov rsi, rbx
    call bi_set_bit_inplace
.Lbda_skip_sub:
    test rbx, rbx
    je .Lbda_finish
    mov rdi, r14
    call bi_shr1_inplace
    dec rbx
    jmp .Lbda_loop
.Lbda_finish:
    mov rdi, qword ptr [rbp-48]
    call bi_normalize
    mov rdi, qword ptr [rbp-56]
    call bi_normalize
    mov rdx, qword ptr [rbp-56]
    mov rax, qword ptr [rbp-48]
.Lbda_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size bi_divmod_abs,.-bi_divmod_abs

.type bi_mod_abs,@function
bi_mod_abs:
    push rbp
    mov rbp, rsp
    call bi_divmod_abs
    mov rax, rdx
    leave
    ret
.size bi_mod_abs,.-bi_mod_abs

.type bi_eq_u64,@function
bi_eq_u64:
    xor eax, eax
    test rsi, rsi
    jne .Lbeq_nonzero
    cmp qword ptr [rdi+BI_LEN], 0
    sete al
    ret
.Lbeq_nonzero:
    cmp qword ptr [rdi+BI_SIGN], 1
    jne .Lbeq_ret
    cmp qword ptr [rdi+BI_LEN], 1
    jne .Lbeq_ret
    mov rcx, qword ptr [rdi+BI_DATA]
    cmp qword ptr [rcx], rsi
    sete al
.Lbeq_ret:
    ret
.size bi_eq_u64,.-bi_eq_u64
