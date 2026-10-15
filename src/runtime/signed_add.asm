; Exact signed-magnitude sum, fixed 4096-byte inputs in SRAM 0 and 1.
; The result occupies 4097 bytes in SRAM bank 2 (A000..B000).
; Signs wSignedSignA/B: 0=nonnegative, 1=negative; negative zero is invalid.
; wSignedAddStatus = 0 success, 1 invalid input (output scrubbed).
; wSignedResultSign = 0 nonnegative, 1 negative. Zero always has sign 0.
; Input banks never modified, successful output is a complete exact sum.
; SRAM must be enabled and input banks explicitly initialized before call.
; Return: SRAM bank 2 selected. Clobbers CPU registers and flags.
; This is a fixed-capacity primitive, not an arbitrary-length BigInt API.
SECTION "Exact signed 4096-byte banked addition", ROM0

; Compute B-A into bank 2 when B>A, leaving source banks 0 and 1 intact.
; Output top byte B000=0 on success; wBankStatus indicates underflow.
BankedSubReverse4096::
    xor a
    ld [wBankBorrow], a
    ld [wBankStatus], a
    ld hl, $a000
    ld bc, 4096
.loop:
    ld a, 1
    call SRAMSelectBank
    ld a, [hl]
    ld d, a

    xor a
    call SRAMSelectBank
    ld a, [hl]
    ld e, a

    ld a, [wBankBorrow]
    rrca                ; previous borrow -> CPU carry
    ld a, d             ; LD leaves carry unchanged
    sbc a, e
    ld d, a
    ld a, 0             ; LD leaves subtract carry unchanged
    adc a, 0            ; capture new borrow
    ld [wBankBorrow], a

    ld a, 2
    call SRAMSelectBank
    ld a, d
    ld [hli], a

    dec bc
    ld a, b
    or c
    jr nz, .loop

    ld a, [wBankBorrow]
    or a
    jr nz, .underflow
    xor a
    ld [hl], a
    ret

.underflow:
    ld a, 2
    ld d, 0
    call SRAMFill4KiB
    xor a
    ld [$b000], a
    ld a, 1
    ld [wBankStatus], a
    ret

SignedAdd4096::
    ; Fail-closed defaults are installed before validation.
    ld a, 1
    ld [wSignedAddStatus], a
    xor a
    ld [wSignedResultSign], a

    ; Reuse one canonical sign/negative-zero validation route.
    call SignedCmp4096
    ld a, [wSignedCmpStatus]
    cp 3
    jp z, .invalid

    ld a, [wSignedSignA]
    ld b, a
    ld a, [wSignedSignB]
    cp b
    jr nz, .opposite

    ; Same sign: exact 4097-byte addition including final carry byte.
    call BankedAdd4096
    ld a, [wSignedSignA]
    ld [wSignedResultSign], a
    jr .success

.opposite:
    ; Opposite signs: subtract smaller unsigned magnitude from larger.
    call BankedCmp4096
    ld a, [wCmpStatus]
    or a
    jr z, .zero
    cp 1
    jr nz, .reverse
    call BankedSub4096
    ld a, [wBankStatus]
    or a
    jr nz, .invalid   ; defensive, magnitude prechecked
    ld a, [wSignedSignA]
    ld [wSignedResultSign], a
    jr .success
.reverse:
    call BankedSubReverse4096
    ld a, [wBankStatus]
    or a
    jr nz, .invalid
    ld a, [wSignedSignB]
    ld [wSignedResultSign], a
    jr .success

.zero:
    ; Different signs with equal magnitudes cancel exactly.
    ld a, 2
    ld d, 0
    call SRAMFill4KiB
    xor a
    ld [$b000], a
    jr .success

.invalid:
    ; Never expose a partially computed or stale result on failure.
    ld a, 2
    ld d, 0
    call SRAMFill4KiB
    xor a
    ld [$b000], a
    ld [wSignedResultSign], a
    ld a, 1
    ld [wSignedAddStatus], a
    ret

.success:
    xor a
    ld [wSignedAddStatus], a
    ret
