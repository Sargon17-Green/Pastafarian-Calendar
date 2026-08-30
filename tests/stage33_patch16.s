.intel_syntax noprefix
.equ CTX_STAGE32_LEGACY_YEAR_MAX_OBSERVED,1288
.equ CTX_STAGE32_CANDIDATE_MASK,1296
.equ CTX_STAGE32_LEGACY_SEEN,1304
.equ CTX_STAGE33_REAL_YEAR_MAX_OBSERVED,1312
.equ CTX_STAGE33_LEGACY_RAW_COUNT,1320
.equ CTX_STAGE33_REJECTED_BEFORE_SORT_COUNT,1328
.equ CTX_STAGE33_FILTERED_PRE_SORT_COUNT,1336
.equ CTX_STAGE33_SORTED_COUNT,1344
.equ CTX_STAGE33_SELECTION_CALLED,1352
.equ CTX_STAGE33_SELECTED_LENGTH,1360
.equ CTX_STAGE33_PATCH_SEEN,1368
.equ YC_OPEN,0
.equ YC_CLOSE,8
.equ YC_LENGTH,16
.equ YC_SIZE,24

.section .rodata
green_token: .ascii "STAGE33_PATCH16_GREEN\n"
green_len = . - green_token
fail_token: .ascii "STAGE33_PATCH16_FAIL\n"
fail_len = . - fail_token

.align 8
family_input:
    .quad 40,46,5781
    .quad 20,26,5779
    .quad 10,16,5778
    .quad 30,36,5780

tie_input:
    .quad 9,15,490
    .quad 3,9,490

.section .bss
.align 16
raw_out: .skip 96
filtered_out: .skip 96
sorted_out: .skip 96
tie_filtered: .skip 48
tie_sorted: .skip 48

.section .text
.extern oldYearCandidate
.extern monster_year_candidate_route
.extern legacyYearCandidatesBeforeSortStage33
.extern yearCandidatesAfterFootnotePatchBeforeSort
.extern stableLengthOnlyPatchedYearCandidates
.extern legacyYearSelectFirst
.extern monster_context_new
.extern monster_stage32_legacy_year_max_handler
.extern monster_stage33_year_ceiling_patch_handler
.extern calendarDateSpaghetti
.global _start

.type require_route_patch,@function
require_route_patch:
    push rbp
    mov rbp,rsp
    mov edi,6
    mov esi,5781
    call oldYearCandidate
    cmp eax,1
    jne .Lrrp_fail
    mov edi,6
    mov esi,5778
    call monster_year_candidate_route
    cmp eax,1
    jne .Lrrp_fail
    mov edi,6
    mov esi,5779
    call monster_year_candidate_route
    test eax,eax
    jne .Lrrp_fail
    mov edi,6
    mov esi,5780
    call monster_year_candidate_route
    test eax,eax
    jne .Lrrp_fail
    mov edi,6
    mov esi,5781
    call monster_year_candidate_route
    test eax,eax
    jne .Lrrp_fail
    mov edi,6
    mov esi,252
    call monster_year_candidate_route
    cmp eax,1
    jne .Lrrp_fail
    mov edi,6
    mov esi,251
    call monster_year_candidate_route
    test eax,eax
    jne .Lrrp_fail
    mov eax,1
    leave
    ret
.Lrrp_fail:
    xor eax,eax
    leave
    ret
.size require_route_patch,.-require_route_patch

