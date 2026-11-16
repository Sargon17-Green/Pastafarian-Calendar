; Separate invocation entry, with an explicit not-implemented result.
; Stage 1 MUST NOT claim to compute a complete calendar date.
SECTION "Production bootstrap dispatcher", ROM0
calendarDateSpaghetti::
    ld a, $40
    ld [wRunStatus], a  ; stage not yet implemented
    ret


; Stage1 owned invocation (ROMX bank1). DI/serialized, SRAM enabled,
; lease table initialized and active byte zero while idle. NOT a date engine.
SECTION "Calendar ownership lifecycle", ROMX, BANK[1]
CalendarInvocationBegin::
    ld a, [wCalendarActive]
    or a
    jr z, .allocate
    ld a, 5
    ld [wCalendarStatus], a
    ret
.allocate:
    ld a, [wCalendarRequestedOwner]
    ld [wOwnerRequest], a
    ld a, [wCalendarRequestedBanks]
    ld [wOwnerCount], a
    call OwnerLeaseAlloc
    ld a, [wOwnerStatus]
    ld [wCalendarStatus], a
    or a
    ret nz
    ld a, 1
    ld [wCalendarActive], a
    ld a, [wCalendarRequestedOwner]
    ld [wCalendarActiveOwner], a
    xor a
    ld [wCalendarOrdinalSign], a
    ld [wCalendarOrdinalLength], a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ret
CalendarInvocationAbort::
    ld a, [wCalendarActive]
    cp 1
    jr z, .release
    ld a, 6
    ld [wCalendarStatus], a
    ret
.release:
    ld a, [wCalendarActiveOwner]
    ld [wOwnerRequest], a
    call OwnerLeaseRelease
    ld a, [wOwnerStatus]
    ld [wCalendarStatus], a
    or a
    ret nz
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wCalendarOrdinalSign], a
    ld [wCalendarOrdinalLength], a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ret
