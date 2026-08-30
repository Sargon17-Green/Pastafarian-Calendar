.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE18_DISCOVERY09_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE18_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE18_DISCOVERY09_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.align 8
expected_order_121:
    .quad 2,1,3,4,5,6
expected_order_1:
    .quad 1,2,3,4,5,6
legacy_expected_121:
    .quad 14675,14700,14754
normative_expected_121:
    .quad 14679,14694,14754
normative_expected_1:
    .quad 35,60,114

.section .text
.extern arena_alloc
.extern bi_from_u64
.extern bi_eq_u64
.extern legacyPoursToFixedBowlIds
.extern monster_pour_route
.extern calendarDateSpaghetti
.global _start

.type make_fixture,@function
make_fixture:
    # Ⲡrax ⲕⲧⲟ ⲉⲟⲩbuffer ⲙⲛ [bowls 48][stones 40].
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,88
    call arena_alloc
    test rax,rax
    je .Lmf_fail
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
    jmp .Lmf_done
.Lmf_fail:
    xor eax,eax
.Lmf_done:
    add rsp,8
    pop r12
    leave
    ret
.size make_fixture,.-make_fixture

.type equal_order6_u64,@function
equal_order6_u64:
    xor ecx,ecx
.Leo_loop:
    cmp rcx,6
    jae .Leo_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Leo_no
    inc rcx
    jmp .Leo_loop
.Leo_yes:
    mov eax,1
    ret
.Leo_no:
    xor eax,eax
    ret
.size equal_order6_u64,.-equal_order6_u64

.type equal_pours_u64,@function
equal_pours_u64:
    # Ⲛargument ⲛⲉ rdi=pours[3] BigInt*, rsi=expected u64[3]; ⲡrax ⲕⲧⲟ ⲙⲡⲏⲡⲉ ⲛmismatch.
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
    xor ecx,ecx
.Lep_loop:
    cmp rcx,3
    jae .Lep_done
    mov rdi,qword ptr [r12+rcx*8]
    mov rsi,qword ptr [r13+rcx*8]
    push rcx
    call bi_eq_u64
    pop rcx
    test eax,eax
    jne .Lep_next
    inc rbx
.Lep_next:
    inc rcx
    jmp .Lep_loop
.Lep_done:
    mov rax,rbx
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
    je .Lrls_fail
    mov r12,rax
    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lrls_fail
    mov r13,rax
    lea r14,[rax+48]
    mov edi,121
    call bi_from_u64
    test rax,rax
    je .Lrls_fail
    mov rdi,rax
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call legacyPoursToFixedBowlIds
    test rax,rax
    je .Lrls_fail
    mov rdi,r13
    lea rsi,[rip+expected_order_121]
    call equal_order6_u64
    test eax,eax
    je .Lrls_fail
    mov rdi,r14
    lea rsi,[rip+legacy_expected_121]
    call equal_pours_u64
    test rax,rax
    jne .Lrls_fail
    mov rdi,r14
    lea rsi,[rip+normative_expected_121]
    call equal_pours_u64
    cmp rax,2
    jne .Lrls_fail
    mov eax,1
    jmp .Lrls_done
.Lrls_fail:
    xor eax,eax
.Lrls_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type route_mismatches_121,@function
route_mismatches_121:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call make_fixture
    test rax,rax
    je .Lrm121_bad
    mov r12,rax
    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lrm121_bad
    mov r13,rax
    lea r14,[rax+48]
    mov edi,121
    call bi_from_u64
    test rax,rax
    je .Lrm121_bad
    mov rdi,rax
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call monster_pour_route
    test rax,rax
    je .Lrm121_bad
    mov rdi,r13
    lea rsi,[rip+expected_order_121]
    call equal_order6_u64
    test eax,eax
    je .Lrm121_bad
    mov rdi,r14
    lea rsi,[rip+normative_expected_121]
    call equal_pours_u64
    jmp .Lrm121_done
.Lrm121_bad:
    mov rax,-1
.Lrm121_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size route_mismatches_121,.-route_mismatches_121

.type require_identity_coincidence,@function
require_identity_coincidence:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call make_fixture
    test rax,rax
    je .Lric_fail
    mov r12,rax
    mov edi,72
    call arena_alloc
    test rax,rax
    je .Lric_fail
    mov r13,rax
    lea r14,[rax+48]
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Lric_fail
    mov rdi,rax
    mov esi,4
    mov rdx,r12
    lea rcx,[r12+48]
    mov r8,r13
    mov r9,r14
    call monster_pour_route
    test rax,rax
    je .Lric_fail
    mov rdi,r13
    lea rsi,[rip+expected_order_1]
    call equal_order6_u64
    test eax,eax
    je .Lric_fail
    mov rdi,r14
    lea rsi,[rip+normative_expected_1]
    call equal_pours_u64
    test rax,rax
    jne .Lric_fail
    mov eax,1
    jmp .Lric_done
.Lric_fail:
    xor eax,eax
.Lric_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_identity_coincidence,.-require_identity_coincidence

.type _start,@function
_start:
    # Ⲡmain route ⲙⲟⲩⲧⲉ ⲉⲡhandler ⲛStage 18.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    call require_legacy_scar
    test eax,eax
    je .Lpattern

    call require_identity_coincidence
    test eax,eax
    je .Lpattern

    call route_mismatches_121
    cmp rax,2
    je .Lred
    test rax,rax
    je .Lgreen
    jmp .Lpattern

.Lred:
    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall
.Lgreen:
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
    mov edi,18
    syscall
.size _start,.-_start