.type require_family_filter_before_sort,@function
require_family_filter_before_sort:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8
    lea rdi,[rip+family_input]
    mov esi,4
    lea rdx,[rip+raw_out]
    call legacyYearCandidatesBeforeSortStage33
    cmp rax,4
    jne .Lrffbs_fail
    lea r12,[rip+raw_out]
    cmp qword ptr [r12+16],5781
    jne .Lrffbs_fail
    cmp qword ptr [r12+40],5779
    jne .Lrffbs_fail
    cmp qword ptr [r12+64],5778
    jne .Lrffbs_fail
    cmp qword ptr [r12+88],5780
    jne .Lrffbs_fail

    lea rdi,[rip+family_input]
    mov esi,4
    lea rdx,[rip+filtered_out]
    call yearCandidatesAfterFootnotePatchBeforeSort
    cmp rax,1
    jne .Lrffbs_fail
    lea r12,[rip+filtered_out]
    cmp qword ptr [r12+YC_LENGTH],5778
    jne .Lrffbs_fail

    lea rdi,[rip+filtered_out]
    mov esi,1
    lea rdx,[rip+sorted_out]
    call stableLengthOnlyPatchedYearCandidates
    cmp rax,1
    jne .Lrffbs_fail
    lea r12,[rip+sorted_out]
    cmp qword ptr [r12+YC_LENGTH],5778
    jne .Lrffbs_fail
    mov rdi,r12
    mov esi,1
    call legacyYearSelectFirst
    test rax,rax
    je .Lrffbs_fail
    cmp qword ptr [rax+YC_LENGTH],5778
    jne .Lrffbs_fail
    mov eax,1
    jmp .Lrffbs_done
.Lrffbs_fail:
    xor eax,eax
.Lrffbs_done:
    add rsp,8
    pop r12
    leave
    ret
.size require_family_filter_before_sort,.-require_family_filter_before_sort

.type require_no_tie_patch_yet,@function
require_no_tie_patch_yet:
    push rbp
    mov rbp,rsp
    lea rdi,[rip+tie_input]
    mov esi,2
    lea rdx,[rip+tie_filtered]
    call yearCandidatesAfterFootnotePatchBeforeSort
    cmp rax,2
    jne .Lrntpy_fail
    lea rdi,[rip+tie_filtered]
    mov esi,2
    lea rdx,[rip+tie_sorted]
    call stableLengthOnlyPatchedYearCandidates
    cmp rax,2
    jne .Lrntpy_fail
    lea r8,[rip+tie_sorted]
    cmp qword ptr [r8+0],9
    jne .Lrntpy_fail
    cmp qword ptr [r8+24],3
    jne .Lrntpy_fail
    cmp qword ptr [r8+16],490
    jne .Lrntpy_fail
    cmp qword ptr [r8+40],490
    jne .Lrntpy_fail
    mov eax,1
    leave
    ret
.Lrntpy_fail:
    xor eax,eax
    leave
    ret
.size require_no_tie_patch_yet,.-require_no_tie_patch_yet

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
    je .Lrct_fail
    mov rdi,r12
    call monster_stage32_legacy_year_max_handler
    cmp eax,1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE32_LEGACY_YEAR_MAX_OBSERVED],5781
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE32_CANDIDATE_MASK],15
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE32_LEGACY_SEEN],1
    jne .Lrct_fail
    mov rdi,r12
    call monster_stage33_year_ceiling_patch_handler
    cmp eax,1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_REAL_YEAR_MAX_OBSERVED],5778
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_LEGACY_RAW_COUNT],4
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_REJECTED_BEFORE_SORT_COUNT],3
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_FILTERED_PRE_SORT_COUNT],1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_SORTED_COUNT],1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_SELECTION_CALLED],1
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_SELECTED_LENGTH],5778
    jne .Lrct_fail
    cmp qword ptr [r12+CTX_STAGE33_PATCH_SEEN],1
    jne .Lrct_fail
    mov eax,1
    jmp .Lrct_done
.Lrct_fail:
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
    call require_route_patch
    test eax,eax
    je .Lfail
    call require_family_filter_before_sort
    test eax,eax
    je .Lfail
    call require_no_tie_patch_yet
    test eax,eax
    je .Lfail
    call require_context_trace
    test eax,eax
    je .Lfail

    mov eax,1
    mov edi,1
    lea rsi,[rip+green_token]
    mov edx,green_len
    syscall
    mov eax,60
    xor edi,edi
    syscall
.Lfail:
    mov eax,1
    mov edi,1
    lea rsi,[rip+fail_token]
    mov edx,fail_len
    syscall
    mov eax,60
    mov edi,33
    syscall
.size _start,.-_start
