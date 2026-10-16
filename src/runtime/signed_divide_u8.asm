; Signed Euclidean quotient by an 8-bit positive divisor on original DMG.
; Input: signed-magnitude 4096-byte absolute value in MBC5 SRAM bank 0.
; wSignedSignA=0 positive or zero, =1 strictly negative; negative zero is invalid.
; wDivisor=1..255. Caller enables SRAM and initializes the input bank.
; Output: 4096-byte quotient magnitude in bank 2 (A000..AFFF),
;         canonical significant length in wDivQuotLength, sign in
;         wSignedDivQuotSign (0/1), remainder in wSignedDivRemainder (0..d-1).
; Semantic invariant: n = q*d + r, 0 <= r < d, q=floor(n/d).
; Invalid sign / negative zero: status=1; zero divisor: status=2.
; All failures scrub 4097 output bytes AND all exposed metadata.
; Input SRAM bank 0 is never modified. Returns with bank 2 selected.
; Clobbers registers/flags; fixed-capacity building block, not BigInt.
SECTION "Exact signed Euclidean u8 division", ROM0

SignedDivEuclidU8::
    ld a, 1
    ld [wSignedDivStatus], a
    xor a
    ld [wSignedDivQuotSign], a
    ld [wSignedDivRemainder], a
    ld [wDivQuotLength], a
    ld [wDivQuotLength+1], a

    ld a, [wSignedSignA]
    cp 2
    jp nc, .invalid

    ; Validate canonical sign before the unsigned routine can mutate
    ; output; negative zero must never be treated as positive zero.
    xor a
    ld hl, $afff
    ld bc, 4096
    call SRAMMeasureLength
    ld a, [wSignedSignA]
    or a
    jr z, .canonicalSign
    ld a, b
    or c
    jp z, .invalid
.canonicalSign:
    ld a, [wDivisor]
    or a
    jp z, .zeroDivisor
    call BankedDivU8
    ld a, [wDivStatus]
    or a
    jp nz, .invalid

    ld a, [wSignedSignA]
    or a
    jr z, .positive

    ld a, [wDivRemainderLo]
    or a
    jr z, .exactNegative
    ; For -m with m = k*d + r (r>0): q=-(k+1), rem=d-r.
    ld b, a
    ld a, [wDivisor]
    sub b
    ld [wSignedDivRemainder], a
    ld hl, $a000
.incrementQuotient:
    ld a, [hl]
    inc a
    ld [hli], a
    or a
    jr z, .incrementQuotient
    ; Exact quotient metadata after possible carry across byte boundary.
    ld a, 2
    ld hl, $afff
    ld bc, 4096
    call SRAMMeasureLength
    ld a, c
    ld [wDivQuotLength], a
    ld a, b
    ld [wDivQuotLength+1], a
    jr .negativeDone

.exactNegative:
    xor a
    ld [wSignedDivRemainder], a
.negativeDone:
    ld a, 1
    ld [wSignedDivQuotSign], a
    jr .success
.positive:
    ld a, [wDivRemainderLo]
    ld [wSignedDivRemainder], a
.success:
    xor a
    ld [wSignedDivStatus], a
    ret

.invalid:
    ld a, 1
    jr .reject
.zeroDivisor:
    ld a, 2
.reject:
    push af
    ld a, 2
    ld d, 0
    call SRAMFill4KiB
    xor a
    ld [$b000], a
    ld [wSignedDivQuotSign], a
    ld [wSignedDivRemainder], a
    ld [wDivQuotLength], a
    ld [wDivQuotLength+1], a
    ld [wDivRemainderLo], a
    ld [wDivRemainderHi], a
    ld a, 1
    ld [wDivStatus], a
    pop af
    ld [wSignedDivStatus], a
    ret
