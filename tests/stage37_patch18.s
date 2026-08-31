.intel_syntax noprefix
.equ CTX_STAGE36_LEGACY_GUESS,1472
.equ CTX_STAGE36_ROUTE_GUESS,1480
.equ CTX_STAGE36_GUESS_USED_AS_SEMANTIC,1504
.equ CTX_STAGE37_TELEMETRY_GUESS,1520
.equ CTX_STAGE37_PATCHED_YEAR,1528
.equ CTX_STAGE37_FINAL_YEAR,1536
.equ CTX_STAGE37_FORWARD_STEPS,1544
.equ CTX_STAGE37_BACKWARD_STEPS,1552
.equ CTX_STAGE37_TELEMETRY_ONLY,1560
.equ CTX_STAGE37_PATCH_SEEN,1568
.equ CTX_STAGE37_TARGET_DAY,1576
.equ YJ_NUMBER,0
.equ YJ_OPEN_DAY,8
.equ YJ_FIRST_DAY,16
.equ YJ_CLOSE_DAY,24

.section .rodata
green_token: .ascii "STAGE37_PATCH18_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE37_PATCH18_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern oldJumpGuess
.extern patchedNextYear
.extern patchedPreviousYear
.extern findYearByWalkPatch
.extern monster_year_jump_route
.extern monster_stage36_legacy_year_jump_handler
.extern monster_stage37_year_walk_patch_handler
.extern bi_add_u64
.extern bi_from_u64
.extern bi_sub
.extern bi_eq_u64
.extern bi_cmp

# rdi=Year*, rsi=target. eax=1 ⲉϣϫⲉ open < target <= close.
.type owns_target,@function
owns_target:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Lot_no
    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jle .Lot_no
    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jg .Lot_no
    mov eax,1
    jmp .Lot_done
.Lot_no:
    xor eax,eax
.Lot_done:
    pop r13
    pop r12
    leave
    ret
.size owns_target,.-owns_target

.type require_legacy_telemetry,@function
require_legacy_telemetry:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    mov r12,rax
    test r12,r12
    je .Lrlt_no
    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call oldJumpGuess
    test rax,rax
    je .Lrlt_no
    mov rdi,rax
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lrlt_no
    mov eax,1
    jmp .Lrlt_done
.Lrlt_no:
    xor eax,eax
.Lrlt_done:
    add rsp,8
    pop r13
    pop r12
    leave
    ret
.size require_legacy_telemetry,.-require_legacy_telemetry

