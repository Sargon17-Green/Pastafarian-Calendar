; Stage 1 — atomic, owner-tagged groups of 8-KiB MBC5 SRAM banks.
; Existing LeaseAlloc/LeaseFree remain the legacy single-bank API.
; wLeaseTable: 0=free, 1=legacy lease, 2=reserved bank 0..2,
; 3..255=owner-tagged lease (owner ID 1..253 plus 2).
; OwnerLeaseAlloc: WRAM input wOwnerRequest (1..253), wOwnerCount (1..13).
;   On success, status=0 and wOwnerBanks[0..count-1] are the claimed
;   ascending handles. Preflight checks duplicate owner and free capacity,
;   so failure has NO partial SRAM allocation and no SRAM bank switching.
;   status=1 insufficient banks, 2 invalid request, 3 duplicate owner.
; OwnerLeaseRelease: WRAM input wOwnerRequest (1..253).
;   Scrubs every bank with that owner before returning it to the free pool;
;   status=0 success, 2 invalid request, 3 owner has no banks.
; These calls are serialized, with enabled SRAM and no interrupts. They are
; NOT reentrant, and do not establish a full calendar invocation frame.
SECTION "Owned groups of MBC5 SRAM bank leases", ROM0

OwnerLeaseClearOutput:
    ; Any allocation or release invalidates a previously returned bank handle.
    ld a, $ff
    ld [wOwnerSelectedBank], a
    xor a
    ld [wOwnerAllocated], a
    ld hl, wOwnerBanks
    ld b, 13
.clear:
    ld [hli], a
    dec b
    jr nz, .clear
    ret

OwnerLeaseValidate:
    ld a, [wOwnerRequest]
    or a
    jr z, .invalid
    cp 254
    jr nc, .invalid
    add a, 2
    ld [wOwnerTag], a
    and a
    ret
.invalid:
    scf
    ret

OwnerLeaseAlloc::
    call OwnerLeaseClearOutput
    call OwnerLeaseValidate
    jp c, .invalid
    ld a, [wOwnerCount]
    or a
    jp z, .invalid
    cp 14
    jp nc, .invalid

    ; Detect duplicate owners and count free banks before any SRAM mutation.
    ld hl, wLeaseTable + 3
    ld b, 13
    ld c, 0
.scan:
    ld a, [hli]
    ld d, a
    ld a, [wOwnerTag]
    cp d
    jp z, .duplicate
    ld a, d
    or a
    jr nz, .occupied
    inc c
.occupied:
    dec b
    jr nz, .scan
    ld a, [wOwnerCount]
    cp c
    jp z, .claim
    jp c, .claim
    ld a, 1
    jp .failure
.claim:
    ; Every call to LeaseAlloc succeeds by the serialized preflight.
    ; It zeroizes a bank before ownership is marked or exposed.
.loop:
    call LeaseAlloc
    ld a, [wLeaseStatus]
    or a
    jp nz, .unexpected
    ld a, [wLeaseBank]
    ld c, a
    ld b, 0
    ld hl, wLeaseTable
    add hl, bc
    ld a, [wOwnerTag]
    ld [hl], a
    ld a, [wOwnerAllocated]
    ld c, a
    ld b, 0
    ld hl, wOwnerBanks
    add hl, bc
    ld a, [wLeaseBank]
    ld [hl], a
    ld a, [wOwnerAllocated]
    inc a
    ld [wOwnerAllocated], a
    ld b, a
    ld a, [wOwnerCount]
    cp b
    jr nz, .loop
    xor a
    ld [wOwnerStatus], a
    ret
.invalid:
    ld a, 2
    jr .failure
.duplicate:
    ld a, 3
    jr .failure
.unexpected:
    ; Internal invariant violation; rollback only this owner's allocations.
    ; No unrelated bank can be released by a rollback.
    call OwnerLeaseRelease
    ld a, 4
.failure:
    ld [wOwnerStatus], a
    call OwnerLeaseClearOutput
    ret

OwnerLeaseRelease::
    call OwnerLeaseClearOutput
    call OwnerLeaseValidate
    jr c, .invalid
    ld a, 3
    ld [wLeaseIter], a
.loop:
    ld a, [wLeaseIter]
    ld c, a
    ld b, 0
    ld hl, wLeaseTable
    add hl, bc
    ld a, [hl]
    ld b, a
    ld a, [wOwnerTag]
    cp b
    jr nz, .next
    ld a, [wLeaseIter]
    call SRAMZero8KiB
    ld a, [wLeaseIter]
    ld c, a
    ld b, 0
    ld hl, wLeaseTable
    add hl, bc
    xor a
    ld [hl], a
    ld a, [wOwnerAllocated]
    inc a
    ld [wOwnerAllocated], a
.next:
    ld a, [wLeaseIter]
    inc a
    ld [wLeaseIter], a
    cp 16
    jr c, .loop
    ld a, [wOwnerAllocated]
    or a
    jr z, .absent
    xor a
    ld [wOwnerStatus], a
    ; Successful release must not leave freed scratch SRAM mapped.
    ; Switch to permanently reserved bank 0 only after every scrub.
    call SRAMSelectBank
    ret
.invalid:
    ld a, 2
    ld [wOwnerStatus], a
    ret
.absent:
    ld a, 3
    ld [wOwnerStatus], a
    ret

; Resolve a logical bank index within an owner-tagged group. Needed by
; multi-bank semantic arithmetic: never assume owned banks are contiguous.
; Inputs: wOwnerRequest=owner (1..253), wOwnerSelectIndex=0..12.
; Outputs: status 0=selected, 2=invalid owner/index, 3=not owned;
;          wOwnerSelectedBank=physical bank 3..15, or $ff on failure.
; Failure leaves the currently selected MBC5 SRAM bank untouched.
; Requires SRAMEnable, serialized caller, no interrupts; clobbers A/BC/D/HL.
OwnerLeaseSelectBank::
    ld a, $ff
    ld [wOwnerSelectedBank], a
    call OwnerLeaseValidate
    jr c, .invalid
    ld a, [wOwnerSelectIndex]
    cp 13
    jr nc, .invalid
    ld c, a
    ld b, 3
    ld hl, wLeaseTable + 3
.scan:
    ld a, [hli]
    ld d, a
    ld a, [wOwnerTag]
    cp d
    jr nz, .next
    ld a, c
    or a
    jr z, .found
    dec c
.next:
    inc b
    ld a, b
    cp 16
    jr c, .scan
    ld a, 3
    jr .failure
.found:
    ld a, b
    ld [wOwnerSelectedBank], a
    call SRAMSelectBank
    xor a
    ld [wOwnerStatus], a
    ret
.invalid:
    ld a, 2
.failure:
    ld [wOwnerStatus], a
    ret
