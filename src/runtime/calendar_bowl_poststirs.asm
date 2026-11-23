; Stage1 post-stirs, isolated Native391 candidate. All arithmetic is native ROMX.
; Contract: 12 rounds, input = canonical six bowls after V46. Each round:
;   S_r=SAVE(sum(previous six bowls)+149*r).
;   order=lex_order(S_r), u=old[b]+3*old[prev]+5*old[next]+S_r+r+q*q,
;   new[b]=SAVE(u*u+7*old[prev]*old[next]).
; Retained S_r is used BOTH for order and u. All six reads use old snapshot.
; Status=0 success, 2 invalid, 6 idle. Published bowls/sums atomic as a whole.
SECTION "Calendar Stage1 retained post-stirs", ROMX, BANK[1]

CalendarBowlPostStirs12::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ; Roll back all twelve updates on any failure.
    ld hl, wCalendarBowlsOld
    ld de, wCalendarPostStirSavedBowls
    ld b, 96
    call .copyN
    ld a, 1
    ld [wCalendarPostStirRound], a
.loop:
    call CalendarBowlPostStirStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    ; Stage S_r in private 12x16 trace, indexed by round r.
    ld a, [wCalendarPostStirRound]
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarPostStirSumsScratch
    add hl, de
    ld d, h
    ld e, l
    ld hl, wCalendarPostStirSum
    ld b, 16
    call .copyN

    ; Promote the six simultaneous new bowls only after step success.
    ld hl, wCalendarBowlsNext
    ld de, wCalendarBowlsOld
    ld b, 96
    call .copyN
    ld hl, wCalendarPostStirRound
    inc [hl]
    ld a, [hl]
    cp 13
    jp nz, .loop

    ; Commit 12 retained canonical sums only after entire sequence succeeds.
    ld hl, wCalendarPostStirSumsScratch
    ld de, wCalendarPostStirSums
    ld b, 192
    call .copyN
    xor a
    ld [wCalendarStatus], a
    ret
.restoreFailure:
    ld a, [wCalendarStatus]
    push af
    ld hl, wCalendarPostStirSavedBowls
    ld de, wCalendarBowlsOld
    ld b, 96
    call .copyN
    pop af
    ld [wCalendarStatus], a
    ret
.copyN:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jp nz, .copyN
    ret

; One isolated simultaneous stir; does not publish BowlsOld or retained trace.
; It updates BowlsNext and the scratch S_r only after validation of all sources.
CalendarBowlPostStirStep::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarPostStirRound]
    or a
    jp z, .invalid
    cp 13
    jp nc, .invalid
    ld hl, wCalendarBowlsOld
    ld b, 6
    call .validateResidues
    jp nz, .invalid

    ; Modular sum of six immutable bowls, retaining canonical 1..M.
    ld hl, wValue
    call Clear16
    ld a, 1
    ld [wCalendarBowlQ], a
.sumOld:
    ld a, [wCalendarBowlQ]
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlsOld
    add hl, de
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    ld hl, wCalendarBowlQ
    inc [hl]
    ld a, [hl]
    cp 7
    jp nz, .sumOld

    ; Add 149 exactly r times, reduced after each addition.
    ld hl, wAddend
    call Clear16
    ld a, 149
    ld [wAddend], a
    ld a, [wCalendarPostStirRound]
    ld [wCalendarBowlRepeat], a
    call .repeatAdd
    ld hl, wValue
    ld de, wCalendarPostStirSum
    call .copy16
    ld hl, wCalendarPostStirSum
    ld de, wCalendarBowlOrderInput
    call .copy16
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    or a
    ret nz

    ld a, 1
    ld [wCalendarBowlQ], a
.each:
    ; Read current, predecessor and successor ONLY from BowlsOld.
    call .loadNeighbors
    ld hl, wCalendarBowlCur
    ld de, wValue
    call .copy16

    ld hl, wCalendarBowlPrev
    ld de, wAddend
    call .copy16
    ld a, 3
    ld [wCalendarBowlRepeat], a
    call .repeatAdd
    ld hl, wCalendarBowlNextNeighbor
    ld de, wAddend
    call .copy16
    ld a, 5
    ld [wCalendarBowlRepeat], a
    call .repeatAdd

    ; IMPORTANT: retained S_r, NOT the raw six-bowl sum.
    ld hl, wCalendarPostStirSum
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarPostStirRound]
    ld [wAddend], a
    call Add16
    call Save127
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarBowlQ]
    dec a
    ld e, a
    ld d, 0
    ld hl, .squares
    add hl, de
    ld a, [hl]
    ld [wAddend], a
    call Add16
    call Save127

    ; Stage u^2, then add seven modular copies of old(prev)*old(next).
    ld hl, wValue
    ld de, wMulA
    call .copy16
    ld hl, wValue
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ld hl, wValue
    ld de, wCalendarBowlTemp
    call .copy16
    ld hl, wCalendarBowlPrev
    ld de, wMulA
    call .copy16
    ld hl, wCalendarBowlNextNeighbor
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ld hl, wValue
    ld de, wAddend
    call .copy16
    ld hl, wCalendarBowlTemp
    ld de, wValue
    call .copy16
    ld a, 7
    ld [wCalendarBowlRepeat], a
    call .repeatAdd

    ; Stage at the ORIGINAL identity index, not permutation position.
    ld a, [wCalendarBowlQ]
    dec a
    call .identityAtPosition
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlNewScratch
    add hl, de
    ld d, h
    ld e, l
    ld hl, wValue
    call .copy16
    ld hl, wCalendarBowlQ
    inc [hl]
    ld a, [hl]
    cp 7
    jp nz, .each

    ld hl, wCalendarBowlNewScratch
    ld de, wCalendarBowlsNext
    ld b, 96
.publish:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jp nz, .publish
    xor a
    ld [wCalendarStatus], a
    ret

.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
.validateResidues:
.residue:
    ld c, 15
    ld d, 0
.low:
    ld a, [hli]
    or d
    ld d, a
    dec c
    jr nz, .low
    ld a, [hli]
    bit 7, a
    jr nz, .bad
    or d
    jr z, .bad
    dec b
    jr nz, .residue
    xor a
    ret
.bad:
    ld a, 1
    or a
    ret
.copy16:
    ld b, 16
.bytes:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .bytes
    ret
.identityAtPosition:
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlOrder
    add hl, de
    ld a, [hl]
    ret
.copyOldByIdentity:
    push de
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlsOld
    add hl, de
    pop de
    jp .copy16
.loadCurrent:
    ld a, [wCalendarBowlQ]
    dec a
    call .identityAtPosition
    ld de, wCalendarBowlCur
    jp .copyOldByIdentity
.loadNeighbors:
    call .loadCurrent
    ld a, [wCalendarBowlQ]
    cp 1
    jr nz, .prevNormal
    ld a, 5
    jr .prevReady
.prevNormal:
    sub 2
.prevReady:
    call .identityAtPosition
    ld de, wCalendarBowlPrev
    call .copyOldByIdentity
    ld a, [wCalendarBowlQ]
    cp 6
    jr nz, .nextNormal
    xor a
.nextNormal:
    call .identityAtPosition
    ld de, wCalendarBowlNextNeighbor
    jp .copyOldByIdentity
.repeatAdd:
.loop:
    call Add16
    call Save127
    ld hl, wCalendarBowlRepeat
    dec [hl]
    jr nz, .loop
    ret
.squares:
    db 1,4,9,16,25,36
