; Native396 isolated candidate. Source only until opt-in build/harness integration.
; Requires calendar_gate_year.asm in the same build. Bank3 entry, bank0 trampolines.
; No SRAM writes or lease lifecycle operations here. Non-reentrant shared scratch.
SECTION "Calendar Stage1 directional buffers", WRAM0
wCalendarDirectionalInput:: ds 13
wCalendarDirectionalResult:: ds 18
wCalendarDirectionalStage:: ds 18
wCalendarDirectionalAnchor:: ds 4
wCalendarDirectionalOpenPhysical:: ds 2
wCalendarDirectionalClosePhysical:: ds 2
wCalendarDirectionalCount:: ds 1
wCalendarDirectionalRemaining:: ds 1
wCalendarDirectionalBudget:: ds 1
wCalendarDirectionalSpan:: ds 4
wCalendarDirectionalGap:: ds 2

SECTION "Calendar Stage1 directional selector", ROMX, BANK[3]
; Inclusive actual-map coverage, proven by Host map hash.
CalendarDirectionalLow: dl -15303131
CalendarDirectionalHigh: dl -14789634
CalendarDirectionalSix: dw 6
CalendarDirectionalMin: dw 252
CalendarDirectionalMax: dw 5778
CalendarDirectionalSelect::
    call CalendarGateYearValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wPairCalcOffset
    ld de, wCalendarGateYearSavedCalc
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wPairTargetOffset
    ld de, wCalendarGateYearSavedTarget
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarAnswerInputBowl
    ld de, wCalendarGateYearSavedAnswerBowl
    ld b, 1
    call CalendarGateYearCopyN
    ld hl, wCalendarAnswerInputSeal
    ld de, wCalendarGateYearSavedAnswerSeal
    ld b, 1
    call CalendarGateYearCopyN
    ld hl, wCalendarSelectCount
    ld de, wCalendarGateYearSavedSelectCount
    ld b, 2
    call CalendarGateYearCopyN
    ld hl, wCalendarSelectDirection
    ld de, wCalendarGateYearSavedSelectDirection
    ld b, 1
    call CalendarGateYearCopyN
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    jr z, .directionOkay
    cp $ff
    jp nz, .invalid
.directionOkay:
    ld hl, wPairCalcOffset
    ld de, CalendarDirectionalLow
    call CalendarGateYearCompareSigned32
    jp c, .invalid
    ld hl, CalendarDirectionalHigh
    ld de, wPairCalcOffset
    call CalendarGateYearCompareSigned32
    jp c, .invalid
    ; Translate each logical index by +512, reject outside physical 0..1024.
    ld hl, wCalendarDirectionalInput+8
    call CalendarDirectionalPhysical
    jp c, .invalid
    ld [wCalendarDirectionalOpenPhysical], a
    ld a, d
    ld [wCalendarDirectionalOpenPhysical+1], a
    ld hl, wCalendarDirectionalInput+10
    call CalendarDirectionalPhysical
    jp c, .invalid
    ld [wCalendarDirectionalClosePhysical], a
    ld a, d
    ld [wCalendarDirectionalClosePhysical+1], a
    ld a, [wCalendarDirectionalOpenPhysical+0]
    ld b, a
    ld a, [wCalendarDirectionalClosePhysical+0]
    sub b
    ld [wCalendarDirectionalGap+0], a
    ld a, [wCalendarDirectionalOpenPhysical+1]
    ld b, a
    ld a, [wCalendarDirectionalClosePhysical+1]
    sbc b
    ld [wCalendarDirectionalGap+1], a
    jp c, .invalid
    ld hl, wCalendarDirectionalGap
    ld de, CalendarDirectionalSix
    call CalendarGateYearCompare16
    jp c, .invalid
    ld hl, wCalendarDirectionalOpenPhysical
    ld de, wCalendarGateYearMapIndex
    ld b, 2
    call CalendarGateYearCopyN
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarDirectionalInput
    call CalendarGateYearCompareSigned32
    jp nz, .invalid
    ld hl, wCalendarDirectionalClosePhysical
    ld de, wCalendarGateYearMapIndex
    ld b, 2
    call CalendarGateYearCopyN
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarDirectionalInput+4
    call CalendarGateYearCompareSigned32
    jp nz, .invalid
    ld a, [wCalendarDirectionalInput+0]
    ld b, a
    ld a, [wCalendarDirectionalInput+4+0]
    sub b
    ld [wCalendarDirectionalSpan+0], a
    ld a, [wCalendarDirectionalInput+1]
    ld b, a
    ld a, [wCalendarDirectionalInput+4+1]
    sbc b
    ld [wCalendarDirectionalSpan+1], a
    ld a, [wCalendarDirectionalInput+2]
    ld b, a
    ld a, [wCalendarDirectionalInput+4+2]
    sbc b
    ld [wCalendarDirectionalSpan+2], a
    ld a, [wCalendarDirectionalInput+3]
    ld b, a
    ld a, [wCalendarDirectionalInput+4+3]
    sbc b
    ld [wCalendarDirectionalSpan+3], a
    call CalendarDirectionalSpanClass
    cp 1
    jp nz, .invalid
    ; Copy prior into staging only; replace nonfixed endpoint after second scan.
    ld hl, wCalendarDirectionalInput
    ld de, wCalendarDirectionalStage
    ld b, 12
    call CalendarGateYearCopyN
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    jr nz, .previous
    ld hl, wCalendarDirectionalInput+4
    ld de, wCalendarDirectionalAnchor
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, CalendarDirectionalHigh
    ld de, wCalendarDirectionalAnchor
    call CalendarGateYearCompareSigned32
    jp c, .invalid
    ld hl, wCalendarDirectionalInput+4
    ld de, wCalendarDirectionalStage
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarDirectionalInput+10
    ld de, wCalendarDirectionalStage+8
    ld b, 2
    call CalendarGateYearCopyN
    jp .scan
