.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE17_PATCH08_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE17_PATCH08_FAIL\n"
fail_len = . - fail_token
.align 8
first_permutation: .quad 1,2,3,4,5,6
last_permutation:  .quad 6,5,4,3,2,1

.section .text
.extern arena_alloc
.extern bi_from_i64
.extern bi_from_u64
.extern oracle_bowl_order_from_value
.extern legacyPermutationRank0FromDropWrong
.extern legacyPermutationOrderFromDropWrong
.extern oldPermutationUnrank0
.extern permutationOneBasedFromDropPatch08
.extern orderPatchFromValue
.extern monster_permutation_route
.extern calendarDateSpaghetti
.global _start

.type equal_order6,@function
equal_order6:
    xor ecx,ecx
.Ls17eo_loop:
    cmp rcx,6
    jae .Ls17eo_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Ls17eo_no
    inc rcx
    jmp .Ls17eo_loop
.Ls17eo_yes:
    mov eax,1
    ret
.Ls17eo_no:
    xor eax,eax
    ret
.size equal_order6,.-equal_order6

.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,16

    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls17rls_fail
    mov r12,rax
    mov rdi,r12
    call legacyPermutationRank0FromDropWrong
    cmp rax,1
    jne .Ls17rls_fail

    mov edi,96
    call arena_alloc
    test rax,rax
    je .Ls17rls_fail
    mov r13,rax
    lea rcx,[rax+48]
    mov qword ptr [rbp-32],rcx

    mov rdi,r12
    mov rsi,r13
    call legacyPermutationOrderFromDropWrong
    test rax,rax
    je .Ls17rls_fail
    mov rdi,r12
    mov rsi,qword ptr [rbp-32]
    call oracle_bowl_order_from_value
    test eax,eax
    je .Ls17rls_fail
    mov rdi,r13
    mov rsi,qword ptr [rbp-32]
    call equal_order6
    test eax,eax
    jne .Ls17rls_fail

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Ls17rls_fail
    mov r12,rax
    xor edi,edi
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    je .Ls17rls_fail
    mov rdi,r12
    lea rsi,[rip+first_permutation]
    call equal_order6
    test eax,eax
    je .Ls17rls_fail

    mov edi,719
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    je .Ls17rls_fail
    mov rdi,r12
    lea rsi,[rip+last_permutation]
    call equal_order6
    test eax,eax
    je .Ls17rls_fail

    mov eax,1
    jmp .Ls17rls_done
.Ls17rls_fail:
    xor eax,eax
.Ls17rls_done:
    add rsp,16
    pop r13
    pop r12
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type require_one_based_case,@function
require_one_based_case:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rdi,r12
    call bi_from_i64
    test rax,rax
    je .Ls17rob_fail
    mov rdi,rax
    call permutationOneBasedFromDropPatch08
    cmp rax,r13
    jne .Ls17rob_fail
    mov eax,1
    jmp .Ls17rob_done
.Ls17rob_fail:
    xor eax,eax
.Ls17rob_done:
    pop r13
    pop r12
    leave
    ret
.size require_one_based_case,.-require_one_based_case

.type compare_patch_case,@function
compare_patch_case:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov rdi,r12
    call bi_from_i64
    test rax,rax
    je .Ls17cpc_fail
    mov r12,rax
    mov edi,96
    call arena_alloc
    test rax,rax
    je .Ls17cpc_fail
    mov r13,rax
    lea r14,[rax+48]

    mov rdi,r12
    mov rsi,r13
    call oracle_bowl_order_from_value
    test eax,eax
    je .Ls17cpc_fail

    mov rdi,r12
    mov rsi,r14
    call orderPatchFromValue
    test rax,rax
    je .Ls17cpc_fail
    mov rdi,r13
    mov rsi,r14
    call equal_order6
    test eax,eax
    je .Ls17cpc_fail

    mov rdi,r12
    mov rsi,r14
    call monster_permutation_route
    test rax,rax
    je .Ls17cpc_fail
    mov rdi,r13
    mov rsi,r14
    call equal_order6
    test eax,eax
    je .Ls17cpc_fail

    mov eax,1
    jmp .Ls17cpc_done
.Ls17cpc_fail:
    xor eax,eax
.Ls17cpc_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size compare_patch_case,.-compare_patch_case

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Ls17fail

    call require_legacy_scar
    test eax,eax
    je .Ls17fail

    mov rdi,1
    mov rsi,1
    call require_one_based_case
    test eax,eax
    je .Ls17fail
    mov rdi,720
    mov rsi,720
    call require_one_based_case
    test eax,eax
    je .Ls17fail
    mov rdi,721
    mov rsi,1
    call require_one_based_case
    test eax,eax
    je .Ls17fail
    xor edi,edi
    mov rsi,720
    call require_one_based_case
    test eax,eax
    je .Ls17fail
    mov rdi,-1
    mov rsi,719
    call require_one_based_case
    test eax,eax
    je .Ls17fail
    mov rdi,-719
    mov rsi,1
    call require_one_based_case
    test eax,eax
    je .Ls17fail
    mov rdi,-720
    mov rsi,720
    call require_one_based_case
    test eax,eax
    je .Ls17fail

    mov rdi,-1440
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,-721
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,-720
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,-719
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,-1
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    xor edi,edi
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,1
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,2
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,719
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,720
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,721
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,1440
    call compare_patch_case
    test eax,eax
    je .Ls17fail
    mov rdi,1441
    call compare_patch_case
    test eax,eax
    je .Ls17fail

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Ls17fail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,17
    syscall
.size _start,.-_start
