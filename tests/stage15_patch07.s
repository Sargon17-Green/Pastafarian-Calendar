.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE15_PATCH07_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE15_PATCH07_FAIL\n"
fail_len = . - fail_token
.align 8
expected_visible_grinds:
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

.section .text
.extern arena_alloc
.extern bi_from_i64
.extern bi_cmp
.extern oracle_work_counts
.extern oracle_build_stones
.extern oracle_build_hidden
.extern oracle_build_visible
.extern buildHiddenWithBackwardStorage
.extern legacyGrindRowAtIndex
.extern grindSentinelRow0
.extern monster_visible_drop_route
.extern calendarDateSpaghetti
.global _start

.type require_sentinel_row0,@function
require_sentinel_row0:
    call grindSentinelRow0
    test rax,rax
    je .Lrs0_fail
    cmp qword ptr [rax],0
    jne .Lrs0_fail
    cmp qword ptr [rax+8],0
    jne .Lrs0_fail
    cmp qword ptr [rax+16],0
    jne .Lrs0_fail
    cmp qword ptr [rax+24],0
    jne .Lrs0_fail
    cmp qword ptr [rax+32],0
    jne .Lrs0_fail
    # Ⲡlegacy API ⲟⲩⲏϩ ⲉϥⲁⲣⲛⲁ ⲙⲡindex 0; ⲡsentinel ⲡⲉ ⲟⲩϣⲟⲩⲱⲃⲉ ⲙⲡtable, ⲛⲟⲩgrind ⲁⲛ.
    xor edi,edi
    call legacyGrindRowAtIndex
    test rax,rax
    jne .Lrs0_fail
    mov eax,1
    ret
.Lrs0_fail:
    xor eax,eax
    ret
.size require_sentinel_row0,.-require_sentinel_row0

.type require_real_rows_1_to_11,@function
require_real_rows_1_to_11:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    mov r12,1
.Lrr_loop:
    cmp r12,11
    ja .Lrr_ok
    mov rdi,r12
    call legacyGrindRowAtIndex
    test rax,rax
    je .Lrr_fail
    mov rbx,rax
    lea r13,[rip+expected_visible_grinds]
    mov rax,r12
    dec rax
    imul rax,40
    add r13,rax
    xor r14d,r14d
.Lrr_field:
    cmp r14,5
    jae .Lrr_next
    mov rax,qword ptr [rbx+r14*8]
    cmp rax,qword ptr [r13+r14*8]
    jne .Lrr_fail
    inc r14
    jmp .Lrr_field
.Lrr_next:
    inc r12
    jmp .Lrr_loop
.Lrr_ok:
    mov eax,1
    jmp .Lrr_out
.Lrr_fail:
    xor eax,eax
.Lrr_out:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size require_real_rows_1_to_11,.-require_real_rows_1_to_11

.type require_first_visible_equal,@function
require_first_visible_equal:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8

    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lrfve_fail
    mov r12,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lrfve_fail
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call oracle_work_counts
    test rax,rax
    je .Lrfve_fail
    mov r12,rax
    call oracle_build_stones
    test rax,rax
    je .Lrfve_fail
    mov r13,rax

    mov rdi,r12
    mov rsi,r13
    call oracle_build_hidden
    test rax,rax
    je .Lrfve_fail
    mov r14,rax
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call oracle_build_visible
    test rax,rax
    je .Lrfve_fail
    mov r15,qword ptr [rax]
    test r15,r15
    je .Lrfve_fail

    mov rdi,r12
    mov rsi,r13
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lrfve_fail
    mov r14,rax

    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lrfve_fail
    mov qword ptr [rbp-48],rax
    mov rdi,rax
    xor eax,eax
    mov ecx,15
    rep stosq
    mov rdx,qword ptr [rbp-48]
    add rdx,48

    mov rdi,r12
    mov rsi,r13
    mov rcx,r14
    mov r8d,1
    call monster_visible_drop_route
    test rax,rax
    je .Lrfve_fail
    mov rdi,rax
    mov rsi,r15
    call bi_cmp
    test eax,eax
    jne .Lrfve_fail
    mov eax,1
    jmp .Lrfve_out
.Lrfve_fail:
    xor eax,eax
.Lrfve_out:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size require_first_visible_equal,.-require_first_visible_equal

.type _start,@function
_start:
    # Ⲡmain route ϣⲱⲡ ⲙⲡStage 15 wrapper ⲙⲛ ⲡsentinel table.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail

    call require_sentinel_row0
    test eax,eax
    je .Lfail
    call require_real_rows_1_to_11
    test eax,eax
    je .Lfail
    call require_first_visible_equal
    test eax,eax
    je .Lfail

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
    mov edi,15
    syscall
.size _start,.-_start
