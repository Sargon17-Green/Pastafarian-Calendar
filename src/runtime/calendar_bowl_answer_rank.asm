; PC-BRANCH-SM83-ASSEMBLY-GEEZ / Stage1 Native393 runtime candidate.
; Not yet linked or Native-tested. Include only in isolated Native393 ROM.
; Input: existing Native392 bowl/seal and Native short-rank count (LE16).
; Outputs on success: A0, direction, rank and accepted A_k (LE16).
; Status 6 idle, 2 invalid, 0 success. Count validated before A0 publication.
; The short-rank kernel's error predicates are exhausted before its call:
; ordinal remains valid, count is unchanged, Native392 yields canonical A0
; and direction 1/FF (mapped to 1/2). No writes to ordinal, Q, order or SRAM.
SECTION "Calendar Stage1 answer rank accepted residue", WRAM0
wCalendarAnswerAccepted:: ds 16

SECTION "Calendar Stage1 answer rank adapter", ROMX, BANK[1]
CalendarBowlAnswerShortRank::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarSelectCount]
    ld b, a
    ld a, [wCalendarSelectCount+1]
    or b
    jr z, .invalid
    ld a, [wCalendarSelectCount+1]
    cp $4a
    jr c, .countOkay
    jr nz, .invalid
    ld a, [wCalendarSelectCount]
    cp $65
    jr nc, .invalid
.countOkay:
    call CalendarBowlAnswerA0Direction
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarAnswerA0
    ld de, wCalendarSelectValue
    call .copy16
    ld a, [wCalendarAnswerDirection]
    cp $ff
    ld a, 1
    jr nz, .directionReady
    inc a
.directionReady:
    ld [wCalendarSelectDirection], a
    call CalendarSelectShortRank
    ld a, [wCalendarStatus]
    or a
    ret nz
    ; Kernel computed L. Determine first accepted A_k without looping
    ; over as many as N-1 rejected tail values.
    ld hl, wCalendarSelectValue+15
    ld de, wCalendarSelectLimit+15
    ld b, 16
.compare:
    ld a, [hl]
    ld c, a
    ld a, [de]
    cp c
    jr c, .tail
    jr nz, .within
    dec hl
    dec de
    dec b
    jr nz, .compare
.within:
    ld hl, wCalendarSelectValue
    jr .publish
.tail:
    ld a, [wCalendarSelectDirection]
    cp 2
    jr z, .backward
    ; Forward crosses M and wraps to 1.
    ld hl, wCalendarAnswerAccepted
    ld a, 1
    ld [hli], a
    xor a
    ld b, 15
.clear:
    ld [hli], a
    dec b
    jr nz, .clear
    ret
.backward:
    ; Backward reaches L directly.
    ld hl, wCalendarSelectLimit
.publish:
    ld de, wCalendarAnswerAccepted
    jp .copy16
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
.copy16:
    ld b, 16
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret
