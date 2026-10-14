; MBC5 RAM registers are in the cartridge, not in the Game Boy CPU.
; Valid on original DMG with an MBC5+RAM cartridge (header 0147=1A).
; Caller is responsible for restoring the selected bank when required.
; Functions do not allocate, clear or own persistent semantic memory.
SECTION "MBC5 SRAM bank operations", ROM0

SRAMEnable::
    ld a, $0a
    ld [$0000], a
    ret

SRAMDisable::
    xor a
    ld [$0000], a
    ret

; A: SRAM bank number, only lower four bits are accepted.
; Maps the selected 8 KiB RAM bank into CPU range A000..BFFF.
SRAMSelectBank::
    and $0f
    ld [$4000], a
    ret
