.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_DATA,24
.equ ML46_COUNT_BIG,0
.equ ML46_COUNT_U64,8
.equ ML46_TOTAL,16
.equ ML46_SLOTS,24
.equ ML46_ROWS,32
.equ ML46_KIND,40
.equ ML46_ROW_BYTES,48
.equ CTX_STAGE46_YEAR_LENGTH,2016
.equ CTX_STAGE46_MONTH_COUNT,2024
.equ CTX_STAGE46_ROUTE_LIST,2032
.equ CTX_STAGE46_ROUTE_KIND,2040
.equ CTX_STAGE46_ROUTE_COUNT_U64,2048
.equ CTX_STAGE46_ROUTE_ROWS,2056
.equ CTX_STAGE46_FIRST_ROW,2064
.equ CTX_STAGE46_LAST_ROW,2072
.equ CTX_STAGE46_SEEN,2080
.equ CTX_STAGE46_LEGACY_MATERIALIZED,2088

.section .bss
.align 8
first_row: .skip 24
last_row: .skip 24
route_first: .skip 24

.section .rodata
red_token: .ascii "STAGE46_DISCOVERY23_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE46_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE46_DISCOVERY23_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern oldMonthLengthMaterializedList
.extern legacyMonthLengthListCount
.extern legacyMonthLengthListItemAt1
.extern monster_month_length_family_route
.extern stage42LegacyBinomialU64
.extern monster_context_new
.extern monster_stage46_legacy_month_materialization_handler

# eax=1 ⲉϣϫⲉ ⲡdirect legacy scar ⲧⲁⲙⲓⲟ ⲛ10 ⲛrows ⲙⲡfamily total=15,K=3 ⲛlexicographic order.
.type stage46RequireDirectMaterializedScar,@function
stage46RequireDirectMaterializedScar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,15
    mov esi,3
    call oldMonthLengthMaterializedList
    test rax,rax
    je .Ls46rdms_no
    mov r12,rax
    cmp qword ptr [r12+ML46_KIND],1
    jne .Ls46rdms_no
    cmp qword ptr [r12+ML46_COUNT_U64],10
    jne .Ls46rdms_no
    cmp qword ptr [r12+ML46_TOTAL],15
    jne .Ls46rdms_no
    cmp qword ptr [r12+ML46_SLOTS],3
    jne .Ls46rdms_no
    cmp qword ptr [r12+ML46_ROW_BYTES],24
    jne .Ls46rdms_no
    cmp qword ptr [r12+ML46_ROWS],0
    je .Ls46rdms_no
    mov rdi,r12
    call legacyMonthLengthListCount
    test rax,rax
    je .Ls46rdms_no
    cmp qword ptr [rax+BI_SIGN],1
    jne .Ls46rdms_no
    cmp qword ptr [rax+BI_LEN],1
    jne .Ls46rdms_no
    mov rdx,qword ptr [rax+BI_DATA]
    test rdx,rdx
    je .Ls46rdms_no
    cmp qword ptr [rdx],10
    jne .Ls46rdms_no

    mov rdi,r12
    mov esi,1
    lea rdx,[rip+first_row]
    call legacyMonthLengthListItemAt1
    test rax,rax
    je .Ls46rdms_no
    cmp qword ptr [rip+first_row],4
    jne .Ls46rdms_no
    cmp qword ptr [rip+first_row+8],4
    jne .Ls46rdms_no
    cmp qword ptr [rip+first_row+16],7
    jne .Ls46rdms_no

    mov rdi,r12
    mov esi,10
    lea rdx,[rip+last_row]
    call legacyMonthLengthListItemAt1
    test rax,rax
    je .Ls46rdms_no
    cmp qword ptr [rip+last_row],7
    jne .Ls46rdms_no
    cmp qword ptr [rip+last_row+8],4
    jne .Ls46rdms_no
    cmp qword ptr [rip+last_row+16],4
    jne .Ls46rdms_no
    mov eax,1
    jmp .Ls46rdms_done
.Ls46rdms_no:
    xor eax,eax
.Ls46rdms_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage46RequireDirectMaterializedScar,.-stage46RequireDirectMaterializedScar

