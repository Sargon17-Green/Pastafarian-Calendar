; Native DMG MBC5 SRAM magnitude length scanner.
; A = SRAM bank (0..15). HL = highest byte address (A000..BFFF).
; BC = byte capacity, 1..8192, with HL=A000+BC-1.
; Returns BC=number of significant little-endian bytes (0 for zero).
; Selected bank remains mapped; input bytes are not modified.
; Does not claim allocation or a variable-length object representation.
SECTION "Canonical SRAM magnitude length", ROM0
SRAMMeasureLength::
    call SRAMSelectBank
.scan:
    ld a, [hl]
    or a
    ret nz
    dec hl
    dec bc
    ld a, b
    or c
    jr nz, .scan
    ret
