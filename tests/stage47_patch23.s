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
.equ ML47_RESIDUAL,56
.equ ML47_STRIDE,64
.equ ML47_DP_TABLE,72
.equ ML47_GHOST_LIST,80
.equ ML47_GHOST_SEEN,88
.equ ML47_GHOST_SKIPPED,96
.equ CTX_STAGE47_ROUTE_LIST,2096
.equ CTX_STAGE47_ROUTE_KIND,2104
.equ CTX_STAGE47_COUNT_BIG,2112
.equ CTX_STAGE47_ROUTE_ROWS,2120
.equ CTX_STAGE47_FIRST_ROW,2128
.equ CTX_STAGE47_LAST_ROW,2136
.equ CTX_STAGE47_GHOST_LIST,2144
.equ CTX_STAGE47_GHOST_SEEN,2152
.equ CTX_STAGE47_PATCH_SEEN,2160
.equ CTX_STAGE47_SEEN,2168

.section .bss
.align 8
small_first: .skip 24
small_mid: .skip 24
ghost_mid: .skip 24
huge_first: .skip 376

.section .rodata
green_token: .ascii "STAGE47_PATCH23_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE47_PATCH23_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern oldMonthLengthMaterializedList
.extern legacyMonthLengthListItemAt1
.extern monster_month_length_family_route
.extern virtualMonthLengthListCount
.extern virtualMonthLengthListItemAt1
.extern virtualMonthLengthListItemAt1Big
.extern monster_context_new
.extern monster_stage47_virtual_month_length_patch_handler
.extern bi_from_u64

# eax=1 ⲉϣϫⲉ ⲡsmall route ⲟ ⲛvirtual, ⲡlegacy ghost ⲣϩⲱⲃ, ⲁⲩⲱ ⲡunrank ⲧⲱⲛ ⲙⲛ ⲡlexicographic family.
.type stage47RequireSmallVirtual,@function
stage47RequireSmallVirtual:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov edi,15
    mov esi,3
    call monster_month_length_family_route
    test rax,rax
    je .Ls47rsv_no
    mov r12,rax
    cmp qword ptr [r12+ML46_KIND],2
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML46_COUNT_U64],10
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML46_TOTAL],15
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML46_SLOTS],3
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML46_ROWS],0
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML46_ROW_BYTES],24
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML47_RESIDUAL],3
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML47_STRIDE],4
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML47_DP_TABLE],0
    je .Ls47rsv_no
    cmp qword ptr [r12+ML47_GHOST_SEEN],1
    jne .Ls47rsv_no
    cmp qword ptr [r12+ML47_GHOST_SKIPPED],0
    jne .Ls47rsv_no
    mov r13,qword ptr [r12+ML47_GHOST_LIST]
    test r13,r13
    je .Ls47rsv_no
    cmp qword ptr [r13+ML46_KIND],1
    jne .Ls47rsv_no
    cmp qword ptr [r13+ML46_COUNT_U64],10
    jne .Ls47rsv_no
    cmp qword ptr [r13+ML46_ROWS],0
    je .Ls47rsv_no

    mov rdi,r12
    call virtualMonthLengthListCount
    test rax,rax
    je .Ls47rsv_no
    cmp qword ptr [rax+BI_SIGN],1
    jne .Ls47rsv_no
    cmp qword ptr [rax+BI_LEN],1
    jne .Ls47rsv_no
    mov rdx,qword ptr [rax+BI_DATA]
    test rdx,rdx
    je .Ls47rsv_no
    cmp qword ptr [rdx],10
    jne .Ls47rsv_no

    mov rdi,r12
    mov esi,1
    lea rdx,[rip+small_first]
    call virtualMonthLengthListItemAt1
    test rax,rax
    je .Ls47rsv_no
    cmp qword ptr [rip+small_first],4
    jne .Ls47rsv_no
    cmp qword ptr [rip+small_first+8],4
    jne .Ls47rsv_no
    cmp qword ptr [rip+small_first+16],7
    jne .Ls47rsv_no

    mov edi,5
    call bi_from_u64
    test rax,rax
    je .Ls47rsv_no
    mov r14,rax
    mov rdi,r12
    mov rsi,r14
    lea rdx,[rip+small_mid]
    call virtualMonthLengthListItemAt1Big
    test rax,rax
    je .Ls47rsv_no
    cmp qword ptr [rip+small_mid],5
    jne .Ls47rsv_no
    cmp qword ptr [rip+small_mid+8],4
    jne .Ls47rsv_no
    cmp qword ptr [rip+small_mid+16],6
    jne .Ls47rsv_no

    mov rdi,r13
    mov esi,5
    lea rdx,[rip+ghost_mid]
    call legacyMonthLengthListItemAt1
    test rax,rax
    je .Ls47rsv_no
    mov rax,qword ptr [rip+ghost_mid]
    cmp rax,qword ptr [rip+small_mid]
    jne .Ls47rsv_no
    mov rax,qword ptr [rip+ghost_mid+8]
    cmp rax,qword ptr [rip+small_mid+8]
    jne .Ls47rsv_no
    mov rax,qword ptr [rip+ghost_mid+16]
    cmp rax,qword ptr [rip+small_mid+16]
    jne .Ls47rsv_no
    mov eax,1
    jmp .Ls47rsv_done
