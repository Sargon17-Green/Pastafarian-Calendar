.intel_syntax noprefix
.equ CTX_STAGE44_CUTLET_COUNT,1912
.equ CTX_STAGE44_SELECTED_RANK,1920
.equ CTX_STAGE44_ROUTE_NAMES,1928
.equ CTX_STAGE44_REPEAT_SEEN,1936
.equ CTX_STAGE44_ROUTE_SEEN,1944
.equ CTX_STAGE44_SEEN,1952

.section .bss
.align 8
legacy_bad: .skip 48
correct_row: .skip 48

.section .rodata
red_token: .ascii "STAGE44_DISCOVERY22_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE44_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE44_DISCOVERY22_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage44_legacy_repeated_names_handler
.extern oldCutletNameRowWithRepeats

# rdi=ptr, rsi=K. eax=1 iff at least two canonical indices repeat.
.type stage44HasRepeat,@function
stage44HasRepeat:
    test rdi,rdi
    je .Ls44hr_no
    xor ecx,ecx
.Ls44hr_outer:
    cmp rcx,rsi
    jae .Ls44hr_no
    mov r8,rcx
    inc r8
.Ls44hr_inner:
    cmp r8,rsi
    jae .Ls44hr_next
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rdi+r8*8]
    je .Ls44hr_yes
    inc r8
    jmp .Ls44hr_inner
.Ls44hr_next:
    inc rcx
    jmp .Ls44hr_outer
.Ls44hr_yes:
    mov eax,1
    ret
.Ls44hr_no:
    xor eax,eax
    ret
.size stage44HasRepeat,.-stage44HasRepeat

# rdi=a, rsi=b, rdx=K. eax=1 equal / 0 different.
.type stage44RowsEqual,@function
stage44RowsEqual:
    test rdi,rdi
    je .Ls44re_no
    test rsi,rsi
    je .Ls44re_no
    xor ecx,ecx
.Ls44re_loop:
    cmp rcx,rdx
    jae .Ls44re_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Ls44re_no
    inc rcx
    jmp .Ls44re_loop
.Ls44re_yes:
    mov eax,1
    ret
.Ls44re_no:
    xor eax,eax
    ret
.size stage44RowsEqual,.-stage44RowsEqual

# rdi=n, rsi=k. rax=P(n,k), or 0 on invalid/overflow.
.type stage44FallingU64,@function
stage44FallingU64:
    cmp rsi,rdi
    ja .Ls44ff_zero
    mov eax,1
    xor ecx,ecx
.Ls44ff_loop:
    cmp rcx,rsi
    jae .Ls44ff_done
    mov r8,rdi
    sub r8,rcx
    mul r8
    test rdx,rdx
    jne .Ls44ff_zero
    inc rcx
    jmp .Ls44ff_loop
.Ls44ff_done:
    ret
.Ls44ff_zero:
    xor eax,eax
    ret
.size stage44FallingU64,.-stage44FallingU64

# test-only normative partial-permutation unrank.
# rdi=rank1, rsi=K, rdx=out canonical indices. rax=out / 0.
.type stage44CorrectPartialPermutationUnrank17,@function
stage44CorrectPartialPermutationUnrank17:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    test rdi,rdi
    je .Ls44cpu_fail
    test rsi,rsi
    je .Ls44cpu_fail
    cmp rsi,17
    ja .Ls44cpu_fail
    test rdx,rdx
    je .Ls44cpu_fail
    xor r12d,r12d                  # used-name bit mask
    mov r13,rsi                    # K
    mov r14,rdx                    # out
    mov r15,rdi
    dec r15                        # q = rank1-1
    xor r10d,r10d                  # position
.Ls44cpu_pos:
    cmp r10,r13
    jae .Ls44cpu_done
    mov r11,r13
    sub r11,r10
    dec r11                        # remaining slots after this choice
    mov rdi,16
    sub rdi,r10                    # available names after this choice
    mov rsi,r11
    call stage44FallingU64
    test rax,rax
    je .Ls44cpu_fail
    mov r11,rax                    # block size
    mov rax,r15
    xor edx,edx
    div r11
    mov r15,rdx                    # q inside chosen block
    mov r9,rax                     # zero-based ordinal among unused names
    mov r8,17
    sub r8,r10                     # number of currently unused names
    cmp r9,r8
    jae .Ls44cpu_fail

    mov ecx,1                      # canonical index candidate
.Ls44cpu_find:
    cmp ecx,17
    ja .Ls44cpu_fail
    mov rdx,rcx
    dec rdx
    bt r12,rdx
    jc .Ls44cpu_used
    test r9,r9
    je .Ls44cpu_choose
    dec r9
.Ls44cpu_used:
    inc rcx
    jmp .Ls44cpu_find
.Ls44cpu_choose:
    bts r12,rdx
    mov qword ptr [r14+r10*8],rcx
    inc r10
    jmp .Ls44cpu_pos
