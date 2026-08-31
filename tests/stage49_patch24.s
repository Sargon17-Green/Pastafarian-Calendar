.intel_syntax noprefix
.equ CTX_STAGE49_GHOST_WEAVE,2248
.equ CTX_STAGE49_CORRECT_WEAVE,2256
.equ CTX_STAGE49_COUNT_BIG,2264
.equ CTX_STAGE49_GHOST_SEEN,2272
.equ CTX_STAGE49_PATCH_SEEN,2280
.equ CTX_STAGE49_GHOST_REUSED_EQUAL,2288
.equ CTX_STAGE49_CORRECT_USED_DIFFERENT,2296
.equ CTX_STAGE49_EQUAL_GHOST,2304
.equ CTX_STAGE49_EQUAL_ROUTE,2312
.equ CTX_STAGE49_SEEN,2320

.section .bss
.align 8
direct_bad: .skip 64
route_diff: .skip 64
route_equal: .skip 64
rank1_row: .skip 64
rank2_row: .skip 64
rank20_row: .skip 64

.section .rodata
.align 8
lengths_44: .quad 4,4
answers_bad: .quad 2
answers_equal: .quad 1
green_token: .ascii "STAGE49_PATCH24_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE49_PATCH24_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern legacyChooseEachDaySeparately
.extern monster_month_weaving_route
.extern CountWeavingsByDP
.extern DPUnrankLegalWeaving
.extern monster_context_new
.extern monster_stage49_month_weaving_patch_handler
.extern bi_from_u64
.extern bi_eq_u64

# eax=1 ⲉϣϫⲉ ⲡdirect daily scar ⲟⲩⲏϩ ⲉϥϯ 2,2,2,2,1,1,1,1.
.type stage49RequireDirectScar,@function
stage49RequireDirectScar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls49rds_no
    mov r12,rax
    lea rdi,[rip+lengths_44]
    mov esi,2
    lea rdx,[rip+answers_bad]
    mov ecx,1
    mov r8,r12
    lea r9,[rip+direct_bad]
    call legacyChooseEachDaySeparately
    test rax,rax
    je .Ls49rds_no
    lea r8,[rip+direct_bad]
    xor ecx,ecx
.Ls49rds_twos:
    cmp ecx,4
    jae .Ls49rds_ones_start
    cmp qword ptr [r8+rcx*8],2
    jne .Ls49rds_no
    inc ecx
    jmp .Ls49rds_twos
.Ls49rds_ones_start:
    mov ecx,4
.Ls49rds_ones:
    cmp ecx,8
    jae .Ls49rds_yes
    cmp qword ptr [r8+rcx*8],1
    jne .Ls49rds_no
    inc ecx
    jmp .Ls49rds_ones
.Ls49rds_yes:
    mov eax,1
    jmp .Ls49rds_done
.Ls49rds_no:
    xor eax,eax
.Ls49rds_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage49RequireDirectScar,.-stage49RequireDirectScar

# eax=1 ⲉϣϫⲉ ⲡDP count ⲡⲉ 20 ⲁⲩⲱ ranks 1,2,20 ⲥⲉⲙⲟⲟϣⲉ ⲕⲁⲧⲁ ⲡlexicographic law.
.type stage49RequireCountAndUnrank,@function
stage49RequireCountAndUnrank:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,16
    lea rdi,[rip+lengths_44]
    mov esi,2
    call CountWeavingsByDP
    test rax,rax
    je .Ls49rcu_no
    mov rdi,rax
    mov esi,20
    call bi_eq_u64
    test eax,eax
    je .Ls49rcu_no

    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls49rcu_no
    mov r12,rax
    lea rdi,[rip+lengths_44]
    mov esi,2
    mov rdx,r12
    lea rcx,[rip+rank1_row]
    call DPUnrankLegalWeaving
    test rax,rax
    je .Ls49rcu_no
    lea r8,[rip+rank1_row]
    xor ecx,ecx
.Ls49rcu_r1_ones:
    cmp ecx,4
    jae .Ls49rcu_r1_twos_start
    cmp qword ptr [r8+rcx*8],1
    jne .Ls49rcu_no
    inc ecx
    jmp .Ls49rcu_r1_ones
.Ls49rcu_r1_twos_start:
    mov ecx,4
.Ls49rcu_r1_twos:
    cmp ecx,8
    jae .Ls49rcu_rank2
    cmp qword ptr [r8+rcx*8],2
    jne .Ls49rcu_no
    inc ecx
    jmp .Ls49rcu_r1_twos

