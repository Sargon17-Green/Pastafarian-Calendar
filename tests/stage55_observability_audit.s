.intel_syntax noprefix
.equ CTX_STAGE54_METRICS,2672
.equ CTX_STAGE54_LOGS,2680
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.section .rodata
green_token:.ascii "STAGE55_OBSERVABILITY_GREEN\n"
green_len=.-green_token
fail_token:.ascii "STAGE55_OBSERVABILITY_FAIL\n"
fail_len=.-fail_token
.section .text
.global _start
.global __wrap_monster_context_new
.extern __real_monster_context_new
.extern calendarDateSpaghetti
.extern bi_eq_u64
.extern catalog_get_cutlet
.extern catalog_get_month
__wrap_monster_context_new:
 call __real_monster_context_new
 test rax,rax
 je .wret
 mov qword ptr [rax+CTX_STAGE54_METRICS],1234567
 mov qword ptr [rax+CTX_STAGE54_LOGS],7654321
.wret: ret
_start:
 mov rdi,-15055671
 mov rsi,-15055671
 call calendarDateSpaghetti
 cmp eax,2; jne .fail
 test rdx,rdx; je .fail
 mov r12,rdx
 mov rdi,[r12+RES_YEAR]; mov esi,5000; call bi_eq_u64; test eax,eax; je .fail
 mov edi,10; call catalog_get_cutlet; cmp rax,[r12+RES_CUTLET_NAME]; jne .fail
 cmp qword ptr [r12+RES_DAY_IN_CUTLET],503; jne .fail
 mov edi,20; call catalog_get_month; cmp rax,[r12+RES_MONTH_NAME]; jne .fail
 cmp qword ptr [r12+RES_DAY_IN_MONTH],56; jne .fail
 mov eax,1; mov edi,1; lea rsi,[rip+green_token]; mov edx,green_len; syscall
 mov eax,60; xor edi,edi; syscall
.fail:
 mov eax,1; mov edi,1; lea rsi,[rip+fail_token]; mov edx,fail_len; syscall
 mov eax,60; mov edi,55; syscall
