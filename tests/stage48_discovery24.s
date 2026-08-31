.intel_syntax noprefix
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_DATA,24
.equ CTX_STAGE48_MONTH_COUNT,2176
.equ CTX_STAGE48_LENGTHS,2184
.equ CTX_STAGE48_ANSWER_STREAM,2192
.equ CTX_STAGE48_WANTED_RANK,2200
.equ CTX_STAGE48_DIRECT_GHOST,2208
.equ CTX_STAGE48_ROUTE_WEAVE,2216
.equ CTX_STAGE48_LEGACY_SEEN,2224
.equ CTX_STAGE48_ROUTE_SEEN,2232
.equ CTX_STAGE48_SEEN,2240

.section .bss
.align 8
direct_row: .skip 64
route_row: .skip 64

.section .rodata
.align 8
witness_lengths: .quad 4,4
witness_answers: .quad 2
red_token: .ascii "STAGE48_DISCOVERY24_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE48_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE48_DISCOVERY24_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern oldMonthWeavingEachDaySeparately
.extern legacyChooseEachDaySeparately
.extern monster_month_weaving_route
.extern monster_context_new
.extern monster_stage48_legacy_daily_month_weaving_handler
.extern bi_from_u64

# eax=1 ⲉϣϫⲉ ⲡdirect scar ϯ ⲙⲡdaily row ⲉⲧⲕⲱ ⲙⲡmultiplicity ⲁⲗⲗⲁ ⲉϥϣⲟⲃⲉ ⲙⲛ ⲡrank-1 legal weave.
.type stage48RequireDirectDailyScar,@function
stage48RequireDirectDailyScar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls48rdds_no
    mov r12,rax
    lea rdi,[rip+witness_lengths]
    mov esi,2
    lea rdx,[rip+witness_answers]
    mov ecx,1
    mov r8,r12
    lea r9,[rip+direct_row]
    call legacyChooseEachDaySeparately
    test rax,rax
    je .Ls48rdds_no
    lea rdx,[rip+direct_row]
    xor ecx,ecx
.Ls48rdds_twos:
    cmp ecx,4
    jae .Ls48rdds_ones_start
    cmp qword ptr [rdx+rcx*8],2
    jne .Ls48rdds_no
    inc ecx
    jmp .Ls48rdds_twos
.Ls48rdds_ones_start:
    mov ecx,4
.Ls48rdds_ones:
    cmp ecx,8
    jae .Ls48rdds_yes
    cmp qword ptr [rdx+rcx*8],1
    jne .Ls48rdds_no
    inc ecx
    jmp .Ls48rdds_ones
.Ls48rdds_yes:
    mov eax,1
    jmp .Ls48rdds_done
.Ls48rdds_no:
    xor eax,eax
.Ls48rdds_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage48RequireDirectDailyScar,.-stage48RequireDirectDailyScar

# eax=0 legacy RED; eax=1 patched legal rank-1 GREEN; eax=2 ⲟⲩpattern ⲛϣⲙⲙⲟ.
.type stage48ClassifyRoute,@function
stage48ClassifyRoute:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls48cr_pattern
    mov r12,rax
    lea rdi,[rip+witness_lengths]
    mov esi,2
    lea rdx,[rip+witness_answers]
    mov ecx,1
    mov r8,r12
    lea r9,[rip+route_row]
    call monster_month_weaving_route
    test rax,rax
    je .Ls48cr_pattern
    lea rdx,[rip+route_row]

    # Ⲡlegacy witness: 2,2,2,2,1,1,1,1.
    xor ecx,ecx
.Ls48cr_bad_twos:
    cmp ecx,4
    jae .Ls48cr_bad_ones_start
    cmp qword ptr [rdx+rcx*8],2
    jne .Ls48cr_try_green
    inc ecx
    jmp .Ls48cr_bad_twos
.Ls48cr_bad_ones_start:
    mov ecx,4
.Ls48cr_bad_ones:
    cmp ecx,8
    jae .Ls48cr_red
    cmp qword ptr [rdx+rcx*8],1
    jne .Ls48cr_try_green
    inc ecx
    jmp .Ls48cr_bad_ones
.Ls48cr_red:
    xor eax,eax
    jmp .Ls48cr_done

.Ls48cr_try_green:
    # Ⲡrank-1 legal weave ⲙⲡ[4,4]: 1,1,1,1,2,2,2,2.
    xor ecx,ecx
.Ls48cr_good_ones:
    cmp ecx,4
    jae .Ls48cr_good_twos_start
    cmp qword ptr [rdx+rcx*8],1
    jne .Ls48cr_pattern
    inc ecx
    jmp .Ls48cr_good_ones
.Ls48cr_good_twos_start:
    mov ecx,4
.Ls48cr_good_twos:
    cmp ecx,8
    jae .Ls48cr_green
    cmp qword ptr [rdx+rcx*8],2
    jne .Ls48cr_pattern
    inc ecx
    jmp .Ls48cr_good_twos
.Ls48cr_green:
    mov eax,1
    jmp .Ls48cr_done
.Ls48cr_pattern:
    mov eax,2
.Ls48cr_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage48ClassifyRoute,.-stage48ClassifyRoute

# eax=1 ⲉϣϫⲉ ⲡhandler ϩⲁⲣⲉϩ ⲉⲡlive direct ghost ⲙⲛ ⲡroute ϩⲙ invocation-local context.
.type stage48RequireContextTrace,@function
stage48RequireContextTrace:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls48rct_no
    mov r12,rax
    mov rdi,r12
    call monster_stage48_legacy_daily_month_weaving_handler
    cmp eax,1
    jne .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_MONTH_COUNT],2
    jne .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_LENGTHS],0
    je .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_ANSWER_STREAM],0
    je .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_WANTED_RANK],0
    je .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_DIRECT_GHOST],0
    je .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_ROUTE_WEAVE],0
    je .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_LEGACY_SEEN],1
    jne .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_ROUTE_SEEN],1
    jne .Ls48rct_no
    cmp qword ptr [r12+CTX_STAGE48_SEEN],1
    jne .Ls48rct_no
    mov rax,qword ptr [r12+CTX_STAGE48_DIRECT_GHOST]
    cmp qword ptr [rax],2
    jne .Ls48rct_no
    cmp qword ptr [rax+56],1
    jne .Ls48rct_no
    mov eax,1
    jmp .Ls48rct_done
.Ls48rct_no:
    xor eax,eax
.Ls48rct_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage48RequireContextTrace,.-stage48RequireContextTrace

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call stage48RequireDirectDailyScar
    cmp eax,1
    jne .Lpattern
    call stage48RequireContextTrace
    cmp eax,1
    jne .Lpattern
    call stage48ClassifyRoute
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
    mov edi,48
    syscall
.size _start,.-_start
