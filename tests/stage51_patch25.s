.intel_syntax noprefix
.equ CTX_STAGE51_GHOST_SUM,2384
.equ CTX_STAGE51_CORRECT_SUM,2392
.equ CTX_STAGE51_GHOST_SEEN,2400
.equ CTX_STAGE51_PATCH_SEEN,2408
.equ CTX_STAGE51_GHOST_REUSED_EQUAL,2416
.equ CTX_STAGE51_CORRECT_USED_DIFFERENT,2424
.equ CTX_STAGE51_EQUAL_GHOST_SUM,2432
.equ CTX_STAGE51_EQUAL_ROUTE_SUM,2440
.equ CTX_STAGE51_SEEN,2448

.section .bss
.align 8
row_a: .skip 376
row_b: .skip 376
wide_row: .skip 376

.section .rodata
green_token: .ascii "STAGE51_PATCH25_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE51_PATCH25_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage51_month_names_patch_handler
.extern oldMonthNameRowWithRepeats
.extern monster_month_names_route
.extern monthNamesPatch25Big
.extern bi_from_u64
.extern bi_mul_u64
.extern bi_bit_length

# eax=1 ⲉϣϫⲉ ⲡold scar ⲟⲩⲏϩ ⲉϥϯ 1,1,1,1,1,1.
.type stage51RequireOldScar,@function
stage51RequireOldScar:
    push rbp
    mov rbp,rsp
    mov edi,1
    mov esi,6
    lea rdx,[rip+row_a]
    call oldMonthNameRowWithRepeats
    test rax,rax
    je .Ls51ros_no
    lea r8,[rip+row_a]
    xor ecx,ecx
.Ls51ros_loop:
    cmp ecx,6
    jae .Ls51ros_yes
    cmp qword ptr [r8+rcx*8],1
    jne .Ls51ros_no
    inc ecx
    jmp .Ls51ros_loop
.Ls51ros_yes:
    mov eax,1
    jmp .Ls51ros_done
.Ls51ros_no:
    xor eax,eax
.Ls51ros_done:
    leave
    ret
.size stage51RequireOldScar,.-stage51RequireOldScar

# eax=1 ⲉϣϫⲉ rank 1 ⲙⲛ rank 2 ⲥⲉⲟ ⲛlexicographic distinct rows.
.type stage51RequireDifferentRoutes,@function
stage51RequireDifferentRoutes:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,1
    mov esi,6
    lea rdx,[rip+row_a]
    call monster_month_names_route
    test rax,rax
    je .Ls51rdr_no
    cmp r8,6
    jne .Ls51rdr_no
    test rcx,rcx
    jne .Ls51rdr_no
    lea r12,[rip+row_a]
    xor ecx,ecx
.Ls51rdr_rank1:
    cmp ecx,6
    jae .Ls51rdr_rank2_start
    mov rax,rcx
    inc rax
    cmp qword ptr [r12+rcx*8],rax
    jne .Ls51rdr_no
    inc ecx
    jmp .Ls51rdr_rank1
.Ls51rdr_rank2_start:
    mov edi,2
    mov esi,6
    lea rdx,[rip+row_b]
    call monster_month_names_route
    test rax,rax
    je .Ls51rdr_no
    test rcx,rcx
    jne .Ls51rdr_no
    lea r12,[rip+row_b]
    cmp qword ptr [r12],1
    jne .Ls51rdr_no
    cmp qword ptr [r12+8],2
    jne .Ls51rdr_no
    cmp qword ptr [r12+16],3
    jne .Ls51rdr_no
    cmp qword ptr [r12+24],4
    jne .Ls51rdr_no
    cmp qword ptr [r12+32],5
    jne .Ls51rdr_no
    cmp qword ptr [r12+40],7
    jne .Ls51rdr_no
    mov eax,1
    jmp .Ls51rdr_done
.Ls51rdr_no:
    xor eax,eax
.Ls51rdr_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage51RequireDifferentRoutes,.-stage51RequireDifferentRoutes