.previous:
    ld hl, wCalendarDirectionalInput
    ld de, wCalendarDirectionalAnchor
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarDirectionalAnchor
    ld de, CalendarDirectionalLow
    call CalendarGateYearCompareSigned32
    jp c, .invalid
    ld hl, wCalendarDirectionalInput
    ld de, wCalendarDirectionalStage+4
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarDirectionalInput+8
    ld de, wCalendarDirectionalStage+10
    ld b, 2
    call CalendarGateYearCopyN
.scan:
    xor a
    ld [wCalendarDirectionalCount], a
    ld [wCalendarDirectionalRemaining], a
    call CalendarDirectionalScan
    or a
    jp nz, .invalid
    ld a, [wCalendarDirectionalCount]
    or a
    jp z, .invalid
    ld [wCalendarDirectionalStage+14], a
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarDirectionalStage+15], a
    ld [wCalendarSelectCount+1], a
    ld a, [wCalendarGateYearSavedCalc+0]
    sub a, CALENDAR_GATE_YEAR_FOUNDATION_B0
    ld [wPairCalcOffset+0], a
    ld a, [wCalendarGateYearSavedCalc+1]
    sbc a, CALENDAR_GATE_YEAR_FOUNDATION_B1
    ld [wPairCalcOffset+1], a
    ld a, [wCalendarGateYearSavedCalc+2]
    sbc a, CALENDAR_GATE_YEAR_FOUNDATION_B2
    ld [wPairCalcOffset+2], a
    ld a, [wCalendarGateYearSavedCalc+3]
    sbc a, CALENDAR_GATE_YEAR_FOUNDATION_B3
    ld [wPairCalcOffset+3], a
    ld a, [wCalendarDirectionalAnchor+0]
    sub a, CALENDAR_GATE_YEAR_FOUNDATION_B0
    ld [wPairTargetOffset+0], a
    ld a, [wCalendarDirectionalAnchor+1]
    sbc a, CALENDAR_GATE_YEAR_FOUNDATION_B1
    ld [wPairTargetOffset+1], a
    ld a, [wCalendarDirectionalAnchor+2]
    sbc a, CALENDAR_GATE_YEAR_FOUNDATION_B2
    ld [wPairTargetOffset+2], a
    ld a, [wCalendarDirectionalAnchor+3]
    sbc a, CALENDAR_GATE_YEAR_FOUNDATION_B3
    ld [wPairTargetOffset+3], a
    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    ld a, 11
    jr z, .seal
    ld a, 12
.seal:
    ld [wCalendarAnswerInputSeal], a
    call CalendarGateYearRunSauce
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    ld a, [wCalendarSelectRank+1]
    or a
    jp nz, .invalid
    ld a, [wCalendarSelectRank]
    or a
    jp z, .invalid
    ld b, a
    ld a, [wCalendarDirectionalCount]
    cp b
    jp c, .invalid
    ld a, b
    ld [wCalendarDirectionalRemaining], a
    ld [wCalendarDirectionalStage+16], a
    xor a
    ld [wCalendarDirectionalStage+17], a
    call CalendarDirectionalScan
    cp 1
    jp nz, .invalid
    ; Selected map entry remains in MapValueAbs; physical index remains intact.
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    jr nz, .chosenPrevious
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarDirectionalStage+4
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarDirectionalStage+10
    jr .chosenIndex
.chosenPrevious:
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarDirectionalStage
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarDirectionalStage+8
.chosenIndex:
    ld a, [wCalendarGateYearMapIndex]
    ld [hli], a
    ld a, [wCalendarGateYearMapIndex+1]
    sub 2
    ld [hl], a
    ld hl, wCalendarDirectionalSpan
    ld de, wCalendarDirectionalStage+12
    ld b, 2
    call CalendarGateYearCopyN
    call CalendarGateYearRestoreInputs
    ld hl, wCalendarDirectionalStage
    ld de, wCalendarDirectionalResult
    ld b, 18
    call CalendarGateYearCopyN
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
.restore:
    jp CalendarGateYearRestoreInputs

