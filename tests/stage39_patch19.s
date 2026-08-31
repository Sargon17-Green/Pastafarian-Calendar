.intel_syntax noprefix
.equ CTX_STAGE39_CALCULATION_REFRESH,1640
.equ CTX_STAGE39_OPEN_REFRESH,1648
.equ CTX_STAGE39_CLOSE_REFRESH,1656
.equ CTX_STAGE39_LEGACY_STALE_CASES,1664
.equ CTX_STAGE39_SAME_STATE_HIT,1672
.equ CTX_STAGE39_NUMBER_ONLY_KEY_KEPT,1680
.equ CTX_STAGE39_PATCH_SEEN,1688
.equ YJ_NUMBER,0
.equ YJ_OPEN_DAY,8
.equ YJ_CLOSE_DAY,24
.equ L38_CACHE_COUNT,0
.equ L38_CACHE_SLOTS,8
.equ G39_ENTRY_CALC_FP,0
.equ G39_ENTRY_OPEN_GATE,8
.equ G39_ENTRY_CLOSE_GATE,16
.equ G39_ENTRY_VALUE,24

.section .rodata
green_token: .ascii "STAGE39_PATCH19_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE39_PATCH19_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage39_year_cache_guard_patch_handler
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern stage38NewLegacyYearCache
.extern stage38YearVariant
.extern legacyYearNumberOnlyCacheGetOrPut
.extern monster_year_cache_route
.extern stage39GuardedCollisionCase
.extern bi_from_i64
.extern bi_from_u64
.extern bi_cmp
.extern bi_eq_u64

# Ⲡlegacy scar ⲟⲩⲏϩ keyed ⲙⲙⲁⲧⲉ ⲕⲁⲧⲁ year.number.
.type require_legacy_scar_still_stale,@function
require_legacy_scar_still_stale:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrls_no
    mov r12,rax
    call stage38NewLegacyYearCache
    test rax,rax
    je .Lrls_no
    mov r13,rax
    mov edi,111
    call bi_from_u64
    test rax,rax
    je .Lrls_no
    mov r14,rax
    mov edi,222
    call bi_from_u64
    test rax,rax
    je .Lrls_no
    mov r15,rax
    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_NUMBER]
    mov rdx,r14
    call legacyYearNumberOnlyCacheGetOrPut
    test rax,rax
    je .Lrls_no
    test rdx,rdx
    jne .Lrls_no
    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_NUMBER]
    mov rdx,r15
    call legacyYearNumberOnlyCacheGetOrPut
    test rax,rax
    je .Lrls_no
    cmp rdx,1
    jne .Lrls_no
    mov rdi,rax
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lrls_no
    mov eax,1
    jmp .Lrls_done
.Lrls_no:
    xor eax,eax
.Lrls_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_legacy_scar_still_stale,.-require_legacy_scar_still_stale