# eax=1 ⲉϣϫⲉ L=252,K=47 ϯ ⲙⲡexact count C(110,46), ⲉϥⲛⲁⲁⲁ ϩⲁ 64-bit rows.
.type stage46RequireHugeFamilyProof,@function
stage46RequireHugeFamilyProof:
    push rbp
    mov rbp,rsp
    mov edi,110
    mov esi,46
    call stage42LegacyBinomialU64
    test rax,rax
    je .Ls46rhfp_no
    cmp qword ptr [rax+BI_SIGN],1
    jne .Ls46rhfp_no
    cmp qword ptr [rax+BI_LEN],2
    jne .Ls46rhfp_no
    mov rdx,qword ptr [rax+BI_DATA]
    test rdx,rdx
    je .Ls46rhfp_no
    mov rcx,0xd6d1731e3f99a907
    cmp qword ptr [rdx],rcx
    jne .Ls46rhfp_no
    mov rcx,0x0000011f1cb183ca
    cmp qword ptr [rdx+8],rcx
    jne .Ls46rhfp_no
    mov eax,1
    jmp .Ls46rhfp_done
.Ls46rhfp_no:
    xor eax,eax
.Ls46rhfp_done:
    leave
    ret
.size stage46RequireHugeFamilyProof,.-stage46RequireHugeFamilyProof

# eax=0 ⲉϣϫⲉ ⲡroute ⲟ ⲛeager legacy, eax=1 ⲉϣϫⲉ ⲁⲩⲡⲁⲧϣ ⲙⲙⲟϥ ⲉvirtual backend, eax=2 ⲉϣϫⲉ ⲟⲩpattern ⲛϣⲙⲙⲟ.
.type stage46ClassifyRoute,@function
stage46ClassifyRoute:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,15
    mov esi,3
    call monster_month_length_family_route
    test rax,rax
    je .Ls46cr_pattern
    mov r12,rax
    mov rax,qword ptr [r12+ML46_KIND]
    cmp rax,1
    je .Ls46cr_red
    cmp rax,2
    je .Ls46cr_green
    jmp .Ls46cr_pattern
.Ls46cr_red:
    cmp qword ptr [r12+ML46_COUNT_U64],10
    jne .Ls46cr_pattern
    cmp qword ptr [r12+ML46_ROWS],0
    je .Ls46cr_pattern
    xor eax,eax
    jmp .Ls46cr_done
.Ls46cr_green:
    mov eax,1
    jmp .Ls46cr_done
.Ls46cr_pattern:
    mov eax,2
.Ls46cr_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage46ClassifyRoute,.-stage46ClassifyRoute

# eax=1 ⲉϣϫⲉ ⲡStage46 handler ⲁϥⲣϩⲱⲃ ϩⲓ ⲡsmall materialized family.
.type stage46RequireContextTrace,@function
stage46RequireContextTrace:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls46rct_no
    mov r12,rax
    mov rdi,r12
    call monster_stage46_legacy_month_materialization_handler
    cmp eax,1
    jne .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_YEAR_LENGTH],15
    jne .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_MONTH_COUNT],3
    jne .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_ROUTE_KIND],1
    jne .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_ROUTE_COUNT_U64],10
    jne .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_ROUTE_ROWS],0
    je .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_SEEN],1
    jne .Ls46rct_no
    cmp qword ptr [r12+CTX_STAGE46_LEGACY_MATERIALIZED],1
    jne .Ls46rct_no
    mov rax,qword ptr [r12+CTX_STAGE46_FIRST_ROW]
    test rax,rax
    je .Ls46rct_no
    cmp qword ptr [rax],4
    jne .Ls46rct_no
    cmp qword ptr [rax+8],4
    jne .Ls46rct_no
    cmp qword ptr [rax+16],7
    jne .Ls46rct_no
    mov rax,qword ptr [r12+CTX_STAGE46_LAST_ROW]
    test rax,rax
    je .Ls46rct_no
    cmp qword ptr [rax],7
    jne .Ls46rct_no
    cmp qword ptr [rax+8],4
    jne .Ls46rct_no
    cmp qword ptr [rax+16],4
    jne .Ls46rct_no
    mov eax,1
    jmp .Ls46rct_done
.Ls46rct_no:
    xor eax,eax
.Ls46rct_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage46RequireContextTrace,.-stage46RequireContextTrace

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call stage46RequireDirectMaterializedScar
    test eax,eax
    je .Lpattern
    call stage46RequireHugeFamilyProof
    test eax,eax
    je .Lpattern
    call stage46RequireContextTrace
    test eax,eax
    je .Lpattern
    call stage46ClassifyRoute
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
    mov edi,46
    syscall
.size _start,.-_start
