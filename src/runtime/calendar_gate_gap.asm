; PC-BRANCH-SM83-ASSEMBLY-GEEZ / Stage1 Native394.
; One source-derived gate gap, with a bounded 1..512 index.
; Positive: sauce(F,F+n); negative: sauce(F,F-n).
; Both use bowl 1, seal 1, N=922; gap = selected rank + 41.
; Pair offsets and answer-input tuple are restored on every path.
; The public result is committed only after the complete sauce/answer path succeeds.

SECTION "Calendar Stage1 gate gap ABI", WRAM0
wCalendarGateGapIndex:: ds 2
wCalendarGateGapDirection:: ds 1 ; 1=positive, 2=negative
wCalendarGateGapResult:: ds 2
wCalendarGateGapResultScratch:: ds 2
wCalendarGateGapSavedCalc:: ds 4
wCalendarGateGapSavedTarget:: ds 4
wCalendarGateGapSavedAnswerBowl:: ds 1
wCalendarGateGapSavedAnswerSeal:: ds 1
wCalendarGateGapSavedSelectCount:: ds 2
wCalendarGateGapSavedSelectDirection:: ds 1

SECTION "Calendar Stage1 gate gap generator", ROMX, BANK[1]
CalendarGateGap::
    ; An inactive or invalid ordinal must not publish a result.
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz

    ; Native Stage1 bound: 1 <= n <= 512.
    ld a, [wCalendarGateGapIndex]
    ld b, a
    ld a, [wCalendarGateGapIndex+1]
    or b
    jp z, .invalid
    ld a, [wCalendarGateGapIndex+1]
    cp 2
    jr c, .indexValid
    jp nz, .invalid
    ld a, [wCalendarGateGapIndex]
    or a
    jp nz, .invalid
.indexValid:
    ld a, [wCalendarGateGapDirection]
    cp 1
    jr z, .inputsValid
    cp 2
    jp nz, .invalid

.inputsValid:
    ; Preserve caller-owned pair and answer-input state.
    ld hl, wPairCalcOffset
    ld de, wCalendarGateGapSavedCalc
    ld b, 4
    call .copyN
    ld hl, wPairTargetOffset
    ld de, wCalendarGateGapSavedTarget
    ld b, 4
    call .copyN
    ld a, [wCalendarAnswerInputBowl]
    ld [wCalendarGateGapSavedAnswerBowl], a
    ld a, [wCalendarAnswerInputSeal]
    ld [wCalendarGateGapSavedAnswerSeal], a
    ld a, [wCalendarSelectCount]
    ld [wCalendarGateGapSavedSelectCount], a
    ld a, [wCalendarSelectCount+1]
    ld [wCalendarGateGapSavedSelectCount+1], a
    ld a, [wCalendarSelectDirection]
    ld [wCalendarGateGapSavedSelectDirection], a

    ; The canonical calculation point is F, represented by offset zero.
    ld hl, wPairCalcOffset
    xor a
    ld b, 4
.clearCalc:
    ld [hli], a
    dec b
    jr nz, .clearCalc

    ; Start with the positive 32-bit target offset +n.
    ld hl, wCalendarGateGapIndex
    ld de, wPairTargetOffset
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    inc de
    xor a
    ld [de], a
    inc de
    ld [de], a

    ; Direction 2 converts +n to the signed 32-bit two's-complement -n.
    ld a, [wCalendarGateGapDirection]
    cp 2
    jr nz, .targetReady
    ld hl, wPairTargetOffset
    ld b, 4
    scf
.negateTarget:
    ld a, [hl]
    cpl
    adc a, 0
    ld [hli], a
    dec b
    jr nz, .negateTarget

.targetReady:
    ; Complete source sauce: five counters, 46 drops, bowl order and 12 post-stirs.
    call CalendarBowlTrace46
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore
    call CalendarBowlPostStirs12
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore

    ; Section O: bowl 1, seal 1, N=922, then add 41 to the selected rank.
    ld a, 1
    ld [wCalendarAnswerInputBowl], a
    ld [wCalendarAnswerInputSeal], a
    ld a, $9a
    ld [wCalendarSelectCount], a
    ld a, $03
    ld [wCalendarSelectCount+1], a
    call CalendarBowlAnswerShortRank
    ld a, [wCalendarStatus]
    or a
    jp nz, .restore

    ; Defensive rank validation: 1..922 only.
    ld a, [wCalendarSelectRank]
    ld b, a
    ld a, [wCalendarSelectRank+1]
    or b
    jr z, .badRank
    ld a, [wCalendarSelectRank+1]
    cp 3
    jr c, .rankValid
    jr nz, .badRank
    ld a, [wCalendarSelectRank]
    cp $9b
    jr nc, .badRank
.rankValid:
    ld a, [wCalendarSelectRank]
    add a, 41
    ld [wCalendarGateGapResultScratch], a
    ld a, [wCalendarSelectRank+1]
    adc a, 0
    ld [wCalendarGateGapResultScratch+1], a

    call .restoreState
    ld hl, wCalendarGateGapResultScratch
    ld de, wCalendarGateGapResult
    ld b, 2
    call .copyN
    xor a
    ld [wCalendarStatus], a
    ret

.badRank:
    ld a, 2
    ld [wCalendarStatus], a
.restore:
    call .restoreState
    ret

.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

.restoreState:
    ld hl, wCalendarGateGapSavedCalc
    ld de, wPairCalcOffset
    ld b, 4
    call .copyN
    ld hl, wCalendarGateGapSavedTarget
    ld de, wPairTargetOffset
    ld b, 4
    call .copyN
    ld a, [wCalendarGateGapSavedAnswerBowl]
    ld [wCalendarAnswerInputBowl], a
    ld a, [wCalendarGateGapSavedAnswerSeal]
    ld [wCalendarAnswerInputSeal], a
    ld a, [wCalendarGateGapSavedSelectCount]
    ld [wCalendarSelectCount], a
    ld a, [wCalendarGateGapSavedSelectCount+1]
    ld [wCalendarSelectCount+1], a
    ld a, [wCalendarGateGapSavedSelectDirection]
    ld [wCalendarSelectDirection], a
    ret

.copyN:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyN
    ret
