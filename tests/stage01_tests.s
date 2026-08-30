.intel_syntax noprefix
.section .rodata
ok_token: .ascii "STAGE01_OK\n"
ok_len = . - ok_token
fail_token: .ascii "STAGE01_FAIL\n"
fail_len = . - fail_token
lens22: .quad 2,2
lens222: .quad 2,2,2
lens23: .quad 2,3

.section .bss
.align 8
out_buf: .zero 65536

.section .text
.extern oracle_init
.extern oracle_SAVE
.extern oracle_M
.extern oracle_FOUNDATION
.extern oracle_day_count
.extern oracle_work_counts
.extern oracle_binomial_u64
.extern oracle_sauce
.extern oracle_gate_gap
.extern oracle_year5000
.extern oracle_exact_gate_node
.extern oracle_gate_node_at_or_after
.extern oracle_to_u64
.extern oracle_cutlet_partition_count
.extern oracle_cutlet_partition_unrank
.extern oracle_bounded_comp_count
.extern oracle_bounded_comp_unrank
.extern oracle_falling_factorial_u64
.extern oracle_distinct_unrank
.extern oracle_weaving_count
.extern oracle_weaving_unrank
.extern catalog_validate
.extern catalog_cutlet_count
.extern catalog_month_count
.extern monster_context_new
.extern monster_validate_base
.extern bi_from_u64
.extern bi_from_i64
.extern bi_add_u64
.extern bi_eq_u64
.extern bi_cmp

.global _start
.type _start,@function
_start:
    call oracle_init
    call catalog_validate
    cmp eax,1
    jne .Lfail
    call catalog_cutlet_count
    cmp eax,17
    jne .Lfail
    call catalog_month_count
    cmp eax,47
    jne .Lfail

    mov rdi,5
    mov rsi,2
    call oracle_binomial_u64
    mov rdi,rax
    mov rsi,10
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,qword ptr [rip+oracle_M]
    call oracle_SAVE
    mov rdi,rax
    mov rsi,qword ptr [rip+oracle_M]
    call bi_cmp
    test eax,eax
    jne .Lfail

    mov rdi,qword ptr [rip+oracle_M]
    mov rsi,1
    call bi_add_u64
    mov rdi,rax
    call oracle_SAVE
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_day_count
    mov rdi,rax
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_work_counts
    push rax
    mov rdi,qword ptr [rax+16]
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lfail_stack
    mov rax,qword ptr [rsp]
    mov rdi,qword ptr [rax+32]
    mov rsi,2
    call bi_eq_u64
    test eax,eax
    je .Lfail_stack
    add rsp,8

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_sauce
    cmp qword ptr [rax+48],4
    jne .Lfail
    cmp qword ptr [rax+56],5
    jne .Lfail
    cmp qword ptr [rax+64],2
    jne .Lfail
    cmp qword ptr [rax+72],3
    jne .Lfail
    cmp qword ptr [rax+80],6
    jne .Lfail
    cmp qword ptr [rax+88],1
    jne .Lfail

    mov rdi,1
    call bi_from_u64
    mov rdi,rax
    mov rsi,1
    call oracle_gate_gap
    cmp rax,345
    jne .Lfail
    mov rdi,1
    call bi_from_u64
    mov rdi,rax
    mov rsi,-1
    call oracle_gate_gap
    cmp rax,503
    jne .Lfail

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_year5000
    push rax
    mov rdi,-15057703
    call bi_from_i64
    mov rsi,rax
    mov rax,qword ptr [rsp]
    mov rdi,qword ptr [rax+24]
    call bi_cmp
    test eax,eax
    jne .Lfail_stack
    mov rdi,-15053459
    call bi_from_i64
    mov rsi,rax
    mov rax,qword ptr [rsp]
    mov rdi,qword ptr [rax+32]
    call bi_cmp
    test eax,eax
    jne .Lfail_stack
    add rsp,8

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_exact_gate_node
    test rax,rax
    je .Lfail
    mov rdi,qword ptr [rax]
    xor esi,esi
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,1
    call bi_add_u64
    mov rdi,rax
    call oracle_gate_node_at_or_after
    test rax,rax
    je .Lfail
    mov rdi,qword ptr [rax]
    mov rsi,1
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,10
    mov rsi,3
    xor edx,edx
    call oracle_cutlet_partition_count
    mov rdi,rax
    mov rsi,36
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,10
    mov rsi,3
    mov rdx,4
    call oracle_cutlet_partition_count
    mov rdi,rax
    mov rsi,8
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,1
    call bi_from_u64
    mov rcx,rax
    lea r8,[rip+out_buf]
    mov rdi,10
    mov rsi,3
    mov rdx,4
    call oracle_cutlet_partition_unrank
    cmp qword ptr [rip+out_buf],1
    jne .Lfail
    cmp qword ptr [rip+out_buf+8],3
    jne .Lfail
    cmp qword ptr [rip+out_buf+16],6
    jne .Lfail

    mov rdi,10
    mov rsi,2
    mov rdx,4
    mov rcx,123
    call oracle_bounded_comp_count
    mov rdi,rax
    mov rsi,3
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,2
    call bi_from_u64
    mov r8,rax
    lea r9,[rip+out_buf]
    mov rdi,10
    mov rsi,2
    mov rdx,4
    mov rcx,123
    call oracle_bounded_comp_unrank
    cmp qword ptr [rip+out_buf],5
    jne .Lfail
    cmp qword ptr [rip+out_buf+8],5
    jne .Lfail

    mov rdi,1
    call bi_from_u64
    mov rdx,rax
    lea rcx,[rip+out_buf]
    mov rdi,5
    mov rsi,3
    call oracle_distinct_unrank
    cmp qword ptr [rip+out_buf],1
    jne .Lfail
    cmp qword ptr [rip+out_buf+8],2
    jne .Lfail
    cmp qword ptr [rip+out_buf+16],3
    jne .Lfail

    lea rdi,[rip+lens22]
    mov rsi,2
    call oracle_weaving_count
    mov rdi,rax
    mov rsi,2
    call bi_eq_u64
    test eax,eax
    je .Lfail

    lea rdi,[rip+lens222]
    mov rsi,3
    call oracle_weaving_count
    mov rdi,rax
    mov rsi,5
    call bi_eq_u64
    test eax,eax
    je .Lfail

    lea rdi,[rip+lens23]
    mov rsi,2
    call oracle_weaving_count
    mov rdi,rax
    mov rsi,3
    call bi_eq_u64
    test eax,eax
    je .Lfail

    mov rdi,1
    call bi_from_u64
    mov rdx,rax
    lea rcx,[rip+out_buf]
    lea rdi,[rip+lens22]
    mov rsi,2
    call oracle_weaving_unrank
    cmp qword ptr [rip+out_buf],1
    jne .Lfail
    cmp qword ptr [rip+out_buf+8],1
    jne .Lfail
    cmp qword ptr [rip+out_buf+16],2
    jne .Lfail
    cmp qword ptr [rip+out_buf+24],2
    jne .Lfail

    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call monster_context_new
    mov rdi,rax
    call monster_validate_base
    cmp eax,1
    jne .Lfail

    mov rax,1
    mov rdi,1
    lea rsi,[rip+ok_token]
    mov rdx,ok_len
    syscall
    xor edi,edi
    mov eax,60
    syscall
.Lfail_stack:
    add rsp,8
.Lfail:
    mov rax,1
    mov rdi,1
    lea rsi,[rip+fail_token]
    mov rdx,fail_len
    syscall
    mov edi,1
    mov eax,60
    syscall
.size _start,.-_start
