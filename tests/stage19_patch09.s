.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE19_PATCH09_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE19_PATCH09_FAIL\n"
fail_len = . - fail_token

.align 8
expected_order_121:
    .quad 2,1,3,4,5,6
legacy_expected_121:
    .quad 14675,14700,14754
normative_expected_121:
    .quad 14679,14694,14754
expected_order_145:
    .quad 2,3,1,4,5,6
expected_pours_145:
    .quad 21063,21096,21108

.section .text
.extern arena_alloc
.extern arena_mark
.extern arena_reset
.extern bi_from_u64
.extern bi_eq_u64
.extern bi_cmp
.extern bi_mul_abs
.extern bi_add_abs
.extern bi_add_u64
.extern oracle_SAVE
.extern oracle_bowl_order_from_value
.extern legacyPoursToFixedBowlIds
.extern installOrderAliases
.extern bowlByLegacyPosition
.extern monster_pour_route
.extern calendarDateSpaghetti
.global _start

.type make_fixture,@function
make_fixture:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,88
    call arena_alloc
    test rax,rax
    je .Lmf19_fail
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
    jmp .Lmf19_done
.Lmf19_fail:
    xor eax,eax
.Lmf19_done:
    add rsp,8
    pop r12
    leave
    ret
.size make_fixture,.-make_fixture

.type equal_order6_u64,@function
equal_order6_u64:
    xor ecx,ecx
.Leo19_loop:
    cmp rcx,6
    jae .Leo19_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Leo19_no
    inc rcx
    jmp .Leo19_loop
.Leo19_yes:
    mov eax,1
    ret
.Leo19_no:
    xor eax,eax
    ret
.size equal_order6_u64,.-equal_order6_u64

.type equal_pours_u64,@function
equal_pours_u64:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
.Lep19_loop:
    cmp rbx,3
    jae .Lep19_yes
    mov rdi,qword ptr [r12+rbx*8]
    mov rsi,qword ptr [r13+rbx*8]
    call bi_eq_u64
    test eax,eax
    je .Lep19_no
    inc rbx
    jmp .Lep19_loop
.Lep19_yes:
    mov eax,1
    jmp .Lep19_done
.Lep19_no:
    xor eax,eax
.Lep19_done:
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size equal_pours_u64,.-equal_pours_u64

.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call make_fixture
    test rax,rax
    je .Lrls19_fail
    mov r12,rax
    mov edi,72
    call arena_alloc
    mov r13,rax
    lea r14,[rax+48]
    mov edi,121
    call bi_from_u64
    mov rdi,rax
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call legacyPoursToFixedBowlIds
    test rax,rax
    je .Lrls19_fail
    mov rdi,r13
    lea rsi,[rip+expected_order_121]
    call equal_order6_u64
    test eax,eax
    je .Lrls19_fail
    mov rdi,r14
    lea rsi,[rip+legacy_expected_121]
    call equal_pours_u64
    test eax,eax
    je .Lrls19_fail
    mov rdi,r14
    lea rsi,[rip+normative_expected_121]
    # Ⲡlegacy ⲙⲡⲉϥⲣⲡⲁⲧϣ: ⲛⲧⲟϥ ⲙⲡⲣⲧⲱⲛ ⲙⲛ ⲡⲉⲓarray.
    call equal_pours_u64
    test eax,eax
    jne .Lrls19_fail
    mov eax,1
    jmp .Lrls19_done
.Lrls19_fail:
    xor eax,eax
.Lrls19_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type require_alias_witness,@function
require_alias_witness:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    call make_fixture
    test rax,rax
    je .Lraw_fail
    mov r12,rax
    mov edi,120
    call arena_alloc
    test rax,rax
    je .Lraw_fail
    mov r13,rax
    lea r14,[rax+48]
    lea r15,[rax+72]

    mov edi,145
    call bi_from_u64
    test rax,rax
    je .Lraw_fail
    mov rdi,rax
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call monster_pour_route
    test rax,rax
    je .Lraw_fail

    mov rdi,r13
    lea rsi,[rip+expected_order_145]
    call equal_order6_u64
    test eax,eax
    je .Lraw_fail

    mov rdi,r13
    mov rsi,r15
    call installOrderAliases
    test rax,rax
    je .Lraw_fail
    mov rdi,r15
    lea rsi,[rip+expected_order_145]
    call equal_order6_u64
    test eax,eax
    je .Lraw_fail

    mov rdi,r12
    mov rsi,r15
    mov edx,1
    call bowlByLegacyPosition
    mov rdi,rax
    mov esi,13
    call bi_eq_u64
    test eax,eax
    je .Lraw_fail

    mov rdi,r12
    mov rsi,r15
    mov edx,2
    call bowlByLegacyPosition
    mov rdi,rax
    mov esi,17
    call bi_eq_u64
    test eax,eax
    je .Lraw_fail

    mov rdi,r12
    mov rsi,r15
    mov edx,3
    call bowlByLegacyPosition
    mov rdi,rax
    mov esi,11
    call bi_eq_u64
    test eax,eax
    je .Lraw_fail

    mov rdi,r14
    lea rsi,[rip+expected_pours_145]
    call equal_pours_u64
    test eax,eax
    je .Lraw_fail

    mov eax,1
    jmp .Lraw_done
.Lraw_fail:
    xor eax,eax
