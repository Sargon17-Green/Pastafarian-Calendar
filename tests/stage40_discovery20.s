.intel_syntax noprefix
.equ CTX_STAGE40_YEAR,1696
.equ CTX_STAGE40_YEAR_FIRST_DAY,1704
.equ CTX_STAGE40_ORIGINAL_TARGET,1712
.equ CTX_STAGE40_GHOST_SAUCE,1720
.equ CTX_STAGE40_ROUTE_SAUCE,1728
.equ CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY,1736
.equ CTX_STAGE40_GHOST_USED_AS_SEMANTIC,1744
.equ CTX_STAGE40_SEEN,1752
.equ S23_FINAL_BOWLS,8
.equ S23_QUERY_ORDER,40
.equ YJ_NUMBER,0
.equ YJ_FIRST_DAY,16
.equ BI_SIGN,0
.equ BI_LEN,8
.equ BI_DATA,24

.section .rodata
red_token: .ascii "STAGE40_DISCOVERY20_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE40_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE40_DISCOVERY20_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage40_legacy_structure_sauce_handler
.extern stage36Year5000JumpAnchorFromPatchedTie
.extern monster_year_jump_route
.extern oldStructureSauce
.extern sauceWithOrderAt46Latch
.extern bi_from_i64
.extern bi_cmp
.extern bi_eq_u64

# rdi=BigInt*. rax=i64, rdx=1 success / 0 fail.
.type stage40SmallBiToI64,@function
stage40SmallBiToI64:
    test rdi,rdi
    je .Ls40bti_fail
    cmp qword ptr [rdi+BI_LEN],1
    jne .Ls40bti_fail
    mov rcx,qword ptr [rdi+BI_DATA]
    test rcx,rcx
    je .Ls40bti_fail
    mov rax,qword ptr [rcx]
    cmp qword ptr [rdi+BI_SIGN],1
    je .Ls40bti_ok
    cmp qword ptr [rdi+BI_SIGN],-1
    jne .Ls40bti_fail
    neg rax
.Ls40bti_ok:
    mov edx,1
    ret
.Ls40bti_fail:
    xor eax,eax
    xor edx,edx
    ret
.size stage40SmallBiToI64,.-stage40SmallBiToI64

# rdi=S23*, rsi=S23*. eax=1 equal / 0 different.
.type stage40SauceEqual,@function
stage40SauceEqual:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    je .Ls40se_no
    test r13,r13
    je .Ls40se_no
    mov rax,qword ptr [r12+S23_FINAL_BOWLS]
    mov rdx,qword ptr [r13+S23_FINAL_BOWLS]
    test rax,rax
    je .Ls40se_no
    test rdx,rdx
    je .Ls40se_no
    mov qword ptr [rbp-40],rax
    mov qword ptr [rbp-48],rdx
    xor ebx,ebx
.Ls40se_bowls:
    cmp ebx,6
    jae .Ls40se_orders_start
    mov rax,qword ptr [rbp-40]
    mov rdi,qword ptr [rax+rbx*8]
    mov rax,qword ptr [rbp-48]
    mov rsi,qword ptr [rax+rbx*8]
    test rdi,rdi
    je .Ls40se_no
    test rsi,rsi
    je .Ls40se_no
    call bi_cmp
    test eax,eax
    jne .Ls40se_no
    inc ebx
    jmp .Ls40se_bowls
.Ls40se_orders_start:
    mov r14,qword ptr [r12+S23_QUERY_ORDER]
    mov r12,qword ptr [r13+S23_QUERY_ORDER]
    test r14,r14
    je .Ls40se_no
    test r12,r12
    je .Ls40se_no
    xor ebx,ebx
.Ls40se_orders:
    cmp ebx,6
    jae .Ls40se_yes
    mov rax,qword ptr [r14+rbx*8]
    cmp rax,qword ptr [r12+rbx*8]
    jne .Ls40se_no
    inc ebx
    jmp .Ls40se_orders
.Ls40se_yes:
    mov eax,1
    jmp .Ls40se_done
.Ls40se_no:
    xor eax,eax
.Ls40se_done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size stage40SauceEqual,.-stage40SauceEqual

# rdi=target i64. rax=YJ*.
.type stage40YearForTarget,@function
stage40YearForTarget:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    call stage36Year5000JumpAnchorFromPatchedTie
    test rax,rax
    je .Ls40yft_fail
    mov r13,rax
    mov rdi,r12
    call bi_from_i64
    test rax,rax
    je .Ls40yft_fail
    mov rdi,r13
    mov rsi,rax
    call monster_year_jump_route
    test rax,rax
    je .Ls40yft_fail
    test rdx,rdx
    je .Ls40yft_fail
    mov rax,rdx
    jmp .Ls40yft_done
