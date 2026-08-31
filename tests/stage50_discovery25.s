.intel_syntax noprefix
.equ CTX_STAGE50_MONTH_COUNT,2328
.equ CTX_STAGE50_RANK,2336
.equ CTX_STAGE50_DIRECT_SUM,2344
.equ CTX_STAGE50_ROUTE_SUM,2352
.equ CTX_STAGE50_LEGACY_SEEN,2360
.equ CTX_STAGE50_ROUTE_SEEN,2368
.equ CTX_STAGE50_SEEN,2376

.section .bss
.align 8
direct_row: .skip 376
correct_row: .skip 376

.section .rodata
red_token: .ascii "STAGE50_DISCOVERY25_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE50_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE50_DISCOVERY25_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage50_legacy_repeated_month_names_handler
.extern oldMonthNameRowWithRepeats
.extern monster_month_names_route

# rdi=row, rsi=K. eax=1 ⲉϣϫⲉ ⲟⲩcanonical index ⲕⲧⲟ ⲛⲕⲉⲥⲟⲡ.
.type stage50HasRepeat,@function
stage50HasRepeat:
    test rdi,rdi
    je .Ls50hr_no
    xor ecx,ecx
.Ls50hr_outer:
    cmp rcx,rsi
    jae .Ls50hr_no
    mov r8,rcx
    inc r8
.Ls50hr_inner:
    cmp r8,rsi
    jae .Ls50hr_next
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rdi+r8*8]
    je .Ls50hr_yes
    inc r8
    jmp .Ls50hr_inner
.Ls50hr_next:
    inc rcx
    jmp .Ls50hr_outer
.Ls50hr_yes:
    mov eax,1
    ret
.Ls50hr_no:
    xor eax,eax
    ret
.size stage50HasRepeat,.-stage50HasRepeat

# rdi=n, rsi=k; rax=P(n,k), 0 ⲉϣϫⲉ ⲟⲩoverflow ϣⲱⲡⲉ.
.type stage50FallingU64,@function
stage50FallingU64:
    test rsi,rsi
    je .Ls50ff_one
    cmp rsi,rdi
    ja .Ls50ff_zero
    mov eax,1
    xor ecx,ecx
.Ls50ff_loop:
    cmp rcx,rsi
    jae .Ls50ff_done
    mov r8,rdi
    sub r8,rcx
    mul r8
    test rdx,rdx
    jne .Ls50ff_zero
    inc rcx
    jmp .Ls50ff_loop
.Ls50ff_one:
    mov eax,1
.Ls50ff_done:
    ret
.Ls50ff_zero:
    xor eax,eax
    ret
.size stage50FallingU64,.-stage50FallingU64

# rdi=rank1, rsi=K, rdx=out. Ⲡreference ⲟ ⲛtest-only ⲁⲩⲱ ϥϫⲓ ⲛ47 canonical names without repeats.
.type stage50CorrectPartialPermutationUnrank47,@function
stage50CorrectPartialPermutationUnrank47:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    test rdi,rdi
    je .Ls50cpu_fail
    test rsi,rsi
    je .Ls50cpu_fail
    cmp rsi,47
    ja .Ls50cpu_fail
    test rdx,rdx
    je .Ls50cpu_fail
    mov r15,rdi
    mov r13,rsi
    mov r14,rdx
    mov edi,47
    mov rsi,r13
    call stage50FallingU64
    test rax,rax
    je .Ls50cpu_fail
    cmp r15,rax
    ja .Ls50cpu_fail
    dec r15
    xor r12d,r12d
    xor ebx,ebx
.Ls50cpu_pos:
    cmp rbx,r13
    jae .Ls50cpu_done
    mov rdi,46
    sub rdi,rbx
    mov rsi,r13
    sub rsi,rbx
    dec rsi
    call stage50FallingU64
    test rax,rax
    je .Ls50cpu_fail
    mov r11,rax
    mov rax,r15
    xor edx,edx
    div r11
    mov r15,rdx
    mov r9,rax
    mov r8,47
    sub r8,rbx
    cmp r9,r8
    jae .Ls50cpu_fail
    mov ecx,1
.Ls50cpu_find:
    cmp ecx,47
    ja .Ls50cpu_fail
    mov rdx,rcx
    dec rdx
    bt r12,rdx
    jc .Ls50cpu_used
    test r9,r9
    je .Ls50cpu_choose
    dec r9
.Ls50cpu_used:
    inc rcx
    jmp .Ls50cpu_find
.Ls50cpu_choose:
    bts r12,rdx
    mov qword ptr [r14+rbx*8],rcx
    inc rbx
    jmp .Ls50cpu_pos
.Ls50cpu_done:
    mov rax,r14
    jmp .Ls50cpu_exit
.Ls50cpu_fail:
    xor eax,eax
.Ls50cpu_exit:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage50CorrectPartialPermutationUnrank47,.-stage50CorrectPartialPermutationUnrank47

