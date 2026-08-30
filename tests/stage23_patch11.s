.intel_syntax noprefix
.section .rodata
green_token: .ascii "STAGE23_PATCH11_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE23_PATCH11_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.equ CTX_CALCULATION_DAY,0
.equ CTX_TARGET_DAY,8
.equ CTX_STAGE22_SAUCE_RESULT,808
.equ CTX_STAGE23_ORDER46_LATCH,872
.equ CTX_STAGE23_LATCH_WRITE_COUNT,880
.equ CTX_STAGE23_LATCH_SOURCE_ORDINAL,888
.equ CTX_STAGE23_LEGACY_DIAGNOSTIC_RESULT,896
.equ CTX_STAGE23_SEEN,904

.equ S23_FINAL_BOWLS,8
.equ S23_DROP46_DIAGNOSTIC,16
.equ S23_LEGACY_ORDER_MEMORY,24
.equ S23_LAST_POST_ORDER,32
.equ S23_QUERY_ORDER,40
.equ S23_ORDER_WRITE_COUNT,64
.equ S23_LAST_SOURCE_KIND,72
.equ S23_LAST_SOURCE_ORDINAL,80
.equ S23_ORDER46_LATCH,88
.equ S23_LATCH_WRITE_COUNT,96
.equ S23_LATCH_SOURCE_ORDINAL,104
.equ S23_LEGACY_DIAGNOSTIC_RESULT,112

.equ S22_FINAL_BOWLS,8
.equ S22_DROP46_DIAGNOSTIC,16
.equ S22_LEGACY_ORDER_MEMORY,24
.equ S22_LAST_POST_ORDER,32
.equ S22_QUERY_ORDER,40
.equ S22_ORDER_WRITE_COUNT,64
.equ S22_LAST_SOURCE_KIND,72
.equ S22_LAST_SOURCE_ORDINAL,80

.section .text
.extern monster_context_new
.extern monster_stage22_overwritable_order_handler
.extern monster_stage23_order46_latch_handler
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
.Lebi623_loop:
    cmp rbx,6
    jae .Lebi623_yes
    mov rdi,qword ptr [r12+rbx*8]
    mov rsi,qword ptr [r13+rbx*8]
    test rdi,rdi
    je .Lebi623_no
    test rsi,rsi
    je .Lebi623_no
    call bi_cmp
    test eax,eax
    jne .Lebi623_no
    inc rbx
    jmp .Lebi623_loop
.Lebi623_yes:
    mov eax,1
    jmp .Lebi623_done
.Lebi623_no:
    xor eax,eax
.Lebi623_done:
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
.Leo623_loop:
    cmp rcx,6
    jae .Leo623_yes
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,qword ptr [rsi+rcx*8]
    jne .Leo623_no
    inc rcx
    jmp .Leo623_loop
.Leo623_yes:
    mov eax,1
    ret
.Leo623_no:
    xor eax,eax
    ret
.size equal_order6,.-equal_order6

.type count_order_mismatch6,@function
count_order_mismatch6:
    xor eax,eax
    xor ecx,ecx
.Lcom623_loop:
    cmp rcx,6
    jae .Lcom623_done
    mov rdx,qword ptr [rdi+rcx*8]
    cmp rdx,qword ptr [rsi+rcx*8]
    je .Lcom623_next
    inc rax
.Lcom623_next:
    inc rcx
    jmp .Lcom623_loop
.Lcom623_done:
    ret
.size count_order_mismatch6,.-count_order_mismatch6

