; PC-BRANCH-SM83-ASSEMBLY-GEEZ / Stage1 Native395.
; Bounded source-derived 1025-entry gate map, signed32 offsets from Foundation.
; ROMX bank 2 stores the table; ROM0 trampolines read it and call bank-1 sauce.
; The selector builds [c-5778,c+5778], counts eligible (open,close] pairs,
; obtains the normative bowl-1/seal-10 rank, then selects by span high/low
; histograms and open-gate tie order. No sorting, truncation, or SRAM writes.

SECTION "Calendar Stage1 gate-year buffers", WRAM0
wCalendarGateYearSavedCalc:: ds 4
wCalendarGateYearSavedTarget:: ds 4
wCalendarGateYearSavedAnswerBowl:: ds 1
wCalendarGateYearSavedAnswerSeal:: ds 1
wCalendarGateYearSavedSelectCount:: ds 2
wCalendarGateYearSavedSelectDirection:: ds 1
wCalendarGateYearWindowLow:: ds 4
wCalendarGateYearWindowHigh:: ds 4
wCalendarGateYearMapIndex:: ds 2
wCalendarGateYearMapValue:: ds 4
wCalendarGateYearMapValueAbs:: ds 4
wCalendarGateYearDiff32:: ds 4
wCalendarGateYearSearchLo:: ds 2
wCalendarGateYearSearchHi:: ds 2
wCalendarGateYearMid:: ds 2
wCalendarGateYearLowerBound:: ds 2
wCalendarGateYearUpperBound:: ds 2
wCalendarGateYearGateCount:: ds 2
wCalendarGateYearLeftCount:: ds 1
wCalendarGateYearRightCount:: ds 1
wCalendarGateYearGatePos:: ds 2
; Exactly 276 signed16 gate offsets: 552 bytes.
wCalendarGateYearGates:: ds 552
wCalendarGateYearOpenPos:: ds 1
wCalendarGateYearClosePos:: ds 2
wCalendarGateYearIndexDiff:: ds 1
wCalendarGateYearOpenOffset:: ds 2
wCalendarGateYearCloseOffset:: ds 2
wCalendarGateYearSpan:: ds 2
wCalendarGateYearCandidateCount:: ds 2
; 23 high buckets * 16 bits = 46 bytes; 256 low buckets = 256 bytes.
wCalendarGateYearHighCounts:: ds 46
wCalendarGateYearLowCounts:: ds 256
wCalendarGateYearSelectedHigh:: ds 1
wCalendarGateYearSelectedLow:: ds 1
wCalendarGateYearBucketIndex:: ds 1
wCalendarGateYearRemaining:: ds 2
wCalendarGateYearCompareTmp:: ds 2
wCalendarGateYearSelectedSpan:: ds 2
wCalendarGateYearSelectedOpenRel:: ds 2
wCalendarGateYearSelectedCloseRel:: ds 2
wCalendarGateYearSignExtend:: ds 1
; Private publication block; copied to public result only after every gate passes.
wCalendarGateYearResultOpenScratch:: ds 4
wCalendarGateYearResultCloseScratch:: ds 4
wCalendarGateYearResultSpanScratch:: ds 2
wCalendarGateYearResultCountScratch:: ds 2
wCalendarGateYearResultRankScratch:: ds 2
wCalendarGateYearResultGateCountScratch:: ds 2
wCalendarGateYearResultLeftCountScratch:: ds 1
wCalendarGateYearResultRightCountScratch:: ds 1
; Public result ABI: keep these 18 bytes contiguous.
wCalendarGateYearResultOpen:: ds 4
wCalendarGateYearResultClose:: ds 4
wCalendarGateYearResultSpan:: ds 2
wCalendarGateYearResultCount:: ds 2
wCalendarGateYearResultRank:: ds 2
wCalendarGateYearResultGateCount:: ds 2
wCalendarGateYearResultLeftCount:: ds 1
wCalendarGateYearResultRightCount:: ds 1
wCalendarGateYearResultSnapshot:: ds 18

SECTION "Calendar Stage1 gate map", ROMX, BANK[2]
INCLUDE "build/calendar_gate_year_map.inc"

; All bank switching happens in fixed ROM0. The caller is Native395 code in
; bank 3; every trampoline restores bank 3 before returning.
SECTION "Calendar Stage1 gate-year bank trampolines", ROM0
CalendarGateYearValidate::
    ld a, 1
    ld [$2000], a
    xor a
    ld [$3000], a
    call CalendarOrdinalValidate
    ld a, 3
    ld [$2000], a
    xor a
    ld [$3000], a
    ret

