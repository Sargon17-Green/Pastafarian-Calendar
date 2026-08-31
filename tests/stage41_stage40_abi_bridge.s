.intel_syntax noprefix
.section .text
.global __wrap_bi_cmp
.extern __real_bi_cmp

# ⲠStage 40 regression ⲕⲱ ⲛⲟⲩpointer ϩⲁ ⲡrsp ⲙⲛⲛⲥⲁ ⲟⲩcall. Ⲡbridge ⲡⲁⲓ ϩⲁⲣⲉϩ ⲉⲡincoming rax ⲙⲡtest-only caller red-zone; ⲡBigInt comparison ⲛⲧⲟϥ ⲟⲩⲏϩ __real_bi_cmp.
.type __wrap_bi_cmp,@function
__wrap_bi_cmp:
    push rbx
    push r12
    sub rsp,8
    mov qword ptr [rsp],rax
    call __real_bi_cmp
    mov r8d,eax
    mov r9,qword ptr [rsp]
    add rsp,8
    pop r12
    pop rbx
    mov r11,qword ptr [rsp]
    add rsp,8
    mov qword ptr [rsp-8],r9
    mov eax,r8d
    jmp r11
.size __wrap_bi_cmp,.-__wrap_bi_cmp
