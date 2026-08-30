.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE10_DISCOVERY05_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE10_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE10_DISCOVERY05_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.extern bi_from_i64
.extern bi_cmp
.extern oracle_work_counts
.extern oracle_build_stones
.extern oracle_build_hidden
.extern buildHiddenWithBackwardStorage
.extern monster_hidden_route
.extern calendarDateSpaghetti
.global _start

.type require_backward_storage,@function
require_backward_storage:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rsi
    xor r14d,r14d
.Lrbs_loop:
    cmp r14,7
    jae .Lrbs_ok
    mov rdi,qword ptr [r12+r14*8]
    mov rax,6
    sub rax,r14
    mov rsi,qword ptr [r13+rax*8]
    call bi_cmp
    test eax,eax
    jne .Lrbs_fail
    inc r14
    jmp .Lrbs_loop
.Lrbs_ok:
    mov eax,1
    jmp .Lrbs_done
.Lrbs_fail:
    xor eax,eax
.Lrbs_done:
    pop r14
    pop r13
    pop r12
    leave
    ret
.size require_backward_storage,.-require_backward_storage

.type count_route_mismatches,@function
count_route_mismatches:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,1
    xor r15d,r15d
.Lcrm_loop:
    cmp r14,7
    ja .Lcrm_done
    mov rdi,r12
    mov rsi,r14
    call monster_hidden_route
    test rax,rax
    je .Lcrm_bad
    mov rdi,rax
    mov rsi,qword ptr [r13+r14*8-8]
    call bi_cmp
    test eax,eax
    je .Lcrm_next
    inc r15
.Lcrm_next:
    inc r14
    jmp .Lcrm_loop
.Lcrm_bad:
    mov rax,-1
    jmp .Lcrm_out
.Lcrm_done:
    mov rax,r15
.Lcrm_out:
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size count_route_mismatches,.-count_route_mismatches

.type require_red_mapping,@function
require_red_mapping:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi

    # Ⲡ k=1 ⲙⲟⲩⲧⲉ ⲉhidden7 ϩⲙⲡlegacy ⲉϥⲥϩⲟⲩⲟⲣⲧ.
    mov rdi,r12
    mov esi,1
    call monster_hidden_route
    mov rdi,rax
    mov rsi,qword ptr [r13+48]
    call bi_cmp
    test eax,eax
    jne .Lrrm_fail

    # Ⲡ k=4 ⲡⲉ ⲡⲙⲏⲧⲉ, ⲉⲧⲃⲉ ⲡⲁⲓ ⲛϥϣⲟⲃⲉ ⲁⲛ.
    mov rdi,r12
    mov esi,4
    call monster_hidden_route
    mov rdi,rax
    mov rsi,qword ptr [r13+24]
    call bi_cmp
    test eax,eax
    jne .Lrrm_fail

    # Ⲡ k=7 ⲙⲟⲩⲧⲉ ⲉhidden1 ϩⲙⲡlegacy ⲉϥⲥϩⲟⲩⲟⲣⲧ.
    mov rdi,r12
    mov esi,7
    call monster_hidden_route
    mov rdi,rax
    mov rsi,qword ptr [r13]
    call bi_cmp
    test eax,eax
    jne .Lrrm_fail

    mov eax,1
    jmp .Lrrm_done
.Lrrm_fail:
    xor eax,eax
.Lrrm_done:
    pop r13
    pop r12
    leave
    ret
.size require_red_mapping,.-require_red_mapping

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern

    mov rdi,-15055671
    call bi_from_i64
    mov r12,rax
    mov rdi,-15055671
    call bi_from_i64
    mov r13,rax
    mov rdi,r12
    mov rsi,r13
    call oracle_work_counts
    mov r14,rax
    call oracle_build_stones
    mov r15,rax

    mov rdi,r14
    mov rsi,r15
    call buildHiddenWithBackwardStorage
    test rax,rax
    je .Lpattern
    mov r12,rax

    mov rdi,r14
    mov rsi,r15
    call oracle_build_hidden
    test rax,rax
    je .Lpattern
    mov r13,rax

    # Ⲡstorage ⲛⲧⲟϥ ⲟⲩⲏϩ ⲉϥⲥϩⲟⲩⲟⲣⲧ hidden7..hidden1.
    mov rdi,r12
    mov rsi,r13
    call require_backward_storage
    test eax,eax
    je .Lpattern

    mov rdi,r12
    mov rsi,r13
    call count_route_mismatches
    cmp rax,0
    je .Lgreen
    cmp rax,6
    jne .Lpattern

    mov rdi,r12
    mov rsi,r13
    call require_red_mapping
    test eax,eax
    je .Lpattern

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
    mov edi,10
    syscall
.size _start,.-_start
