.intel_syntax noprefix
.section .rodata
ok_token: .ascii "STAGE25_PATCH12_GREEN\n"
ok_len = . - ok_token
fail_token: .ascii "STAGE25_PATCH12_FAIL\n"
fail_len = . - fail_token

.equ CTX_STAGE22_SAUCE_RESULT,808
.equ CTX_STAGE23_ORDER46_LATCH,872
.equ CTX_STAGE24_QUERIED_BOWL_ID,912
.equ CTX_STAGE24_LEGACY_NEXT_BOWL_ID,920
.equ CTX_STAGE24_ROUTE_NEXT_BOWL_ID,928
.equ CTX_STAGE24_LEGACY_SEEN,936
.equ CTX_STAGE24_ROUTE_SEEN,944
.equ CTX_STAGE25_QUERIED_POSITION,952
.equ CTX_STAGE25_PATCHED_NEXT_BOWL_ID,960
.equ CTX_STAGE25_PATCH_SEEN,968

.equ S23_QUERY_ORDER,40
.equ S23_ORDER46_LATCH,88

.section .text
.extern monster_context_new
.extern monster_stage22_overwritable_order_handler
.extern monster_stage23_order46_latch_handler
.extern monster_stage24_legacy_next_bowl_handler
.extern monster_stage25_next_bowl_patch_handler
.extern oldNextBowlFixedName
.extern nextBowlQueryPatch
.extern monster_next_bowl_route
.global _start

.type find_circular_successor6_25,@function
find_circular_successor6_25:
    xor ecx,ecx
.Lfcs625_loop:
    cmp rcx,6
    jae .Lfcs625_fail
    cmp qword ptr [rdi+rcx*8],rsi
    je .Lfcs625_found
    inc rcx
    jmp .Lfcs625_loop
.Lfcs625_found:
    inc rcx
    cmp rcx,6
    jb .Lfcs625_load
    xor ecx,ecx
.Lfcs625_load:
    mov rax,qword ptr [rdi+rcx*8]
    ret
.Lfcs625_fail:
    xor eax,eax
    ret
.size find_circular_successor6_25,.-find_circular_successor6_25

.type sweep_six_25,@function
sweep_six_25:
    # Ⲡrdi ϥϫⲓ ⲙⲡsauceResult. Ⲡreturn ⲡⲉ 1 ⲉϣϫⲉ ⲡlegacy ϣⲟⲃⲉ 3 ⲛⲥⲟⲡ ⲁⲩⲱ ⲡpatch ϣⲟⲃⲉ 0.
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    push rbx
    sub rsp,8
    mov r12,rdi
    test r12,r12
    je .Lss25_fail
    mov r13,qword ptr [r12+S23_QUERY_ORDER]
    test r13,r13
    je .Lss25_fail
    mov r14,1
    xor r15d,r15d
    xor ebx,ebx
.Lss25_loop:
    cmp r14,7
    jae .Lss25_done

    mov rdi,r13
    mov rsi,r14
    call find_circular_successor6_25
    test rax,rax
    je .Lss25_fail
    mov qword ptr [rbp-48],rax

    mov rdi,r14
    call oldNextBowlFixedName
    test rax,rax
    je .Lss25_fail
    cmp rax,qword ptr [rbp-48]
    je .Lss25_legacy_equal
    inc r15
.Lss25_legacy_equal:

    mov rdi,r12
    mov rsi,r14
    call nextBowlQueryPatch
    test rax,rax
    je .Lss25_fail
    cmp rax,qword ptr [rbp-48]
    je .Lss25_patch_equal
    inc rbx
.Lss25_patch_equal:

    mov rdi,r12
    mov rsi,r14
    call monster_next_bowl_route
    test rax,rax
    je .Lss25_fail
    cmp rax,qword ptr [rbp-48]
    je .Lss25_route_equal
    inc rbx
.Lss25_route_equal:
    inc r14
    jmp .Lss25_loop
