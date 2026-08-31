.intel_syntax noprefix
.equ CTX_STAGE34_LEGACY_SELECTED_OPEN,1400
.equ CTX_STAGE34_ROUTE_SELECTED_OPEN,1408
.equ CTX_STAGE34_LEGACY_SEEN,1416
.equ CTX_STAGE34_ROUTE_SEEN,1424
.equ CTX_STAGE35_PATCH_SELECTED_OPEN,1432
.equ CTX_STAGE35_PATCH_SEEN,1440
.equ YC_OPEN,0
.equ YC_CLOSE,8
.equ YC_LENGTH,16
.equ YC_SIZE,24

.section .rodata
stage35_green:
    .ascii "STAGE35_PATCH17_GREEN\n"
.set stage35_green_len,.-stage35_green
stage35_fail:
    .ascii "STAGE35_PATCH17_FAIL\n"
.set stage35_fail_len,.-stage35_fail

.section .data
.align 8
year5000_tie_input:
    .quad 9,15,490
    .quad 3,9,490
legacy_out:
    .zero 48
route_out:
    .zero 48

# Ⲥⲛⲁⲩ ⲛequal-length run ⲙⲛ length ⲉⲩϣⲟⲃⲉ ϩⲓⲧⲟⲩⲟⲩ.
multi_run_input:
    .quad 8,14,500
    .quad 9,15,490
    .quad 3,9,490
    .quad 2,8,500
multi_run_out:
    .zero 96

singleton_input:
    .quad 7,13,480
    .quad 1,7,490
    .quad 5,11,500
singleton_out:
    .zero 72

.section .text
.global _start
.extern calendarDateSpaghetti
.extern monster_context_new
.extern monster_stage34_legacy_year5000_tie_handler
.extern monster_stage35_year5000_tie_patch_handler
.extern legacyYear5000TieSelection
.extern monster_year5000_tie_route
.extern year5000TieSelectionPatch17

.type require_legacy_scar,@function
require_legacy_scar:
    push rbp
    mov rbp,rsp
    lea rdi,[rip+year5000_tie_input]
    mov esi,2
    lea rdx,[rip+legacy_out]
    call legacyYear5000TieSelection
    test rax,rax
    je .Lrls_no
    cmp qword ptr [rax+YC_OPEN],9
    jne .Lrls_no
    lea rcx,[rip+legacy_out]
    cmp qword ptr [rcx+0],9
    jne .Lrls_no
    cmp qword ptr [rcx+24],3
    jne .Lrls_no
    mov eax,1
    leave
    ret
.Lrls_no:
    xor eax,eax
    leave
    ret
.size require_legacy_scar,.-require_legacy_scar

.type require_year5000_patch,@function
require_year5000_patch:
    push rbp
    mov rbp,rsp
    lea rdi,[rip+year5000_tie_input]
    mov esi,2
    lea rdx,[rip+route_out]
    call monster_year5000_tie_route
    test rax,rax
    je .Lryp_no
    cmp qword ptr [rax+YC_OPEN],3
    jne .Lryp_no
    lea rcx,[rip+route_out]
    cmp qword ptr [rcx+0],3
    jne .Lryp_no
    cmp qword ptr [rcx+24],9
    jne .Lryp_no
    mov eax,1
    leave
    ret
.Lryp_no:
    xor eax,eax
    leave
    ret
.size require_year5000_patch,.-require_year5000_patch

.type require_only_equal_runs_reordered,@function
require_only_equal_runs_reordered:
    push rbp
    mov rbp,rsp
    lea rdi,[rip+multi_run_input]
    mov esi,4
    lea rdx,[rip+multi_run_out]
    call year5000TieSelectionPatch17
    test rax,rax
    je .Lroerr_no
    cmp qword ptr [rax+YC_OPEN],3
    jne .Lroerr_no
    lea rcx,[rip+multi_run_out]
    cmp qword ptr [rcx+0],3
    jne .Lroerr_no
    cmp qword ptr [rcx+16],490
    jne .Lroerr_no
    cmp qword ptr [rcx+24],9
    jne .Lroerr_no
    cmp qword ptr [rcx+40],490
    jne .Lroerr_no
    cmp qword ptr [rcx+48],2
    jne .Lroerr_no
    cmp qword ptr [rcx+64],500
    jne .Lroerr_no
    cmp qword ptr [rcx+72],8
    jne .Lroerr_no
    cmp qword ptr [rcx+88],500
    jne .Lroerr_no
    mov eax,1
    leave
    ret
.Lroerr_no:
    xor eax,eax
    leave
    ret
.size require_only_equal_runs_reordered,.-require_only_equal_runs_reordered

.type require_singletons_unchanged,@function
require_singletons_unchanged:
    push rbp
    mov rbp,rsp
    lea rdi,[rip+singleton_input]
    mov esi,3
    lea rdx,[rip+singleton_out]
    call year5000TieSelectionPatch17
    test rax,rax
    je .Lrsu_no
    lea rcx,[rip+singleton_out]
    cmp qword ptr [rcx+0],7
    jne .Lrsu_no
    cmp qword ptr [rcx+16],480
    jne .Lrsu_no
    cmp qword ptr [rcx+24],1
    jne .Lrsu_no
    cmp qword ptr [rcx+40],490
    jne .Lrsu_no
    cmp qword ptr [rcx+48],5
    jne .Lrsu_no
    cmp qword ptr [rcx+64],500
    jne .Lrsu_no
    mov eax,1
    leave
    ret
.Lrsu_no:
    xor eax,eax
    leave
    ret
.size require_singletons_unchanged,.-require_singletons_unchanged

.type require_context_trace,@function
require_context_trace:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    mov rdi,-15055671
    mov rsi,-15055671
    call monster_context_new
    mov r12,rax
    test r12,r12
    je .Lrct_no
    mov rdi,r12
    call monster_stage34_legacy_year5000_tie_handler
    cmp eax,1
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE34_LEGACY_SELECTED_OPEN],9
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE34_ROUTE_SELECTED_OPEN],3
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE34_LEGACY_SEEN],1
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE34_ROUTE_SEEN],1
    jne .Lrct_no
    mov rdi,r12
    call monster_stage35_year5000_tie_patch_handler
    cmp eax,1
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE35_PATCH_SELECTED_OPEN],3
    jne .Lrct_no
    cmp qword ptr [r12+CTX_STAGE35_PATCH_SEEN],1
    jne .Lrct_no
    mov eax,1
    jmp .Lrct_done
.Lrct_no:
    xor eax,eax
.Lrct_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_context_trace,.-require_context_trace

.type _start,@function
_start:
    mov rdi,-15055671
    mov rsi,-15055671
    call calendarDateSpaghetti
    cmp eax,2
    jne .Lfail
    call require_legacy_scar
    test eax,eax
    je .Lfail
    call require_year5000_patch
    test eax,eax
    je .Lfail
    call require_only_equal_runs_reordered
    test eax,eax
    je .Lfail
    call require_singletons_unchanged
    test eax,eax
    je .Lfail
    call require_context_trace
    test eax,eax
    je .Lfail
    mov eax,1
    mov edi,1
    lea rsi,[rip+stage35_green]
    mov edx,stage35_green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Lfail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+stage35_fail]
    mov edx,stage35_fail_len
    syscall
    mov eax,60
    mov edi,35
    syscall
.size _start,.-_start
