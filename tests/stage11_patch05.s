.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE11_PATCH05_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE11_PATCH05_FAIL\n"
fail_len = . - fail_token

.section .text
.extern bi_from_i64
.extern bi_cmp
.extern oracle_work_counts
.extern oracle_build_stones
.extern oracle_build_hidden
.extern buildHiddenWithBackwardStorage
.extern legacyHiddenAtNearnessWrong
.extern hiddenByNearness
.extern monster_hidden_route
.extern calendarDateSpaghetti
.global _start

.type require_backward_storage,@function
require_backward_storage:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
.Ls11_rbs_loop:
    cmp r14,7
    jae .Ls11_rbs_ok
    mov rdi,qword ptr [r12+r14*8]
    mov rax,6
    sub rax,r14
    mov rsi,qword ptr [r13+rax*8]
    call bi_cmp
    test eax,eax
    jne .Ls11_rbs_fail
    inc r14
    jmp .Ls11_rbs_loop
.Ls11_rbs_ok:
    mov eax,1
    jmp .Ls11_rbs_done
.Ls11_rbs_fail:
    xor eax,eax
.Ls11_rbs_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_backward_storage,.-require_backward_storage

.type count_legacy_mismatches,@function
count_legacy_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,1
    xor r15d,r15d
.Ls11_clm_loop:
    cmp r14,7
    ja .Ls11_clm_done
    mov rdi,r12
    mov rsi,r14
    call legacyHiddenAtNearnessWrong
    test rax,rax
    je .Ls11_clm_bad
    mov rdi,rax
    mov rsi,qword ptr [r13+r14*8-8]
    call bi_cmp
    test eax,eax
    je .Ls11_clm_next
    inc r15
.Ls11_clm_next:
    inc r14
    jmp .Ls11_clm_loop
.Ls11_clm_bad:
    mov rax,-1
    jmp .Ls11_clm_out
.Ls11_clm_done:
    mov rax,r15
.Ls11_clm_out:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size count_legacy_mismatches,.-count_legacy_mismatches

.type require_patched_all,@function
require_patched_all:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    mov r14,1
.Ls11_rpa_loop:
    cmp r14,7
    ja .Ls11_rpa_ok

    # Ⲡroute ⲙⲛ hiddenByNearness ⲥⲉϫⲓ ⲙⲡhidden k ϩⲙⲡstorage ⲛⲥⲁϩⲟⲩ.
    mov rdi,r12
    mov rsi,r14
    call monster_hidden_route
    test rax,rax
    je .Ls11_rpa_fail
    mov rdi,rax
    mov rsi,qword ptr [r13+r14*8-8]
    call bi_cmp
    test eax,eax
    jne .Ls11_rpa_fail

    mov rdi,r12
    mov rsi,r14
    call hiddenByNearness
    test rax,rax
    je .Ls11_rpa_fail
    mov rdi,rax
    mov rsi,qword ptr [r13+r14*8-8]
    call bi_cmp
    test eax,eax
    jne .Ls11_rpa_fail

    inc r14
    jmp .Ls11_rpa_loop
.Ls11_rpa_ok:
    mov eax,1
    jmp .Ls11_rpa_done
.Ls11_rpa_fail:
    xor eax,eax
.Ls11_rpa_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_patched_all,.-require_patched_all

.type require_edge_scar,@function
require_edge_scar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi

    # Ⲡlegacy k=1 ⲟⲩⲏϩ ⲉϥϯ hidden7.
    mov rdi,r12
    mov esi,1
    call legacyHiddenAtNearnessWrong
    test rax,rax
    je .Ls11_res_fail
    mov rdi,rax
    mov rsi,qword ptr [r13+48]
    call bi_cmp
    test eax,eax
    jne .Ls11_res_fail

    # Ⲡpatched k=1 ϯ hidden1 ⲁϫⲛ ⲧⲣⲉϥⲕⲧⲟ ⲙⲡarray.
    mov rdi,r12
    mov esi,1
    call monster_hidden_route
    test rax,rax
    je .Ls11_res_fail
    mov rdi,rax
    mov rsi,qword ptr [r13]
    call bi_cmp
    test eax,eax
    jne .Ls11_res_fail

    # Ⲡlegacy k=7 ⲟⲩⲏϩ ⲉϥϯ hidden1; ⲡpatched ϯ hidden7.
    mov rdi,r12
    mov esi,7
    call legacyHiddenAtNearnessWrong
    mov rdi,rax
    mov rsi,qword ptr [r13]
    call bi_cmp
    test eax,eax
    jne .Ls11_res_fail

    mov rdi,r12
    mov esi,7
    call monster_hidden_route
    mov rdi,rax
    mov rsi,qword ptr [r13+48]
    call bi_cmp
    test eax,eax
    jne .Ls11_res_fail

    mov eax,1
    jmp .Ls11_res_done
.Ls11_res_fail:
    xor eax,eax
.Ls11_res_done:
    pop r13
    pop r12
    leave
    ret
.size require_edge_scar,.-require_edge_scar

.type _start,@function
_start:
    # Ⲡmain route ⲟⲩⲏϩ ⲉϥⲙⲟⲟϣⲉ ⲙⲛ ⲡhandler ⲙⲡhidden.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Ls11_fail

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
    je .Ls11_fail
    mov r12,rax

    mov rdi,r14
    mov rsi,r15
    call oracle_build_hidden
    test rax,rax
    je .Ls11_fail
    mov r13,rax

    # Ⲡstorage ⲙⲡlegacy ⲙⲡϥϣⲓⲃⲉ: hidden7..hidden1.
    mov rdi,r12
    mov rsi,r13
    call require_backward_storage
    test eax,eax
    je .Ls11_fail

    # Ⲡlegacy access ⲟⲩⲏϩ ⲉϥⲡⲗⲁⲛⲁ: exactly six mismatches.
    mov rdi,r12
    mov rsi,r13
    call count_legacy_mismatches
    cmp rax,6
    jne .Ls11_fail

    # Ⲡpatched access ⲧⲱⲛ ⲙⲛ ⲡoracle ϩⲓ k=1..7.
    mov rdi,r12
    mov rsi,r13
    call require_patched_all
    test eax,eax
    je .Ls11_fail

    mov rdi,r12
    mov rsi,r13
    call require_edge_scar
    test eax,eax
    je .Ls11_fail

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Ls11_fail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,11
    syscall
.size _start,.-_start