.Ls49rcu_rank2:
    mov edi,2
    call bi_from_u64
    test rax,rax
    je .Ls49rcu_no
    mov r13,rax
    lea rdi,[rip+lengths_44]
    mov esi,2
    mov rdx,r13
    lea rcx,[rip+rank2_row]
    call DPUnrankLegalWeaving
    test rax,rax
    je .Ls49rcu_no
    lea r8,[rip+rank2_row]
    cmp qword ptr [r8],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+8],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+16],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+24],2
    jne .Ls49rcu_no
    cmp qword ptr [r8+32],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+40],2
    jne .Ls49rcu_no
    cmp qword ptr [r8+48],2
    jne .Ls49rcu_no
    cmp qword ptr [r8+56],2
    jne .Ls49rcu_no

    mov edi,20
    call bi_from_u64
    test rax,rax
    je .Ls49rcu_no
    mov qword ptr [rbp-48],rax
    lea rdi,[rip+lengths_44]
    mov esi,2
    mov rdx,rax
    lea rcx,[rip+rank20_row]
    call DPUnrankLegalWeaving
    test rax,rax
    je .Ls49rcu_no
    lea r8,[rip+rank20_row]
    cmp qword ptr [r8],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+8],2
    jne .Ls49rcu_no
    cmp qword ptr [r8+16],2
    jne .Ls49rcu_no
    cmp qword ptr [r8+24],2
    jne .Ls49rcu_no
    cmp qword ptr [r8+32],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+40],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+48],1
    jne .Ls49rcu_no
    cmp qword ptr [r8+56],2
    jne .Ls49rcu_no
    mov eax,1
    jmp .Ls49rcu_done
.Ls49rcu_no:
    xor eax,eax
.Ls49rcu_done:
    add rsp,16
    pop r13
    pop r12
    leave
    ret
.size stage49RequireCountAndUnrank,.-stage49RequireCountAndUnrank

# eax=1 ⲉϣϫⲉ ⲡbad ghost ⲣϩⲱⲃ, ⲁⲗⲗⲁ ⲡroute ϯ ⲙⲡcorrect rank-1 weave.
.type stage49RequireDifferentDetour,@function
stage49RequireDifferentDetour:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls49rdd_no
    mov r12,rax
    lea rdi,[rip+lengths_44]
    mov esi,2
    lea rdx,[rip+answers_bad]
    mov ecx,1
    mov r8,r12
    lea r9,[rip+route_diff]
    call monster_month_weaving_route
    test rax,rax
    je .Ls49rdd_no
    cmp r8,1
    jne .Ls49rdd_no
    cmp rcx,0
    jne .Ls49rdd_no
    test rdx,rdx
    je .Ls49rdd_no
    mov r13,rdx
    lea r10,[rip+route_diff]
    xor ecx,ecx
.Ls49rdd_route_ones:
    cmp ecx,4
    jae .Ls49rdd_route_twos_start
    cmp qword ptr [r10+rcx*8],1
    jne .Ls49rdd_no
    inc ecx
    jmp .Ls49rdd_route_ones
.Ls49rdd_route_twos_start:
    mov ecx,4
.Ls49rdd_route_twos:
    cmp ecx,8
    jae .Ls49rdd_ghost_twos_start
    cmp qword ptr [r10+rcx*8],2
    jne .Ls49rdd_no
    inc ecx
    jmp .Ls49rdd_route_twos
.Ls49rdd_ghost_twos_start:
    xor ecx,ecx
.Ls49rdd_ghost_twos:
    cmp ecx,4
    jae .Ls49rdd_ghost_ones_start
    cmp qword ptr [r13+rcx*8],2
    jne .Ls49rdd_no
    inc ecx
    jmp .Ls49rdd_ghost_twos
.Ls49rdd_ghost_ones_start:
    mov ecx,4
.Ls49rdd_ghost_ones:
    cmp ecx,8
    jae .Ls49rdd_yes
    cmp qword ptr [r13+rcx*8],1
    jne .Ls49rdd_no
    inc ecx
    jmp .Ls49rdd_ghost_ones
.Ls49rdd_yes:
    mov eax,1
    jmp .Ls49rdd_done
.Ls49rdd_no:
    xor eax,eax
.Ls49rdd_done:
    add rsp,8
    pop r13
    pop r12
    leave
    ret
.size stage49RequireDifferentDetour,.-stage49RequireDifferentDetour

