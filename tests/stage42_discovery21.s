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

.section .bss
.align 8
direct_out: .skip 24
route_out: .skip 24
oracle_out: .skip 24

.section .rodata
red_token: .ascii "STAGE42_DISCOVERY21_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE42_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE42_DISCOVERY21_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage42_legacy_cutlet_partition_handler
.extern oldCutletPartitionFamily
.extern monster_cutlet_partition_route
.extern oracle_cutlet_partition_count
.extern oracle_cutlet_partition_unrank
.extern bi_from_u64
.extern bi_eq_u64
.extern bi_cmp

.type stage42TestPrefixHasOffset,@function
stage42TestPrefixHasOffset:
    test rdi,rdi
    je .Ls42tpho_no
    cmp rsi,2
    jb .Ls42tpho_no
    xor r8d,r8d
    xor ecx,ecx
.Ls42tpho_loop:
    inc rcx
    cmp rcx,rsi
    jae .Ls42tpho_no
    add r8,qword ptr [rdi+rcx*8-8]
    cmp r8,rdx
    je .Ls42tpho_yes
    cmp r8,rdx
    ja .Ls42tpho_no
    jmp .Ls42tpho_loop
.Ls42tpho_yes:
    mov eax,1
    ret
.Ls42tpho_no:
    xor eax,eax
    ret
.size stage42TestPrefixHasOffset,.-stage42TestPrefixHasOffset

# eax=1 only when the direct legacy scar is exactly the all-positive witness.
.type require_stage42_direct_scar,@function
require_stage42_direct_scar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Lr42ds_no
    mov r12,rax
    mov edi,10
    mov esi,3
    mov rdx,r12
    lea rcx,[rip+direct_out]
    call oldCutletPartitionFamily
    test rax,rax
    je .Lr42ds_no
    cmp rdx,1
    jne .Lr42ds_no
    mov rdi,rax
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Lr42ds_no
    cmp qword ptr [rip+direct_out],1
    jne .Lr42ds_no
    cmp qword ptr [rip+direct_out+8],1
    jne .Lr42ds_no
    cmp qword ptr [rip+direct_out+16],8
    jne .Lr42ds_no
    lea rdi,[rip+direct_out]
    mov esi,3
    mov edx,4
    call stage42TestPrefixHasOffset
    test eax,eax
    jne .Lr42ds_no
    mov eax,1
    jmp .Lr42ds_done
.Lr42ds_no:
    xor eax,eax
.Lr42ds_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_stage42_direct_scar,.-require_stage42_direct_scar

# rax=0 green / 3 exact discovery divergence / -1 unexpected pattern.
.type stage42_route_mismatch_count,@function
stage42_route_mismatch_count:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,24
    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Ls42rm_pattern
    mov r12,rax

    mov edi,10
    mov esi,3
    mov edx,4
    mov rcx,r12
    lea r8,[rip+route_out]
    call monster_cutlet_partition_route
    test rax,rax
    je .Ls42rm_pattern
    cmp rdx,1
    jne .Ls42rm_pattern
    mov r13,rax

    mov edi,10
    mov esi,3
    mov edx,4
    call oracle_cutlet_partition_count
    test rax,rax
    je .Ls42rm_pattern
    mov r14,rax
    mov rdi,r14
    mov esi,8
    call bi_eq_u64
    test eax,eax
    je .Ls42rm_pattern

    mov edi,10
    mov esi,3
    mov edx,4
    mov rcx,r12
    lea r8,[rip+oracle_out]
    call oracle_cutlet_partition_unrank
    test rax,rax
    je .Ls42rm_pattern
    cmp qword ptr [rip+oracle_out],1
    jne .Ls42rm_pattern
    cmp qword ptr [rip+oracle_out+8],3
    jne .Ls42rm_pattern
    cmp qword ptr [rip+oracle_out+16],6
    jne .Ls42rm_pattern

    xor ebx,ebx
    mov rdi,r13
    mov rsi,r14
    call bi_cmp
    test eax,eax
    je .Ls42rm_count_ok
    inc ebx
