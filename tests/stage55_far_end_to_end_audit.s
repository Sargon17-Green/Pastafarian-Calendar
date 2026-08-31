.intel_syntax noprefix
.equ RES_YEAR,0
.equ RES_CUTLET_NAME,8
.equ RES_DAY_IN_CUTLET,16
.equ RES_MONTH_NAME,24
.equ RES_DAY_IN_MONTH,32
.ifndef FAR_CASE
.set FAR_CASE,1
.endif
.if FAR_CASE == 1
.equ C_DAY,-15055671
.equ T_DAY,-36378304
.equ E_YEAR,1
.equ E_CUTLET,16
.equ E_DCUT,1
.equ E_MONTH,38
.equ E_DMONTH,1
.elseif FAR_CASE == 2
.equ C_DAY,-15055671
.equ T_DAY,-36383647
.equ E_YEAR,0
.equ E_CUTLET,10
.equ E_DCUT,1
.equ E_MONTH,9
.equ E_DMONTH,1
.elseif FAR_CASE == 3
.equ C_DAY,-15055671
.equ T_DAY,-36387500
.equ E_YEAR,-1
.equ E_CUTLET,11
.equ E_DCUT,1
.equ E_MONTH,44
.equ E_DMONTH,1
.else
.error "FAR_CASE"
.endif
.section .rodata
green_token:.ascii "STAGE55_FAR_E2E_GREEN\n"
green_len=.-green_token
fail_token:.ascii "STAGE55_FAR_E2E_FAIL\n"
fail_len=.-fail_token
.section .text
.global _start
.extern calendarDateSpaghetti
.extern bi_from_i64
.extern bi_cmp
.extern catalog_get_cutlet
.extern catalog_get_month
_start:
 mov rdi,C_DAY
 mov rsi,T_DAY
 call calendarDateSpaghetti
 cmp eax,2
 jne .fail
 test rdx,rdx
 je .fail
 mov r12,rdx
 mov rdi,E_YEAR
 call bi_from_i64
 test rax,rax
 je .fail
 mov rdi,qword ptr [r12+RES_YEAR]
 mov rsi,rax
 call bi_cmp
 test eax,eax
 jne .fail
 mov edi,E_CUTLET
 call catalog_get_cutlet
 cmp rax,qword ptr [r12+RES_CUTLET_NAME]
 jne .fail
 cmp qword ptr [r12+RES_DAY_IN_CUTLET],E_DCUT
 jne .fail
 mov edi,E_MONTH
 call catalog_get_month
 cmp rax,qword ptr [r12+RES_MONTH_NAME]
 jne .fail
 cmp qword ptr [r12+RES_DAY_IN_MONTH],E_DMONTH
 jne .fail
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