; Input: wCalendarGateYearMapIndex (0..1024).
; Output: four little-endian signed bytes in wCalendarGateYearMapValue.
CalendarGateYearReadMap::
    ld a, 2
    ld [$2000], a
    xor a
    ld [$3000], a
    ld hl, CalendarGateYearMap
    ld a, [wCalendarGateYearMapIndex]
    ld e, a
    ld a, [wCalendarGateYearMapIndex+1]
    ld d, a
    sla e
    rl d
    sla e
    rl d
    add hl, de
    ld de, wCalendarGateYearMapValue
    ld b, 4
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ld a, 3
    ld [$2000], a
    xor a
    ld [$3000], a
    ret

; Run the existing independent source pipeline while bank 1 is mapped.
; The caller has already set pair=(c,c), bowl=1, seal=10 and N=candidate count.
CalendarGateYearRunSauce::
    ld a, 1
    ld [$2000], a
    xor a
    ld [$3000], a
    call CalendarBowlTrace46
    ld a, [wCalendarStatus]
    or a
    jr nz, .restore
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    or a
    jr nz, .restore
    call CalendarBowlAnswerShortRank
.restore:
    ld a, 3
    ld [$2000], a
    xor a
    ld [$3000], a
    ret

; Test-only lifecycle trampolines; production selection never resets/releases
; a caller's lease.
CalendarGateYearLeaseBegin::
    call SRAMEnable
    ld a, 1
    ld [$2000], a
    xor a
    ld [$3000], a
    call LeaseResetAll
    call CalendarInvocationBegin
    ld a, 3
    ld [$2000], a
    xor a
    ld [$3000], a
    ret

CalendarGateYearLeaseAbort::
    call SRAMEnable
    ld a, 1
    ld [$2000], a
    xor a
    ld [$3000], a
    call CalendarInvocationAbort
    ld a, 3
    ld [$2000], a
    xor a
    ld [$3000], a
    ret

SECTION "Calendar Stage1 bounded gate-year selector", ROMX, BANK[3]
CalendarGateYearSelect::
    call CalendarGateYearValidate
    ld a, [wCalendarStatus]
    or a
    ret nz

    ; Preserve the caller's pair and answer-input tuple on every active path.
    ld hl, wPairCalcOffset
    ld de, wCalendarGateYearSavedCalc
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wPairTargetOffset
    ld de, wCalendarGateYearSavedTarget
    ld b, 4
    call CalendarGateYearCopyN
    ld a, [wCalendarAnswerInputBowl]
    ld [wCalendarGateYearSavedAnswerBowl], a
    ld a, [wCalendarAnswerInputSeal]
    ld [wCalendarGateYearSavedAnswerSeal], a
    ld a, [wCalendarSelectCount]
    ld [wCalendarGateYearSavedSelectCount], a
    ld a, [wCalendarSelectCount+1]
    ld [wCalendarGateYearSavedSelectCount+1], a
    ld a, [wCalendarSelectDirection]
    ld [wCalendarGateYearSavedSelectDirection], a

    call CalendarGateYearBuildWindow
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    call CalendarGateYearCountCandidates
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore

    ; Normative answer flow is for (c,c), bowl 1, seal 10, N exact candidates.
    ld hl, wCalendarGateYearSavedCalc
    ld de, wPairTargetOffset
    ld b, 4
    call CalendarGateYearCopyN
    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld a, 10
    ld [wCalendarAnswerInputSeal], a
    ld a, [wCalendarGateYearCandidateCount]
    ld [wCalendarSelectCount], a
    ld a, [wCalendarGateYearCandidateCount+1]
    ld [wCalendarSelectCount+1], a
    call CalendarGateYearRunSauce
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore

    call CalendarGateYearSelectHigh
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    call CalendarGateYearBuildLow
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    call CalendarGateYearSelectLow
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    call CalendarGateYearFindPair
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    call CalendarGateYearPublish
    call CalendarGateYearRestoreInputs
    xor a
    ld [wCalendarStatus], a
    ret

.restore:
    call CalendarGateYearRestoreInputs
    ret

; Signed32 comparison: HL points to left, DE to right. Returns flags for left-right.
CalendarGateYearCompareSigned32::
    push hl
    push de
    ld bc, 3
    add hl, bc
    ld a, e
    add a, 3
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    ld a, [de]
    xor $80
    ld b, a
    ld a, [hl]
    xor $80
    cp b
    jr nz, .done
    dec hl
    dec de
    ld a, [de]
    ld b, a
    ld a, [hl]
    cp b
    jr nz, .done
    dec hl
    dec de
    ld a, [de]
    ld b, a
    ld a, [hl]
    cp b
    jr nz, .done
    dec hl
    dec de
    ld a, [de]
    ld b, a
    ld a, [hl]
    cp b
