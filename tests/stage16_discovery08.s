.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE16_DISCOVERY08_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE16_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE16_DISCOVERY08_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token
.align 8
first_permutation:
    .quad 1,2,3,4,5,6
last_permutation:
    .quad 6,5,4,3,2,1

.section .text
.extern arena_alloc
.extern bi_from_u64
.extern oracle_bowl_order_from_value
.extern oldPermutationUnrank0
.extern legacyPermutationRank0FromDropWrong
.extern monster_permutation_route
.extern calendarDateSpaghetti
.global _start

.type equal_order6,@function
equal_order6:
    xor ecx,ecx
.Leo6_loop:
    cmp rcx,6
    jae .Leo6_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Leo6_no
    inc rcx
    jmp .Leo6_loop
.Leo6_yes:
    mov eax,1
    ret
.Leo6_no:
    xor eax,eax
    ret
.size equal_order6,.-equal_order6

.type require_old_unrank0_scar,@function
require_old_unrank0_scar:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,56
    lea r12,[rbp-64]

    xor edi,edi
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    je .Lrous_fail
    mov rdi,r12
    lea rsi,[rip+first_permutation]
    call equal_order6
    test eax,eax
    je .Lrous_fail

    mov edi,719
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    je .Lrous_fail
    mov rdi,r12
    lea rsi,[rip+last_permutation]
    call equal_order6
    test eax,eax
    je .Lrous_fail

    mov edi,720
    mov rsi,r12
    call oldPermutationUnrank0
    test eax,eax
    jne .Lrous_fail

    mov eax,1
    jmp .Lrous_done
.Lrous_fail:
    xor eax,eax
.Lrous_done:
    add rsp,56
    pop r12
    leave
    ret
.size require_old_unrank0_scar,.-require_old_unrank0_scar

.type require_wrong_rank_mapping,@function
require_wrong_rank_mapping:
    push rbp
    mov rbp,rsp
    push r12

    mov edi,1
    call bi_from_u64
    test rax,rax
    je .Lrwrm_fail
    mov rdi,rax
    call legacyPermutationRank0FromDropWrong
    cmp rax,1
    jne .Lrwrm_fail

    mov edi,719
    call bi_from_u64
    test rax,rax
    je .Lrwrm_fail
    mov rdi,rax
    call legacyPermutationRank0FromDropWrong
    cmp rax,719
    jne .Lrwrm_fail

    mov edi,720
    call bi_from_u64
    test rax,rax
    je .Lrwrm_fail
    mov rdi,rax
    call legacyPermutationRank0FromDropWrong
    test rax,rax
    jne .Lrwrm_fail

    mov edi,721
    call bi_from_u64
    test rax,rax
    je .Lrwrm_fail
    mov rdi,rax
    call legacyPermutationRank0FromDropWrong
    cmp rax,1
    jne .Lrwrm_fail

    mov eax,1
    jmp .Lrwrm_done
.Lrwrm_fail:
    xor eax,eax
.Lrwrm_done:
    pop r12
    leave
    ret
.size require_wrong_rank_mapping,.-require_wrong_rank_mapping

.type compare_route_drop,@function
compare_route_drop:
    # rdi = drop u64; return 1 mismatch, 0 equal, -1 internal failure.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi

    mov rdi,r12
    call bi_from_u64
    test rax,rax
    je .Lcrd_bad
    mov r12,rax

    mov edi,96
    call arena_alloc
    test rax,rax
    je .Lcrd_bad
    mov r13,rax
    lea r14,[rax+48]

    mov rdi,r12
    mov rsi,r13
    call oracle_bowl_order_from_value
    test eax,eax
    je .Lcrd_bad

    mov rdi,r12
    mov rsi,r14
    call monster_permutation_route
    test rax,rax
    je .Lcrd_bad

    mov rdi,r13
    mov rsi,r14
    call equal_order6
    xor eax,1
    jmp .Lcrd_done
.Lcrd_bad:
    mov rax,-1
.Lcrd_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size compare_route_drop,.-compare_route_drop

.type count_route_mismatches,@function
count_route_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    xor r12d,r12d

    mov edi,1
    call compare_route_drop
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov edi,719
    call compare_route_drop
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov edi,720
    call compare_route_drop
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov edi,721
    call compare_route_drop
    cmp rax,1
    ja .Lcrm_bad
    add r12,rax

    mov rax,r12
    jmp .Lcrm_done
.Lcrm_bad:
    mov rax,-1
.Lcrm_done:
    pop r12
    leave
    ret
.size count_route_mismatches,.-count_route_mismatches

.type _start,@function
_start:
    # Ⲡmain route ⲙⲟⲩⲧⲉ ⲉⲡlegacy permutation handler ⲙⲡStage 16.
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    call require_old_unrank0_scar
    test eax,eax
    je .Lpattern

    call require_wrong_rank_mapping
    test eax,eax
    je .Lpattern

    call count_route_mismatches
    cmp rax,4
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
    mov edi,16
    syscall
.size _start,.-_start