.type require_transition_shapes,@function
require_transition_shapes:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    call stage36Year5000JumpAnchorFromPatchedTie
    mov r12,rax
    test r12,r12
    je .Lrts_no

    mov rdi,r12
    call patchedNextYear
    mov r13,rax
    test r13,r13
    je .Lrts_no
    mov rdi,qword ptr [r13+YJ_NUMBER]
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lrts_no
    mov rdi,qword ptr [r13+YJ_OPEN_DAY]
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jne .Lrts_no
    mov rdi,qword ptr [r13+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r13+YJ_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    mov esi,490
    call bi_eq_u64
    test eax,eax
    je .Lrts_no

    mov rdi,r12
    call patchedPreviousYear
    mov r14,rax
    test r14,r14
    je .Lrts_no
    mov rdi,qword ptr [r14+YJ_NUMBER]
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrts_no
    mov rdi,qword ptr [r14+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jne .Lrts_no
    mov rdi,qword ptr [r14+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r14+YJ_OPEN_DAY]
    call bi_sub
    mov rdi,rax
    mov esi,490
    call bi_eq_u64
    test eax,eax
    je .Lrts_no

    mov eax,1
    jmp .Lrts_done
.Lrts_no:
    xor eax,eax
.Lrts_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_transition_shapes,.-require_transition_shapes

# Ⲡwrapper ⲡⲁⲓ ⲧⲁϫⲣⲟ ⲙⲡtarget ownership ⲙⲛ ⲡexact step count.
# rdi=anchor, rsi=target, rdx=expected year, rcx=fwd, r8=back; ⲡtelemetry ⲥⲙⲓⲛⲉ ⲙⲙⲟϥ ϩⲙⲡcaller.
.type require_walk_case_owned,@function
require_walk_case_owned:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov rbx,rsi
    mov r12,rdx
    mov r13,rcx
    mov r14,r8
    call findYearByWalkPatch
    test rax,rax
    je .Lrwco_no
    mov r15,rdx
    cmp rcx,r13
    jne .Lrwco_no
    cmp r8,r14
    jne .Lrwco_no
    mov rdi,rax
    mov rsi,r12
    call bi_eq_u64
    test eax,eax
    je .Lrwco_no
    mov rdi,r15
    mov rsi,rbx
    call owns_target
    test eax,eax
    je .Lrwco_no
    mov eax,1
    jmp .Lrwco_done
.Lrwco_no:
    xor eax,eax
.Lrwco_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size require_walk_case_owned,.-require_walk_case_owned

.type require_zero_one_two_walks,@function
require_zero_one_two_walks:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    call stage36Year5000JumpAnchorFromPatchedTie
    mov r12,rax
    test r12,r12
    je .Lrzot_no

    # 0 step: first+365 ⲟⲩⲏϩ ϩⲙⲡYear 5000.
    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    mov esi,365
    call bi_add_u64
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    mov edx,5000
    xor ecx,ecx
    xor r8d,r8d
    call require_walk_case_owned
    test eax,eax
    je .Lrzot_no

    # +1 transition: close+1 ϣⲟⲟⲡ ⲙⲡYear 5001.
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov esi,1
    call bi_add_u64
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    mov edx,5001
    mov ecx,1
    xor r8d,r8d
    call require_walk_case_owned
    test eax,eax
    je .Lrzot_no

    # +2 transition: close+491 ⲟ ⲙⲛⲛⲥⲁ ⲡnext 490-day interval.
    mov rdi,qword ptr [r12+YJ_CLOSE_DAY]
    mov esi,491
    call bi_add_u64
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    mov edx,5002
    mov ecx,2
    xor r8d,r8d
    call require_walk_case_owned
    test eax,eax
    je .Lrzot_no

    # -1 transition: ⲡopening gate ⲙⲡanchor ϣⲟⲟⲡ ⲙⲡprevious year.
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    mov edx,4999
    xor ecx,ecx
    mov r8d,1
    call require_walk_case_owned
    test eax,eax
    je .Lrzot_no

    # -2 transition: ⲡopening gate ⲙⲡprevious year ϣⲟⲟⲡ ⲙⲡYear 4998.
    mov rdi,490
    call bi_from_u64
    mov rsi,rax
    mov rdi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_sub
    mov r15,rax
    mov rdi,r12
    mov rsi,r15
    mov edx,4998
    xor ecx,ecx
    mov r8d,2
    call require_walk_case_owned
    test eax,eax
    je .Lrzot_no

    mov eax,1
    jmp .Lrzot_done
.Lrzot_no:
    xor eax,eax
.Lrzot_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_zero_one_two_walks,.-require_zero_one_two_walks

.type require_context_patch,@function
require_context_patch:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    mov r12,rax
    test r12,r12
    je .Lrcp_no
    mov rdi,r12
    call monster_stage36_legacy_year_jump_handler
    cmp eax,1
    jne .Lrcp_no
    mov rdi,r12
    call monster_stage37_year_walk_patch_handler
    cmp eax,1
    jne .Lrcp_no
    cmp qword ptr [r12+CTX_STAGE36_GUESS_USED_AS_SEMANTIC],1
    jne .Lrcp_no
    cmp qword ptr [r12+CTX_STAGE37_TELEMETRY_ONLY],1
    jne .Lrcp_no
    cmp qword ptr [r12+CTX_STAGE37_PATCH_SEEN],1
    jne .Lrcp_no
    cmp qword ptr [r12+CTX_STAGE37_FORWARD_STEPS],0
    jne .Lrcp_no
    cmp qword ptr [r12+CTX_STAGE37_BACKWARD_STEPS],0
    jne .Lrcp_no
    mov rdi,qword ptr [r12+CTX_STAGE37_TELEMETRY_GUESS]
    mov esi,5001
    call bi_eq_u64
    test eax,eax
    je .Lrcp_no
    mov rdi,qword ptr [r12+CTX_STAGE37_PATCHED_YEAR]
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrcp_no
    mov eax,1
    jmp .Lrcp_done
.Lrcp_no:
    xor eax,eax
.Lrcp_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_context_patch,.-require_context_patch

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call require_legacy_telemetry
    test eax,eax
    je .Lfail
    call require_transition_shapes
    test eax,eax
    je .Lfail
    call require_zero_one_two_walks
    test eax,eax
    je .Lfail
    call require_context_patch
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
    mov edi,37
    syscall
.size _start,.-_start
