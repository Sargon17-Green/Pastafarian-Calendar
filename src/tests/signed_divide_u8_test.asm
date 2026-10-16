; Signed Euclidean divide native regression, cases 139..150.
SECTION "Signed Euclidean u8 division tests", ROM0

; Check status=0, sign H, remainder D, length BC, quotient low E.
; Caller has just executed SignedDivEuclidU8; SRAM bank 2 remains selected.
SignedDivCheck::
    ld a, [wSignedDivStatus]
    or a
    jr nz, .bad
    ld a, [wSignedDivQuotSign]
    cp h
    jr nz, .bad
    ld a, [wSignedDivRemainder]
    cp d
    jr nz, .bad
    ld a, [wDivQuotLength]
    cp c
    jr nz, .bad
    ld a, [wDivQuotLength+1]
    cp b
    jr nz, .bad
    ld a, [$a000]
    cp e
    jr nz, .bad
    scf
    ret
.bad:
    and a
    ret

; Verify rejected operation: status D, all result fields and sample
; output locations are zero. This also checks no stale quotient exposure.
SignedDivRejected::
    ld a, [wSignedDivStatus]
    cp d
    jr nz, .bad
    ld a, [wSignedDivQuotSign]
    or a
    jr nz, .bad
    ld a, [wSignedDivRemainder]
    or a
    jr nz, .bad
    ld a, [wDivQuotLength]
    ld b, a
    ld a, [wDivQuotLength+1]
    or b
    jr nz, .bad
    ld a, [$a000]
    or a
    jr nz, .bad
    ld a, [$a800]
    or a
    jr nz, .bad
    ld a, [$afff]
    or a
    jr nz, .bad
    ld a, [$b000]
    or a
    jr nz, .bad
    scf
    ret
.bad:
    and a
    ret

RunSignedDivisionTests::
    call SRAMEnable
    ld d, 0
    xor a
    call SRAMFill4KiB
    xor a
    ld [wSignedSignA], a
    ld a, 1
    ld [wDivisor], a

    ; 139. Positive zero / 1 = canonical zero.
    ld a, 139
    ld [wTestCase], a
    call SignedDivEuclidU8
    ld h, 0
    ld d, 0
    ld bc, 0
    ld e, 0
    call SignedDivCheck
    jp nc, .fail

    ; 140. +1000 / 3 -> +333, remainder 1.
    ld a, 140
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $e8
    ld [$a000], a
    ld a, $03
    ld [$a001], a
    ld [wDivisor], a
    call SignedDivEuclidU8
    ld h, 0
    ld d, 1
    ld bc, 2
    ld e, $4d
    call SignedDivCheck
    jp nc, .fail

    ; 141. -1000 / 3 -> -334, remainder 2.
    ld a, 141
    ld [wTestCase], a
    ld a, 1
    ld [wSignedSignA], a
    call SignedDivEuclidU8
    ld h, 1
    ld d, 2
    ld bc, 2
    ld e, $4e
    call SignedDivCheck
    jp nc, .fail
    ld a, [$a001]
    cp 1
    jp nz, .fail

    ; 142. -1000 / 4 -> -250, exact quotient.
    ld a, 142
    ld [wTestCase], a
    ld a, 4
    ld [wDivisor], a
    call SignedDivEuclidU8
    ld h, 1
    ld d, 0
    ld bc, 1
    ld e, $fa
    call SignedDivCheck
    jp nc, .fail

    ; 143. -1 / 255 -> -1, remainder 254.
    ld a, 143
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld a, 1
    ld [$a000], a
    ld a, $ff
    ld [wDivisor], a
    call SignedDivEuclidU8
    ld h, 1
    ld d, $fe
    ld bc, 1
    ld e, 1
    call SignedDivCheck
    jp nc, .fail

    ; 144. -256 / 255 -> -2, remainder 254.
    ld a, 144
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld [$a000], a
    ld a, 1
    ld [$a001], a
    call SignedDivEuclidU8
    ld h, 1
    ld d, $fe
    ld bc, 1
    ld e, 2
    call SignedDivCheck
    jp nc, .fail

    ; 145. -65536 / 1 -> -65536, length 3.
    ld a, 145
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld [$a001], a
    ld a, 1
    ld [$a002], a
    ld [wDivisor], a
    call SignedDivEuclidU8
    ld h, 1
    ld d, 0
    ld bc, 3
    ld e, 0
    call SignedDivCheck
    jp nc, .fail
    ld a, [$a002]
    cp 1
    jp nz, .fail

    ; 146. Reject negative zero, scrub previous quotient.
    ld a, 146
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    call SignedDivEuclidU8
    ld d, 1
    call SignedDivRejected
    jp nc, .fail

    ; 147. Reject sign byte 2 with nonzero input.
    ld a, 147
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 7
    ld [$a000], a
    ld a, 2
    ld [wSignedSignA], a
    call SignedDivEuclidU8
    ld d, 1
    call SignedDivRejected
    jp nc, .fail

    ; 148. Zero divisor is a different failure, and scrubs output.
    ld a, 148
    ld [wTestCase], a
    xor a
    ld [wSignedSignA], a
    ld [wDivisor], a
    call SignedDivEuclidU8
    ld d, 2
    call SignedDivRejected
    jp nc, .fail

    ; 149. Recover with 7 / 3 = 2, remainder 1.
    ld a, 149
    ld [wTestCase], a
    ld a, 3
    ld [wDivisor], a
    call SignedDivEuclidU8
    ld h, 0
    ld d, 1
    ld bc, 1
    ld e, 2
    call SignedDivCheck
    jp nc, .fail

    ; 150. Repeat with negative sign: -7 = (-3)*3 + 2.
    ld a, 150
    ld [wTestCase], a
    ld a, 1
    ld [wSignedSignA], a
    call SignedDivEuclidU8
    ld h, 1
    ld d, 2
    ld bc, 1
    ld e, 3
    call SignedDivCheck
    jp nc, .fail
    xor a
    call SRAMSelectBank
    ld a, [$a000]
    cp 7
    jp nz, .fail

    call SRAMDisable
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    call SRAMDisable
    ld a, $e0
    ld [wTestResult], a
    ret