.done:
    pop de
    pop hl
    ret

; Unsigned16 comparison: HL points to left, DE to right. Returns flags for left-right.
CalendarGateYearCompare16::
    push hl
    push de
    inc hl
    inc de
    ld a, [de]
    ld b, a
    ld a, [hl]
    cp b
    jr nz, .done
    dec hl
    dec de
    ld a, [de]
    ld b, a
    ld a, [hl]
    cp b
.done:
    pop de
    pop hl
    ret

CalendarGateYearComputeMid::
    ld a, [wCalendarGateYearSearchLo]
    ld b, a
    ld a, [wCalendarGateYearSearchHi]
    add a, b
    ld [wCalendarGateYearMid], a
    ld a, [wCalendarGateYearSearchLo+1]
    ld b, a
    ld a, [wCalendarGateYearSearchHi+1]
    adc a, b
    srl a
    ld [wCalendarGateYearMid+1], a
    ld a, [wCalendarGateYearMid]
    rr a
    ld [wCalendarGateYearMid], a
    ld a, [wCalendarGateYearMid]
    ld [wCalendarGateYearMapIndex], a
    ld a, [wCalendarGateYearMid+1]
    ld [wCalendarGateYearMapIndex+1], a
    ret

CalendarGateYearMakeMapAbsolute::
    ; Map entries are signed offsets from Foundation (-15055671).
    ; Convert each to the absolute signed32 day number used by the sauce ABI.
    ld a, [wCalendarGateYearMapValue]
    ld b, a
    ld a, CALENDAR_GATE_YEAR_FOUNDATION_B0
    add a, b
    ld [wCalendarGateYearMapValueAbs], a
    ld a, [wCalendarGateYearMapValue+1]
    ld b, a
    ld a, CALENDAR_GATE_YEAR_FOUNDATION_B1
    adc a, b
    ld [wCalendarGateYearMapValueAbs+1], a
    ld a, [wCalendarGateYearMapValue+2]
    ld b, a
    ld a, CALENDAR_GATE_YEAR_FOUNDATION_B2
    adc a, b
    ld [wCalendarGateYearMapValueAbs+2], a
    ld a, [wCalendarGateYearMapValue+3]
    ld b, a
    ld a, CALENDAR_GATE_YEAR_FOUNDATION_B3
    adc a, b
    ld [wCalendarGateYearMapValueAbs+3], a
    ret

CalendarGateYearBuildWindow::
    ; Signed32 lo=c-5778, hi=c+5778. Reject signed overflow by requiring
    ; lo<c<hi, then require both requested edges to be covered by the map.
    ld hl, wCalendarGateYearSavedCalc
    ld de, wCalendarGateYearWindowLow
    ld a, [hli]
    sub a, $92
    ld [de], a
    inc de
    ld a, [hli]
    sbc a, $16
    ld [de], a
    inc de
    ld a, [hli]
    sbc a, 0
    ld [de], a
    inc de
    ld a, [hl]
    sbc a, 0
    ld [de], a

    ld hl, wCalendarGateYearSavedCalc
    ld de, wCalendarGateYearWindowHigh
    ld a, [hli]
    add a, $92
    ld [de], a
    inc de
    ld a, [hli]
    adc a, $16
    ld [de], a
    inc de
    ld a, [hli]
    adc a, 0
    ld [de], a
    inc de
    ld a, [hl]
    adc a, 0
    ld [de], a

    ld hl, wCalendarGateYearWindowLow
    ld de, wCalendarGateYearSavedCalc
    call CalendarGateYearCompareSigned32
    jp nc, .invalid
    ld hl, wCalendarGateYearWindowHigh
    ld de, wCalendarGateYearSavedCalc
    call CalendarGateYearCompareSigned32
    jp c, .invalid
    jp z, .invalid

    ; Map endpoints: map[0] <= lo and map[1024] >= hi.
    xor a
    ld [wCalendarGateYearMapIndex], a
    ld [wCalendarGateYearMapIndex+1], a
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarGateYearWindowLow
    call CalendarGateYearCompareSigned32
    jp c, .minimumCovered
    jp z, .minimumCovered
    jp .invalid
.minimumCovered:
    ld a, 0
    ld [wCalendarGateYearMapIndex], a
    ld a, 4
    ld [wCalendarGateYearMapIndex+1], a
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarGateYearWindowHigh
    call CalendarGateYearCompareSigned32
    jp c, .invalid

    ; lower_bound(first map entry >= lo), over the half-open index range [0,1025).
    xor a
    ld [wCalendarGateYearSearchLo], a
    ld [wCalendarGateYearSearchLo+1], a
    ld a, 1
    ld [wCalendarGateYearSearchHi], a
    ld a, 4
    ld [wCalendarGateYearSearchHi+1], a
