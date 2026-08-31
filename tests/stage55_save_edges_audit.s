.intel_syntax noprefix
.section .rodata
green_token:.ascii "STAGE55_SAVE_EDGES_GREEN\n"
green_len=.-green_token
fail_token:.ascii "STAGE55_SAVE_EDGES_FAIL\n"
fail_len=.-fail_token
.section .text
.global _start
.extern legacy_remainder_M
.extern savePatch
.extern oracle_SAVE
.extern oracle_init
.extern bi_from_i64
.extern bi_from_u64
.extern bi_clone
.extern bi_add_u64
.extern bi_sub_abs
.extern bi_mul_u64
.extern bi_neg
.extern bi_cmp
check_one:
 push rbp
 mov rbp,rsp
 push r12
 mov r12,rdi
 mov rdi,r12
 call savePatch
 test rax,rax
 je .co_no
 push rax
 mov rdi,r12
 call oracle_SAVE
 pop rdi
 mov rsi,rax
 call bi_cmp
 test eax,eax
 sete al
 movzx eax,al
 jmp .co_done
.co_no:
 xor eax,eax
.co_done:
 pop r12
 leave
 ret
_start:
 call oracle_init
 mov rdi,1
 call bi_from_i64
 mov r12,rax
 mov rdi,r12
 call check_one
 test eax,eax
 je .fail
 # M-1
 lea rdi,[rip+legacy_remainder_M]
 mov rsi,r12
 call bi_sub_abs
 mov r13,rax
 mov rdi,r13
 call check_one
 test eax,eax
 je .fail
 # M
 lea rdi,[rip+legacy_remainder_M]
 call check_one
 test eax,eax
 je .fail
 # M+1
 lea rdi,[rip+legacy_remainder_M]
 mov rsi,1
 call bi_add_u64
 mov r13,rax
 mov rdi,r13
 call check_one
 test eax,eax
 je .fail
 # 2M
 lea rdi,[rip+legacy_remainder_M]
 mov rsi,2
 call bi_mul_u64
 mov r13,rax
 mov rdi,r13
 call check_one
 test eax,eax
 je .fail
 # -1
 mov rdi,r12
 call bi_neg
 mov r13,rax
 mov rdi,r13
 call check_one
 test eax,eax
 je .fail
 # -(M+1)
 lea rdi,[rip+legacy_remainder_M]
 mov rsi,1
 call bi_add_u64
 mov rdi,rax
 call bi_neg
 mov r13,rax
 mov rdi,r13
 call check_one
 test eax,eax
 je .fail
 mov eax,1
 mov edi,1
 lea rsi,[rip+green_token]
 mov edx,green_len
 syscall
 mov eax,60
 xor edi,edi
 syscall
.fail:
 mov eax,1
 mov edi,1
 lea rsi,[rip+fail_token]
 mov edx,fail_len
 syscall
 mov eax,60
 mov edi,55
 syscall