.type _start,@function
_start:
    # Ⲡhandler ⲙⲡStage 22 ⲙⲟⲩⲧⲉ ⲉⲡpatched route ⲛⲟⲩⲥⲟⲡ; ⲡStage 23 handler ϫⲓ ⲙⲙⲁⲧⲉ ⲙⲡlatch state ⲙⲡresult ⲡⲁⲓ.
    call monster_context_new
    test rax,rax
    je .Lpattern23
    mov r12,rax
    mov qword ptr [r12+CTX_CALCULATION_DAY],-15055671
    mov qword ptr [r12+CTX_TARGET_DAY],-15055671
    mov rdi,r12
    call monster_stage22_overwritable_order_handler
    test eax,eax
    je .Lpattern23
    mov rdi,r12
    call monster_stage23_order46_latch_handler
    test eax,eax
    je .Lpattern23
    cmp qword ptr [r12+CTX_STAGE23_SEEN],1
    jne .Lpattern23
    cmp qword ptr [r12+CTX_STAGE23_LATCH_WRITE_COUNT],1
    jne .Lpattern23
    cmp qword ptr [r12+CTX_STAGE23_LATCH_SOURCE_ORDINAL],46
    jne .Lpattern23

    mov r13,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test r13,r13
    je .Lpattern23
    mov r14,qword ptr [r12+CTX_STAGE23_LEGACY_DIAGNOSTIC_RESULT]
    test r14,r14
    je .Lpattern23
    cmp r14,qword ptr [r13+S23_LEGACY_DIAGNOSTIC_RESULT]
    jne .Lpattern23

    cmp qword ptr [r13+S23_LATCH_WRITE_COUNT],1
    jne .Lpattern23
    cmp qword ptr [r13+S23_LATCH_SOURCE_ORDINAL],46
    jne .Lpattern23
    cmp qword ptr [r13+S23_ORDER_WRITE_COUNT],58
    jne .Lpattern23
    cmp qword ptr [r13+S23_LAST_SOURCE_KIND],2
    jne .Lpattern23
    cmp qword ptr [r13+S23_LAST_SOURCE_ORDINAL],12
    jne .Lpattern23

    mov rdi,qword ptr [r13+S23_ORDER46_LATCH]
    mov rsi,qword ptr [r13+S23_DROP46_DIAGNOSTIC]
    call equal_order6
    test eax,eax
    je .Lpattern23
    mov rdi,qword ptr [r13+S23_QUERY_ORDER]
    mov rsi,qword ptr [r13+S23_ORDER46_LATCH]
    call equal_order6
    test eax,eax
    je .Lpattern23
    mov rdi,qword ptr [r13+S23_LEGACY_ORDER_MEMORY]
    mov rsi,qword ptr [r13+S23_LAST_POST_ORDER]
    call equal_order6
    test eax,eax
    je .Lpattern23
    mov rdi,qword ptr [r13+S23_LEGACY_ORDER_MEMORY]
    mov rsi,qword ptr [r13+S23_ORDER46_LATCH]
    call count_order_mismatch6
    test rax,rax
    je .Lpattern23

    # Ⲡlegacy full path ⲛⲧⲟϥ ⲟⲩⲏϩ ⲉϥⲥⲏϩ 58 ⲛⲥⲟⲡ ⲁⲩⲱ ⲡquery ⲉϥϫⲓ ⲙⲡmemory ⲉⲧⲁⲩⲥϩⲁⲓ ⲉϫⲱϥ.
    cmp qword ptr [r14+S22_ORDER_WRITE_COUNT],58
    jne .Lpattern23
    cmp qword ptr [r14+S22_LAST_SOURCE_KIND],2
    jne .Lpattern23
    cmp qword ptr [r14+S22_LAST_SOURCE_ORDINAL],12
    jne .Lpattern23
    mov rdi,qword ptr [r14+S22_QUERY_ORDER]
    mov rsi,qword ptr [r14+S22_LEGACY_ORDER_MEMORY]
    call equal_order6
    test eax,eax
    je .Lpattern23
    mov rdi,qword ptr [r14+S22_LEGACY_ORDER_MEMORY]
    mov rsi,qword ptr [r14+S22_DROP46_DIAGNOSTIC]
    call count_order_mismatch6
    test rax,rax
    je .Lpattern23

    call oracle_init
    mov rdi,qword ptr [rip+oracle_FOUNDATION]
    mov rsi,qword ptr [rip+oracle_FOUNDATION]
    call oracle_sauce
    test rax,rax
    je .Lpattern23
    mov r15,rax

    mov rdi,qword ptr [r13+S23_FINAL_BOWLS]
    mov rsi,r15
    call equal_bigint6
    test eax,eax
    je .Lpattern23
    mov rdi,qword ptr [r13+S23_ORDER46_LATCH]
    lea rsi,[r15+48]
    call equal_order6
    test eax,eax
    je .Lpattern23
    mov rdi,qword ptr [r13+S23_QUERY_ORDER]
    lea rsi,[r15+48]
    call equal_order6
    test eax,eax
    je .Lpattern23

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lpattern23:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,23
    syscall
.size _start,.-_start