.lowerLoop:
    ld hl, wCalendarGateYearSearchLo
    ld de, wCalendarGateYearSearchHi
    call CalendarGateYearCompare16
    jp nc, .lowerDone
    call CalendarGateYearComputeMid
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarGateYearWindowLow
    call CalendarGateYearCompareSigned32
    jp c, .lowerMoveLo
    ld a, [wCalendarGateYearMid]
    ld [wCalendarGateYearSearchHi], a
    ld a, [wCalendarGateYearMid+1]
    ld [wCalendarGateYearSearchHi+1], a
    jp .lowerLoop
.lowerMoveLo:
    ld a, [wCalendarGateYearMid]
    add a, 1
    ld [wCalendarGateYearSearchLo], a
    ld a, [wCalendarGateYearMid+1]
    adc a, 0
    ld [wCalendarGateYearSearchLo+1], a
    jp .lowerLoop
.lowerDone:
    ld a, [wCalendarGateYearSearchLo]
    ld [wCalendarGateYearLowerBound], a
    ld a, [wCalendarGateYearSearchLo+1]
    ld [wCalendarGateYearLowerBound+1], a

    ; upper_bound(first map entry > hi), starting at lower_bound.
    ld a, [wCalendarGateYearLowerBound]
    ld [wCalendarGateYearSearchLo], a
    ld a, [wCalendarGateYearLowerBound+1]
    ld [wCalendarGateYearSearchLo+1], a
    ld a, 1
    ld [wCalendarGateYearSearchHi], a
    ld a, 4
    ld [wCalendarGateYearSearchHi+1], a
.upperLoop:
    ld hl, wCalendarGateYearSearchLo
    ld de, wCalendarGateYearSearchHi
    call CalendarGateYearCompare16
    jp nc, .upperDone
    call CalendarGateYearComputeMid
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute
    ld hl, wCalendarGateYearMapValueAbs
    ld de, wCalendarGateYearWindowHigh
    call CalendarGateYearCompareSigned32
    jp c, .upperMoveLo
    jp z, .upperMoveLo
    ld a, [wCalendarGateYearMid]
    ld [wCalendarGateYearSearchHi], a
    ld a, [wCalendarGateYearMid+1]
    ld [wCalendarGateYearSearchHi+1], a
    jp .upperLoop
.upperMoveLo:
    ld a, [wCalendarGateYearMid]
    add a, 1
    ld [wCalendarGateYearSearchLo], a
    ld a, [wCalendarGateYearMid+1]
    adc a, 0
    ld [wCalendarGateYearSearchLo+1], a
    jp .upperLoop
.upperDone:
    ld a, [wCalendarGateYearSearchLo]
    ld [wCalendarGateYearUpperBound], a
    ld a, [wCalendarGateYearSearchLo+1]
    ld [wCalendarGateYearUpperBound+1], a

    ; gateCount = upper-lower; the proven maximum is 276.
    ld a, [wCalendarGateYearUpperBound]
    ld b, a
    ld a, [wCalendarGateYearLowerBound]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarGateYearGateCount], a
    ld a, [wCalendarGateYearUpperBound+1]
    ld b, a
    ld a, [wCalendarGateYearLowerBound+1]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarGateYearGateCount+1], a
    ld a, [wCalendarGateYearGateCount+1]
    or a
    jr z, .gateCountRangeOkay
    cp 1
    jp nz, .invalid
    ld a, [wCalendarGateYearGateCount]
    cp $15
    jp nc, .invalid
.gateCountRangeOkay:

    xor a
    ld [wCalendarGateYearLeftCount], a
    ld [wCalendarGateYearRightCount], a
    ld [wCalendarGateYearGatePos], a
    ld [wCalendarGateYearGatePos+1], a
