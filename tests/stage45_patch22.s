.intel_syntax noprefix
.equ CTX_STAGE45_GHOST_NAMES,1960
.equ CTX_STAGE45_GHOST_SEEN,1968
.equ CTX_STAGE45_PATCH_SEEN,1976
.equ CTX_STAGE45_GHOST_REUSED_EQUAL,1984
.equ CTX_STAGE45_CORRECT_USED_DIFFERENT,1992
.equ CTX_STAGE45_EQUAL_ROUTE_NAMES,2000
.equ CTX_STAGE45_EQUAL_GHOST_NAMES,2008

.section .bss
.align 8
bad_row: .skip 136
route_row: .skip 136
ghost_slot: .skip 8

.section .rodata
green_token: .ascii "STAGE45_PATCH22_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE45_PATCH22_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage45_cutlet_names_patch_handler
.extern oldCutletNameRowWithRepeats
.extern monster_cutlet_names_route

# rdi=row, rsi=K. eax=1 ⲉϣϫⲉ ⲟⲩcanonical index ⲕⲧⲟ ⲛⲕⲉⲥⲟⲡ.
.type stage45HasRepeat,@function
stage45HasRepeat:
    test rdi,rdi
    je .Ls45hr_no
    xor ecx,ecx
.Ls45hr_outer:
    cmp rcx,rsi
    jae .Ls45hr_no
    mov r8,rcx
    inc r8
.Ls45hr_inner:
    cmp r8,rsi
    jae .Ls45hr_next
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rdi+r8*8]
    je .Ls45hr_yes
    inc r8
    jmp .Ls45hr_inner
.Ls45hr_next:
    inc rcx
    jmp .Ls45hr_outer
.Ls45hr_yes:
    mov eax,1
    ret
.Ls45hr_no:
    xor eax,eax
    ret
.size stage45HasRepeat,.-stage45HasRepeat

# eax=1 ⲉϣϫⲉ ⲡdirect scar ⲟⲩⲏϩ ⲉϥϯ ⲙⲡrepeated witness ⲙⲡStage 44.
.type stage45RequireDirectScar,@function
stage45RequireDirectScar:
    push rbp
    mov rbp,rsp
    mov edi,1
    mov esi,6
    lea rdx,[rip+bad_row]
    call oldCutletNameRowWithRepeats
    test rax,rax
    je .Ls45rds_no
    lea r8,[rip+bad_row]
    xor ecx,ecx
.Ls45rds_loop:
    cmp ecx,6
    jae .Ls45rds_repeat
    cmp qword ptr [r8+rcx*8],1
    jne .Ls45rds_no
    inc ecx
    jmp .Ls45rds_loop
.Ls45rds_repeat:
    lea rdi,[rip+bad_row]
    mov esi,6
    call stage45HasRepeat
    jmp .Ls45rds_done
.Ls45rds_no:
    xor eax,eax
.Ls45rds_done:
    leave
    ret
.size stage45RequireDirectScar,.-stage45RequireDirectScar

# eax=1 ⲉϣϫⲉ ⲡroute ⲙⲡrank1 K6 ⲟ ⲛcorrect ⲁⲩⲱ ⲡlive ghost ⲟ ⲛrepeated legacy row.
.type stage45RequireDifferentDetour,@function
stage45RequireDifferentDetour:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov edi,1
    mov esi,6
    lea rdx,[rip+route_row]
    call monster_cutlet_names_route
    test rax,rax
    je .Ls45rdd_no
    test rdx,rdx
    je .Ls45rdd_no
    test rcx,rcx
    jne .Ls45rdd_no
    mov r12,rdx
    lea r13,[rip+route_row]
    xor ecx,ecx
.Ls45rdd_route:
    cmp ecx,6
    jae .Ls45rdd_ghost
    mov rax,rcx
    inc rax
    cmp qword ptr [r13+rcx*8],rax
    jne .Ls45rdd_no
    inc ecx
    jmp .Ls45rdd_route
.Ls45rdd_ghost:
    xor ecx,ecx
.Ls45rdd_ghost_loop:
    cmp ecx,6
    jae .Ls45rdd_distinct
    cmp qword ptr [r12+rcx*8],1
    jne .Ls45rdd_no
    inc ecx
    jmp .Ls45rdd_ghost_loop
.Ls45rdd_distinct:
    lea rdi,[rip+route_row]
    mov esi,6
    call stage45HasRepeat
    test eax,eax
    jne .Ls45rdd_no
    mov eax,1
    jmp .Ls45rdd_done
.Ls45rdd_no:
    xor eax,eax
.Ls45rdd_done:
    pop r13
    pop r12
    leave
    ret
.size stage45RequireDifferentDetour,.-stage45RequireDifferentDetour

# eax=1 ⲉϣϫⲉ rank2 K6 ⲙⲟⲟϣⲉ ⲕⲁⲧⲁ ⲡpartial-permutation lexicographic order.
.type stage45RequireRank2,@function
stage45RequireRank2:
    push rbp
    mov rbp,rsp
    mov edi,2
    mov esi,6
    lea rdx,[rip+route_row]
    call monster_cutlet_names_route
    test rax,rax
    je .Ls45r2_no
    test rdx,rdx
    je .Ls45r2_no
    test rcx,rcx
    jne .Ls45r2_no
    lea r8,[rip+route_row]
    cmp qword ptr [r8],1
    jne .Ls45r2_no
    cmp qword ptr [r8+8],2
    jne .Ls45r2_no
    cmp qword ptr [r8+16],3
    jne .Ls45r2_no
    cmp qword ptr [r8+24],4
    jne .Ls45r2_no
    cmp qword ptr [r8+32],5
    jne .Ls45r2_no
    cmp qword ptr [r8+40],7
    jne .Ls45r2_no
    mov eax,1
    jmp .Ls45r2_done