# eax=1 ⲉϣϫⲉ ⲡghost==correct branch ⲕⲱ ⲙⲡlive ghost ⲉⲡsemantic output.
.type stage49RequireEqualReuse,@function
stage49RequireEqualReuse:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls49rer_no
    mov r12,rax
    lea rdi,[rip+lengths_44]
    mov esi,2
    lea rdx,[rip+answers_equal]
    mov ecx,1
    mov r8,r12
    lea r9,[rip+route_equal]
    call monster_month_weaving_route
    test rax,rax
    je .Ls49rer_no
    cmp r8,1
    jne .Ls49rer_no
    cmp rcx,1
    jne .Ls49rer_no
    test rdx,rdx
    je .Ls49rer_no
    mov r13,rdx
    lea r10,[rip+route_equal]
    xor ecx,ecx
.Ls49rer_loop:
    cmp ecx,8
    jae .Ls49rer_yes
    mov rax,qword ptr [r10+rcx*8]
    cmp rax,qword ptr [r13+rcx*8]
    jne .Ls49rer_no
    cmp ecx,4
    jb .Ls49rer_expect_one
    cmp rax,2
    jne .Ls49rer_no
    jmp .Ls49rer_next
.Ls49rer_expect_one:
    cmp rax,1
    jne .Ls49rer_no
.Ls49rer_next:
    inc ecx
    jmp .Ls49rer_loop
.Ls49rer_yes:
    mov eax,1
    jmp .Ls49rer_done
.Ls49rer_no:
    xor eax,eax
.Ls49rer_done:
    add rsp,8
    pop r13
    pop r12
    leave
    ret
.size stage49RequireEqualReuse,.-stage49RequireEqualReuse

# eax=1 ⲉϣϫⲉ ⲡMonsterContext ϩⲁⲣⲉϩ ⲉⲡghost, correct, count ⲙⲛ ⲛbranch flags.
.type stage49RequireContext,@function
stage49RequireContext:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls49rc_no
    mov r12,rax
    mov rdi,r12
    call monster_stage49_month_weaving_patch_handler
    cmp eax,1
    jne .Ls49rc_no
    cmp qword ptr [r12+CTX_STAGE49_GHOST_SEEN],1
    jne .Ls49rc_no
    cmp qword ptr [r12+CTX_STAGE49_PATCH_SEEN],1
    jne .Ls49rc_no
    cmp qword ptr [r12+CTX_STAGE49_GHOST_REUSED_EQUAL],1
    jne .Ls49rc_no
    cmp qword ptr [r12+CTX_STAGE49_CORRECT_USED_DIFFERENT],1
    jne .Ls49rc_no
    cmp qword ptr [r12+CTX_STAGE49_SEEN],1
    jne .Ls49rc_no
    mov rdi,qword ptr [r12+CTX_STAGE49_COUNT_BIG]
    test rdi,rdi
    je .Ls49rc_no
    mov esi,20
    call bi_eq_u64
    test eax,eax
    je .Ls49rc_no
    mov r13,qword ptr [r12+CTX_STAGE49_GHOST_WEAVE]
    test r13,r13
    je .Ls49rc_no
    cmp qword ptr [r13],2
    jne .Ls49rc_no
    cmp qword ptr [r13+56],1
    jne .Ls49rc_no
    mov r13,qword ptr [r12+CTX_STAGE49_CORRECT_WEAVE]
    test r13,r13
    je .Ls49rc_no
    cmp qword ptr [r13],1
    jne .Ls49rc_no
    cmp qword ptr [r13+56],2
    jne .Ls49rc_no
    mov rax,qword ptr [r12+CTX_STAGE49_EQUAL_GHOST]
    mov rdx,qword ptr [r12+CTX_STAGE49_EQUAL_ROUTE]
    test rax,rax
    je .Ls49rc_no
    test rdx,rdx
    je .Ls49rc_no
    cmp qword ptr [rax],1
    jne .Ls49rc_no
    cmp qword ptr [rdx],1
    jne .Ls49rc_no
    cmp qword ptr [rax+56],2
    jne .Ls49rc_no
    cmp qword ptr [rdx+56],2
    jne .Ls49rc_no
    mov eax,1
    jmp .Ls49rc_done
.Ls49rc_no:
    xor eax,eax
.Ls49rc_done:
    pop r13
    pop r12
    leave
    ret
.size stage49RequireContext,.-stage49RequireContext

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call stage49RequireDirectScar
    test eax,eax
    je .Lfail
    call stage49RequireCountAndUnrank
    test eax,eax
    je .Lfail
    call stage49RequireDifferentDetour
    test eax,eax
    je .Lfail
    call stage49RequireEqualReuse
    test eax,eax
    je .Lfail
    call stage49RequireContext
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
    mov edi,49
    syscall
.size _start,.-_start
