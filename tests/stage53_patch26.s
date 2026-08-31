.intel_syntax noprefix
.equ CTX_STAGE53_DIFF_GHOST_YEAR,2536
.equ CTX_STAGE53_CORRECT_YEAR,2544
.equ CTX_STAGE53_GHOST_SEEN,2552
.equ CTX_STAGE53_PATCH_SEEN,2560
.equ CTX_STAGE53_GHOST_REUSED_EQUAL,2568
.equ CTX_STAGE53_CORRECT_USED_DIFFERENT,2576
.equ CTX_STAGE53_EQUAL_GHOST_YEAR,2584
.equ CTX_STAGE53_EQUAL_ROUTE_YEAR,2592
.equ CTX_STAGE53_SEEN,2600
.equ YJ_NUMBER,0
.equ YJ_OPEN_DAY,8
.equ YJ_CLOSE_DAY,24
.section .rodata
green_token: .ascii "STAGE53_PATCH26_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE53_PATCH26_FAIL\n"
fail_len = . - fail_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern oldYearOwnsClosedInterval
.extern legacyFindYearByClosedIntervalWalk
.extern findYearByHalfOpenIntervalWalkPatch26
.extern yearOwnershipPatch26
.extern monster_year_ownership_route
.extern monster_stage53_year_ownership_patch_handler
.extern bi_eq_u64
.extern bi_cmp

# Ⲡdirect legacy scar ⲟⲩⲏϩ ⲉϥϫⲓ ⲙⲡopening gate ⲉYear 5000.
.type require_live_wrong_scar,@function
require_live_wrong_scar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrlws_no
    mov r12,rax
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call oldYearOwnsClosedInterval
    cmp eax,1
    jne .Lrlws_no
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call legacyFindYearByClosedIntervalWalk
    test rax,rax
    je .Lrlws_no
    mov rdi,rax
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrlws_no
    mov eax,1
    jmp .Lrlws_done
.Lrlws_no:
    xor eax,eax
.Lrlws_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_live_wrong_scar,.-require_live_wrong_scar

# Ⲡopening gate ⲧⲁϫⲣⲟ ϫⲉ ghost=5000, authoritative=4999.
.type require_opening_detour,@function
require_opening_detour:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrod_no
    mov r12,rax
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call yearOwnershipPatch26
    test rax,rax
    je .Lrod_no
    test rdx,rdx
    je .Lrod_no
    cmp r9,1
    jne .Lrod_no
    test r10,r10
    jne .Lrod_no
    mov r13,rax
    mov r14,rcx
    mov rdi,r13
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrod_no
    mov rdi,r14
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrod_no
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call monster_year_ownership_route
    test rax,rax
    je .Lrod_no
    mov rdi,rax
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrod_no
    mov eax,1
    jmp .Lrod_done
.Lrod_no:
    xor eax,eax
.Lrod_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_opening_detour,.-require_opening_detour

# Ⲡclosing gate ⲧⲁϫⲣⲟ ϫⲉ ⲡghost ⲙⲛ ⲡcorrect ⲟⲩⲱⲧ ⲁⲩⲱ ⲡghost ⲕⲧⲟ ⲉⲡout.
.type require_equal_reuse,@function
require_equal_reuse:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,16
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrer_no
    mov r12,rax
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    call yearOwnershipPatch26
    test rax,rax
    je .Lrer_no
    test rdx,rdx
    je .Lrer_no
    cmp r9,1
    jne .Lrer_no
    cmp r10,1
    jne .Lrer_no
    cmp rax,rcx
    jne .Lrer_no
    cmp rdx,r8
    jne .Lrer_no
    mov r13,rax
    mov rdi,r13
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrer_no
    mov eax,1
    jmp .Lrer_done
.Lrer_no:
    xor eax,eax
.Lrer_done:
    add rsp,16
    pop r13
    pop r12
    leave
    ret
.size require_equal_reuse,.-require_equal_reuse

# Ⲡboundary sweep ⲧⲁϫⲣⲟ ⲙⲡ `(open,close]` ownership.
.type require_boundary_semantics,@function
require_boundary_semantics:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrbs_no
    mov r12,rax

    # open -> 4999.
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call findYearByHalfOpenIntervalWalkPatch26
    test rax,rax
    je .Lrbs_no
    mov rdi,rax
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrbs_no

    # close -> 5000.
    mov rdi,r12
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    call findYearByHalfOpenIntervalWalkPatch26
    test rax,rax
    je .Lrbs_no
    mov rdi,rax
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lrbs_no

    mov eax,1
    jmp .Lrbs_done
.Lrbs_no:
    xor eax,eax
.Lrbs_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_boundary_semantics,.-require_boundary_semantics

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
    je .Lrc53_no
    mov r12,rax
    mov rdi,r12
    call monster_stage53_year_ownership_patch_handler
    cmp eax,1
    jne .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_DIFF_GHOST_YEAR],0
    je .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_CORRECT_YEAR],0
    je .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_GHOST_SEEN],1
    jne .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_PATCH_SEEN],2
    jne .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_GHOST_REUSED_EQUAL],1
    jne .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_CORRECT_USED_DIFFERENT],1
    jne .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_EQUAL_GHOST_YEAR],0
    je .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_EQUAL_ROUTE_YEAR],0
    je .Lrc53_no
    cmp qword ptr [r12+CTX_STAGE53_SEEN],1
    jne .Lrc53_no
    mov eax,1
    jmp .Lrc53_done
.Lrc53_no:
    xor eax,eax
.Lrc53_done:
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
    jne .Lfail
    call require_live_wrong_scar
    cmp eax,1
    jne .Lfail
    call require_opening_detour
    cmp eax,1
    jne .Lfail
    call require_equal_reuse
    cmp eax,1
    jne .Lfail
    call require_boundary_semantics
    cmp eax,1
    jne .Lfail
    call require_context
    cmp eax,1
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
    mov edi,53
    syscall