.gateLoop:
    ld hl, wCalendarGateYearGatePos
    ld de, wCalendarGateYearGateCount
    call CalendarGateYearCompare16
    jp nc, .gatesDone

    ; mapIndex = lowerBound + gatePos
    ld a, [wCalendarGateYearLowerBound]
    ld b, a
    ld a, [wCalendarGateYearGatePos]
    add a, b
    ld [wCalendarGateYearMapIndex], a
    ld a, [wCalendarGateYearLowerBound+1]
    ld b, a
    ld a, [wCalendarGateYearGatePos+1]
    adc a, b
    ld [wCalendarGateYearMapIndex+1], a
    call CalendarGateYearReadMap
    call CalendarGateYearMakeMapAbsolute

    ; diff32 = absolute gate day - c; it must sign-extend to int16.
    ld a, [wCalendarGateYearMapValueAbs]
    ld b, a
    ld a, [wCalendarGateYearSavedCalc]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarGateYearDiff32], a
    ld a, [wCalendarGateYearMapValueAbs+1]
    ld b, a
    ld a, [wCalendarGateYearSavedCalc+1]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarGateYearDiff32+1], a
    ld a, [wCalendarGateYearMapValueAbs+2]
    ld b, a
    ld a, [wCalendarGateYearSavedCalc+2]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarGateYearDiff32+2], a
    ld a, [wCalendarGateYearMapValueAbs+3]
    ld b, a
    ld a, [wCalendarGateYearSavedCalc+3]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarGateYearDiff32+3], a

    ld a, [wCalendarGateYearDiff32+1]
    bit 7, a
    jp nz, .negativeOffset
    ld a, [wCalendarGateYearDiff32+2]
    ld b, a
    ld a, [wCalendarGateYearDiff32+3]
    or b
    jp nz, .invalid
    jp .storeOffset
.negativeOffset:
    ld a, [wCalendarGateYearDiff32+2]
    cp $ff
    jp nz, .invalid
    ld a, [wCalendarGateYearDiff32+3]
    cp $ff
    jp nz, .invalid
.storeOffset:
    ld hl, wCalendarGateYearGates
    ld a, [wCalendarGateYearGatePos]
    ld e, a
    ld a, [wCalendarGateYearGatePos+1]
    ld d, a
    sla e
    rl d
    add hl, de
    ld a, [wCalendarGateYearDiff32]
    ld [hli], a
    ld a, [wCalendarGateYearDiff32+1]
    ld [hl], a

    ld a, [wCalendarGateYearDiff32+1]
    bit 7, a
    jr z, .rightGate
    ld hl, wCalendarGateYearLeftCount
    inc [hl]
    jr .nextGate
.rightGate:
    ld hl, wCalendarGateYearRightCount
    inc [hl]
.nextGate:
    ld hl, wCalendarGateYearGatePos
    inc [hl]
    jp nz, .gateLoop
    inc hl
    inc [hl]
    jp .gateLoop

.gatesDone:
    ld a, [wCalendarGateYearLeftCount]
    cp 139
    jp nc, .invalid
    ld a, [wCalendarGateYearRightCount]
    cp 139
    jp nc, .invalid
    xor a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarGateYearCountCandidates::
    ; Clear all 23 16-bit high counters.
    ld hl, wCalendarGateYearHighCounts
    ld b, 46
    xor a
.clearHigh:
    ld [hli], a
    dec b
    jr nz, .clearHigh
    xor a
    ld [wCalendarGateYearCandidateCount], a
    ld [wCalendarGateYearCandidateCount+1], a
    ld [wCalendarGateYearOpenPos], a
.openLoop:
    ld a, [wCalendarGateYearOpenPos]
    ld b, a
    ld a, [wCalendarGateYearLeftCount]
    cp b
    jp c, .countDone
    jp z, .countDone
    ld a, [wCalendarGateYearLeftCount]
    ld [wCalendarGateYearClosePos], a
    xor a
    ld [wCalendarGateYearClosePos+1], a
.closeLoop:
    ld hl, wCalendarGateYearClosePos
    ld de, wCalendarGateYearGateCount
    call CalendarGateYearCompare16
    jp nc, .nextOpen
    call CalendarGateYearLoadPairSpan
    or a
    jr z, .skipCount
    ld hl, wCalendarGateYearCandidateCount
    inc [hl]
    jr nz, .candidateCounted
    inc hl
    inc [hl]
.candidateCounted:
    ld hl, wCalendarGateYearHighCounts
    ld a, [wCalendarGateYearSpan+1]
    ld e, a
    ld d, 0
    add hl, de
    add hl, de
    inc [hl]
    jr nz, .skipCount
    inc hl
    inc [hl]
.skipCount:
    ld hl, wCalendarGateYearClosePos
    inc [hl]
    jp nz, .closeLoop
    inc hl
    inc [hl]
    jp .closeLoop
.nextOpen:
    ld hl, wCalendarGateYearOpenPos
    inc [hl]
    jp .openLoop
.countDone:
    ld a, [wCalendarGateYearCandidateCount]
    ld b, a
    ld a, [wCalendarGateYearCandidateCount+1]
    or b
    jp z, .invalid
    ld a, [wCalendarGateYearCandidateCount+1]
    cp $4a
    jr c, .countOkay
    jp nz, .invalid
    ld a, [wCalendarGateYearCandidateCount]
    cp $65
    jp nc, .invalid
.countOkay:
    ld a, [wCalendarGateYearCandidateCount]
    ld [wCalendarSelectCount], a
    ld a, [wCalendarGateYearCandidateCount+1]
    ld [wCalendarSelectCount+1], a
    xor a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

