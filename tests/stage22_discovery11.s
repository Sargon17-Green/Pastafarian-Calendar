.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE22_DISCOVERY11_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE22_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE22_DISCOVERY11_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.equ S22_FINAL_BOWLS,8
.equ S22_DROP46_DIAGNOSTIC,16
.equ S22_LEGACY_ORDER_MEMORY,24
.equ S22_LAST_POST_ORDER,32
.equ S22_QUERY_ORDER,40
.equ S22_ORDER_WRITE_COUNT,64
.equ S22_LAST_SOURCE_KIND,72
.equ S22_LAST_SOURCE_ORDINAL,80

.section .text
.extern monster_order46_memory_route
.extern oracle_sauce
.extern oracle_init
.extern oracle_FOUNDATION
.extern bi_cmp
.global _start

.type equal_bigint6,@function
equal_bigint6:
    push rbp
    mov rbp,rsp
    push rbx
    push r12
    push r13
    sub rsp,8
    mov r12,rdi
    mov r13,rsi
    xor ebx,ebx
.Lebi6_loop:
    cmp rbx,6
    jae .Lebi6_yes
    mov rdi,qword ptr [r12+rbx*8]
    mov rsi,qword ptr [r13+rbx*8]
    test rdi,rdi
    je .Lebi6_no
    test rsi,rsi
    je .Lebi6_no
    call bi_cmp
    test eax,eax
    jne .Lebi6_no
    inc rbx
    jmp .Lebi6_loop
.Lebi6_yes:
    mov eax,1
    jmp .Lebi6_done
.Lebi6_no:
    xor eax,eax
.Lebi6_done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    leave
    ret
.size equal_bigint6,.-equal_bigint6

.type equal_order6,@function
equal_order6:
    xor ecx,ecx
.Leo622_loop:
    cmp rcx,6
    jae .Leo622_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Leo622_no
    inc rcx
    jmp .Leo622_loop
.Leo622_yes:
    mov eax,1
    ret
.Leo622_no:
    xor eax,eax
    ret
.size equal_order6,.-equal_order6

.type count_order_mismatch6,@function
count_order_mismatch6:
    xor eax,eax
    xor ecx,ecx
.Lcom622_loop:
    cmp rcx,6
    jae .Lcom622_done
    mov rdx,qword ptr [rdi+rcx*8]
    cmp rdx,qword ptr [rsi+rcx*8]
    je .Lcom622_next
    inc rax
.Lcom622_next:
    inc rcx
    jmp .Lcom622_loop
.Lcom622_done:
    ret
.size count_order_mismatch6,.-count_order_mismatch6

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_order46_memory_route
    test rax,rax
    je .Lpattern22
    mov r12,rax

    call oracle_init
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_sauce
    test rax,rax
    je .Lpattern22
    mov r13,rax

    cmp qword ptr [r12+S22_ORDER_WRITE_COUNT],58
    jne .Lpattern22
    cmp qword ptr [r12+S22_LAST_SOURCE_KIND],2
    jne .Lpattern22
    cmp qword ptr [r12+S22_LAST_SOURCE_ORDINAL],12
    jne .Lpattern22

    mov rdi,qword ptr [r12+S22_FINAL_BOWLS]
    mov rsi,r13
    call equal_bigint6
    test eax,eax
    je .Lpattern22

    mov rdi,qword ptr [r12+S22_DROP46_DIAGNOSTIC]
    lea rsi,[r13+48]
    call equal_order6
    test eax,eax
    je .Lpattern22

    mov rdi,qword ptr [r12+S22_LEGACY_ORDER_MEMORY]
    mov rsi,qword ptr [r12+S22_LAST_POST_ORDER]
    call equal_order6
    test eax,eax
    je .Lpattern22

    mov rdi,qword ptr [r12+S22_LEGACY_ORDER_MEMORY]
    lea rsi,[r13+48]
    call count_order_mismatch6
    test rax,rax
    je .Lpattern22
    mov r14,rax

    mov rdi,qword ptr [r12+S22_QUERY_ORDER]
    lea rsi,[r13+48]
    call count_order_mismatch6
    mov r15,rax
    test r15,r15
    je .Lgreen22

    mov rdi,qword ptr [r12+S22_QUERY_ORDER]
    mov rsi,qword ptr [r12+S22_LEGACY_ORDER_MEMORY]
    call equal_order6
    test eax,eax
    je .Lpattern22
    cmp r15,r14
    jne .Lpattern22
    jmp .Lred22

.Lred22:
    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall

.Lgreen22:
    test r14,r14
    je .Lpattern22
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lpattern22:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,22
    syscall
.size _start,.-_start