.Lss25_done:
    cmp r15,3
    jne .Lss25_fail
    test rbx,rbx
    jne .Lss25_fail

    # Ⲡwrap ⲙⲡposition ⲙⲙⲁϩ6: ⲡID ⲉⲧϩⲙⲡϩⲁⲉ ϫⲓ ⲙⲡID ⲙⲡposition ⲛϣⲟⲣⲡ.
    mov r14,qword ptr [r13+40]
    mov r15,qword ptr [r13]
    mov rdi,r12
    mov rsi,r14
    call nextBowlQueryPatch
    cmp rax,r15
    jne .Lss25_fail

    # ⲚID ⲉⲧⲃⲏⲕ ⲉⲃⲟⲗ ϩⲙ 1..6 ⲛⲥⲉϯ 0.
    mov rdi,r12
    xor esi,esi
    call nextBowlQueryPatch
    test rax,rax
    jne .Lss25_fail
    mov rdi,r12
    mov esi,7
    call nextBowlQueryPatch
    test rax,rax
    jne .Lss25_fail
    mov rdi,r12
    xor esi,esi
    call monster_next_bowl_route
    test rax,rax
    jne .Lss25_fail
    mov rdi,r12
    mov esi,7
    call monster_next_bowl_route
    test rax,rax
    jne .Lss25_fail

    mov eax,1
    jmp .Lss25_out
.Lss25_fail:
    xor eax,eax
.Lss25_out:
    add rsp,8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    leave
    ret
.size sweep_six_25,.-sweep_six_25

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lfail25
    mov r12,rax

    mov rdi,r12
    call monster_stage22_overwritable_order_handler
    test eax,eax
    je .Lfail25
    mov rdi,r12
    call monster_stage23_order46_latch_handler
    test eax,eax
    je .Lfail25
    mov rdi,r12
    call monster_stage24_legacy_next_bowl_handler
    test eax,eax
    je .Lfail25
    mov rdi,r12
    call monster_stage25_next_bowl_patch_handler
    test eax,eax
    je .Lfail25

    cmp qword ptr [r12+CTX_STAGE24_LEGACY_SEEN],1
    jne .Lfail25
    cmp qword ptr [r12+CTX_STAGE24_ROUTE_SEEN],1
    jne .Lfail25
    cmp qword ptr [r12+CTX_STAGE25_PATCH_SEEN],1
    jne .Lfail25

    mov r13,qword ptr [r12+CTX_STAGE22_SAUCE_RESULT]
    test r13,r13
    je .Lfail25
    mov r14,qword ptr [r12+CTX_STAGE23_ORDER46_LATCH]
    test r14,r14
    je .Lfail25
    cmp r14,qword ptr [r13+S23_QUERY_ORDER]
    jne .Lfail25
    cmp r14,qword ptr [r13+S23_ORDER46_LATCH]
    jne .Lfail25

    # Ⲡprobe ⲛStage 24 ⲡⲉ position 4: Foundation latch [4,5,2,3,6,1], queried ID 3.
    cmp qword ptr [r12+CTX_STAGE24_QUERIED_BOWL_ID],3
    jne .Lfail25
    cmp qword ptr [r12+CTX_STAGE24_LEGACY_NEXT_BOWL_ID],4
    jne .Lfail25
    cmp qword ptr [r12+CTX_STAGE24_ROUTE_NEXT_BOWL_ID],6
    jne .Lfail25
    cmp qword ptr [r12+CTX_STAGE25_QUERIED_POSITION],4
    jne .Lfail25
    cmp qword ptr [r12+CTX_STAGE25_PATCHED_NEXT_BOWL_ID],6
    jne .Lfail25

    mov rdi,r13
    call sweep_six_25
    test eax,eax
    je .Lfail25

    mov eax,1
    mov edi,1
    lea rsi,[rip+ok_token]
    mov edx,ok_len
    syscall
    mov eax,60
    xor edi,edi
    syscall

.Lfail25:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,25
    syscall
.size _start,.-_start
