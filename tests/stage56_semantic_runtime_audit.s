.intel_syntax noprefix

.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_DATA,24
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.equ S23_FINAL_BOWLS,8
.equ S23_ORDER46_LATCH,88
.equ S23_BOWLS_AFTER_DROPS,0
.equ S56_OLD_RESULT,120
.equ S56_CORRECTED_RESULT,128
.equ S56_RAW_BOWL_SUM,136
.equ S56_SAVED_ORDER_NUMBER,144
.equ S56_STIR_INDEX,152
.equ S56_APPLIED_COUNT,160
.equ S56_APPLIED_FLAG,168
.equ S56_ORDER_GUARD,176
.equ S56_SIZE,184
.equ CTX_STAGE56_CORRECTED_RESULT,2712
.equ CTX_STAGE56_RAW_BOWL_SUM,2720
.equ CTX_STAGE56_SAVED_ORDER_NUMBER,2728
.equ CTX_STAGE56_STIR_INDEX,2736
.equ CTX_STAGE56_APPLIED_COUNT,2744
.equ CTX_STAGE56_APPLIED_FLAG,2752
.equ CTX_STAGE56_ORDER_GUARD,2760

.section .rodata
ok_token: .ascii "STAGE56_SEMANTIC_AUDIT_GREEN\n"
ok_len = . - ok_token
fail_token: .ascii "STAGE56_SEMANTIC_AUDIT_FAIL\n"
fail_len = . - fail_token

cases:
.quad -15055671,-15055671,5000,4,762,12,105
.quad -15048173,-15048173,5000,12,21,47,57
.quad -15048173,-15048172,5000,12,22,18,58
.quad -15048173,-15048174,5000,12,20,7,58

foundation_bowls:
.quad 0x0324ee3aedefa7d6,0x3274dede2c892516
.quad 0x80d75ce91b3b5c73,0x75fc8287bac46fa0
.quad 0x178f8804ce09a5ad,0x14f5b026702a34c2
.quad 0x0f820c2a2903201b,0x7493e09e62fa09ff
.quad 0xb0646c37f9780d90,0x3f04130f04a5de7f
.quad 0xaf84a2f99b8238c1,0x74556c4e99493c08
foundation_order: .quad 4,5,2,3,6,1

second_bowls:
.quad 0x4ccd31263ec3843d,0x589a902fb2b9822d
.quad 0x64f16702560d3d87,0x138c65bc39238ccf
.quad 0x9eeb5721785b9098,0x6c340766194a5d5a
.quad 0x2c4d76a57d948852,0x2cd1047a0bbb13dc
.quad 0xe7782a7c44620414,0x315df489ad3be870
.quad 0x104bf237719fe169,0x159293e89ee4de74
second_order: .quad 3,4,6,5,2,1

.section .text
.global _start
.extern arena_alloc
.extern bi_from_u64
.extern bi_clone
.extern bi_add_abs
.extern bi_add_u64
.extern bi_mul_u64
.extern bi_mul_abs
.extern bi_cmp
.extern bi_eq_u64
.extern savePatch
.extern orderPatchFromValue
.extern postStirOneOverwritingOrderMemoryStage22
.extern stage56PostStirRawBowlSumDetour
.extern stage56SauceRawBowlSumCorrective
.extern stage56_LEGACY_POSTSTIR_CALL_COUNT
.extern calendarDateSpaghetti
.extern catalog_get_cutlet
.extern catalog_get_month
.extern monster_context_new
.extern stage56ContextEnter
.extern stage56ContextLeave

.type check_bi_u64,@function
check_bi_u64:
    test rdi,rdi
    je .Lcbu_no
    cmp qword ptr [rdi+BI_SIGN],1
    jne .Lcbu_no
    cmp qword ptr [rdi+BI_LEN],1
    jne .Lcbu_no
    mov rax,qword ptr [rdi+BI_DATA]
    cmp qword ptr [rax],rsi
    jne .Lcbu_no
    mov eax,1
    ret
