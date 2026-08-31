.intel_syntax noprefix
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.section .rodata
green_token:.ascii "STAGE55_HISTORY_GREEN\n"
green_len=.-green_token
fail_token:.ascii "STAGE55_HISTORY_FAIL\n"
fail_len=.-fail_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern bi_eq_u64
.extern catalog_get_cutlet
.extern catalog_get_month
check_a:
 cmp eax,2; jne .bad
 test rdx,rdx; je .bad
 mov r12,rdx
 mov rdi,[r12+RES_YEAR]; mov esi,5000; call bi_eq_u64; test eax,eax; je .bad
 mov edi,10; call catalog_get_cutlet; cmp rax,[r12+RES_CUTLET_NAME]; jne .bad
 cmp qword ptr [r12+RES_DAY_IN_CUTLET],503; jne .bad
 mov edi,20; call catalog_get_month; cmp rax,[r12+RES_MONTH_NAME]; jne .bad
 cmp qword ptr [r12+RES_DAY_IN_MONTH],56; jne .bad
 mov eax,1; ret
.bad: xor eax,eax; ret
check_b:
 cmp eax,2; jne .badb
 test rdx,rdx; je .badb
 mov r12,rdx
 mov rdi,[r12+RES_YEAR]; mov esi,5000; call bi_eq_u64; test eax,eax; je .badb
 mov edi,10; call catalog_get_cutlet; cmp rax,[r12+RES_CUTLET_NAME]; jne .badb
 cmp qword ptr [r12+RES_DAY_IN_CUTLET],503; jne .badb
 mov edi,40; call catalog_get_month; cmp rax,[r12+RES_MONTH_NAME]; jne .badb
 cmp qword ptr [r12+RES_DAY_IN_MONTH],99; jne .badb
 mov eax,1; ret
.badb: xor eax,eax; ret
_start:
 mov rdi,-15055671; mov rsi,-15055671; call calendarDateSpaghetti; call check_a; test eax,eax; je .fail
 mov rdi,-15055670; mov rsi,-15055671; call calendarDateSpaghetti; call check_b; test eax,eax; je .fail
 mov rdi,-15055671; mov rsi,-15055671; call calendarDateSpaghetti; call check_a; test eax,eax; je .fail
 mov eax,1; mov edi,1; lea rsi,[rip+green_token]; mov edx,green_len; syscall
 mov eax,60; xor edi,edi; syscall
.fail:
 mov eax,1; mov edi,1; lea rsi,[rip+fail_token]; mov edx,fail_len; syscall
 mov eax,60; mov edi,55; syscall
