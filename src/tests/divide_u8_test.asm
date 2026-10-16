; Native DMG regression suite for exact 4096-byte unsigned /u8.
; Test cases 123..138, independently expected values.
SECTION "Banked u8 division tests", ROM0

DivTestResetInputs::
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld d, 0
    ld a, 1
    call SRAMFill4KiB
    ret

; Input expected remainder D; quotient length BC; low quotient byte E.
; Caller has just run BankedDivU8, so SRAM bank 2 is selected.
; Carry set on success, cleared on failure.
DivTestCheck::
    ld a, [wDivStatus]
    or a
    jr nz, .bad
    ld a, [wDivRemainderLo]
    cp d
    jr nz, .bad
    ld a, [wDivRemainderHi]
    or a
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

RunDivisionTests::
    call SRAMEnable
    call DivTestResetInputs

    ; 123. Zero / 1 = zero; stale bank-2 content is overwritten.
    ld a, 123
    ld [wTestCase], a
    ld d, $cc
    ld a, 2
    call SRAMFill4KiB
    ld a, 1
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 0
    ld e, 0
    call DivTestCheck
    jp nc, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 124. One / one = one.
    ld a, 124
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call BankedDivU8
    ld d, 0
    ld bc, 1
    ld e, 1
    call DivTestCheck
    jp nc, .fail

    ; 125. 255 / 255 = 1, zero remainder.
    ld a, 125
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $ff
    ld [$a000], a
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 1
    ld e, 1
    call DivTestCheck
    jp nc, .fail

    ; 126. 254 / 255 = zero, remainder 254.
    ld a, 126
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $fe
    ld [$a000], a
    call BankedDivU8
    ld d, $fe
    ld bc, 0
    ld e, 0
    call DivTestCheck
    jp nc, .fail

    ; 127. 256 / 2 = 128, exact across byte boundary.
    ld a, 127
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld [$a000], a
    ld a, 1
    ld [$a001], a
    ld a, 2
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 1
    ld e, $80
    call DivTestCheck
    jp nc, .fail

    ; 128. 257 / 2 = 128, remainder one.
    ld a, 128
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, 1
    ld [$a000], a
    call BankedDivU8
    ld d, 1
    ld bc, 1
    ld e, $80
    call DivTestCheck
    jp nc, .fail

    ; 129. 65535 / 255 = 257 ($0101), no remainder.
    ld a, 129
    ld [wTestCase], a
    xor a
    call SRAMSelectBank
    ld a, $ff
    ld [$a000], a
    ld [$a001], a
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 2
    ld e, 1
    call DivTestCheck
    jp nc, .fail
    ld a, [$a001]
    cp 1
    jp nz, .fail

    ; 130. 65535 / 254 = 258 ($0102), remainder 3.
    ld a, 130
    ld [wTestCase], a
    ld a, $fe
    ld [wDivisor], a
    call BankedDivU8
    ld d, 3
    ld bc, 2
    ld e, 2
    call DivTestCheck
    jp nc, .fail
    ld a, [$a001]
    cp 1
    jp nz, .fail

    ; 131. (2^(8*4096)-1) / 1 = unchanged 4096-byte magnitude.
    ld a, 131
    ld [wTestCase], a
    ld d, $ff
    xor a
    call SRAMFill4KiB
    ld a, 1
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 4096
    ld e, $ff
    call DivTestCheck
    jp nc, .fail
    ld a, [$a800]
    cp $ff
    jp nz, .fail
    ld a, [$afff]
    cp $ff
    jp nz, .fail

    ; 132. (2^(8*4096)-1) / 255 = 0x0101...01, exact.
    ld a, 132
    ld [wTestCase], a
    ld a, $ff
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 4096
    ld e, 1
    call DivTestCheck
    jp nc, .fail
    ld a, [$a800]
    cp 1
    jp nz, .fail
    ld a, [$afff]
    cp 1
    jp nz, .fail

    ; 133. Zero divisor is rejected and output/metadata scrubbed.
    ld a, 133
    ld [wTestCase], a
    xor a
    ld [wDivisor], a
    call BankedDivU8
    ld a, [wDivStatus]
    cp 1
    jp nz, .fail
    ld a, [wDivRemainderLo]
    or a
    jp nz, .fail
    ld a, [wDivRemainderHi]
    or a
    jp nz, .fail
    ld a, [wDivQuotLength]
    ld b, a
    ld a, [wDivQuotLength+1]
    or b
    jp nz, .fail
    ld a, [$a000]
    or a
    jp nz, .fail
    ld a, [$a800]
    or a
    jp nz, .fail
    ld a, [$afff]
    or a
    jp nz, .fail
    ld a, [$b000]
    or a
    jp nz, .fail

    ; 134. Recovery: same source / 255 again, with unchanged inputs.
    ld a, 134
    ld [wTestCase], a
    ld a, $ff
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 4096
    ld e, 1
    call DivTestCheck
    jp nc, .fail
    xor a
    call SRAMSelectBank
    ld a, [$a000]
    cp $ff
    jp nz, .fail
    ld a, [$afff]
    cp $ff
    jp nz, .fail

    ; 135. Top-only 0x80 at AFFF / 128 => AFFF=1, length 4096.
    ld a, 135
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld a, $80
    ld [$afff], a
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 4096
    ld e, 0
    call DivTestCheck
    jp nc, .fail
    ld a, [$afff]
    cp 1
    jp nz, .fail
    ld a, [$affe]
    or a
    jp nz, .fail

    ; 136. 1000 / 3 = 333 ($014d), remainder 1.
    ld a, 136
    ld [wTestCase], a
    ld d, 0
    xor a
    call SRAMFill4KiB
    ld a, $e8
    ld [$a000], a
    ld a, 3
    ld [$a001], a
    ld [wDivisor], a
    call BankedDivU8
    ld d, 1
    ld bc, 2
    ld e, $4d
    call DivTestCheck
    jp nc, .fail
    ld a, [$a001]
    cp 1
    jp nz, .fail

    ; 137. 1000 / 4 = 250 with zero remainder.
    ld a, 137
    ld [wTestCase], a
    ld a, 4
    ld [wDivisor], a
    call BankedDivU8
    ld d, 0
    ld bc, 1
    ld e, $fa
    call DivTestCheck
    jp nc, .fail
    ld a, [$a001]
    or a
    jp nz, .fail

    ; 138. Identical second invocation resets all scratch state.
    ld a, 138
    ld [wTestCase], a
    call BankedDivU8
    ld d, 0
    ld bc, 1
    ld e, $fa
    call DivTestCheck
    jp nc, .fail
    ld a, [$b000]
    or a
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