.Lcbu_no:
    xor eax,eax
    ret
.size check_bi_u64,.-check_bi_u64

.type check_bi2,@function
check_bi2:
    test rdi,rdi
    je .Lcb2_no
    cmp qword ptr [rdi+BI_SIGN],1
    jne .Lcb2_no
    cmp qword ptr [rdi+BI_LEN],2
    jne .Lcb2_no
    mov rcx,qword ptr [rdi+BI_DATA]
    cmp qword ptr [rcx],rsi
    jne .Lcb2_no
    cmp qword ptr [rcx+8],rdx
    jne .Lcb2_no
    mov eax,1
    ret
.Lcb2_no:
    xor eax,eax
    ret
.size check_bi2,.-check_bi2

.type compare_bowl_arrays,@function
compare_bowl_arrays:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
.Lcba_loop:
    cmp rbx,6
    jae .Lcba_yes
    mov rdi,qword ptr [r12+rbx*8]
    mov rsi,qword ptr [r13+rbx*8]
    call bi_cmp
    test eax,eax
    jne .Lcba_no
    inc rbx
    jmp .Lcba_loop
.Lcba_yes:
    mov eax,1
    jmp .Lcba_done
.Lcba_no:
    xor eax,eax
.Lcba_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size compare_bowl_arrays,.-compare_bowl_arrays

.type arrays_differ,@function
arrays_differ:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
.Lad_loop:
    cmp rbx,6
    jae .Lad_no
    mov rdi,qword ptr [r12+rbx*8]
    mov rsi,qword ptr [r13+rbx*8]
    call bi_cmp
    test eax,eax
    jne .Lad_yes
    inc rbx
    jmp .Lad_loop
.Lad_yes:
    mov eax,1
    jmp .Lad_done
.Lad_no:
    xor eax,eax
.Lad_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size arrays_differ,.-arrays_differ

.type clone_pointer_array,@function
clone_pointer_array:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    mov r12,rdi
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lcpa_fail
    mov rbx,rax
    xor ecx,ecx
.Lcpa_loop:
    cmp rcx,6
    jae .Lcpa_ok
    mov rdx,qword ptr [r12+rcx*8]
    mov qword ptr [rbx+rcx*8],rdx
    inc rcx
    jmp .Lcpa_loop
.Lcpa_ok:
    mov rax,rbx
    jmp .Lcpa_done
.Lcpa_fail:
    xor eax,eax
.Lcpa_done:
    pop r12
    pop rbx
    leave
    ret
.size clone_pointer_array,.-clone_pointer_array

.type compare_order,@function
compare_order:
    xor ecx,ecx
.Lco_loop:
    cmp rcx,6
    jae .Lco_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Lco_no
    inc rcx
    jmp .Lco_loop
.Lco_yes:
    mov eax,1
    ret
.Lco_no:
    xor eax,eax
    ret
.size compare_order,.-compare_order

.type check_known_bowls,@function
check_known_bowls:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
.Lckb_loop:
    cmp rbx,6
    jae .Lckb_yes
    mov rdi,qword ptr [r12+rbx*8]
    mov rcx,rbx
    shl rcx,4
    mov rsi,qword ptr [r13+rcx]
    mov rdx,qword ptr [r13+rcx+8]
    call check_bi2
    test eax,eax
    je .Lckb_no
    inc rbx
    jmp .Lckb_loop
.Lckb_yes:
    mov eax,1
    jmp .Lckb_done
.Lckb_no:
    xor eax,eax
.Lckb_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size check_known_bowls,.-check_known_bowls

# Ⲡⲁⲓ ⲡⲉ ⲟⲩoracle ⲛⲇⲟⲕⲓⲙⲏ ⲛⲣⲉϥⲥⲙⲓⲛⲉ; ⲛϥⲃⲱⲕ ⲁⲛ ⲉⲡproduction.
.type oracle_stage56_stir,@function
oracle_stage56_stir:
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
    xor edi,edi
    call bi_from_u64
    test rax,rax
    je .Loss_fail
    mov r15,rax
    xor ebx,ebx