# Ⲡmap key ⲟⲩⲏϩ year.number ⲙⲙⲁⲧⲉ; ⲡvalue ⲧⲉⲛⲟⲩ ⲟ ⲛ4-field guarded entry.
.type require_guarded_entry_shape_and_hit,@function
require_guarded_entry_shape_and_hit:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrges_no
    mov r12,rax
    call stage38NewLegacyYearCache
    test rax,rax
    je .Lrges_no
    mov r13,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lrges_no
    mov r14,rax
    mov rdi,r13
    mov rsi,r12
    mov rdx,r14
    call monster_year_cache_route
    test rax,rax
    je .Lrges_no
    mov r15,rax
    mov qword ptr [rbp-40],rdx
    test rcx,rcx
    jne .Lrges_no
    test r8,r8
    jne .Lrges_no
    mov rdi,r15
    mov rsi,qword ptr [rbp-40]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    cmp qword ptr [r13+L38_CACHE_COUNT],1
    jne .Lrges_no
    mov rdi,qword ptr [r13+L38_CACHE_SLOTS]
    mov rsi,qword ptr [r12+YJ_NUMBER]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov r15,qword ptr [r13+L38_CACHE_SLOTS+8]
    test r15,r15
    je .Lrges_no
    mov rax,qword ptr [rbp-40]
    cmp r15,rax
    je .Lrges_no
    mov rdi,qword ptr [r15+G39_ENTRY_CALC_FP]
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov rdi,qword ptr [r15+G39_ENTRY_OPEN_GATE]
    mov rsi,qword ptr [r12+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov rdi,qword ptr [r15+G39_ENTRY_CLOSE_GATE]
    mov rsi,qword ptr [r12+YJ_CLOSE_DAY]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov rdi,qword ptr [r15+G39_ENTRY_VALUE]
    mov rsi,qword ptr [rbp-40]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov qword ptr [rbp-48],r15

    # Ⲡsame semantic state ⲟⲩⲏϩ ⲛⲟⲩreal HIT.
    mov rdi,r13
    mov rsi,r12
    mov rdx,r14
    call monster_year_cache_route
    test rax,rax
    je .Lrges_no
    cmp rcx,1
    jne .Lrges_no
    test r8,r8
    jne .Lrges_no

    # Ⲟⲩopen-gate mismatch replace ⲙⲙⲁⲧⲉ ⲙⲡvalue pointer; ⲡkey ⲙⲛ ⲡcount ⲟⲩⲏϩ.
    mov rdi,r12
    mov esi,1
    call stage38YearVariant
    test rax,rax
    je .Lrges_no
    mov r15,rax
    mov rdi,r13
    mov rsi,r15
    mov rdx,r14
    call monster_year_cache_route
    test rax,rax
    je .Lrges_no
    test rcx,rcx
    jne .Lrges_no
    cmp r8,1
    jne .Lrges_no
    cmp qword ptr [r13+L38_CACHE_COUNT],1
    jne .Lrges_no
    mov rdi,qword ptr [r13+L38_CACHE_SLOTS]
    mov rsi,qword ptr [r12+YJ_NUMBER]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov rax,qword ptr [r13+L38_CACHE_SLOTS+8]
    cmp rax,qword ptr [rbp-48]
    je .Lrges_no
    mov rdi,qword ptr [rax+G39_ENTRY_OPEN_GATE]
    mov rsi,qword ptr [r15+YJ_OPEN_DAY]
    call bi_cmp
    test eax,eax
    jne .Lrges_no
    mov eax,1
    jmp .Lrges_done
.Lrges_no:
    xor eax,eax
.Lrges_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_guarded_entry_shape_and_hit,.-require_guarded_entry_shape_and_hit

# Ⲛ3 ⲛguard mismatch ⲧⲏⲣⲟⲩ ⲣ ⲛrefresh, ⲉⲣⲉ ⲡdirect legacy ⲟⲩⲏϩ stale.
.type require_three_guard_refreshes,@function
require_three_guard_refreshes:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,8
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrtgr_no
    mov r12,rax
    mov rdi,-15055671
    call bi_from_i64
    test rax,rax
    je .Lrtgr_no
    mov r13,rax
    mov edx,1
.Lrtgr_loop:
    mov rdi,r12
    mov rsi,r13
    call stage39GuardedCollisionCase
    cmp rax,0
    jne .Lrtgr_no
    cmp rdx,1
    jne .Lrtgr_no
    cmp rcx,1
    jne .Lrtgr_no
    inc edx
    jmp .Lrtgr_mode2
.Lrtgr_mode2:
    mov rdi,r12
    mov rsi,r13
    mov edx,2
    call stage39GuardedCollisionCase
    cmp rax,0
    jne .Lrtgr_no
    cmp rdx,1
    jne .Lrtgr_no
    cmp rcx,1
    jne .Lrtgr_no
    mov rdi,r12
    mov rsi,r13
    mov edx,3
    call stage39GuardedCollisionCase
    cmp rax,0
    jne .Lrtgr_no
    cmp rdx,1
    jne .Lrtgr_no
    cmp rcx,1
    jne .Lrtgr_no
    mov eax,1
    jmp .Lrtgr_done
.Lrtgr_no:
    xor eax,eax
.Lrtgr_done:
    add rsp,8
    pop r13
    pop r12
    leave
    ret
.size require_three_guard_refreshes,.-require_three_guard_refreshes

.type require_context_trace,@function
require_context_trace:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lrct_no
    mov r12,rax
    mov rdi,r12
    call monster_stage39_year_cache_guard_patch_handler
    cmp eax,1
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_CALCULATION_REFRESH],0
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_OPEN_REFRESH],0
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_CLOSE_REFRESH],0
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_LEGACY_STALE_CASES],3
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_SAME_STATE_HIT],1
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_NUMBER_ONLY_KEY_KEPT],1
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE39_PATCH_SEEN],1
    jne .Lrct_no
    mov eax,1
    jmp .Lrct_done
.Lrct_no:
    xor eax,eax
.Lrct_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_context_trace,.-require_context_trace

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call require_legacy_scar_still_stale
    test eax,eax
    je .Lfail
    call require_guarded_entry_shape_and_hit
    test eax,eax
    je .Lfail
    call require_three_guard_refreshes
    test eax,eax
    je .Lfail
    call require_context_trace
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
    mov edi,39
    syscall
.size _start,.-_start