.Ls44cpu_done:
    mov rax,r14
    jmp .Ls44cpu_exit
.Ls44cpu_fail:
    xor eax,eax
.Ls44cpu_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size stage44CorrectPartialPermutationUnrank17,.-stage44CorrectPartialPermutationUnrank17

# eax=1 iff the direct legacy scar still yields the repeated rank-1 row.
.type stage44RequireDirectScar,@function
stage44RequireDirectScar:
    push rbp
    mov rbp,rsp
    mov edi,1
    mov esi,6
    lea rdx,[rip+legacy_bad]
    call oldCutletNameRowWithRepeats
    test rax,rax
    je .Ls44rds_no
    lea r8,[rip+legacy_bad]
    xor ecx,ecx
.Ls44rds_values:
    cmp ecx,6
    jae .Ls44rds_repeat
    cmp qword ptr [r8+rcx*8],1
    jne .Ls44rds_no
    inc ecx
    jmp .Ls44rds_values
.Ls44rds_repeat:
    lea rdi,[rip+legacy_bad]
    mov esi,6
    call stage44HasRepeat
    jmp .Ls44rds_done
.Ls44rds_no:
    xor eax,eax
.Ls44rds_done:
    leave
    ret
.size stage44RequireDirectScar,.-stage44RequireDirectScar

# eax=1 iff the test-only correct row is the first distinct lexicographic row 1..6.
.type stage44RequireCorrectReference,@function
stage44RequireCorrectReference:
    push rbp
    mov rbp,rsp
    mov edi,1
    mov esi,6
    lea rdx,[rip+correct_row]
    call stage44CorrectPartialPermutationUnrank17
    test rax,rax
    je .Ls44rcr_no
    lea r8,[rip+correct_row]
    xor ecx,ecx
.Ls44rcr_values:
    cmp ecx,6
    jae .Ls44rcr_distinct
    mov rax,rcx
    inc rax
    cmp qword ptr [r8+rcx*8],rax
    jne .Ls44rcr_no
    inc ecx
    jmp .Ls44rcr_values
.Ls44rcr_distinct:
    lea rdi,[rip+correct_row]
    mov esi,6
    call stage44HasRepeat
    test eax,eax
    sete al
    movzx eax,al
    jmp .Ls44rcr_done
.Ls44rcr_no:
    xor eax,eax
.Ls44rcr_done:
    leave
    ret
.size stage44RequireCorrectReference,.-stage44RequireCorrectReference

# eax=0 expected RED legacy route, 1 GREEN patched route, 2 unexpected pattern.
.type stage44ClassifyContextRoute,@function
stage44ClassifyContextRoute:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Ls44cc_pattern
    mov r12,rax
    mov rdi,r12
    call monster_stage44_legacy_repeated_names_handler
    cmp eax,1
    jne .Ls44cc_pattern
    cmp qword ptr [r12+CTX_STAGE44_CUTLET_COUNT],6
    jne .Ls44cc_pattern
    cmp qword ptr [r12+CTX_STAGE44_SELECTED_RANK],1
    jne .Ls44cc_pattern
    cmp qword ptr [r12+CTX_STAGE44_ROUTE_SEEN],1
    jne .Ls44cc_pattern
    cmp qword ptr [r12+CTX_STAGE44_SEEN],1
    jne .Ls44cc_pattern
    mov r13,qword ptr [r12+CTX_STAGE44_ROUTE_NAMES]
    test r13,r13
    je .Ls44cc_pattern

    mov rdi,r13
    lea rsi,[rip+correct_row]
    mov edx,6
    call stage44RowsEqual
    test eax,eax
    jne .Ls44cc_green_candidate

    mov rdi,r13
    lea rsi,[rip+legacy_bad]
    mov edx,6
    call stage44RowsEqual
    test eax,eax
    je .Ls44cc_pattern
    cmp qword ptr [r12+CTX_STAGE44_REPEAT_SEEN],1
    jne .Ls44cc_pattern
    xor eax,eax
    jmp .Ls44cc_done

.Ls44cc_green_candidate:
    cmp qword ptr [r12+CTX_STAGE44_REPEAT_SEEN],0
    jne .Ls44cc_pattern
    mov eax,1
    jmp .Ls44cc_done
.Ls44cc_pattern:
    mov eax,2
.Ls44cc_done:
    pop r13
    pop r12
    leave
    ret
.size stage44ClassifyContextRoute,.-stage44ClassifyContextRoute

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call stage44RequireDirectScar
    test eax,eax
    je .Lpattern
    call stage44RequireCorrectReference
    test eax,eax
    je .Lpattern
    lea rdi,[rip+legacy_bad]
    lea rsi,[rip+correct_row]
    mov edx,6
    call stage44RowsEqual
    test eax,eax
    jne .Lpattern
    call stage44ClassifyContextRoute
    cmp eax,0
    je .Lred
    cmp eax,1
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
    mov edi,44
    syscall
.size _start,.-_start