.Loss_sum:
    cmp rbx,6
    jae .Loss_saved
    mov rdi,r15
    mov rsi,qword ptr [r12+rbx*8]
    call bi_add_abs
    test rax,rax
    je .Loss_fail
    mov r15,rax
    inc rbx
    jmp .Loss_sum
.Loss_saved:
    mov qword ptr [r14],r15
    mov rax,r13
    imul rax,149
    mov rdi,r15
    mov rsi,rax
    call bi_add_u64
    test rax,rax
    je .Loss_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Loss_fail
    mov qword ptr [r14+8],rax
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Loss_fail
    mov qword ptr [r14+16],rax
    mov rsi,rax
    mov rdi,qword ptr [r14+8]
    call orderPatchFromValue
    test rax,rax
    je .Loss_fail
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Loss_fail
    mov qword ptr [rbp-48],rax
    xor ebx,ebx
.Loss_pos:
    cmp rbx,6
    jae .Loss_validate
    mov rdx,qword ptr [r14+16]
    mov rax,qword ptr [rdx+rbx*8]
    mov qword ptr [rbp-56],rax
    mov rcx,rbx
    add rcx,5
    cmp rcx,6
    jb .Loss_prev_ok
    sub rcx,6
.Loss_prev_ok:
    mov rax,qword ptr [rdx+rcx*8]
    mov qword ptr [rbp-64],rax
    mov rcx,rbx
    inc rcx
    cmp rcx,6
    jb .Loss_next_ok
    xor ecx,ecx
.Loss_next_ok:
    mov rax,qword ptr [rdx+rcx*8]
    mov qword ptr [rbp-72],rax
    mov rax,qword ptr [rbp-56]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    call bi_clone
    test rax,rax
    je .Loss_fail
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [rbp-64]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,3
    call bi_mul_u64
    test rax,rax
    je .Loss_fail
    mov rdi,qword ptr [rbp-80]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Loss_fail
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [rbp-72]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,5
    call bi_mul_u64
    test rax,rax
    je .Loss_fail
    mov rdi,qword ptr [rbp-80]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Loss_fail
    mov rdi,rax
    mov rsi,qword ptr [r14]
    call bi_add_abs
    test rax,rax
    je .Loss_fail
    mov rdi,rax
    mov rsi,r13
    call bi_add_u64
    test rax,rax
    je .Loss_fail
    mov rcx,rbx
    inc rcx
    imul rcx,rcx
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Loss_fail
    mov rdi,rax
    mov rsi,rax
    call bi_mul_abs
    test rax,rax
    je .Loss_fail
    mov qword ptr [rbp-80],rax
    mov rax,qword ptr [rbp-64]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov rax,qword ptr [rbp-72]
    dec rax
    mov rsi,qword ptr [r12+rax*8]
    call bi_mul_abs
    test rax,rax
    je .Loss_fail
    mov rdi,rax
    mov esi,7
    call bi_mul_u64
    test rax,rax
    je .Loss_fail
    mov rdi,qword ptr [rbp-80]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Loss_fail
    mov rdi,rax
    call savePatch
    test rax,rax
    je .Loss_fail
    mov rcx,qword ptr [rbp-56]
    dec rcx
    mov rdx,qword ptr [rbp-48]
    mov qword ptr [rdx+rcx*8],rax
    inc rbx
    jmp .Loss_pos
.Loss_validate:
    xor ebx,ebx
.Loss_vloop:
    cmp rbx,6
    jae .Loss_ok
    mov rax,qword ptr [rbp-48]
    cmp qword ptr [rax+rbx*8],0
    je .Loss_fail
    inc rbx
    jmp .Loss_vloop
.Loss_ok:
    mov rax,qword ptr [rbp-48]
    jmp .Loss_done
.Loss_fail:
    xor eax,eax
