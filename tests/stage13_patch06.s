.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE13_PATCH06_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE13_PATCH06_FAIL\n"
fail_len = . - fail_token
.align 8
prior_cases:
    .quad 2,1,0
    .quad 3,1,0
    .quad 1,1,1
    .quad 2,3,2
    .quad 1,3,3
    .quad 2,7,6
    .quad 1,7,7

.section .text
.extern arena_alloc
.extern bi_from_i64
.extern bi_from_u64
.extern bi_cmp
.extern oracle_work_counts
.extern oracle_build_stones
.extern buildHiddenWithBackwardStorage
.extern legacyPrior
.extern priorPatch
.extern monster_hidden_route
.extern monster_prior_route
.extern calendarDateSpaghetti
.global _start

.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    push r12
    mov r12,rdi

    # Ⲡslot 0 ⲟⲩⲏϩ ⲉϥⲟ ⲛ0 ϩⲙⲡdropStore ⲛⲗⲉⲅⲁⲥⲓ.
    mov rdi,r12
    mov esi,1
    mov edx,1
    call legacyPrior
    test rax,rax
    jne .Lrls_fail

    # Ⲡslot 1 ⲟ visible, ⲁⲩⲱ ⲡlegacy ϫⲓ ⲙⲡpointer ⲛⲧⲟϥ.
    mov rdi,r12
    mov esi,2
    mov edx,1
    call legacyPrior
    test rax,rax
    je .Lrls_fail
    mov rdi,rax
    mov rsi,qword ptr [r12+8]
    call bi_cmp
    test eax,eax
    jne .Lrls_fail
    mov eax,1
    jmp .Lrls_done
.Lrls_fail:
    xor eax,eax
.Lrls_done:
    pop r12
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type count_patch_mismatches,@function
count_patch_mismatches:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
    xor r15d,r15d
.Lcpm_loop:
    cmp r15,7
    jae .Lcpm_done
    lea rax,[rip+prior_cases]
    mov rcx,r15
    imul rcx,24
    add rax,rcx
    mov qword ptr [rbp-48],rax
    mov r8,qword ptr [rax]
    mov r9,qword ptr [rax+8]
    mov r10,qword ptr [rax+16]

    test r10,r10
    jne .Lcpm_hidden_expected
    mov rbx,r8
    sub rbx,r9
    mov rbx,qword ptr [r12+rbx*8]
    jmp .Lcpm_have_expected
.Lcpm_hidden_expected:
    mov rdi,r13
    mov rsi,r10
    call monster_hidden_route
    test rax,rax
    je .Lcpm_bad
    mov rbx,rax
.Lcpm_have_expected:
    mov rax,qword ptr [rbp-48]
    mov rdx,qword ptr [rax]
    mov rcx,qword ptr [rax+8]
    mov rdi,r12
    mov rsi,r13
    call priorPatch
    test rax,rax
    je .Lcpm_mismatch
    mov rdi,rax
    mov rsi,rbx
    call bi_cmp
    test eax,eax
    je .Lcpm_next
.Lcpm_mismatch:
    inc r14
.Lcpm_next:
    inc r15
    jmp .Lcpm_loop
.Lcpm_bad:
    mov rax,-1
    jmp .Lcpm_out
.Lcpm_done:
    mov rax,r14
.Lcpm_out:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size count_patch_mismatches,.-count_patch_mismatches

.type count_route_mismatches,@function
count_route_mismatches:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
    xor r15d,r15d
.Lcrm_loop:
    cmp r15,7
    jae .Lcrm_done
    lea rax,[rip+prior_cases]
    mov rcx,r15
    imul rcx,24
    add rax,rcx
    mov qword ptr [rbp-48],rax
    mov r8,qword ptr [rax]
    mov r9,qword ptr [rax+8]
    mov r10,qword ptr [rax+16]

    test r10,r10
    jne .Lcrm_hidden_expected
    mov rbx,r8
    sub rbx,r9
    mov rbx,qword ptr [r12+rbx*8]
    jmp .Lcrm_have_expected
.Lcrm_hidden_expected:
    mov rdi,r13
    mov rsi,r10
    call monster_hidden_route
    test rax,rax
    je .Lcrm_bad
    mov rbx,rax
.Lcrm_have_expected:
    mov rax,qword ptr [rbp-48]
    mov rdx,qword ptr [rax]
    mov rcx,qword ptr [rax+8]
    mov rdi,r12
    mov rsi,r13
    call monster_prior_route
    test rax,rax
    je .Lcrm_mismatch
    mov rdi,rax
    mov rsi,rbx
    call bi_cmp
    test eax,eax
    je .Lcrm_next
.Lcrm_mismatch:
    inc r14
.Lcrm_next:
    inc r15
    jmp .Lcrm_loop
.Lcrm_bad:
    mov rax,-1
    jmp .Lcrm_out
.Lcrm_done:
    mov rax,r14
.Lcrm_out:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size count_route_mismatches,.-count_route_mismatches

.type _start,@function
_start:
    # Ⲡmain route ⲙⲟⲟϣⲉ ϩⲓⲧⲛ ⲡprior patch.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail

    # Ⲧⲁⲙⲓⲟ ⲙⲡhidden storage ⲙⲛ ⲡdropStore ⲛⲧⲉⲡⲇⲟⲕⲓⲙⲏ.
    mov rdi,-15055671
    call bi_from_i64
    mov r12,rax
    mov rdi,-15055671
    call bi_from_i64
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call oracle_work_counts
    mov r14,rax
    call oracle_build_stones
    mov r15,rax
    mov rdi,r14
    mov rsi,r15
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lfail
    mov r13,rax

    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lfail
    mov r12,rax
    mov rdi,r12
    xor eax,eax
    mov ecx,15
    rep stosq
    lea r12,[r12+48]

    mov edi,111
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov edi,222
    call bi_from_u64
    mov qword ptr [r12+16],rax

    # Ⲡlegacy scar ⲙⲉⲛⲉⲓ: slot 0 ⲛϥϫⲓ ⲁⲛ ⲙⲡhidden1.
    mov rdi,r12
    call require_legacy_scar
    test eax,eax
    je .Lfail

    # ⲠpriorPatch ⲧⲱⲛ ⲙⲛ ⲛ7 ⲛpredecessor ⲧⲏⲣⲟⲩ.
    mov rdi,r12
    mov rsi,r13
    call count_patch_mismatches
    test rax,rax
    jne .Lfail

    # Ⲡroute authoritative ⲧⲱⲛ ⲟⲛ ⲙⲛ ⲛ7 ⲛpredecessor.
    mov rdi,r12
    mov rsi,r13
    call count_route_mismatches
    test rax,rax
    jne .Lfail

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lfail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,13
    syscall
.size _start,.-_start
