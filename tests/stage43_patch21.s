.intel_syntax noprefix
.equ CTX_STAGE42_GAP_COUNT,1792
.equ CTX_STAGE42_CUTLET_COUNT,1800
.equ CTX_STAGE42_CALC_GATE_OFFSET,1808
.equ CTX_STAGE42_ROUTE_FAMILY_COUNT,1816
.equ CTX_STAGE42_ROUTE_PARTITION,1824
.equ CTX_STAGE42_LEGACY_ALL_POSITIVE,1832
.equ CTX_STAGE42_ROUTE_SEEN,1840
.equ CTX_STAGE42_SEEN,1848
.equ CTX_STAGE42_SELECTED_RANK,1856
.equ CTX_STAGE43_GHOST_FAMILY_COUNT,1864
.equ CTX_STAGE43_GHOST_PARTITION,1872
.equ CTX_STAGE43_GHOST_SEEN,1880
.equ CTX_STAGE43_FILTERED_USED,1888
.equ CTX_STAGE43_PATCH_SEEN,1896
.equ CTX_STAGE43_GHOST_REUSED,1904

.section .bss
.align 8
legacy_out: .skip 24
route_out: .skip 24
route_last_out: .skip 24
no_gate_out: .skip 24

.section .rodata
green_token: .ascii "STAGE43_PATCH21_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE43_PATCH21_FAIL\n"
fail_len = . - fail_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage42_legacy_cutlet_partition_handler
.extern legacyCutletPartitionWithoutCalculationGate
.extern oldCutletPartitionFamily
.extern monster_cutlet_partition_route
.extern filteredCutletPartitionFamilyCount
.extern bi_from_u64
.extern bi_eq_u64
.extern bi_cmp

# eax=1 iff direct legacy scar remains all-positive and ignores required offset.
.type stage43RequireLegacyScar,@function
stage43RequireLegacyScar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls43rls_no
    mov r12,rax
    mov edi,10
    mov esi,3
    mov edx,4
    mov rcx,r12
    lea r8,[rip+legacy_out]
    call legacyCutletPartitionWithoutCalculationGate
    test rax,rax
    je .Ls43rls_no
    cmp rdx,1
    jne .Ls43rls_no
    mov rdi,rax
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Ls43rls_no
    cmp qword ptr [rip+legacy_out],1
    jne .Ls43rls_no
    cmp qword ptr [rip+legacy_out+8],1
    jne .Ls43rls_no
    cmp qword ptr [rip+legacy_out+16],8
    jne .Ls43rls_no
    mov eax,1
    jmp .Ls43rls_done
.Ls43rls_no:
    xor eax,eax
.Ls43rls_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage43RequireLegacyScar,.-stage43RequireLegacyScar

# eax=1 iff filtered route returns count=8, rank1=[1,3,6], while live ghost is count=36 [1,1,8].
.type stage43RequireFilteredRoute,@function
stage43RequireFilteredRoute:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls43rfr_no
    mov r12,rax
    mov edi,10
    mov esi,3
    mov edx,4
    mov rcx,r12
    lea r8,[rip+route_out]
    call monster_cutlet_partition_route
    test rax,rax
    je .Ls43rfr_no
    cmp rdx,1
    jne .Ls43rfr_no
    cmp r9,0
    jne .Ls43rfr_no
    mov r13,rcx
    mov rbx,r8
    mov rdi,rax
    mov esi,8
    call bi_eq_u64
    test eax,eax
    je .Ls43rfr_no
    mov rdi,r13
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Ls43rfr_no
    cmp qword ptr [rip+route_out],1
    jne .Ls43rfr_no
    cmp qword ptr [rip+route_out+8],3
    jne .Ls43rfr_no
    cmp qword ptr [rip+route_out+16],6
    jne .Ls43rfr_no
    test rbx,rbx
    je .Ls43rfr_no
    cmp qword ptr [rbx],1
    jne .Ls43rfr_no
    cmp qword ptr [rbx+8],1
    jne .Ls43rfr_no
    cmp qword ptr [rbx+16],8
    jne .Ls43rfr_no
    mov eax,1
    jmp .Ls43rfr_done
.Ls43rfr_no:
    xor eax,eax
.Ls43rfr_done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage43RequireFilteredRoute,.-stage43RequireFilteredRoute