# eax=1 ⲉϣϫⲉ ⲡdirect scar ⲟⲩⲏϩ ⲉϥϯ ⲙⲡrepeated rank-1 row.
.type stage50RequireDirectScar,@function
stage50RequireDirectScar:
    push rbp
    mov rbp,rsp
    mov edi,1
    mov esi,6
    lea rdx,[rip+direct_row]
    call oldMonthNameRowWithRepeats
    test rax,rax
    je .Ls50rds_no
    lea r8,[rip+direct_row]
    xor ecx,ecx
.Ls50rds_values:
    cmp ecx,6
    jae .Ls50rds_repeat
    cmp qword ptr [r8+rcx*8],1
    jne .Ls50rds_no
    inc ecx
    jmp .Ls50rds_values
.Ls50rds_repeat:
    lea rdi,[rip+direct_row]
    mov esi,6
    call stage50HasRepeat
    jmp .Ls50rds_done
.Ls50rds_no:
    xor eax,eax
.Ls50rds_done:
    leave
    ret
.size stage50RequireDirectScar,.-stage50RequireDirectScar

# eax=1 ⲉϣϫⲉ ⲡtest-only correct row ⲡⲉ 1..6 ⲁⲩⲱ ⲙⲛ repeat ⲛϩⲏⲧϥ.
.type stage50RequireCorrectReference,@function
stage50RequireCorrectReference:
    push rbp
    mov rbp,rsp
    mov edi,1
    mov esi,6
    lea rdx,[rip+correct_row]
    call stage50CorrectPartialPermutationUnrank47
    test rax,rax
    je .Ls50rcr_no
    lea r8,[rip+correct_row]
    xor ecx,ecx
.Ls50rcr_values:
    cmp ecx,6
    jae .Ls50rcr_distinct
    mov rax,rcx
    inc rax
    cmp qword ptr [r8+rcx*8],rax
    jne .Ls50rcr_no
    inc ecx
    jmp .Ls50rcr_values
.Ls50rcr_distinct:
    lea rdi,[rip+correct_row]
    mov esi,6
    call stage50HasRepeat
    test eax,eax
    sete al
    movzx eax,al
    jmp .Ls50rcr_done
.Ls50rcr_no:
    xor eax,eax
.Ls50rcr_done:
    leave
    ret
.size stage50RequireCorrectReference,.-stage50RequireCorrectReference

# eax=0 ⲡlegacy RED, eax=1 ⲡpatched GREEN, eax=2 ⲟⲩpattern ⲛϣⲙⲙⲟ.
.type stage50ClassifyContextRoute,@function
stage50ClassifyContextRoute:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls50cc_pattern
    mov r12,rax
    mov rdi,r12
    call monster_stage50_legacy_repeated_month_names_handler
    cmp eax,1
    jne .Ls50cc_pattern
    cmp qword ptr [r12+CTX_STAGE50_MONTH_COUNT],6
    jne .Ls50cc_pattern
    cmp qword ptr [r12+CTX_STAGE50_RANK],1
    jne .Ls50cc_pattern
    cmp qword ptr [r12+CTX_STAGE50_DIRECT_SUM],6
    jne .Ls50cc_pattern
    cmp qword ptr [r12+CTX_STAGE50_LEGACY_SEEN],1
    jne .Ls50cc_pattern
    cmp qword ptr [r12+CTX_STAGE50_ROUTE_SEEN],1
    jne .Ls50cc_pattern
    cmp qword ptr [r12+CTX_STAGE50_SEEN],1
    jne .Ls50cc_pattern

    mov edi,1
    mov esi,6
    lea rdx,[rip+direct_row]
    call monster_month_names_route
    test rax,rax
    je .Ls50cc_pattern
    lea r8,[rip+direct_row]
    xor ecx,ecx
.Ls50cc_red_loop:
    cmp ecx,6
    jae .Ls50cc_red
    cmp qword ptr [r8+rcx*8],1
    jne .Ls50cc_green_try
    inc ecx
    jmp .Ls50cc_red_loop
.Ls50cc_green_try:
    xor ecx,ecx
.Ls50cc_green_loop:
    cmp ecx,6
    jae .Ls50cc_green
    mov rax,rcx
    inc rax
    cmp qword ptr [r8+rcx*8],rax
    jne .Ls50cc_pattern
    inc ecx
    jmp .Ls50cc_green_loop
.Ls50cc_red:
    cmp qword ptr [r12+CTX_STAGE50_ROUTE_SUM],6
    jne .Ls50cc_pattern
    xor eax,eax
    jmp .Ls50cc_done
.Ls50cc_green:
    cmp qword ptr [r12+CTX_STAGE50_ROUTE_SUM],21
    jne .Ls50cc_pattern
    mov eax,1
    jmp .Ls50cc_done
.Ls50cc_pattern:
    mov eax,2
.Ls50cc_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage50ClassifyContextRoute,.-stage50ClassifyContextRoute

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call stage50RequireDirectScar
    test eax,eax
    je .Lpattern
    call stage50RequireCorrectReference
    test eax,eax
    je .Lpattern
    call stage50ClassifyContextRoute
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
    mov edi,50
    syscall
.size _start,.-_start