.Loss_done:
    add rsp,80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size oracle_stage56_stir,.-oracle_stage56_stir

.type check_e2e_cases,@function
check_e2e_cases:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    lea r15,[rip+cases]
    xor r14d,r14d
.Lcec_loop:
    cmp r14,4
    jae .Lcec_yes
    mov rdi,qword ptr [r15]
    mov rsi,qword ptr [r15+8]
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lcec_no
    test rdx,rdx
    je .Lcec_no
    mov r12,rdx
    mov rdi,qword ptr [r12+RES_YEAR]
    mov rsi,qword ptr [r15+16]
    call bi_eq_u64
    test eax,eax
    je .Lcec_no
    mov rdi,qword ptr [r15+24]
    call catalog_get_cutlet
    cmp rax,qword ptr [r12+RES_CUTLET_NAME]
    jne .Lcec_no
    mov rax,qword ptr [r15+32]
    cmp qword ptr [r12+RES_DAY_IN_CUTLET],rax
    jne .Lcec_no
    mov rdi,qword ptr [r15+40]
    call catalog_get_month
    cmp rax,qword ptr [r12+RES_MONTH_NAME]
    jne .Lcec_no
    mov rax,qword ptr [r15+48]
    cmp qword ptr [r12+RES_DAY_IN_MONTH],rax
    jne .Lcec_no
    add r15,56
    inc r14
    jmp .Lcec_loop
.Lcec_yes:
    mov eax,1
    jmp .Lcec_done
.Lcec_no:
    xor eax,eax
.Lcec_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size check_e2e_cases,.-check_e2e_cases

.type check_sauce_witnesses,@function
check_sauce_witnesses:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rdi,-15055671
    mov rsi,-15055671
    call stage56SauceRawBowlSumCorrective
    test rax,rax
    je .Lcsw_no
    mov r12,rax
    cmp qword ptr [r12+S56_APPLIED_COUNT],12
    jne .Lcsw_no
    cmp qword ptr [r12+S56_APPLIED_FLAG],1
    jne .Lcsw_no
    cmp qword ptr [r12+S56_ORDER_GUARD],1
    jne .Lcsw_no
    cmp qword ptr [rip+stage56_LEGACY_POSTSTIR_CALL_COUNT],12
    jne .Lcsw_no
    mov rdi,qword ptr [r12+S23_FINAL_BOWLS]
    lea rsi,[rip+foundation_bowls]
    call check_known_bowls
    test eax,eax
    je .Lcsw_no
    mov rdi,qword ptr [r12+S23_ORDER46_LATCH]
    lea rsi,[rip+foundation_order]
    call compare_order
    test eax,eax
    je .Lcsw_no
    mov rdi,-15048173
    mov rsi,-15048173
    call stage56SauceRawBowlSumCorrective
    test rax,rax
    je .Lcsw_no
    mov r12,rax
    cmp qword ptr [r12+S56_APPLIED_COUNT],12
    jne .Lcsw_no
    cmp qword ptr [rip+stage56_LEGACY_POSTSTIR_CALL_COUNT],12
    jne .Lcsw_no
    mov rdi,qword ptr [r12+S23_FINAL_BOWLS]
    lea rsi,[rip+second_bowls]
    call check_known_bowls
    test eax,eax
    je .Lcsw_no
    mov rdi,qword ptr [r12+S23_ORDER46_LATCH]
    lea rsi,[rip+second_order]
    call compare_order
    test eax,eax
    je .Lcsw_no
    mov eax,1
    jmp .Lcsw_done
.Lcsw_no:
    xor eax,eax
.Lcsw_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size check_sauce_witnesses,.-check_sauce_witnesses

.type check_discriminator,@function
check_discriminator:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lcd_no
    mov r12,rax
    mov r13,1
.Lcd_make:
    cmp r13,7
    jae .Lcd_state
    mov rdi,r13
    call bi_from_u64
    test rax,rax
    je .Lcd_no
    mov rcx,r13
    dec rcx
    mov qword ptr [r12+rcx*8],rax
    inc r13
    jmp .Lcd_make