# eax=1 iff lexicographic filtered unrank also gets the last member rank8=[4,5,1].
.type stage43RequireFilteredLast,@function
stage43RequireFilteredLast:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,8
    call bi_from_u64
    test rax,rax
    je .Ls43rfl_no
    mov r12,rax
    mov edi,10
    mov esi,3
    mov edx,4
    mov rcx,r12
    lea r8,[rip+route_last_out]
    call monster_cutlet_partition_route
    test rax,rax
    je .Ls43rfl_no
    cmp rdx,1
    jne .Ls43rfl_no
    mov rdi,rax
    mov esi,8
    call bi_eq_u64
    test eax,eax
    je .Ls43rfl_no
    cmp qword ptr [rip+route_last_out],4
    jne .Ls43rfl_no
    cmp qword ptr [rip+route_last_out+8],5
    jne .Ls43rfl_no
    cmp qword ptr [rip+route_last_out+16],1
    jne .Ls43rfl_no
    mov eax,1
    jmp .Ls43rfl_done
.Ls43rfl_no:
    xor eax,eax
.Ls43rfl_done:
    add rsp,8
    pop r12
    leave
    ret
.size stage43RequireFilteredLast,.-stage43RequireFilteredLast

# eax=1 iff NONE boundary keeps exact legacy semantics and reuses the live ghost.
.type stage43RequireNoGateReuse,@function
stage43RequireNoGateReuse:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls43rng_no
    mov r12,rax
    mov edi,10
    mov esi,3
    xor edx,edx
    mov rcx,r12
    lea r8,[rip+no_gate_out]
    call monster_cutlet_partition_route
    test rax,rax
    je .Ls43rng_no
    cmp rdx,1
    jne .Ls43rng_no
    cmp r9,1
    jne .Ls43rng_no
    mov r13,rcx
    mov rbx,r8
    mov rdi,rax
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Ls43rng_no
    mov rdi,r13
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Ls43rng_no
    cmp qword ptr [rip+no_gate_out],1
    jne .Ls43rng_no
    cmp qword ptr [rip+no_gate_out+8],1
    jne .Ls43rng_no
    cmp qword ptr [rip+no_gate_out+16],8
    jne .Ls43rng_no
    test rbx,rbx
    je .Ls43rng_no
    cmp qword ptr [rbx],1
    jne .Ls43rng_no
    cmp qword ptr [rbx+8],1
    jne .Ls43rng_no
    cmp qword ptr [rbx+16],8
    jne .Ls43rng_no
    mov eax,1
    jmp .Ls43rng_done
.Ls43rng_no:
    xor eax,eax
.Ls43rng_done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage43RequireNoGateReuse,.-stage43RequireNoGateReuse

# eax=1 iff Stage42 handler now records the patched route plus the actual ghost.
.type stage43RequireContextTrace,@function
stage43RequireContextTrace:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls43rct_no
    mov r12,rax
    mov rdi,r12
    call monster_stage42_legacy_cutlet_partition_handler
    cmp eax,1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE42_GAP_COUNT],10
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE42_CUTLET_COUNT],3
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE42_CALC_GATE_OFFSET],4
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE42_LEGACY_ALL_POSITIVE],1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE42_ROUTE_SEEN],1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE42_SEEN],1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE43_GHOST_SEEN],1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE43_FILTERED_USED],1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE43_PATCH_SEEN],1
    jne .Ls43rct_no
    cmp qword ptr [r12+CTX_STAGE43_GHOST_REUSED],0
    jne .Ls43rct_no

    mov rdi,qword ptr [r12+CTX_STAGE42_ROUTE_FAMILY_COUNT]
    mov esi,8
    call bi_eq_u64
    test eax,eax
    je .Ls43rct_no
    mov rdi,qword ptr [r12+CTX_STAGE43_GHOST_FAMILY_COUNT]
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Ls43rct_no
    mov r13,qword ptr [r12+CTX_STAGE42_ROUTE_PARTITION]
    mov r14,qword ptr [r12+CTX_STAGE43_GHOST_PARTITION]
    test r13,r13
    je .Ls43rct_no
    test r14,r14
    je .Ls43rct_no
    cmp qword ptr [r13],1
    jne .Ls43rct_no
    cmp qword ptr [r13+8],3
    jne .Ls43rct_no
    cmp qword ptr [r13+16],6
    jne .Ls43rct_no
    cmp qword ptr [r14],1
    jne .Ls43rct_no
    cmp qword ptr [r14+8],1
    jne .Ls43rct_no
    cmp qword ptr [r14+16],8
    jne .Ls43rct_no
    mov eax,1
    jmp .Ls43rct_done
.Ls43rct_no:
    xor eax,eax
.Ls43rct_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage43RequireContextTrace,.-stage43RequireContextTrace

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call stage43RequireLegacyScar
    test eax,eax
    je .Lfail
    call stage43RequireFilteredRoute
    test eax,eax
    je .Lfail
    call stage43RequireFilteredLast
    test eax,eax
    je .Lfail
    call stage43RequireNoGateReuse
    test eax,eax
    je .Lfail
    call stage43RequireContextTrace
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
    mov edi,43
    syscall
.size _start,.-_start
