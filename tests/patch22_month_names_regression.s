.intel_syntax noprefix
.section .bss
.align 8
badrow: .skip 48
goodrow: .skip 48
lastrow: .skip 376
.section .rodata
green_token: .ascii "PATCH22_MONTH_NAMES_CORRECTION_GREEN\n"
green_len = . - green_token
fail_token: .ascii "PATCH22_MONTH_NAMES_CORRECTION_FAIL\n"
fail_len = . - fail_token
.section .text
.global _start
.extern legacyMonthNamesWithRepeats
.extern monster_month_names_route
.extern monster_month_names_route_big
.extern namePatch22FallingBig

.type require_small,@function
require_small:
    push rbp
    mov rbp,rsp
    lea rdx,[rip+badrow]
    mov edi,1
    mov esi,6
    call legacyMonthNamesWithRepeats
    test rax,rax
    je .Lrs_no
    lea r8,[rip+badrow]
    xor ecx,ecx
.Lrs_bad:
    cmp ecx,6
    jae .Lrs_route
    cmp qword ptr [r8+rcx*8],1
    jne .Lrs_no
    inc ecx
    jmp .Lrs_bad
.Lrs_route:
    lea rdx,[rip+goodrow]
    mov edi,1
    mov esi,6
    call monster_month_names_route
    test rax,rax
    je .Lrs_no
    lea r8,[rip+goodrow]
    mov ecx,1
.Lrs_good:
    cmp ecx,7
    jae .Lrs_yes
    mov rax,qword ptr [r8+rcx*8-8]
    cmp rax,rcx
    jne .Lrs_no
    inc ecx
    jmp .Lrs_good
.Lrs_yes:
    mov eax,1
    leave
    ret
.Lrs_no:
    xor eax,eax
    leave
    ret
.size require_small,.-require_small

.type require_wide_last,@function
require_wide_last:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,47
    mov esi,47
    call namePatch22FallingBig
    test rax,rax
    je .Lrwl_no
    mov r12,rax
    mov rdi,r12
    mov esi,47
    lea rdx,[rip+lastrow]
    call monster_month_names_route_big
    test rax,rax
    je .Lrwl_no
    lea r8,[rip+lastrow]
    xor ecx,ecx
.Lrwl_loop:
    cmp ecx,47
    jae .Lrwl_yes
    mov rax,47
    sub rax,rcx
    cmp qword ptr [r8+rcx*8],rax
    jne .Lrwl_no
    inc ecx
    jmp .Lrwl_loop
.Lrwl_yes:
    mov eax,1
    jmp .Lrwl_done
.Lrwl_no:
    xor eax,eax
.Lrwl_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_wide_last,.-require_wide_last

_start:
    call require_small
    cmp eax,1
    jne .Lfail
    call require_wide_last
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
    mov edi,1
    syscall