.Lraw_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_alias_witness,.-require_alias_witness

.type build_expected_pours,@function
build_expected_pours:
    # rdi=drop, rsi=i, rdx=oldBowls, rcx=stones, r8=oracleOrder, r9=out.
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov qword ptr [rbp-48],r8
    mov qword ptr [rbp-56],r9
    xor ebx,ebx
.Lbep_loop:
    cmp rbx,3
    jae .Lbep_ok
    mov rdi,r12
    mov rsi,r12
    call bi_mul_abs
    test rax,rax
    je .Lbep_fail
    mov qword ptr [rbp-64],rax

    mov rcx,qword ptr [rbp-48]
    mov rax,qword ptr [rcx+rbx*8]
    cmp rax,1
    jb .Lbep_fail
    cmp rax,6
    ja .Lbep_fail
    dec rax
    mov rsi,qword ptr [r14+rax*8]
    mov rdi,qword ptr [r15+rbx*8]
    call bi_mul_abs
    test rax,rax
    je .Lbep_fail
    mov rsi,rax
    mov rdi,qword ptr [rbp-64]
    call bi_add_abs
    test rax,rax
    je .Lbep_fail

    mov rcx,rbx
    cmp rcx,0
    jne .Lbep_f2
    mov edx,3
    jmp .Lbep_factor
.Lbep_f2:
    cmp rcx,1
    jne .Lbep_f3
    mov edx,5
    jmp .Lbep_factor
.Lbep_f3:
    mov edx,7
.Lbep_factor:
    imul rdx,r13
    mov rdi,rax
    mov rsi,rdx
    call bi_add_u64
    test rax,rax
    je .Lbep_fail
    mov rdi,rax
    call oracle_SAVE
    test rax,rax
    je .Lbep_fail
    mov rdx,qword ptr [rbp-56]
    mov qword ptr [rdx+rbx*8],rax
    inc rbx
    jmp .Lbep_loop
.Lbep_ok:
    mov rax,qword ptr [rbp-56]
    jmp .Lbep_done
.Lbep_fail:
    xor eax,eax
.Lbep_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size build_expected_pours,.-build_expected_pours

.type require_all_720,@function
require_all_720:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,56

    # Ⲡoracle ⲛⲧⲟϥ ⲁⲣⲭⲉⲓ ⲙⲡⲉⲓⲙⲁ, ⲡⲉϥstate ⲛⲧⲟϣ ⲛϥⲛⲁⲟⲩⲱϣϥ ⲁⲛ ϩⲙⲡreset.
    mov edi,1
    call bi_from_u64
    mov qword ptr [rbp-48],rax
    mov edi,48
    call arena_alloc
    mov rsi,rax
    mov rdi,qword ptr [rbp-48]
    call oracle_bowl_order_from_value
    test eax,eax
    je .Lra720_fail

    call make_fixture
    test rax,rax
    je .Lra720_fail
    mov r12,rax
    call arena_mark
    mov r13,rax
    mov r14,1

.Lra720_loop:
    cmp r14,721
    jae .Lra720_ok

    mov rdi,r14
    call bi_from_u64
    test rax,rax
    je .Lra720_fail
    mov qword ptr [rbp-48],rax

    mov edi,144
    call arena_alloc
    test rax,rax
    je .Lra720_fail
    mov r15,rax
    lea rax,[r15+48]
    mov qword ptr [rbp-56],rax
    lea rax,[r15+96]
    mov qword ptr [rbp-64],rax
    lea rax,[r15+120]
    mov qword ptr [rbp-72],rax

    mov rdi,qword ptr [rbp-48]
    mov rsi,r15
    call oracle_bowl_order_from_value
    test eax,eax
    je .Lra720_fail

    mov rdi,qword ptr [rbp-48]
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,qword ptr [rbp-56]
    mov r9,qword ptr [rbp-64]
    call monster_pour_route
    test rax,rax
    je .Lra720_fail

    mov rdi,r15
    mov rsi,qword ptr [rbp-56]
    call equal_order6_u64
    test eax,eax
    je .Lra720_fail

    mov rdi,qword ptr [rbp-48]
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r15
    mov r9,qword ptr [rbp-72]
    call build_expected_pours
    test rax,rax
    je .Lra720_fail

    xor ebx,ebx
.Lra720_cmp:
    cmp rbx,3
    jae .Lra720_next
    mov rcx,qword ptr [rbp-72]
    mov rdi,qword ptr [rcx+rbx*8]
    mov rcx,qword ptr [rbp-64]
    mov rsi,qword ptr [rcx+rbx*8]
    call bi_cmp
    test eax,eax
    jne .Lra720_fail
    inc rbx
    jmp .Lra720_cmp

.Lra720_next:
    mov rdi,r13
    call arena_reset
    inc r14
    jmp .Lra720_loop

.Lra720_ok:
    mov eax,1
    jmp .Lra720_done
.Lra720_fail:
    xor eax,eax
.Lra720_done:
    add rsp,56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size require_all_720,.-require_all_720

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail19

    call require_legacy_scar
    test eax,eax
    je .Lfail19

    call require_alias_witness
    test eax,eax
    je .Lfail19

    call require_all_720
    test eax,eax
    je .Lfail19

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lfail19:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,19
    syscall
.size _start,.-_start
