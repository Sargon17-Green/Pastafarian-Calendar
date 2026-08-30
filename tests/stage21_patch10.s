.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE21_PATCH10_UNEXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE21_PATCH10_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE21_PATCH10_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token
.align 8
identity_order20:
    .quad 1,2,3,4,5,6
stone_pos20:
    .quad 0,1,2,3,4,0

.section .text
.extern arena_alloc
.extern bi_from_u64
.extern bi_clone
.extern bi_mul_u64
.extern bi_mul_abs
.extern bi_add_abs
.extern bi_add_u64
.extern bi_cmp
.extern oracle_SAVE
.extern monster_pour_route
.extern legacyStirOneDropInPlace
.extern monster_bowl_stir_route
.extern calendarDateSpaghetti
.global _start

.type make_fixture20,@function
make_fixture20:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,88
    call arena_alloc
    test rax,rax
    je .Lmf20_fail
    mov r12,rax
    mov edi,11
    call bi_from_u64
    mov qword ptr [r12],rax
    mov edi,13
    call bi_from_u64
    mov qword ptr [r12+8],rax
    mov edi,17
    call bi_from_u64
    mov qword ptr [r12+16],rax
    mov edi,19
    call bi_from_u64
    mov qword ptr [r12+24],rax
    mov edi,23
    call bi_from_u64
    mov qword ptr [r12+32],rax
    mov edi,29
    call bi_from_u64
    mov qword ptr [r12+40],rax
    mov edi,2
    call bi_from_u64
    mov qword ptr [r12+48],rax
    mov edi,3
    call bi_from_u64
    mov qword ptr [r12+56],rax
    mov edi,5
    call bi_from_u64
    mov qword ptr [r12+64],rax
    mov edi,7
    call bi_from_u64
    mov qword ptr [r12+72],rax
    mov edi,11
    call bi_from_u64
    mov qword ptr [r12+80],rax
    mov rax,r12
    jmp .Lmf20_done
.Lmf20_fail:
    xor eax,eax
.Lmf20_done:
    add rsp,8
    pop r12
    leave
    ret
.size make_fixture20,.-make_fixture20

.type clone_bowl_vector20,@function
clone_bowl_vector20:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lcb20_fail
    mov r13,rax
    xor ecx,ecx
.Lcb20_loop:
    cmp rcx,6
    jae .Lcb20_ok
    mov rax,qword ptr [r12+rcx*8]
    test rax,rax
    je .Lcb20_fail
    mov qword ptr [r13+rcx*8],rax
    inc rcx
    jmp .Lcb20_loop
.Lcb20_ok:
    mov rax,r13
    jmp .Lcb20_done
.Lcb20_fail:
    xor eax,eax
.Lcb20_done:
    pop r13
    pop r12
    leave
    ret
.size clone_bowl_vector20,.-clone_bowl_vector20

.type equal_order20,@function
equal_order20:
    xor ecx,ecx
.Le20_loop:
    cmp rcx,6
    jae .Le20_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Le20_no
    inc rcx
    jmp .Le20_loop
.Le20_yes:
    mov eax,1
    ret
.Le20_no:
    xor eax,eax
    ret
.size equal_order20,.-equal_order20

.type snapshotBowlRoundReference20,@function
snapshotBowlRoundReference20:
# Ⲡreference ⲙⲡⲇⲟⲕⲓⲙⲏ ϫⲓ ⲛread ⲧⲏⲣⲟⲩ ⲉⲃⲟⲗ ϩⲙⲡoldB ⲛⲟⲩⲱⲧ.
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,104
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9
    test r12,r12
    je .Lsbr20_fail
    test r14,r14
    je .Lsbr20_fail
    test r15,r15
    je .Lsbr20_fail
    test r8,r8
    je .Lsbr20_fail
    test r9,r9
    je .Lsbr20_fail

    mov edi,48
    call arena_alloc
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-64],rax
    xor ebx,ebx

.Lsbr20_loop:
    cmp rbx,6
    jae .Lsbr20_ok

    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rbx*8]
    test rax,rax
    je .Lsbr20_fail
    cmp rax,6
    ja .Lsbr20_fail
    mov qword ptr [rbp-72],rax

    mov rcx,rbx
    add rcx,5
    cmp rcx,6
    jb .Lsbr20_prev_ready
    sub rcx,6