.Ls45r2_no:
    xor eax,eax
.Ls45r2_done:
    leave
    ret
.size stage45RequireRank2,.-stage45RequireRank2

# eax=1 ⲉϣϫⲉ ⲡlast rank ⲙⲡK6 ⲡⲉ [17,16,15,14,13,12].
.type stage45RequireLastK6,@function
stage45RequireLastK6:
    push rbp
    mov rbp,rsp
    mov edi,8910720
    mov esi,6
    lea rdx,[rip+route_row]
    call monster_cutlet_names_route
    test rax,rax
    je .Ls45rl_no
    test rdx,rdx
    je .Ls45rl_no
    test rcx,rcx
    jne .Ls45rl_no
    lea r8,[rip+route_row]
    cmp qword ptr [r8],17
    jne .Ls45rl_no
    cmp qword ptr [r8+8],16
    jne .Ls45rl_no
    cmp qword ptr [r8+16],15
    jne .Ls45rl_no
    cmp qword ptr [r8+24],14
    jne .Ls45rl_no
    cmp qword ptr [r8+32],13
    jne .Ls45rl_no
    cmp qword ptr [r8+40],12
    jne .Ls45rl_no
    mov eax,1
    jmp .Ls45rl_done
.Ls45rl_no:
    xor eax,eax
.Ls45rl_done:
    leave
    ret
.size stage45RequireLastK6,.-stage45RequireLastK6

# eax=1 ⲉϣϫⲉ ⲡbranch bad==correct reuse ⲙⲡlive ghost ϩⲙ K2 rank272.
.type stage45RequireEqualReuse,@function
stage45RequireEqualReuse:
    push rbp
    mov rbp,rsp
    push r12
    mov edi,272
    mov esi,2
    lea rdx,[rip+route_row]
    call monster_cutlet_names_route
    test rax,rax
    je .Ls45rer_no
    test rdx,rdx
    je .Ls45rer_no
    cmp rcx,1
    jne .Ls45rer_no
    mov r12,rdx
    cmp qword ptr [rip+route_row],17
    jne .Ls45rer_no
    cmp qword ptr [rip+route_row+8],16
    jne .Ls45rer_no
    cmp qword ptr [r12],17
    jne .Ls45rer_no
    cmp qword ptr [r12+8],16
    jne .Ls45rer_no
    mov eax,1
    jmp .Ls45rer_done
.Ls45rer_no:
    xor eax,eax
.Ls45rer_done:
    pop r12
    leave
    ret
.size stage45RequireEqualReuse,.-stage45RequireEqualReuse

# eax=1 ⲉϣϫⲉ ⲡinvocation-local trace ⲧⲁϫⲣⲟ ϫⲉ ⲡdifferent branch ⲙⲛ ⲡequal branch ⲁⲩⲣϩⲱⲃ.
.type stage45RequireContextTrace,@function
stage45RequireContextTrace:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls45rct_no
    mov r12,rax
    mov rdi,r12
    call monster_stage45_cutlet_names_patch_handler
    cmp eax,1
    jne .Ls45rct_no
    cmp qword ptr [r12+CTX_STAGE45_GHOST_SEEN],1
    jne .Ls45rct_no
    cmp qword ptr [r12+CTX_STAGE45_PATCH_SEEN],1
    jne .Ls45rct_no
    cmp qword ptr [r12+CTX_STAGE45_GHOST_REUSED_EQUAL],1
    jne .Ls45rct_no
    cmp qword ptr [r12+CTX_STAGE45_CORRECT_USED_DIFFERENT],1
    jne .Ls45rct_no
    mov r13,qword ptr [r12+CTX_STAGE45_GHOST_NAMES]
    test r13,r13
    je .Ls45rct_no
    xor ecx,ecx
.Ls45rct_bad:
    cmp ecx,6
    jae .Ls45rct_equal
    cmp qword ptr [r13+rcx*8],1
    jne .Ls45rct_no
    inc ecx
    jmp .Ls45rct_bad
.Ls45rct_equal:
    mov rax,qword ptr [r12+CTX_STAGE45_EQUAL_ROUTE_NAMES]
    mov rdx,qword ptr [r12+CTX_STAGE45_EQUAL_GHOST_NAMES]
    test rax,rax
    je .Ls45rct_no
    test rdx,rdx
    je .Ls45rct_no
    cmp qword ptr [rax],17
    jne .Ls45rct_no
    cmp qword ptr [rax+8],16
    jne .Ls45rct_no
    cmp qword ptr [rdx],17
    jne .Ls45rct_no
    cmp qword ptr [rdx+8],16
    jne .Ls45rct_no
    mov eax,1
    jmp .Ls45rct_done
.Ls45rct_no:
    xor eax,eax
.Ls45rct_done:
    pop r13
    pop r12
    leave
    ret
.size stage45RequireContextTrace,.-stage45RequireContextTrace

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call stage45RequireDirectScar
    test eax,eax
    je .Lfail
    call stage45RequireDifferentDetour
    test eax,eax
    je .Lfail
    call stage45RequireRank2
    test eax,eax
    je .Lfail
    call stage45RequireLastK6
    test eax,eax
    je .Lfail
    call stage45RequireEqualReuse
    test eax,eax
    je .Lfail
    call stage45RequireContextTrace
    test eax,eax
    je .Lfail
.Lgreen:
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
    mov edi,45
    syscall
.size _start,.-_start