.Lcd_state:
    mov edi,S56_SIZE
    call arena_alloc
    test rax,rax
    je .Lcd_no
    mov r14,rax
    mov rdi,r14
    xor eax,eax
    mov ecx,S56_SIZE/8
    rep stosq
    mov qword ptr [rip+stage56_LEGACY_POSTSTIR_CALL_COUNT],0
    mov rdi,r12
    mov rsi,1
    xor edx,edx
    mov rcx,r14
    call stage56PostStirRawBowlSumDetour
    test rax,rax
    je .Lcd_no
    mov rdi,qword ptr [r14+S56_RAW_BOWL_SUM]
    mov rsi,21
    call check_bi_u64
    test eax,eax
    je .Lcd_no
    mov rdi,qword ptr [r14+S56_SAVED_ORDER_NUMBER]
    mov rsi,170
    call check_bi_u64
    test eax,eax
    je .Lcd_no
    cmp qword ptr [r14+S56_APPLIED_COUNT],1
    jne .Lcd_no
    cmp qword ptr [r14+S56_APPLIED_FLAG],1
    jne .Lcd_no
    cmp qword ptr [r14+S56_ORDER_GUARD],1
    jne .Lcd_no
    cmp qword ptr [rip+stage56_LEGACY_POSTSTIR_CALL_COUNT],1
    jne .Lcd_no
    mov rdi,qword ptr [r14+S56_OLD_RESULT]
    mov rsi,qword ptr [r14+S56_CORRECTED_RESULT]
    call arrays_differ
    test eax,eax
    je .Lcd_no
    mov eax,1
    jmp .Lcd_done
.Lcd_no:
    xor eax,eax
.Lcd_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size check_discriminator,.-check_discriminator

.type check_twelve_stirs,@function
check_twelve_stirs:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,48
    mov rdi,-15055671
    mov rsi,-15055671
    call stage56SauceRawBowlSumCorrective
    test rax,rax
    je .Lcts_no
    mov rdi,qword ptr [rax+S23_BOWLS_AFTER_DROPS]
    call clone_pointer_array
    test rax,rax
    je .Lcts_no
    mov r12,rax
    mov rdi,r12
    call clone_pointer_array
    test rax,rax
    je .Lcts_no
    mov r13,rax
    mov rbx,1
.Lcts_loop:
    cmp rbx,12
    ja .Lcts_yes
    mov rdi,r12
    call clone_pointer_array
    test rax,rax
    je .Lcts_no
    mov qword ptr [rbp-48],rax
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lcts_no
    mov qword ptr [rbp-56],rax
    mov edi,S56_SIZE
    call arena_alloc
    test rax,rax
    je .Lcts_no
    mov r14,rax
    mov rdi,r14
    xor eax,eax
    mov ecx,S56_SIZE/8
    rep stosq
    mov rdi,r12
    mov rsi,rbx
    mov rdx,qword ptr [rbp-56]
    mov rcx,r14
    call stage56PostStirRawBowlSumDetour
    test rax,rax
    je .Lcts_no
    mov r12,rax
    mov edi,24
    call arena_alloc
    test rax,rax
    je .Lcts_no
    mov r15,rax
    mov rdi,r13
    mov rsi,rbx
    mov rdx,r15
    call oracle_stage56_stir
    test rax,rax
    je .Lcts_no
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call compare_bowl_arrays
    test eax,eax
    je .Lcts_no
    mov rdi,qword ptr [r14+S56_RAW_BOWL_SUM]
    mov rsi,qword ptr [r15]
    call bi_cmp
    test eax,eax
    jne .Lcts_no
    mov rdi,qword ptr [r14+S56_SAVED_ORDER_NUMBER]
    mov rsi,qword ptr [r15+8]
    call bi_cmp
    test eax,eax
    jne .Lcts_no
    mov rdi,qword ptr [rbp-56]
    mov rsi,qword ptr [r15+16]
    call compare_order
    test eax,eax
    je .Lcts_no
    mov rdi,qword ptr [rbp-48]
    call clone_pointer_array
    test rax,rax
    je .Lcts_no
    mov qword ptr [rbp-64],rax
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lcts_no
    mov rdx,rax
    mov rdi,qword ptr [rbp-64]
    mov rsi,rbx
    call postStirOneOverwritingOrderMemoryStage22
    test rax,rax
    je .Lcts_no
    mov rdi,rax
    mov rsi,qword ptr [r14+S56_OLD_RESULT]
    call compare_bowl_arrays
    test eax,eax
    je .Lcts_no
    inc rbx
    jmp .Lcts_loop
