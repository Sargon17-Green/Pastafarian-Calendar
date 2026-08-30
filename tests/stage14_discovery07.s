.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE14_DISCOVERY07_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE14_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE14_DISCOVERY07_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token
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
.extern monster_visible_drop_route
.extern calendarDateSpaghetti
.global _start

.type count_grind_row_mismatches,@function
count_grind_row_mismatches:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    xor r12d,r12d
    mov r13,1
.Lcgrm_loop:
    cmp r13,11
    ja .Lcgrm_done
    mov rdi,r13
    call legacyGrindRowAtIndex
    test rax,rax
    je .Lcgrm_bad
    mov rbx,rax
    lea r14,[rip+expected_visible_grinds]
    mov rax,r13
    dec rax
    imul rax,40
    add r14,rax
    xor ecx,ecx
.Lcgrm_field:
    cmp rcx,5
    jae .Lcgrm_next
    mov rax,qword ptr [rbx+rcx*8]
    cmp rax,qword ptr [r14+rcx*8]
    jne .Lcgrm_row_mismatch
    inc rcx
    jmp .Lcgrm_field
.Lcgrm_row_mismatch:
    inc r12
.Lcgrm_next:
    inc r13
    jmp .Lcgrm_loop
.Lcgrm_done:
    mov rax,r12
    jmp .Lcgrm_out
.Lcgrm_bad:
    mov rax,-1
.Lcgrm_out:
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size count_grind_row_mismatches,.-count_grind_row_mismatches

.type require_stage14_missing_fence,@function
require_stage14_missing_fence:
    mov edi,11
    call legacyGrindRowAtIndex
    test rax,rax
    je .Lrsmf_fail
    cmp qword ptr [rax],0
    jne .Lrsmf_fail
    cmp qword ptr [rax+8],0
    jne .Lrsmf_fail
    cmp qword ptr [rax+16],0
    jne .Lrsmf_fail
    cmp qword ptr [rax+24],0
    jne .Lrsmf_fail
    cmp qword ptr [rax+32],0
    jne .Lrsmf_fail
    mov eax,1
    ret
.Lrsmf_fail:
    xor eax,eax
    ret
.size require_stage14_missing_fence,.-require_stage14_missing_fence

.type compare_first_visible,@function
compare_first_visible:
    # 0 = ⲧⲱⲛ, 1 = ⲥⲉϣⲟⲃⲉ, -1 = ⲡpattern ⲙⲡⲟⲛⲏⲣⲟⲛ.
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
    je .Lcfv_bad
    mov r12,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lcfv_bad
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call oracle_work_counts
    test rax,rax
    je .Lcfv_bad
    mov r12,rax
    call oracle_build_stones
    test rax,rax
    je .Lcfv_bad
    mov r13,rax

    mov rdi,r12
    mov rsi,r13
    call oracle_build_hidden
    test rax,rax
    je .Lcfv_bad
    mov r14,rax
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call oracle_build_visible
    test rax,rax
    je .Lcfv_bad
    mov r15,qword ptr [rax]
    test r15,r15
    je .Lcfv_bad

    mov rdi,r12
    mov rsi,r13
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lcfv_bad
    mov r14,rax

    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lcfv_bad
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
    je .Lcfv_bad
    mov rdi,rax
    mov rsi,r15
    call bi_cmp
    test eax,eax
    setne al
    movzx eax,al
    jmp .Lcfv_out
.Lcfv_bad:
    mov rax,-1
.Lcfv_out:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size compare_first_visible,.-compare_first_visible

.type _start,@function
_start:
    # Ⲡmain route ϫⲓ ⲙⲡlegacy grind indexing ϩⲙⲡStage 14.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    call count_grind_row_mismatches
    cmp rax,0
    je .Lcandidate_green
    cmp rax,11
    jne .Lpattern

    call require_stage14_missing_fence
    test eax,eax
    je .Lpattern

    call compare_first_visible
    cmp rax,1
    jne .Lpattern

    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall

.Lcandidate_green:
    call compare_first_visible
    cmp rax,0
    jne .Lpattern
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lpattern:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,14
    syscall
.size _start,.-_start
