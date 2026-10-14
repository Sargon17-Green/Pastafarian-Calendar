; Separate invocation entry, with an explicit not-implemented result.
; Stage 1 MUST NOT claim to compute a complete calendar date.
SECTION "Production bootstrap dispatcher", ROM0
calendarDateSpaghetti::
    ld a, $40
    ld [wRunStatus], a  ; stage not yet implemented
    ret