.Lcts_yes:
    mov eax,1
    jmp .Lcts_done
.Lcts_no:
    xor eax,eax
.Lcts_done:
    add rsp,48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size check_twelve_stirs,.-check_twelve_stirs

.type check_contexts,@function
check_contexts:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lcc_no
    mov r12,rax
    mov rdi,-15048173
    mov rsi,-15048173
    call monster_context_new
    test rax,rax
    je .Lcc_no
    mov r13,rax
    mov rdi,r12
    call stage56ContextEnter
    mov r14,rax
    mov rdi,-15055671
    mov rsi,-15055671
    call stage56SauceRawBowlSumCorrective
    test rax,rax
    je .Lcc_restore_no
    mov rdi,r14
    call stage56ContextLeave
    mov rdi,r13
    call stage56ContextEnter
    mov r15,rax
    mov rdi,-15048173
    mov rsi,-15048173
    call stage56SauceRawBowlSumCorrective
    test rax,rax
    je .Lcc_restore_b_no
    mov rdi,r15
    call stage56ContextLeave
    cmp qword ptr [r12+CTX_STAGE56_APPLIED_COUNT],12
    jne .Lcc_no
    cmp qword ptr [r13+CTX_STAGE56_APPLIED_COUNT],12
    jne .Lcc_no
    cmp qword ptr [r12+CTX_STAGE56_APPLIED_FLAG],1
    jne .Lcc_no
    cmp qword ptr [r13+CTX_STAGE56_APPLIED_FLAG],1
    jne .Lcc_no
    mov rax,qword ptr [r12+CTX_STAGE56_CORRECTED_RESULT]
    cmp rax,qword ptr [r13+CTX_STAGE56_CORRECTED_RESULT]
    je .Lcc_no
    mov rdi,r12
    call stage56ContextEnter
    mov r14,rax
    mov rdi,-15055671
    mov rsi,-15055671
    call stage56SauceRawBowlSumCorrective
    test rax,rax
    je .Lcc_restore_no
    mov rdi,r14
    call stage56ContextLeave
    cmp qword ptr [r12+CTX_STAGE56_APPLIED_COUNT],12
    jne .Lcc_no
    cmp qword ptr [r13+CTX_STAGE56_APPLIED_COUNT],12
    jne .Lcc_no
    mov eax,1
    jmp .Lcc_done
.Lcc_restore_b_no:
    mov rdi,r15
    call stage56ContextLeave
    jmp .Lcc_no
.Lcc_restore_no:
    mov rdi,r14
    call stage56ContextLeave
.Lcc_no:
    xor eax,eax
.Lcc_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size check_contexts,.-check_contexts

_start:
    call check_discriminator
    test eax,eax
    je .Lmain_fail
    call check_twelve_stirs
    test eax,eax
    je .Lmain_fail
    call check_sauce_witnesses
    test eax,eax
    je .Lmain_fail
    call check_e2e_cases
    test eax,eax
    je .Lmain_fail
    call check_contexts
    test eax,eax
    je .Lmain_fail
    mov eax,1
    mov edi,1
    lea rsi,[rip+ok_token]
    mov edx,ok_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Lmain_fail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,56
    syscall