; Load gate offsets at (openPos,closePos), require index gap >=6 and
; span 252..5778. Returns A=1 valid, A=0 otherwise.
CalendarGateYearLoadPairSpan::
    ld a, [wCalendarGateYearClosePos]
    ld b, a
    ld a, [wCalendarGateYearOpenPos]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarGateYearIndexDiff], a
    ld a, [wCalendarGateYearClosePos+1]
    sbc a, 0
    jr nz, .indexOkay
    ld a, [wCalendarGateYearIndexDiff]
    cp 6
    jp c, .invalid
.indexOkay:
    ld hl, wCalendarGateYearGates
    ld a, [wCalendarGateYearOpenPos]
    ld e, a
    ld d, 0
    sla e
    rl d
    add hl, de
    ld a, [hli]
    ld [wCalendarGateYearOpenOffset], a
    ld a, [hl]
    ld [wCalendarGateYearOpenOffset+1], a

    ld hl, wCalendarGateYearGates
    ld a, [wCalendarGateYearClosePos]
    ld e, a
    ld a, [wCalendarGateYearClosePos+1]
    ld d, a
    sla e
    rl d
    add hl, de
    ld a, [hli]
    ld [wCalendarGateYearCloseOffset], a
    ld a, [hl]
    ld [wCalendarGateYearCloseOffset+1], a

    ld a, [wCalendarGateYearCloseOffset]
    ld b, a
    ld a, [wCalendarGateYearOpenOffset]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarGateYearSpan], a
    ld a, [wCalendarGateYearCloseOffset+1]
    ld b, a
    ld a, [wCalendarGateYearOpenOffset+1]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarGateYearSpan+1], a

    ld a, [wCalendarGateYearSpan+1]
    cp $16
    jr c, .checkMinimum
    jp nz, .invalid
    ld a, [wCalendarGateYearSpan]
    cp $93
    jp nc, .invalid
.checkMinimum:
    ld a, [wCalendarGateYearSpan+1]
    or a
    jr nz, .valid
    ld a, [wCalendarGateYearSpan]
    cp $fc
    jp c, .invalid
.valid:
    ld a, 1
    ret
.invalid:
    xor a
    ret

CalendarGateYearSelectHigh::
    ld a, [wCalendarSelectRank]
    ld [wCalendarGateYearRemaining], a
    ld a, [wCalendarSelectRank+1]
    ld [wCalendarGateYearRemaining+1], a
    xor a
    ld [wCalendarGateYearBucketIndex], a
.highLoop:
    ld a, [wCalendarGateYearBucketIndex]
    cp 23
    jp nc, .invalid
    ld hl, wCalendarGateYearHighCounts
    ld a, [wCalendarGateYearBucketIndex]
    ld e, a
    ld d, 0
    add hl, de
    add hl, de
    ld a, [wCalendarGateYearRemaining]
    ld b, a
    ld a, [hl]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarGateYearCompareTmp], a
    inc hl
    ld a, [wCalendarGateYearRemaining+1]
    ld b, a
    ld a, [hl]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarGateYearCompareTmp+1], a
    jp c, .highFound
    ld a, [wCalendarGateYearCompareTmp]
    ld b, a
    ld a, [wCalendarGateYearCompareTmp+1]
    or b
    jp z, .highFound
    ld a, [wCalendarGateYearCompareTmp]
    ld [wCalendarGateYearRemaining], a
    ld a, [wCalendarGateYearCompareTmp+1]
    ld [wCalendarGateYearRemaining+1], a
    ld hl, wCalendarGateYearBucketIndex
    inc [hl]
    jp .highLoop
.highFound:
    ld a, [wCalendarGateYearBucketIndex]
    ld [wCalendarGateYearSelectedHigh], a
    xor a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarGateYearBuildLow::
    ; Exactly 256 zeroed 8-bit low counters.
    ld hl, wCalendarGateYearLowCounts
    ld b, 0
    xor a
.clearLow:
    ld [hli], a
    dec b
    jr nz, .clearLow
    xor a
    ld [wCalendarGateYearOpenPos], a
.lowOpenLoop:
    ld a, [wCalendarGateYearOpenPos]
    ld b, a
    ld a, [wCalendarGateYearLeftCount]
    cp b
    jp c, .done
    jp z, .done
    ld a, [wCalendarGateYearLeftCount]
    ld [wCalendarGateYearClosePos], a
    xor a
    ld [wCalendarGateYearClosePos+1], a
