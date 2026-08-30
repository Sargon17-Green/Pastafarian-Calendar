.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE32_DISCOVERY16_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE32_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE32_DISCOVERY16_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern oldYearCandidate
.extern monster_year_candidate_route
.extern calendarDateSpaghetti
.global _start

# Ⲡreference ⲛⲧⲉⲡtest ⲙⲙⲁⲧⲉ ϫⲓ ⲙⲡyear maximum ⲛ5778 ⲕⲁⲧⲁ ⲡscroll.
.type normativeYearCandidateBoundary,@function
normativeYearCandidateBoundary:
    cmp rdi,6
    jb .Lnycb_no
    cmp rsi,252
    jb .Lnycb_no
    cmp rsi,5778
    ja .Lnycb_no
    mov eax,1
    ret
.Lnycb_no:
    xor eax,eax
    ret
.size normativeYearCandidateBoundary,.-normativeYearCandidateBoundary

.type require_legacy_scar,@function
require_legacy_scar:
    mov edi,5
    mov esi,252
    call oldYearCandidate
    test eax,eax
    jne .Lrls_fail
    mov edi,6
    mov esi,251
    call oldYearCandidate
    test eax,eax
    jne .Lrls_fail
    mov edi,6
    mov esi,252
    call oldYearCandidate
    cmp eax,1
    jne .Lrls_fail
    mov edi,6
    mov esi,5778
    call oldYearCandidate
    cmp eax,1
    jne .Lrls_fail
    mov edi,6
    mov esi,5779
    call oldYearCandidate
    cmp eax,1
    jne .Lrls_fail
    mov edi,6
    mov esi,5780
    call oldYearCandidate
    cmp eax,1
    jne .Lrls_fail
    mov edi,6
    mov esi,5781
    call oldYearCandidate
    cmp eax,1
    jne .Lrls_fail
    mov edi,6
    mov esi,5782
    call oldYearCandidate
    test eax,eax
    jne .Lrls_fail
    mov eax,1
    ret
.Lrls_fail:
    xor eax,eax
    ret
.size require_legacy_scar,.-require_legacy_scar

.type compare_one,@function
compare_one:
    # rdi=gaps, rsi=length; return 1 mismatch, 0 match.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call monster_year_candidate_route
    mov r8d,eax
    mov rdi,r12
    mov rsi,r13
    call normativeYearCandidateBoundary
    cmp r8d,eax
    setne al
    movzx eax,al
    pop r13
    pop r12
    leave
    ret
.size compare_one,.-compare_one

.type count_boundary_mismatches,@function
count_boundary_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    xor r12d,r12d
    mov edi,6
    mov esi,251
    call compare_one
    add r12,rax
    mov edi,6
    mov esi,252
    call compare_one
    add r12,rax
    mov edi,6
    mov esi,5778
    call compare_one
    add r12,rax
    mov edi,6
    mov esi,5779
    call compare_one
    add r12,rax
    mov edi,6
    mov esi,5780
    call compare_one
    add r12,rax
    mov edi,6
    mov esi,5781
    call compare_one
    add r12,rax
    mov edi,6
    mov esi,5782
    call compare_one
    add r12,rax
    mov rax,r12
    pop r12
    leave
    ret
.size count_boundary_mismatches,.-count_boundary_mismatches

.type _start,@function
_start:
    # Ⲡhandler ⲙⲡStage 32 ⲙⲟⲟϣⲉ ϩⲙⲡmain route.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    call require_legacy_scar
    test eax,eax
    je .Lpattern

    call count_boundary_mismatches
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
    mov edi,32
    syscall
.size _start,.-_start