.Ls47rsv_no:
    xor eax,eax
.Ls47rsv_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage47RequireSmallVirtual,.-stage47RequireSmallVirtual

# eax=1 ⲉϣϫⲉ ⲡhuge family ⲟ ⲛvirtual without rows ⲁⲩⲱ ⲡrank 1 ⲟ ⲛexact.
.type stage47RequireHugeVirtual,@function
stage47RequireHugeVirtual:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,16
    mov edi,252
    mov esi,47
    call monster_month_length_family_route
    test rax,rax
    je .Ls47rhv_no
    mov r12,rax
    cmp qword ptr [r12+ML46_KIND],2
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML46_ROWS],0
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML46_COUNT_U64],0
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML47_RESIDUAL],64
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML47_STRIDE],65
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML47_GHOST_LIST],0
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML47_GHOST_SEEN],0
    jne .Ls47rhv_no
    cmp qword ptr [r12+ML47_GHOST_SKIPPED],1
    jne .Ls47rhv_no
    mov r13,qword ptr [r12+ML46_COUNT_BIG]
    test r13,r13
    je .Ls47rhv_no
    cmp qword ptr [r13+BI_SIGN],1
    jne .Ls47rhv_no
    cmp qword ptr [r13+BI_LEN],2
    jne .Ls47rhv_no
    mov rdx,qword ptr [r13+BI_DATA]
    test rdx,rdx
    je .Ls47rhv_no
    mov rcx,0xd6d1731e3f99a907
    cmp qword ptr [rdx],rcx
    jne .Ls47rhv_no
    mov rcx,0x0000011f1cb183ca
    cmp qword ptr [rdx+8],rcx
    jne .Ls47rhv_no

    mov rdi,r12
    mov esi,1
    lea rdx,[rip+huge_first]
    call virtualMonthLengthListItemAt1
    test rax,rax
    je .Ls47rhv_no
    lea r13,[rip+huge_first]
    xor ecx,ecx
.Ls47rhv_prefix:
    cmp ecx,46
    jae .Ls47rhv_last
    cmp qword ptr [r13+rcx*8],4
    jne .Ls47rhv_no
    inc ecx
    jmp .Ls47rhv_prefix
.Ls47rhv_last:
    cmp qword ptr [rip+huge_first+368],68
    jne .Ls47rhv_no
    mov eax,1
    jmp .Ls47rhv_done
.Ls47rhv_no:
    xor eax,eax
.Ls47rhv_done:
    add rsp,16
    pop r13
    pop r12
    leave
    ret
.size stage47RequireHugeVirtual,.-stage47RequireHugeVirtual

# eax=1 ⲉϣϫⲉ ⲡStage47 handler ⲕⲱ ⲙⲡvirtual route ⲙⲛ ⲡsmall ghost ϩⲙⲡcontext.
.type stage47RequireContext,@function
stage47RequireContext:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls47rc_no
    mov r12,rax
    mov rdi,r12
    call monster_stage47_virtual_month_length_patch_handler
    cmp eax,1
    jne .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_ROUTE_KIND],2
    jne .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_ROUTE_ROWS],0
    jne .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_GHOST_SEEN],1
    jne .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_PATCH_SEEN],1
    jne .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_SEEN],1
    jne .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_ROUTE_LIST],0
    je .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_COUNT_BIG],0
    je .Ls47rc_no
    cmp qword ptr [r12+CTX_STAGE47_GHOST_LIST],0
    je .Ls47rc_no
    mov rax,qword ptr [r12+CTX_STAGE47_FIRST_ROW]
    test rax,rax
    je .Ls47rc_no
    cmp qword ptr [rax],4
    jne .Ls47rc_no
    cmp qword ptr [rax+8],4
    jne .Ls47rc_no
    cmp qword ptr [rax+16],7
    jne .Ls47rc_no
    mov rax,qword ptr [r12+CTX_STAGE47_LAST_ROW]
    test rax,rax
    je .Ls47rc_no
    cmp qword ptr [rax],7
    jne .Ls47rc_no
    cmp qword ptr [rax+8],4
    jne .Ls47rc_no
    cmp qword ptr [rax+16],4
    jne .Ls47rc_no
    mov eax,1
    jmp .Ls47rc_done
.Ls47rc_no:
    xor eax,eax
.Ls47rc_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage47RequireContext,.-stage47RequireContext

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call stage47RequireSmallVirtual
    test eax,eax
    je .Lfail
    call stage47RequireHugeVirtual
    test eax,eax
    je .Lfail
    call stage47RequireContext
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
    mov edi,47
    syscall
.size _start,.-_start
