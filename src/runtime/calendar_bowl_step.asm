; Stage1 Native388 candidate: one complete six-bowl update from a frozen snapshot.
; Caller inputs: wCalendarBowlsOld[6*16], wCalendarBowlOrder[6],
; wCalendarVisibleOutput (drop), wCalendarStoneOld[5*16],
; wCalendarVisibleIteration (1..46), valid active ordinal and lease.
; Published on success ONLY: wCalendarBowlsNext[6*16], indexed by bowl ID.
; All residues canonical 1..M; no source or lease/SRAM mutation.
; The caller, not this routine, decides when to promote Next to Old.
SECTION "Calendar Stage1 simultaneous bowl step", ROMX, BANK[1]

CalendarBowlUpdateStep::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarVisibleIteration]
    or a
    jp z, .invalid
    cp 47
    jp nc, .invalid
    ld hl, wCalendarBowlsOld
    ld b, 6
    call .validateResidues
    jp nz, .invalid
    ld hl, wCalendarStoneOld
    ld b, 5
    call .validateResidues
    jp nz, .invalid
    ld hl, wCalendarVisibleOutput
    ld b, 1
    call .validateResidues
    jp nz, .invalid
    ; Exactly the six distinct IDs 1..6: reject duplicates before work.
    xor a
    ld [wCalendarBowlSeen], a
    ld hl, wCalendarBowlOrder
    ld b, 6
.validateOrder:
    ld a, [hli]
    or a
    jp z, .invalid
    cp 7
    jp nc, .invalid
    dec a
    ld e, a
    ld d, 0
    push hl
    ld hl, .masks
    add hl, de
    ld a, [hl]
    ld c, a
    ld a, [wCalendarBowlSeen]
    and c
    pop hl
    jp nz, .invalid
    ld a, [wCalendarBowlSeen]
    or c
    ld [wCalendarBowlSeen], a
    dec b
    jp nz, .validateOrder

    ; The first three positions get direct pours using OLD bowls.
    ld a, 1
    ld [wCalendarBowlQ], a
.pours:
    call .loadCurrent
    ld hl, wCalendarVisibleOutput
    ld de, wMulA
    call .copy16
    ld hl, wCalendarVisibleOutput
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ld hl, wValue
    ld de, wCalendarBowlTemp
    call .copy16

    ld a, [wCalendarBowlQ]
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOld
    add hl, de
    ld de, wMulA
    call .copy16
    ld hl, wCalendarBowlCur
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ld hl, wCalendarBowlTemp
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    ; (2q+1)*i as repeated canonical additions, never raw overflow.
    ld a, [wCalendarBowlQ]
    add a, a
    inc a
    ld [wCalendarBowlRepeat], a
    call .iterAddend
    call .repeatAdd
    ld a, [wCalendarBowlQ]
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlPours
    add hl, de
    ld d, h
    ld e, l
    ld hl, wValue
    call .copy16
    ld hl, wCalendarBowlQ
    inc [hl]
    ld a, [hl]
    cp 4
    jp nz, .pours

    ; All six outputs are staged; every old value comes from BowlsOld.
    ld a, 1
    ld [wCalendarBowlQ], a
.each:
    call .loadNeighbors
    ld hl, wCalendarBowlCur
    ld de, wValue
    call .copy16
    ld hl, wCalendarBowlPrev
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    call Add16
    call Save127
    ld hl, wCalendarBowlNextNeighbor
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    call Add16
    call Save127
    call Add16
    call Save127
    ld a, [wCalendarBowlQ]
    cp 4
    jp nc, .noPour
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlPours
    add hl, de
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
.noPour:
    ld hl, wCalendarVisibleOutput
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    ld a, [wCalendarBowlQ]
    cp 6
    jr nz, .stoneQ
    xor a
    jr .stoneReady
.stoneQ:
    dec a
.stoneReady:
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOld
    add hl, de
    ld de, wAddend
    call .copy16
    call Add16
    call Save127
    ; temp = SAVE(u*u)
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
    ; product = SAVE(old(prev)*old(next)) 
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
    ld a, 5
    ld [wCalendarBowlRepeat], a
    call .repeatAdd
    ; i*q, bounded by 276, via q additions of the iteration byte.
    ld a, [wCalendarBowlQ]
    ld [wCalendarBowlRepeat], a
    call .iterAddend
    call .repeatAdd
    ; Stage by bowl ID rather than permutation position.
    ld a, [wCalendarBowlQ]
    dec a
    call .idAtPosition
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

    ; Single publication point; no preceding branch touched public output.
    ld hl, wCalendarBowlNewScratch
    ld de, wCalendarBowlsNext
    ld b, 96
.publish:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .publish
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

.idAtPosition:
    ; A=zero-based position, return identity 1..6
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlOrder
    add hl, de
    ld a, [hl]
    ret

.copyOldByIdentity:
    ; A=identity 1..6, DE=destination
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
    call .idAtPosition
    ld de, wCalendarBowlCur
    jp .copyOldByIdentity

.loadNeighbors:
    call .loadCurrent
    ld a, [wCalendarBowlQ]
    cp 1
    jr nz, .previousNormal
    ld a, 5
    jr .previousReady
.previousNormal:
    sub 2
.previousReady:
    call .idAtPosition
    ld de, wCalendarBowlPrev
    call .copyOldByIdentity
    ld a, [wCalendarBowlQ]
    cp 6
    jr nz, .nextNormal
    xor a
    jr .nextReady
.nextNormal:
    ; q already equals the zero-based successor position.
.nextReady:
    call .idAtPosition
    ld de, wCalendarBowlNextNeighbor
    jp .copyOldByIdentity

.iterAddend:
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarVisibleIteration]
    ld [wAddend], a
    ret
.repeatAdd:
.loop:
    call Add16
    call Save127
    ld hl, wCalendarBowlRepeat
    dec [hl]
    jr nz, .loop
    ret
.masks:
    db 1,2,4,8,16,32