; HL points to logical s16, return physical low A/high D, carry on invalid.
CalendarDirectionalPhysical:
    ld a, [hli]
    ld e, a
    ld a, [hl]
    add a, 2
    ld d, a
    cp 4
    jr c, .ok
    jr nz, .bad
    ld a, e
    or a
    jr nz, .bad
.ok:
    ld a, e
    and a
    ret
.bad:
    scf
    ret

; Classify full unsigned difference: 0 too short, 1 eligible, 2 too long.
CalendarDirectionalSpanClass:
    ld a, [wCalendarDirectionalSpan+2]
    ld b, a
    ld a, [wCalendarDirectionalSpan+3]
    or b
    jr nz, .long
    ld hl, CalendarDirectionalMax
    ld de, wCalendarDirectionalSpan
    call CalendarGateYearCompare16
    jr c, .long
    ld hl, wCalendarDirectionalSpan
    ld de, CalendarDirectionalMin
    call CalendarGateYearCompare16
    jr c, .short
    ld a, 1
    ret
.short:
    xor a
    ret
.long:
    ld a, 2
    ret

; First pass returns 0 at exhaustion. Second returns 1 at selected rank.
; 2 indicates unexpected budget/count overflow. Each map read is range checked.
CalendarDirectionalScan:
    ld a, 133
    ld [wCalendarDirectionalBudget], a
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    jr nz, .startPrevious
    ld a, [wCalendarDirectionalClosePhysical]
    add a, 6
    ld [wCalendarGateYearMapIndex], a
    ld a, [wCalendarDirectionalClosePhysical+1]
    adc a, 0
    ld [wCalendarGateYearMapIndex+1], a
    jr .loop
.startPrevious:
    ld a, [wCalendarDirectionalOpenPhysical]
    sub 6
    ld [wCalendarGateYearMapIndex], a
    ld a, [wCalendarDirectionalOpenPhysical+1]
    sbc a, 0
    ld [wCalendarGateYearMapIndex+1], a
.loop:
    ld a, [wCalendarGateYearMapIndex+1]
    cp 4
    jr c, .inMap
    jp nz, .end
    ld a, [wCalendarGateYearMapIndex]
    or a
    jp nz, .end
.inMap:
    ld hl, wCalendarDirectionalBudget
    ld a, [hl]
    or a
    jp z, .error
    dec [hl]
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    jp nz, .spanPrevious
    ld a, [wCalendarDirectionalAnchor+0]
    ld b, a
    ld a, [wCalendarGateYearMapValueAbs+0]
    sub b
    ld [wCalendarDirectionalSpan+0], a
    ld a, [wCalendarDirectionalAnchor+1]
    ld b, a
    ld a, [wCalendarGateYearMapValueAbs+1]
    sbc b
    ld [wCalendarDirectionalSpan+1], a
    ld a, [wCalendarDirectionalAnchor+2]
    ld b, a
    ld a, [wCalendarGateYearMapValueAbs+2]
    sbc b
    ld [wCalendarDirectionalSpan+2], a
    ld a, [wCalendarDirectionalAnchor+3]
    ld b, a
    ld a, [wCalendarGateYearMapValueAbs+3]
    sbc b
    ld [wCalendarDirectionalSpan+3], a
    jp .spanReady
.spanPrevious:
    ld a, [wCalendarGateYearMapValueAbs+0]
    ld b, a
    ld a, [wCalendarDirectionalAnchor+0]
    sub b
    ld [wCalendarDirectionalSpan+0], a
    ld a, [wCalendarGateYearMapValueAbs+1]
    ld b, a
    ld a, [wCalendarDirectionalAnchor+1]
    sbc b
    ld [wCalendarDirectionalSpan+1], a
    ld a, [wCalendarGateYearMapValueAbs+2]
    ld b, a
    ld a, [wCalendarDirectionalAnchor+2]
    sbc b
    ld [wCalendarDirectionalSpan+2], a
    ld a, [wCalendarGateYearMapValueAbs+3]
    ld b, a
    ld a, [wCalendarDirectionalAnchor+3]
    sbc b
    ld [wCalendarDirectionalSpan+3], a
.spanReady:
    call CalendarDirectionalSpanClass
    cp 2
    jp z, .end
    or a
    jr z, .advance
    ld hl, wCalendarDirectionalRemaining
    ld a, [hl]
    or a
    jr z, .count
    dec [hl]
    jr nz, .advance
    ld a, 1
    ret
.count:
    ld hl, wCalendarDirectionalCount
    inc [hl]
    ld a, [hl]
    cp 133
    jp nc, .error
.advance:
    ld hl, wCalendarGateYearMapIndex
    ld a, [wCalendarDirectionalInput+12]
    cp 1
    jr nz, .decrement
    inc [hl]
    jp nz, .loop
    inc hl
    inc [hl]
    jp .loop
.decrement:
    ld a, [hl]
    sub 1
    ld [hli], a
    ld a, [hl]
    sbc a, 0
    ld [hl], a
    jp .loop
.end:
    xor a
    ret
.error:
    ld a, 2
    ret
