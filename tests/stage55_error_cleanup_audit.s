.intel_syntax noprefix
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.section .data
fail_budget:.quad 3
.section .rodata
green_token:.ascii "STAGE55_ERROR_CLEANUP_GREEN\n"
green_len=.-green_token
fail_token:.ascii "STAGE55_ERROR_CLEANUP_FAIL\n"
fail_len=.-fail_token
.section .text
.global _start
.global __wrap_catalog_get_cutlet
.extern __real_catalog_get_cutlet
.extern calendarDateSpaghetti
.extern bi_eq_u64
.extern catalog_get_month
__wrap_catalog_get_cutlet:
 mov rax,[rip+fail_budget]
 test rax,rax; je .real
 dec qword ptr [rip+fail_budget]
 xor eax,eax
 ret
.real: jmp __real_catalog_get_cutlet
_start:
 # Ⲡϫⲱⲕ ⲙⲡretry ⲕⲧⲟ ⲛⲟⲩerror ⲉϥⲟⲩⲟⲛϩ, ⲁⲛ ⲟⲩpartial result.
 mov rdi,-15055671; mov rsi,-15055671; call calendarDateSpaghetti
 test eax,eax; jne .fail
 test rdx,rdx; jne .fail
 cmp qword ptr [rip+fail_budget],0; jne .fail
 # Ⲟⲩinvocation ⲉϥⲟⲩⲁⲁⲃ ⲙⲛⲛⲥⲁ ⲡerror ⲛϥϫⲓ ⲁⲛ ⲛⲟⲩsemantic state ⲉⲃⲟⲗ ϩⲙⲡⲉϥϩⲏⲧ.
 mov rdi,-15055671; mov rsi,-15055671; call calendarDateSpaghetti
 cmp eax,2; jne .fail
 test rdx,rdx; je .fail
 mov r12,rdx
 mov rdi,[r12+RES_YEAR]; mov esi,5000; call bi_eq_u64; test eax,eax; je .fail
 mov edi,10; call __real_catalog_get_cutlet; cmp rax,[r12+RES_CUTLET_NAME]; jne .fail
 cmp qword ptr [r12+RES_DAY_IN_CUTLET],503; jne .fail
 mov edi,20; call catalog_get_month; cmp rax,[r12+RES_MONTH_NAME]; jne .fail
 cmp qword ptr [r12+RES_DAY_IN_MONTH],56; jne .fail
 mov eax,1; mov edi,1; lea rsi,[rip+green_token]; mov edx,green_len; syscall
 mov eax,60; xor edi,edi; syscall
.fail:
 mov eax,1; mov edi,1; lea rsi,[rip+fail_token]; mov edx,fail_len; syscall
 mov eax,60; mov edi,55; syscall