.Ls40yft_fail:
    xor eax,eax
.Ls40yft_done:
    pop r13
    pop r12
    leave
    ret
.size stage40YearForTarget,.-stage40YearForTarget

# Ⲡdirect ghost scar ⲧⲁϫⲣⲟ ϫⲉ original-target sauce ϣⲟⲃⲉ ⲙⲛ year.firstDay sauce.
.type require_old_structure_sauce_ghost,@function
require_old_structure_sauce_ghost:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov rdi,-15055671
    call stage40YearForTarget
    test rax,rax
    je .Lrossg_no
    mov r12,rax
    mov rdi,qword ptr [r12+YJ_NUMBER]
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Lrossg_no
    mov rdi,qword ptr [r12+YJ_FIRST_DAY]
    call stage40SmallBiToI64
    test rdx,rdx
    je .Lrossg_no
    mov r13,rax
    cmp r13,-15055671
    je .Lrossg_no

    mov rdi,-15055671
    mov rsi,-15055671
    call oldStructureSauce
    test rax,rax
    je .Lrossg_no
    mov r14,rax

    mov rdi,-15055671
    mov rsi,r13
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Lrossg_no
    mov r15,rax

    mov rdi,r14
    mov rsi,r15
    call stage40SauceEqual
    test eax,eax
    jne .Lrossg_no
    mov eax,1
    jmp .Lrossg_done
.Lrossg_no:
    xor eax,eax
.Lrossg_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_old_structure_sauce_ghost,.-require_old_structure_sauce_ghost

# rax=semantic mismatch count; -1 unexpected pattern.
.type count_stage40_context_mismatches,@function
count_stage40_context_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls40cc_pattern
    mov r12,rax
    mov rdi,r12
    call monster_stage40_legacy_structure_sauce_handler
    cmp eax,1
    jne .Ls40cc_pattern
    cmp qword ptr [r12+CTX_STAGE40_SEEN],1
    jne .Ls40cc_pattern
    cmp qword ptr [r12+CTX_STAGE40_TARGET_DIFFERS_FIRSTDAY],1
    jne .Ls40cc_pattern
    cmp qword ptr [r12+CTX_STAGE40_ORIGINAL_TARGET],-15055671
    jne .Ls40cc_pattern
    mov r13,qword ptr [r12+CTX_STAGE40_YEAR]
    test r13,r13
    je .Ls40cc_pattern
    mov rdi,qword ptr [r13+YJ_NUMBER]
    mov esi,4999
    call bi_eq_u64
    test eax,eax
    je .Ls40cc_pattern
    mov rdi,qword ptr [r12+CTX_STAGE40_YEAR_FIRST_DAY]
    call stage40SmallBiToI64
    test rdx,rdx
    je .Ls40cc_pattern
    mov r14,rax

    mov rdi,-15055671
    mov rsi,r14
    call sauceWithOrderAt46Latch
    test rax,rax
    je .Ls40cc_pattern
    mov r15,rax

    # Ⲡghost direct value ⲟⲩⲏϩ ⲉϥϣⲟⲃⲉ ⲙⲛ authoritative year.firstDay sauce.
    mov rdi,qword ptr [r12+CTX_STAGE40_GHOST_SAUCE]
    mov rsi,r15
    call stage40SauceEqual
    test eax,eax
    jne .Ls40cc_pattern

    xor ebx,ebx
    mov rdi,qword ptr [r12+CTX_STAGE40_ROUTE_SAUCE]
    mov rsi,r15
    call stage40SauceEqual
    test eax,eax
    jne .Ls40cc_route_ok
    inc ebx
.Ls40cc_route_ok:
    mov rax,qword ptr [r12+CTX_STAGE40_GHOST_USED_AS_SEMANTIC]
    cmp rax,1
    ja .Ls40cc_pattern
    add rbx,rax
    mov rax,rbx
    jmp .Ls40cc_done
.Ls40cc_pattern:
    mov rax,-1
.Ls40cc_done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size count_stage40_context_mismatches,.-count_stage40_context_mismatches

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call require_old_structure_sauce_ghost
    test eax,eax
    je .Lpattern
    call count_stage40_context_mismatches
    cmp rax,-1
    je .Lpattern
    cmp rax,2
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
    mov edi,40
    syscall
.size _start,.-_start