.lowCloseLoop:
    ld hl, wCalendarGateYearClosePos
    ld de, wCalendarGateYearGateCount
    call CalendarGateYearCompare16
    jp nc, .nextLowOpen
    call CalendarGateYearLoadPairSpan
    or a
    jr z, .skipLow
    ld a, [wCalendarGateYearSpan+1]
    ld b, a
    ld a, [wCalendarGateYearSelectedHigh]
    cp b
    jr nz, .skipLow
    ld hl, wCalendarGateYearLowCounts
    ld a, [wCalendarGateYearSpan]
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    cp $ff
    jp z, .invalid
    inc [hl]
.skipLow:
    ld hl, wCalendarGateYearClosePos
    inc [hl]
    jp nz, .lowCloseLoop
    inc hl
    inc [hl]
    jp .lowCloseLoop
.nextLowOpen:
    ld hl, wCalendarGateYearOpenPos
    inc [hl]
    jp .lowOpenLoop
.done:
    xor a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarGateYearSelectLow::
    xor a
    ld [wCalendarGateYearBucketIndex], a
    ld hl, wCalendarGateYearLowCounts
.lowSelectLoop:
    ld a, [wCalendarGateYearRemaining+1]
    or a
    jr nz, .subtractLow
    ld a, [wCalendarGateYearRemaining]
    cp [hl]
    jr c, .lowFound
    jr z, .lowFound
.subtractLow:
    ld a, [wCalendarGateYearRemaining]
    sub [hl]
    ld [wCalendarGateYearRemaining], a
    ld a, [wCalendarGateYearRemaining+1]
    sbc a, 0
    ld [wCalendarGateYearRemaining+1], a
    inc hl
    ld hl, wCalendarGateYearBucketIndex
    inc [hl]
    ld a, [wCalendarGateYearBucketIndex]
    or a
    jp z, .invalid
    ld hl, wCalendarGateYearLowCounts
    ld a, [wCalendarGateYearBucketIndex]
    ld e, a
    ld d, 0
    add hl, de
    jp .lowSelectLoop
.lowFound:
    ld a, [wCalendarGateYearBucketIndex]
    ld [wCalendarGateYearSelectedLow], a
    ld [wCalendarGateYearSelectedSpan], a
    ld a, [wCalendarGateYearSelectedHigh]
    ld [wCalendarGateYearSelectedSpan+1], a
    xor a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarGateYearFindPair::
    xor a
    ld [wCalendarGateYearOpenPos], a
.findOpenLoop:
    ld a, [wCalendarGateYearOpenPos]
    ld b, a
    ld a, [wCalendarGateYearLeftCount]
    cp b
    jp c, .invalid
    jp z, .invalid
    ld a, [wCalendarGateYearLeftCount]
    ld [wCalendarGateYearClosePos], a
    xor a
    ld [wCalendarGateYearClosePos+1], a
.findCloseLoop:
    ld hl, wCalendarGateYearClosePos
    ld de, wCalendarGateYearGateCount
    call CalendarGateYearCompare16
    jp nc, .nextFindOpen
    call CalendarGateYearLoadPairSpan
    or a
    jr z, .skipFind
    ld a, [wCalendarGateYearSpan]
    ld b, a
    ld a, [wCalendarGateYearSelectedSpan]
    cp b
    jr nz, .skipFind
    ld a, [wCalendarGateYearSpan+1]
    ld b, a
    ld a, [wCalendarGateYearSelectedSpan+1]
    cp b
    jr nz, .skipFind
    ld a, [wCalendarGateYearRemaining]
    sub 1
    ld [wCalendarGateYearRemaining], a
    ld a, [wCalendarGateYearRemaining+1]
    sbc a, 0
    ld [wCalendarGateYearRemaining+1], a
    ld a, [wCalendarGateYearRemaining]
    ld b, a
    ld a, [wCalendarGateYearRemaining+1]
    or b
    jp z, .found
.skipFind:
    ld hl, wCalendarGateYearClosePos
    inc [hl]
    jp nz, .findCloseLoop
    inc hl
    inc [hl]
    jp .findCloseLoop
.nextFindOpen:
    ld hl, wCalendarGateYearOpenPos
    inc [hl]
    jp .findOpenLoop
.found:
    ld a, [wCalendarGateYearOpenOffset]
    ld [wCalendarGateYearSelectedOpenRel], a
    ld a, [wCalendarGateYearOpenOffset+1]
    ld [wCalendarGateYearSelectedOpenRel+1], a
    ld a, [wCalendarGateYearCloseOffset]
    ld [wCalendarGateYearSelectedCloseRel], a
    ld a, [wCalendarGateYearCloseOffset+1]
    ld [wCalendarGateYearSelectedCloseRel+1], a
    xor a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarGateYearPublish::
    ; Absolute gate offsets from Foundation = c + sign-extended relative offset.
    ld a, [wCalendarGateYearSelectedOpenRel+1]
    and $80
    jr z, .openPositive
    ld a, $ff
    jr .openSignReady
