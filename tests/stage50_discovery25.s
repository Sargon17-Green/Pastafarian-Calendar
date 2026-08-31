.intel_syntax noprefix
.equ CTX_STAGE50_YEAR_FIRST_DAY,2328
.equ CTX_STAGE50_TARGET_DAY,2336
.equ CTX_STAGE50_WEAVE,2344
.equ CTX_STAGE50_WEAVE_COUNT,2352
.equ CTX_STAGE50_DIRECT_GHOST,2360
.equ CTX_STAGE50_ROUTE_VALUE,2368
.equ CTX_STAGE50_LEGACY_SEEN,2376
.equ CTX_STAGE50_ROUTE_SEEN,2384
.equ CTX_STAGE50_SEEN,2392

.section .rodata
.align 8
witness_weave: .quad 1,2,1,2,1,2
red_token: .ascii "STAGE50_DISCOVERY25_EXPECTED_RED\n"
red_len = . - red_token
green_token: .ascii "STAGE50_REGRESSION_GREEN\n"
green_len = . - green_token
pattern_token: .ascii "STAGE50_DISCOVERY25_UNEXPECTED_PATTERN\n"
pattern_len = . - pattern_token

.section .text
.global _start
.extern calendarDateSpaghetti
.extern oldContiguousMonthDayGuess
.extern legacyContiguousMonthDayGuess
.extern monster_day_in_month_route
.extern monster_context_new
.extern monster_stage50_legacy_contiguous_month_day_handler

.type require_direct_scar,@function
require_direct_scar:
    mov edi,1000
    mov esi,1004
    call legacyContiguousMonthDayGuess
    cmp rax,5
    sete al
    movzx eax,al
    ret
.size require_direct_scar,.-require_direct_scar

# eax=0 ⲡlegacy RED; eax=1 ⲡpatched GREEN; eax=2 ⲟⲩpattern ⲛϣⲙⲙⲟ.
.type classify_route,@function
classify_route:
    lea rdi,[rip+witness_weave]
    mov esi,6
    mov edx,1000
    mov ecx,1004
    call monster_day_in_month_route
    cmp rax,5
    je .Lcr_red
    cmp rax,3
    je .Lcr_green
    mov eax,2
    ret
.Lcr_red:
    xor eax,eax
    ret
.Lcr_green:
    mov eax,1
    ret
.size classify_route,.-classify_route

.type require_context,@function
require_context:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    test rax,rax
    je .Lrc_no
    mov r12,rax
    mov rdi,r12
    call monster_stage50_legacy_contiguous_month_day_handler
    cmp eax,1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_YEAR_FIRST_DAY],1000
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_TARGET_DAY],1004
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_WEAVE],0
    je .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_WEAVE_COUNT],6
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_DIRECT_GHOST],5
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_ROUTE_VALUE],0
    je .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_LEGACY_SEEN],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_ROUTE_SEEN],1
    jne .Lrc_no
    cmp qword ptr [r12+CTX_STAGE50_SEEN],1
    jne .Lrc_no
    mov eax,1
    jmp .Lrc_done
.Lrc_no:
    xor eax,eax
.Lrc_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_context,.-require_context

_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lpattern
    call require_direct_scar
    cmp eax,1
    jne .Lpattern
    call require_context
    cmp eax,1
    jne .Lpattern
    call classify_route
    cmp eax,0
    je .Lred
    cmp eax,1
    je .Lgreen
    jmp .Lpattern
.Lred:
    mov eax,1
    mov edi,1
    lea rsi,[rip+red_token]
    mov edx,red_len
    syscall
    mov eax,60
    mov edi,1
    syscall
.Lgreen:
    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Lpattern:
    mov eax,1
    mov edi,1
    lea rsi,[rip+pattern_token]
    mov edx,pattern_len
    syscall
    mov eax,60
    mov edi,50
    syscall
