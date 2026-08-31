.intel_syntax noprefix
.equ CTX_STAGE51_GHOST_VALUE,2400
.equ CTX_STAGE51_CORRECT_VALUE,2408
.equ CTX_STAGE51_GHOST_SEEN,2416
.equ CTX_STAGE51_PATCH_SEEN,2424
.equ CTX_STAGE51_GHOST_REUSED_EQUAL,2432
.equ CTX_STAGE51_CORRECT_USED_DIFFERENT,2440
.equ CTX_STAGE51_EQUAL_GHOST,2448
.equ CTX_STAGE51_EQUAL_ROUTE,2456
.equ CTX_STAGE51_SEEN,2464
.section .rodata
.align 8
diff_weave: .quad 1,2,1,2,1,2
equal_weave: .quad 1,1,1,2,2,2
v3_weave: .quad 1,2,3,1,2,3,1,2,3
green_token: .ascii "STAGE51_PATCH25_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE51_PATCH25_FAIL\n"
fail_len = . - fail_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern oldContiguousMonthDayGuess
.extern monster_day_in_month_route
.extern monster_context_new
.extern monster_stage51_day_in_month_patch_handler

.type require_diff,@function
require_diff:
    lea rdi,[rip+diff_weave]
    mov esi,6
    mov edx,1000
    mov ecx,1004
    call monster_day_in_month_route
    cmp rax,3
    jne .Lrd_no
    cmp rdx,5
    jne .Lrd_no
    cmp rcx,1
    jne .Lrd_no
    cmp r8,0
    jne .Lrd_no
    mov eax,1
    ret
.Lrd_no:
    xor eax,eax
    ret
.size require_diff,.-require_diff

.type require_equal,@function
require_equal:
    lea rdi,[rip+equal_weave]
    mov esi,6
    mov edx,2000
    mov ecx,2002
    call monster_day_in_month_route
    cmp rax,3
    jne .Lre_no
    cmp rdx,3
    jne .Lre_no
    cmp rcx,1
    jne .Lre_no
    cmp r8,1
    jne .Lre_no
    mov eax,1
    ret
.Lre_no:
    xor eax,eax
    ret
.size require_equal,.-require_equal

# Ⲡvector ⲙⲛ three separated threads: target positions 6,7,8 ⲧⲁϫⲣⲟ 2,3,3.
.type require_vectors,@function
require_vectors:
    lea rdi,[rip+v3_weave]
    mov esi,9
    mov edx,3000
    mov ecx,3005
    call monster_day_in_month_route
    cmp rax,2
    jne .Lrv_no
    lea rdi,[rip+v3_weave]
    mov esi,9
    mov edx,3000
    mov ecx,3006
    call monster_day_in_month_route
    cmp rax,3
    jne .Lrv_no
    lea rdi,[rip+v3_weave]
    mov esi,9
    mov edx,3000
    mov ecx,3007
    call monster_day_in_month_route
    cmp rax,3
    jne .Lrv_no
    mov eax,1
    ret
.Lrv_no:
    xor eax,eax
    ret
.size require_vectors,.-require_vectors

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
    call monster_stage51_day_in_month_patch_handler
    cmp eax,1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_GHOST_VALUE],5
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_CORRECT_VALUE],3
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_GHOST_SEEN],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_PATCH_SEEN],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_GHOST_REUSED_EQUAL],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_CORRECT_USED_DIFFERENT],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_EQUAL_GHOST],3
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_EQUAL_ROUTE],3
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE51_SEEN],1
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
    jne .Lfail
    mov edi,1000
    mov esi,1004
    call oldContiguousMonthDayGuess
    cmp rax,5
    jne .Lfail
    call require_diff
    cmp eax,1
    jne .Lfail
    call require_equal
    cmp eax,1
    jne .Lfail
    call require_vectors
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
    mov edi,1
    syscall