.Ls42rm_count_ok:
    lea r10,[rip+route_out]
    lea r11,[rip+oracle_out]
    xor r15d,r15d
.Ls42rm_part_loop:
    cmp r15d,3
    jae .Ls42rm_part_done
    mov rax,qword ptr [r10+r15*8]
    cmp rax,qword ptr [r11+r15*8]
    jne .Ls42rm_part_diff
    inc r15d
    jmp .Ls42rm_part_loop
.Ls42rm_part_diff:
    inc ebx
.Ls42rm_part_done:
    lea rdi,[rip+route_out]
    mov esi,3
    mov edx,4
    call stage42TestPrefixHasOffset
    cmp eax,1
    je .Ls42rm_prefix_ok
    inc ebx
.Ls42rm_prefix_ok:
    cmp ebx,0
    je .Ls42rm_green
    cmp ebx,3
    jne .Ls42rm_pattern
    # Ⲡexact RED witness ⲡⲉ count=36, rank1=[1,1,8], no prefix 4.
    mov rdi,r13
    mov esi,36
    call bi_eq_u64
    test eax,eax
    je .Ls42rm_pattern
    cmp qword ptr [rip+route_out],1
    jne .Ls42rm_pattern
    cmp qword ptr [rip+route_out+8],1
    jne .Ls42rm_pattern
    cmp qword ptr [rip+route_out+16],8
    jne .Ls42rm_pattern
    mov eax,3
    jmp .Ls42rm_done
.Ls42rm_green:
    xor eax,eax
    jmp .Ls42rm_done
.Ls42rm_pattern:
    mov rax,-1
.Ls42rm_done:
    add rsp,24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage42_route_mismatch_count,.-stage42_route_mismatch_count

# eax=1 iff the Stage 42 handler is actually wired and records the same route witness.
.type require_stage42_context_route,@function
require_stage42_context_route:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    sub rsp,16
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lr42cr_no
    mov r12,rax
    mov rdi,r12
    call monster_stage42_legacy_cutlet_partition_handler
    cmp eax,1
    jne .Lr42cr_no
    cmp qword ptr [r12+CTX_STAGE42_GAP_COUNT],10
    jne .Lr42cr_no
    cmp qword ptr [r12+CTX_STAGE42_CUTLET_COUNT],3
    jne .Lr42cr_no
    cmp qword ptr [r12+CTX_STAGE42_CALC_GATE_OFFSET],4
    jne .Lr42cr_no
    cmp qword ptr [r12+CTX_STAGE42_LEGACY_ALL_POSITIVE],1
    jne .Lr42cr_no
    cmp qword ptr [r12+CTX_STAGE42_ROUTE_SEEN],1
    jne .Lr42cr_no
    cmp qword ptr [r12+CTX_STAGE42_SEEN],1
    jne .Lr42cr_no
    mov rdi,qword ptr [r12+CTX_STAGE42_SELECTED_RANK]
    mov esi,1
    call bi_eq_u64
    test eax,eax
    je .Lr42cr_no
    mov r13,qword ptr [r12+CTX_STAGE42_ROUTE_PARTITION]
    test r13,r13
    je .Lr42cr_no
    mov rdi,qword ptr [r12+CTX_STAGE42_ROUTE_FAMILY_COUNT]
    test rdi,rdi
    je .Lr42cr_no
    mov eax,1
    jmp .Lr42cr_done
.Lr42cr_no:
    xor eax,eax
.Lr42cr_done:
    add rsp,16
    pop r13
    pop r12
    leave
    ret
.size require_stage42_context_route,.-require_stage42_context_route

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call require_stage42_direct_scar
    test eax,eax
    je .Lpattern
    call require_stage42_context_route
    test eax,eax
    je .Lpattern
    call stage42_route_mismatch_count
    cmp rax,-1
    je .Lpattern
    cmp rax,3
    je .Lred
    test rax,rax
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
    mov edi,42
    syscall
.size _start,.-_start