.Lsbr20_prev_ready:
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rcx*8]
    test rax,rax
    je .Lsbr20_fail
    cmp rax,6
    ja .Lsbr20_fail
    mov qword ptr [rbp-80],rax

    mov rcx,rbx
    inc rcx
    cmp rcx,6
    jb .Lsbr20_next_ready
    xor ecx,ecx
.Lsbr20_next_ready:
    mov rax,qword ptr [rbp-48]
    mov rax,qword ptr [rax+rcx*8]
    test rax,rax
    je .Lsbr20_fail
    cmp rax,6
    ja .Lsbr20_fail
    mov qword ptr [rbp-88],rax

    mov rax,qword ptr [rbp-72]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    call bi_clone
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-96],rax

    mov rax,qword ptr [rbp-80]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,2
    call bi_mul_u64
    test rax,rax
    je .Lsbr20_fail
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-96],rax

    mov rax,qword ptr [rbp-88]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov esi,3
    call bi_mul_u64
    test rax,rax
    je .Lsbr20_fail
    mov rdi,qword ptr [rbp-96]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-96],rax

    cmp rbx,3
    jae .Lsbr20_no_pour
    mov rax,qword ptr [rbp-56]
    mov rsi,qword ptr [rax+rbx*8]
    test rsi,rsi
    je .Lsbr20_fail
    mov rdi,qword ptr [rbp-96]
    call bi_add_abs
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-96],rax
.Lsbr20_no_pour:

    mov rdi,qword ptr [rbp-96]
    mov rsi,r14
    call bi_add_abs
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-96],rax

    lea rax,[rip+stone_pos20]
    mov rcx,qword ptr [rax+rbx*8]
    mov rsi,qword ptr [r15+rcx*8]
    test rsi,rsi
    je .Lsbr20_fail
    mov rdi,qword ptr [rbp-96]
    call bi_add_abs
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-96],rax

    mov rdi,qword ptr [rbp-96]
    mov rsi,rdi
    call bi_mul_abs
    test rax,rax
    je .Lsbr20_fail
    mov qword ptr [rbp-104],rax

    mov rax,qword ptr [rbp-80]
    dec rax
    mov rdi,qword ptr [r12+rax*8]
    mov rax,qword ptr [rbp-88]
    dec rax
    mov rsi,qword ptr [r12+rax*8]
    call bi_mul_abs
    test rax,rax
    je .Lsbr20_fail
    mov rdi,rax
    mov esi,5
    call bi_mul_u64
    test rax,rax
    je .Lsbr20_fail
    mov rdi,qword ptr [rbp-104]
    mov rsi,rax
    call bi_add_abs
    test rax,rax
    je .Lsbr20_fail

    mov rcx,rbx
    inc rcx
    imul rcx,r13
    mov rdi,rax
    mov rsi,rcx
    call bi_add_u64
    test rax,rax
    je .Lsbr20_fail
    mov rdi,rax
    call oracle_SAVE
    test rax,rax
    je .Lsbr20_fail

    mov rcx,qword ptr [rbp-72]
    dec rcx
    mov rdx,qword ptr [rbp-64]
    mov qword ptr [rdx+rcx*8],rax
    inc rbx
    jmp .Lsbr20_loop

.Lsbr20_ok:
    mov rax,qword ptr [rbp-64]
    jmp .Lsbr20_done
.Lsbr20_fail:
    xor eax,eax
.Lsbr20_done:
    add rsp,104
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size snapshotBowlRoundReference20,.-snapshotBowlRoundReference20

.type count_bowl_mismatches20,@function
count_bowl_mismatches20:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
    xor r14d,r14d
.Lcbm20_loop:
    cmp rbx,6
    jae .Lcbm20_done
    mov rdi,qword ptr [r12+rbx*8]
    mov rsi,qword ptr [r13+rbx*8]
    call bi_cmp
    test eax,eax
    je .Lcbm20_next
    inc r14
.Lcbm20_next:
    inc rbx
    jmp .Lcbm20_loop
.Lcbm20_done:
    mov rax,r14
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size count_bowl_mismatches20,.-count_bowl_mismatches20