# eax=1 ⲉϣϫⲉ ⲡnontrivial equal-case ϯ [47,46] ⲁⲩⲱ ⲡghost ⲁⲩreuse ⲙⲙⲟϥ.
.type stage51RequireEqualReuse,@function
stage51RequireEqualReuse:
    push rbp
    mov rbp,rsp
    mov edi,2162
    mov esi,2
    lea rdx,[rip+row_a]
    call monster_month_names_route
    test rax,rax
    je .Ls51rer_no
    cmp rcx,1
    jne .Ls51rer_no
    cmp r8,93
    jne .Ls51rer_no
    lea r9,[rip+row_a]
    cmp qword ptr [r9],47
    jne .Ls51rer_no
    cmp qword ptr [r9+8],46
    jne .Ls51rer_no
    mov eax,1
    jmp .Ls51rer_done
.Ls51rer_no:
    xor eax,eax
.Ls51rer_done:
    leave
    ret
.size stage51RequireEqualReuse,.-stage51RequireEqualReuse

# eax=1 ⲉϣϫⲉ rank=47! ϩⲙ BigInt ϯ ⲙⲡlast lexicographic permutation [47..1].
.type stage51RequireWideRank,@function
stage51RequireWideRank:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls51rwr_no
    mov r12,rax
    mov ebx,47
.Ls51rwr_fact:
    cmp ebx,1
    jbe .Ls51rwr_fact_done
    mov rdi,r12
    mov rsi,rbx
    call bi_mul_u64
    test rax,rax
    je .Ls51rwr_no
    mov r12,rax
    dec ebx
    jmp .Ls51rwr_fact
.Ls51rwr_fact_done:
    mov rdi,r12
    call bi_bit_length
    cmp rax,198
    jne .Ls51rwr_no
    mov rdi,r12
    mov esi,47
    lea rdx,[rip+wide_row]
    call monthNamesPatch25Big
    test rax,rax
    je .Ls51rwr_no
    test rcx,rcx
    jne .Ls51rwr_no
    lea r13,[rip+wide_row]
    xor ebx,ebx
.Ls51rwr_row:
    cmp ebx,47
    jae .Ls51rwr_yes
    mov rax,47
    sub rax,rbx
    cmp qword ptr [r13+rbx*8],rax
    jne .Ls51rwr_no
    inc ebx
    jmp .Ls51rwr_row
.Ls51rwr_yes:
    mov eax,1
    jmp .Ls51rwr_done
.Ls51rwr_no:
    xor eax,eax
.Ls51rwr_done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage51RequireWideRank,.-stage51RequireWideRank

# eax=1 ⲉϣϫⲉ ⲡMonsterContext trace ⲧⲁϫⲣⲟ ⲙⲡghost/detour ⲙⲛ equal reuse.
.type stage51RequireContext,@function
stage51RequireContext:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls51rc_no
    mov r12,rax
    mov rdi,r12
    call monster_stage51_month_names_patch_handler
    cmp eax,1
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_GHOST_SUM],6
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_CORRECT_SUM],21
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_GHOST_SEEN],1
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_PATCH_SEEN],1
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_GHOST_REUSED_EQUAL],1
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_CORRECT_USED_DIFFERENT],1
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_EQUAL_GHOST_SUM],93
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_EQUAL_ROUTE_SUM],93
    jne .Ls51rc_no
    cmp qword ptr [r12+CTX_STAGE51_SEEN],1
    jne .Ls51rc_no
    mov eax,1
    jmp .Ls51rc_done
.Ls51rc_no:
    xor eax,eax
.Ls51rc_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage51RequireContext,.-stage51RequireContext

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call stage51RequireOldScar
    test eax,eax
    je .Lfail
    call stage51RequireDifferentRoutes
    test eax,eax
    je .Lfail
    call stage51RequireEqualReuse
    test eax,eax
    je .Lfail
    call stage51RequireWideRank
    test eax,eax
    je .Lfail
    call stage51RequireContext
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
    mov edi,51
    syscall
.size _start,.-_start
