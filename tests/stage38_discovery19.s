.intel_syntax noprefix
.equ CTX_STAGE38_CACHE_KEY_YEAR,1584
.equ CTX_STAGE38_CALCULATION_STALE,1592
.equ CTX_STAGE38_OPEN_STALE,1600
.equ CTX_STAGE38_CLOSE_STALE,1608
.equ CTX_STAGE38_ROUTE_CASES,1616
.equ CTX_STAGE38_NUMBER_ONLY_KEY,1624
.equ CTX_STAGE38_SEEN,1632
.equ YJ_NUMBER,0

.section .rodata
red_token: .ascii "STAGE38_DISCOVERY19_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE38_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE38_DISCOVERY19_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern stage38NewLegacyYearCache
.extern legacyYearNumberOnlyCacheGetOrPut
.extern monster_stage38_legacy_year_number_cache_handler
.extern bi_from_u64
.extern bi_eq_u64
.extern bi_cmp

# Ⲡdirect scar ⲧⲁϫⲣⲟ ϫⲉ ⲡcache hit ϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡyear.number ⲁⲩⲱ ⲕⲱ ⲙⲡvalue ⲛϣⲟⲣⲡ.
.type require_legacy_number_only_scar,@function
require_legacy_number_only_scar:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Lrlns_no
    mov r12,rax
    call stage38NewLegacyYearCache
    test rax,rax
    je .Lrlns_no
    mov r13,rax
    mov edi,111
    call bi_from_u64
    test rax,rax
    je .Lrlns_no
    mov r14,rax
    mov edi,222
    call bi_from_u64
    test rax,rax
    je .Lrlns_no
    mov r15,rax

    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_NUMBER]
    mov rdx,r14
    call legacyYearNumberOnlyCacheGetOrPut
    test rax,rax
    je .Lrlns_no
    test rdx,rdx
    jne .Lrlns_no
    mov rdi,rax
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lrlns_no

    mov rdi,r13
    mov rsi,qword ptr [r12+YJ_NUMBER]
    mov rdx,r15
    call legacyYearNumberOnlyCacheGetOrPut
    test rax,rax
    je .Lrlns_no
    cmp rdx,1
    jne .Lrlns_no
    mov rdi,rax
    mov rsi,r14
    call bi_cmp
    test eax,eax
    jne .Lrlns_no
    mov rdi,r14
    mov rsi,r15
    call bi_cmp
    test eax,eax
    je .Lrlns_no
    mov eax,1
    jmp .Lrlns_done
.Lrlns_no:
    xor eax,eax
.Lrlns_done:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_legacy_number_only_scar,.-require_legacy_number_only_scar

# Ⲡsemantic mismatch ⲧⲏⲣϥ ⲛⲏⲩ ⲉⲃⲟⲗ ϩⲙ3 ⲛrequest ⲉⲩϣⲟⲃⲉ ϩⲓ calculation/open/close.
.type count_context_mismatches,@function
count_context_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    mov r12,rax
    test r12,r12
    je .Lccm_pattern
    mov rdi,r12
    call monster_stage38_legacy_year_number_cache_handler
    cmp eax,1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE38_ROUTE_CASES],3
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE38_NUMBER_ONLY_KEY],1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE38_SEEN],1
    jne .Lccm_pattern
    mov rdi,qword ptr [r12+CTX_STAGE38_CACHE_KEY_YEAR]
    mov esi,5000
    call bi_eq_u64
    test eax,eax
    je .Lccm_pattern

    mov rax,qword ptr [r12+CTX_STAGE38_CALCULATION_STALE]
    cmp rax,1
    ja .Lccm_pattern
    mov rcx,qword ptr [r12+CTX_STAGE38_OPEN_STALE]
    cmp rcx,1
    ja .Lccm_pattern
    add rax,rcx
    mov rcx,qword ptr [r12+CTX_STAGE38_CLOSE_STALE]
    cmp rcx,1
    ja .Lccm_pattern
    add rax,rcx
    jmp .Lccm_done
.Lccm_pattern:
    mov rax,-1
.Lccm_done:
    add rsp,8
    pop r12
    leave
    ret
.size count_context_mismatches,.-count_context_mismatches

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call require_legacy_number_only_scar
    test eax,eax
    je .Lpattern
    call count_context_mismatches
    cmp rax,-1
    je .Lpattern
    cmp rax,3
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
    mov edi,38
    syscall
.size _start,.-_start