.type make_round20,@function
make_round20:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    call make_fixture20
    test rax,rax
    je .Lmr20_fail
    mov r12,rax

    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lmr20_fail
    mov r13,rax
    lea r14,[rax+48]

    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Lmr20_fail
    mov r15,rax

    mov rdi,r15
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call monster_pour_route
    test rax,rax
    je .Lmr20_fail

    mov rdi,r13
    lea rsi,[rip+identity_order20]
    call equal_order20
    test eax,eax
    je .Lmr20_fail

    mov rdi,r12
    mov esi,4
    mov rdx,r15
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call snapshotBowlRoundReference20
    test rax,rax
    je .Lmr20_fail
    mov qword ptr [rbp-40],rax

    mov edi,40
    call arena_alloc
    test rax,rax
    je .Lmr20_fail
    mov qword ptr [rax],r12
    mov qword ptr [rax+8],r13
    mov qword ptr [rax+16],r14
    mov qword ptr [rax+24],r15
    mov rdx,qword ptr [rbp-40]
    mov qword ptr [rax+32],rdx
    jmp .Lmr20_done

.Lmr20_fail:
    xor eax,eax
.Lmr20_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size make_round20,.-make_round20

.type require_legacy_scar20,@function
require_legacy_scar20:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call make_round20
    test rax,rax
    je .Lrls20_fail
    mov r12,rax
    mov rdi,qword ptr [r12]
    call clone_bowl_vector20
    test rax,rax
    je .Lrls20_fail
    mov r13,rax

    mov rdi,r13
    mov esi,4
    mov rdx,qword ptr [r12+24]
    mov rax,qword ptr [r12]
    lea rcx,[rax+48]
    mov r8,qword ptr [r12+8]
    mov r9,qword ptr [r12+16]
    call legacyStirOneDropInPlace
    cmp rax,r13
    jne .Lrls20_fail

    # Ⲡϣⲟⲣⲡ bowl ⲧⲱⲛ ϫⲉ ⲙⲡⲁⲧⲉⲩϣⲓⲃⲉ ⲙⲡⲉⲧϩⲁⲧⲏϥ.
    mov rdi,qword ptr [r13]
    mov rax,qword ptr [r12+32]
    mov rsi,qword ptr [rax]
    call bi_cmp
    test eax,eax
    jne .Lrls20_fail

    mov rdi,r13
    mov rsi,qword ptr [r12+32]
    call count_bowl_mismatches20
    cmp rax,5
    jne .Lrls20_fail
    mov eax,1
    jmp .Lrls20_done
.Lrls20_fail:
    xor eax,eax
.Lrls20_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_legacy_scar20,.-require_legacy_scar20

.type route_mismatch_count20,@function
route_mismatch_count20:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call make_round20
    test rax,rax
    je .Lrmc20_fail
    mov r12,rax
    mov rdi,qword ptr [r12]
    call clone_bowl_vector20
    test rax,rax
    je .Lrmc20_fail
    mov r13,rax

    mov rdi,r13
    mov esi,4
    mov rdx,qword ptr [r12+24]
    mov rax,qword ptr [r12]
    lea rcx,[rax+48]
    mov r8,qword ptr [r12+8]
    mov r9,qword ptr [r12+16]
    call monster_bowl_stir_route
    cmp rax,r13
    jne .Lrmc20_fail

    mov rdi,r13
    mov rsi,qword ptr [r12+32]
    call count_bowl_mismatches20
    jmp .Lrmc20_done
.Lrmc20_fail:
    mov rax,-1
.Lrmc20_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size route_mismatch_count20,.-route_mismatch_count20

.type _start,@function
_start:
    # Ⲡⲣⲱⲧⲉ ⲛⲙⲟⲛⲥⲧⲉⲣ ⲙⲟⲩⲧⲉ ⲉⲡhandler ⲙⲡⲃⲁⲑⲙⲟⲥ 20.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern20

    call require_legacy_scar20
    test eax,eax
    je .Lpattern20

    call route_mismatch_count20
    test rax,rax
    je .Lgreen20
    cmp rax,5
    je .Lred20
    jmp .Lpattern20

.Lred20:
    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall

.Lgreen20:
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lpattern20:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,20
    syscall
.size _start,.-_start
