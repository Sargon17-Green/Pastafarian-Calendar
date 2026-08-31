.intel_syntax noprefix
.section .bss
.align 8
.global arena_current
.global arena_limit
arena_current: .quad 0
arena_limit: .quad 0

.section .text
.global arena_alloc
.global arena_mark
.global arena_reset
.type arena_alloc,@function
arena_alloc:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    mov r12, rdi
    add r12, 15
    and r12, -16
    mov rax, qword ptr [rip + arena_current]
    test rax, rax
    jne .Larena_have_base
    xor rdi, rdi
    mov rax, 12
    syscall
    mov qword ptr [rip + arena_current], rax
    mov qword ptr [rip + arena_limit], rax
.Larena_have_base:
    mov rbx, qword ptr [rip + arena_current]
    mov r13, rbx
    add r13, r12
    jc .Larena_soft_fail
    mov rdx, qword ptr [rip + arena_limit]
    cmp r13, rdx
    jbe .Larena_commit
    mov rdi, r13
    add rdi, 65535
    and rdi, -65536
    mov rax, 12
    syscall
    cmp rax, rdi
    jb .Larena_soft_fail
    mov qword ptr [rip + arena_limit], rax
.Larena_commit:
    mov qword ptr [rip + arena_current], r13
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Larena_soft_fail:
    # Ⲡsoft-failure detour ⲕⲱ ⲙⲡlegacy abort scar ⲉϥⲟⲩⲟⲛϩ, ⲁⲗⲗⲁ ⲡlive route ⲕⲧⲟ ⲛNULL.
    xor eax,eax
    pop r13
    pop r12
    pop rbx
    leave
    ret
.Larena_fail:
    # Ⲡlegacy abort scar ⲙⲡarena allocation; ⲙⲛ ⲗⲁⲁⲩ ⲛlive branch ⲉⲣⲟϥ.
    mov rdi, 99
    mov rax, 60
    syscall
.size arena_alloc,.-arena_alloc


.type arena_mark,@function
arena_mark:
    mov rax,qword ptr [rip+arena_current]
    ret
.size arena_mark,.-arena_mark

.type arena_reset,@function
arena_reset:
    mov rax,qword ptr [rip+arena_current]
    cmp rdi,rax
    ja .Larena_reset_soft_fail
    mov rdx,qword ptr [rip+arena_limit]
    cmp rdi,rdx
    ja .Larena_reset_soft_fail
    mov qword ptr [rip+arena_current],rdi
    mov rax,rdi
    ret
.Larena_reset_soft_fail:
    # Ⲡinvalid mark ⲕⲧⲟ ⲛzero; ⲡlegacy scar ⲙⲛⲧⲁϥ live caller.
    xor eax,eax
    ret
.Larena_reset_fail:
    # Ⲡlegacy abort scar ⲙⲡarena reset.
    mov rdi,98
    mov rax,60
    syscall
.size arena_reset,.-arena_reset
