.intel_syntax noprefix
.equ CTX_STAGE34_YEAR_NUMBER,1376
.equ CTX_STAGE34_TIE_LENGTH,1384
.equ CTX_STAGE34_TIE_COUNT,1392
.equ CTX_STAGE34_LEGACY_SELECTED_OPEN,1400
.equ CTX_STAGE34_ROUTE_SELECTED_OPEN,1408
.equ CTX_STAGE34_LEGACY_SEEN,1416
.equ CTX_STAGE34_ROUTE_SEEN,1424
.equ YC_OPEN,0
.equ YC_CLOSE,8
.equ YC_LENGTH,16
.equ YC_SIZE,24

.section .rodata
red_token: .ascii "STAGE34_DISCOVERY17_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE34_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE34_DISCOVERY17_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token
.align 8
year5000_tie_input:
    .quad 9,15,490
    .quad 3,9,490

.section .bss
.align 16
legacy_sorted: .skip 48
route_sorted: .skip 48
reference_sorted: .skip 48

.section .text
.extern stableLengthOnlyPatchedYearCandidates
.extern legacyYearSelectFirst
.extern legacyYear5000TieSelection
.extern monster_year5000_tie_route
.extern monster_context_new
.extern monster_stage34_legacy_year5000_tie_handler
.extern calendarDateSpaghetti
.global _start

# Ⲡreference ⲛⲧⲉⲡtest: ⲙⲛⲛⲥⲁ ⲡstable length sort, ⲡϣⲟⲣⲡ equal-length run ϫⲓ ⲙⲡopening gate ⲉⲧⲟ ⲛϣⲟⲣⲡ.
.type normativeYear5000TieFirst,@function
normativeYear5000TieFirst:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov rdi,r12
    mov rsi,r13
    mov rdx,r14
    call stableLengthOnlyPatchedYearCandidates
    test rax,rax
    je .Lnyt_no
    mov r15,rax
    mov r8,r14
    mov r9,qword ptr [r8+YC_LENGTH]
    mov r10,qword ptr [r8+YC_OPEN]
    mov r11,r8
    mov rcx,1
.Lnyt_scan:
    cmp rcx,r15
    jae .Lnyt_done
    lea rax,[rcx+rcx*2]
    lea rax,[r14+rax*8]
    cmp qword ptr [rax+YC_LENGTH],r9
    jne .Lnyt_done
    cmp qword ptr [rax+YC_OPEN],r10
    jae .Lnyt_next
    mov r10,qword ptr [rax+YC_OPEN]
    mov r11,rax
.Lnyt_next:
    inc rcx
    jmp .Lnyt_scan
.Lnyt_done:
    mov rax,r11
    jmp .Lnyt_ret
.Lnyt_no:
    xor eax,eax
.Lnyt_ret:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size normativeYear5000TieFirst,.-normativeYear5000TieFirst

.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    lea rdi,[rip+year5000_tie_input]
    mov esi,2
    lea rdx,[rip+legacy_sorted]
    call legacyYear5000TieSelection
    test rax,rax
    je .Lrls_fail
    cmp qword ptr [rax+YC_OPEN],9
    jne .Lrls_fail
    lea r8,[rip+legacy_sorted]
    cmp qword ptr [r8+0],9
    jne .Lrls_fail
    cmp qword ptr [r8+24],3
    jne .Lrls_fail
    cmp qword ptr [r8+16],490
    jne .Lrls_fail
    cmp qword ptr [r8+40],490
    jne .Lrls_fail
    mov eax,1
    leave
    ret
.Lrls_fail:
    xor eax,eax
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type count_route_mismatches,@function
count_route_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    xor r12d,r12d
    lea rdi,[rip+year5000_tie_input]
    mov esi,2
    lea rdx,[rip+reference_sorted]
    call normativeYear5000TieFirst
    mov r13,rax
    test r13,r13
    je .Lcrm_pattern
    cmp qword ptr [r13+YC_OPEN],3
    jne .Lcrm_pattern
    lea rdi,[rip+year5000_tie_input]
    mov esi,2
    lea rdx,[rip+route_sorted]
    call monster_year5000_tie_route
    test rax,rax
    je .Lcrm_pattern
    mov rcx,qword ptr [rax+YC_OPEN]
    cmp rcx,qword ptr [r13+YC_OPEN]
    sete dl
    xor dl,1
    movzx rax,dl
    mov r12,rax
    mov rax,r12
    jmp .Lcrm_done
.Lcrm_pattern:
    mov rax,-1
.Lcrm_done:
    pop r13
    pop r12
    leave
    ret
.size count_route_mismatches,.-count_route_mismatches

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
    call monster_stage34_legacy_year5000_tie_handler
    cmp eax,1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE34_YEAR_NUMBER],5000
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE34_TIE_LENGTH],490
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE34_TIE_COUNT],2
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE34_LEGACY_SELECTED_OPEN],9
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE34_LEGACY_SEEN],1
    jne .Lccm_pattern
    cmp qword ptr [r12+CTX_STAGE34_ROUTE_SEEN],1
    jne .Lccm_pattern
    xor eax,eax
    cmp qword ptr [r12+CTX_STAGE34_ROUTE_SELECTED_OPEN],3
    sete al
    xor al,1
    movzx eax,al
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
    call require_legacy_scar
    test eax,eax
    je .Lpattern
    call count_route_mismatches
    cmp rax,-1
    je .Lpattern
    mov r12,rax
    call count_context_mismatches
    cmp rax,-1
    je .Lpattern
    add r12,rax
    cmp r12,2
    je .Lred
    test r12,r12
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
    mov edi,34
    syscall
.size _start,.-_start
