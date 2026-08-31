.intel_syntax noprefix
.equ CTX_STAGE52_ANCHOR,2472
.equ CTX_STAGE52_TARGET_DAY,2480
.equ CTX_STAGE52_DIRECT_OWNS,2488
.equ CTX_STAGE52_ROUTE_YEAR,2496
.equ CTX_STAGE52_CORRECT_PREVIOUS,2504
.equ CTX_STAGE52_LEGACY_SEEN,2512
.equ CTX_STAGE52_ROUTE_SEEN,2520
.equ CTX_STAGE52_SEEN,2528
.equ YJ_NUMBER,0
.equ YJ_OPEN_DAY,8
.equ YJ_CLOSE_DAY,24
.section .rodata
red_token: .ascii "STAGE52_DISCOVERY26_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE52_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE52_DISCOVERY26_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern oldYearOwnsClosedInterval
.extern legacyFindYearByClosedIntervalWalk
.extern monster_year_ownership_route
.extern monster_stage52_legacy_opening_gate_owner_handler
.extern patchedPreviousYear
.extern bi_eq_u64
.extern bi_cmp

.type require_direct_scar,@function
require_direct_scar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrds_no
    mov r12,rax
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call oldYearOwnsClosedInterval
    cmp eax,1
    jne .Lrds_no
    mov eax,1
    jmp .Lrds_done
.Lrds_no:
    xor eax,eax
.Lrds_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_direct_scar,.-require_direct_scar

# eax=0 ⲡlegacy RED (5000); eax=1 ⲡpatched GREEN (4999); eax=2 ⲟⲩpattern ⲛϣⲙⲙⲟ.
.type classify_route,@function
classify_route:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lcr_pattern
    mov r12,rax
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call monster_year_ownership_route
    test rax,rax
    je .Lcr_pattern
    mov rdi,rax
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    jne .Lcr_red
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call monster_year_ownership_route
    test rax,rax
    je .Lcr_pattern
    mov rdi,rax
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    jne .Lcr_green
.Lcr_pattern:
    mov eax,2
    jmp .Lcr_done
.Lcr_red:
    xor eax,eax
    jmp .Lcr_done
.Lcr_green:
    mov eax,1
.Lcr_done:
    add rsp,8
    pop r12
    leave
    ret
.size classify_route,.-classify_route

.type require_previous_reference,@function
require_previous_reference:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrpr_no
    mov r12,rax
    mov rdi,r12
    call patchedPreviousYear
    test rax,rax
    je .Lrpr_no
    mov r13,rax
    mov rdi,qword ptr [r13+YJ_NUMBER]
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrpr_no
    mov rdi,qword ptr [r13+YJ_CLOSE_DAY]
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jne .Lrpr_no
    mov eax,1
    jmp .Lrpr_done
.Lrpr_no:
    xor eax,eax
.Lrpr_done:
    pop r13
    pop r12
    leave
    ret
.size require_previous_reference,.-require_previous_reference

.type require_context,@function
require_context:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lrc_no
    mov r12,rax
    mov rdi,r12
    call monster_stage52_legacy_opening_gate_owner_handler
    cmp eax,1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_ANCHOR],0
    je .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_TARGET_DAY],0
    je .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_DIRECT_OWNS],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_ROUTE_YEAR],0
    je .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_CORRECT_PREVIOUS],0
    je .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_LEGACY_SEEN],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_ROUTE_SEEN],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE52_SEEN],1
    jne .Lrc_no
    mov eax,1
    jmp .Lrc_done
.Lrc_no:
    xor eax,eax
.Lrc_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_context,.-require_context

_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call require_direct_scar
    cmp eax,1
    jne .Lpattern
    call require_previous_reference
    cmp eax,1
    jne .Lpattern
    call require_context
    cmp eax,1
    jne .Lpattern
    call classify_route
    cmp eax,0
    je .Lred
    cmp eax,1
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
    mov edi,52
    syscall