.openPositive:
    xor a
.openSignReady:
    ld [wCalendarGateYearSignExtend], a
    ld a, [wCalendarGateYearSavedCalc]
    ld b, a
    ld a, [wCalendarGateYearSelectedOpenRel]
    add a, b
    ld [wCalendarGateYearResultOpenScratch], a
    ld a, [wCalendarGateYearSavedCalc+1]
    ld b, a
    ld a, [wCalendarGateYearSelectedOpenRel+1]
    adc a, b
    ld [wCalendarGateYearResultOpenScratch+1], a
    ld a, [wCalendarGateYearSavedCalc+2]
    ld b, a
    ld a, [wCalendarGateYearSignExtend]
    adc a, b
    ld [wCalendarGateYearResultOpenScratch+2], a
    ld a, [wCalendarGateYearSavedCalc+3]
    ld b, a
    ld a, [wCalendarGateYearSignExtend]
    adc a, b
    ld [wCalendarGateYearResultOpenScratch+3], a

    ld a, [wCalendarGateYearSelectedCloseRel+1]
    and $80
    jr z, .closePositive
    ld a, $ff
    jr .closeSignReady
.closePositive:
    xor a
.closeSignReady:
    ld [wCalendarGateYearSignExtend], a
    ld a, [wCalendarGateYearSavedCalc]
    ld b, a
    ld a, [wCalendarGateYearSelectedCloseRel]
    add a, b
    ld [wCalendarGateYearResultCloseScratch], a
    ld a, [wCalendarGateYearSavedCalc+1]
    ld b, a
    ld a, [wCalendarGateYearSelectedCloseRel+1]
    adc a, b
    ld [wCalendarGateYearResultCloseScratch+1], a
    ld a, [wCalendarGateYearSavedCalc+2]
    ld b, a
    ld a, [wCalendarGateYearSignExtend]
    adc a, b
    ld [wCalendarGateYearResultCloseScratch+2], a
    ld a, [wCalendarGateYearSavedCalc+3]
    ld b, a
    ld a, [wCalendarGateYearSignExtend]
    adc a, b
    ld [wCalendarGateYearResultCloseScratch+3], a

    ld a, [wCalendarGateYearSelectedSpan]
    ld [wCalendarGateYearResultSpanScratch], a
    ld a, [wCalendarGateYearSelectedSpan+1]
    ld [wCalendarGateYearResultSpanScratch+1], a
    ld a, [wCalendarGateYearCandidateCount]
    ld [wCalendarGateYearResultCountScratch], a
    ld a, [wCalendarGateYearCandidateCount+1]
    ld [wCalendarGateYearResultCountScratch+1], a
    ld a, [wCalendarSelectRank]
    ld [wCalendarGateYearResultRankScratch], a
    ld a, [wCalendarSelectRank+1]
    ld [wCalendarGateYearResultRankScratch+1], a
    ld a, [wCalendarGateYearGateCount]
    ld [wCalendarGateYearResultGateCountScratch], a
    ld a, [wCalendarGateYearGateCount+1]
    ld [wCalendarGateYearResultGateCountScratch+1], a
    ld a, [wCalendarGateYearLeftCount]
    ld [wCalendarGateYearResultLeftCountScratch], a
    ld a, [wCalendarGateYearRightCount]
    ld [wCalendarGateYearResultRightCountScratch], a

    ld hl, wCalendarGateYearResultOpenScratch
    ld de, wCalendarGateYearResultOpen
    ld b, 18
    jp CalendarGateYearCopyN

CalendarGateYearRestoreInputs::
    ld hl, wCalendarGateYearSavedCalc
    ld de, wPairCalcOffset
    ld b, 4
    call CalendarGateYearCopyN
    ld hl, wCalendarGateYearSavedTarget
    ld de, wPairTargetOffset
    ld b, 4
    call CalendarGateYearCopyN
    ld a, [wCalendarGateYearSavedAnswerBowl]
    ld [wCalendarAnswerInputBowl], a
    ld a, [wCalendarGateYearSavedAnswerSeal]
    ld [wCalendarAnswerInputSeal], a
    ld a, [wCalendarGateYearSavedSelectCount]
    ld [wCalendarSelectCount], a
    ld a, [wCalendarGateYearSavedSelectCount+1]
    ld [wCalendarSelectCount+1], a
    ld a, [wCalendarGateYearSavedSelectDirection]
    ld [wCalendarSelectDirection], a
    ret

CalendarGateYearCopyN::
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret
