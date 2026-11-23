; SM83 Stage1 Native392 candidate: A0 and direction from retained orderAt46.
; Input bowl 1..6, seal 10..12, six post-stir bowls, owner/ordinal lease.
; Atomic output A0[16] LE and direction (1/-1); status 0/2/6.
SECTION "Calendar Stage1 A0 direction", ROMX, BANK[1]
CalendarBowlAnswerA0Direction::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarAnswerInputBowl]
    or a
    jp z, .invalid
    cp 7
    jp nc, .invalid
    ld a, [wCalendarAnswerInputSeal]
    cp 10
    jp c, .invalid
    cp 13
    jp nc, .invalid
    ; Validate a permutation of six identities and canonical residues.
    xor a
    ld [wCalendarAnswerSeen], a
    ld hl, wCalendarBowlOrderAt46
    ld b, 6
.orderValid:
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
    ld a, [wCalendarAnswerSeen]
    and c
    pop hl
    jp nz, .invalid
    ld a, [wCalendarAnswerSeen]
    or c
    ld [wCalendarAnswerSeen], a
    dec b
    jr nz, .orderValid
    ld hl, wCalendarBowlsOld
    ld b, 6
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
    jp nz, .invalid
    or d
    jp z, .invalid
    dec b
    jr nz, .residue

    ld hl, wCalendarBowlOrderAt46
    ld b, 6
    ld c, 0
.find:
    ld a, [hli]
    ld d, a
    ld a, [wCalendarAnswerInputBowl]
    cp d
    jr z, .found
    inc c
    dec b
    jr nz, .find
    jp .invalid
.found:
    ld a, c
    cp 5
    jr nz, .next
    ld hl, wCalendarBowlOrderAt46
.next:
    ld a, [hl]
    ld [wCalendarAnswerNextBowl], a
    ; A0 = SAVE((Q[B]+z+181)^2 +179*Q[successor]+z).
    ld a, [wCalendarAnswerInputBowl]
    ld de, wValue
    call .loadBowl
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarAnswerInputSeal]
    add a, 181
    ld [wAddend], a
    call Add16
    call Save127
    call .square
    ld a, [wCalendarAnswerNextBowl]
    ld de, wAddend
    call .loadBowl
    ld a, 179
    ld [wCalendarAnswerRepeat], a
    call .repeat
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarAnswerInputSeal]
    ld [wAddend], a
    call Add16
    call Save127
    ld hl, wValue
    ld de, wCalendarAnswerA0Scratch
    call .copy16

    ; D = SAVE((A0+z+194)^2 +193*A0 +197*Q[6]).
    ld hl, wCalendarAnswerA0Scratch
    ld de, wValue
    call .copy16
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarAnswerInputSeal]
    add a, 194
    ld [wAddend], a
    call Add16
    call Save127
    call .square
    ld hl, wCalendarAnswerA0Scratch
    ld de, wAddend
    call .copy16
    ld a, 193
    ld [wCalendarAnswerRepeat], a
    call .repeat
    ld a, 6
    ld de, wAddend
    call .loadBowl
    ld a, 197
    ld [wCalendarAnswerRepeat], a
    call .repeat
    ld a, [wValue]
    and 1
    jr z, .backwards
    ld a, 1
    jr .stageDir
.backwards:
    ld a, $ff
.stageDir:
    ld [wCalendarAnswerDirectionScratch], a
    ld hl, wCalendarAnswerA0Scratch
    ld de, wCalendarAnswerA0
    call .copy16
    ld a, [wCalendarAnswerDirectionScratch]
    ld [wCalendarAnswerDirection], a
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
.square:
    ld hl, wValue
    ld de, wMulA
    call .copy16
    ld hl, wValue
    ld de, wMulB
    call .copy16
    call Mul128x128
    call SaveWide256
    ret
.repeat:
.loop:
    call Add16
    call Save127
    ld hl, wCalendarAnswerRepeat
    dec [hl]
    jr nz, .loop
    ret
.loadBowl:
    push de
    dec a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarBowlsOld
    add hl, de
    pop de
    jp .copy16
.copy16:
    ld b, 16
.loopCopy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loopCopy
    ret
.masks:
    db 1,2,4,8,16,32
