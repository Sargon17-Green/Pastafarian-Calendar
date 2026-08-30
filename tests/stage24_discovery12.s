.intel_syntax noprefix
.section .rodata
red_token: .ascii "STAGE24_DISCOVERY12_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE24_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE24_DISCOVERY12_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.equ CTX_STAGE22_SAUCE_RESULT,808
.equ CTX_STAGE23_ORDER46_LATCH,872
.equ CTX_STAGE24_QUERIED_BOWL_ID,912
.equ CTX_STAGE24_LEGACY_NEXT_BOWL_ID,920
.equ CTX_STAGE24_ROUTE_NEXT_BOWL_ID,928
.equ CTX_STAGE24_LEGACY_SEEN,936
.equ CTX_STAGE24_ROUTE_SEEN,944

.equ S23_QUERY_ORDER,40
.equ S23_ORDER46_LATCH,88

.section .text
.extern monster_context_new
.extern monster_stage22_overwritable_order_handler
.extern monster_stage23_order46_latch_handler
.extern monster_stage24_legacy_next_bowl_handler
.extern oldNextBowlFixedName
.extern monster_next_bowl_route
.global _start

.type require_fixed_numeric_scar,@function
require_fixed_numeric_scar:
    mov edi,1
    call oldNextBowlFixedName
    cmp rax,2
    jne .Lrfns24_fail
    mov edi,2
    call oldNextBowlFixedName
    cmp rax,3
    jne .Lrfns24_fail
    mov edi,3
    call oldNextBowlFixedName
    cmp rax,4
    jne .Lrfns24_fail
    mov edi,4
    call oldNextBowlFixedName
    cmp rax,5
    jne .Lrfns24_fail
    mov edi,5
    call oldNextBowlFixedName
    cmp rax,6
    jne .Lrfns24_fail
    mov edi,6
    call oldNextBowlFixedName
    cmp rax,1
    jne .Lrfns24_fail
    mov eax,1
    ret
.Lrfns24_fail:
    xor eax,eax
    ret
.size require_fixed_numeric_scar,.-require_fixed_numeric_scar

.type find_circular_successor6,@function
find_circular_successor6:
    # Ⲡrdi ϥϫⲓ ⲙⲡorder pointer, ⲡrsi ϥϫⲓ ⲙⲡqueried ID; ⲡreturn ⲡⲉ ⲡsuccessor ID ⲏ 0.
    xor ecx,ecx
.Lfcs624_loop:
    cmp rcx,6
    jae .Lfcs624_fail
    mov rax,qword ptr [rdi+rcx*8]
    cmp rax,rsi
    je .Lfcs624_found
    inc rcx
    jmp .Lfcs624_loop
.Lfcs624_found:
    inc rcx
    cmp rcx,6
    jb .Lfcs624_load
    xor ecx,ecx
.Lfcs624_load:
    mov rax,qword ptr [rdi+rcx*8]
    ret
.Lfcs624_fail:
    xor eax,eax
    ret
.size find_circular_successor6,.-find_circular_successor6

.type _start,@function
_start:
    call require_fixed_numeric_scar
    test eax,eax
    je .Lpattern24

    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lpattern24
    mov r12,rax
    mov rdi,r12
    call monster_stage22_overwritable_order_handler
    test eax,eax
    je .Lpattern24
    mov rdi,r12
    call monster_stage23_order46_latch_handler
    test eax,eax
    je .Lpattern24
    mov rdi,r12
    call monster_stage24_legacy_next_bowl_handler
    test eax,eax
    je .Lpattern24

    cmp qword ptr [r12+CTX_STAGE24_LEGACY_SEEN],1
    jne .Lpattern24
    cmp qword ptr [r12+CTX_STAGE24_ROUTE_SEEN],1
    jne .Lpattern24

    mov r13,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test r13,r13
    je .Lpattern24
    mov r14,qword ptr [r12+CTX_STAGE23_ORDER46_LATCH]
    test r14,r14
    je .Lpattern24
    cmp r14,qword ptr [r13+S23_ORDER46_LATCH]
    jne .Lpattern24
    cmp r14,qword ptr [r13+S23_QUERY_ORDER]
    jne .Lpattern24

    # Ⲡqueried ID ⲡⲉ ⲡposition ⲙⲙⲁϩ4 ⲙⲡlatch ⲛⲧⲟϣ.
    mov r15,qword ptr [r14+24]
    cmp r15,qword ptr [r12+CTX_STAGE24_QUERIED_BOWL_ID]
    jne .Lpattern24

    mov rdi,r15
    call oldNextBowlFixedName
    cmp rax,qword ptr [r12+CTX_STAGE24_LEGACY_NEXT_BOWL_ID]
    jne .Lpattern24

    mov rdi,r14
    mov rsi,r15
    call find_circular_successor6
    test rax,rax
    je .Lpattern24
    mov rbx,rax

    mov rdi,r13
    mov rsi,r15
    call monster_next_bowl_route
    test rax,rax
    je .Lpattern24
    cmp rax,qword ptr [r12+CTX_STAGE24_ROUTE_NEXT_BOWL_ID]
    jne .Lpattern24

    cmp rax,rbx
    je .Lgreen24
    # ⲠDISCOVERY ⲥⲱⲡ ⲙⲙⲁⲧⲉ ⲉϣϫⲉ ⲡroute ⲧⲱⲛ ⲙⲛ ⲡlegacy fixed-name result ⲁⲩⲱ ⲛϥⲧⲱⲛ ⲁⲛ ⲙⲛ ⲡsuccessor ⲙⲡlatch.
    cmp rax,qword ptr [r12+CTX_STAGE24_LEGACY_NEXT_BOWL_ID]
    jne .Lpattern24
    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall

.Lgreen24:
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lpattern24:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,24
    syscall
.size _start,.-_start
