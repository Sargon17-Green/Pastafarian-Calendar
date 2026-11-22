#!/usr/bin/env python3
"""Independent modular rank and lexicographic permutation acceptance for Native387.

This is a Host and static guard: it is never reported as native execution.
"""
from __future__ import annotations
from itertools import permutations
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
M = (1 << 127) - 1
FACTORS = (120, 24, 6, 2, 1, 1)
ALL_ORDERS = tuple(permutations(range(1, 7)))


def serial_remainder_720(residue: int) -> int:
    """Reference 128-bit streamed division independent of SM83 opcodes."""
    assert 1 <= residue <= M
    remainder = 0
    for bit in f'{residue:0128b}':
        remainder = 2 * remainder + int(bit)
        if remainder >= 720:
            remainder -= 720
    return remainder


def factoradic_unrank(index: int) -> tuple[int, ...]:
    available = list(range(1, 7))
    output = []
    for factor in FACTORS:
        digit, index = divmod(index, factor)
        output.append(available.pop(digit))
    assert index == 0
    return tuple(output)


def main() -> None:
    asm = (ROOT/'src/runtime/calendar_bowl_order.asm').read_text()
    bench = (ROOT/'src/tests/calendar_bowl_order_native_test.asm').read_text()
    boot = (ROOT/'src/boot.asm').read_text()
    workflow = (ROOT/'.github/workflows/canonical-names-lock.yml').read_text()
    makefile = (ROOT/'Makefile').read_text()
    for symbol in ('CalendarBowlOrderFromResidue::', 'CalendarOrdinalValidate',
                   'wCalendarBowlOrderInput', 'wCalendarBowlOrderScratch',
                   'wCalendarBowlOrder', 'wCalendarBowlRankLo',
                   'wCalendarBowlRankHi', '.factorials:', '.subtract720:'):
        assert symbol in asm, symbol
    assert re.search(r'\.factorials:\s*db 120, 24, 6, 2, 1, 1', asm)
    assert 'ld hl, wCalendarBowlOrderScratch' in asm
    assert 'ld de, wCalendarBowlOrder' in asm
    assert asm.index('ld de, wCalendarBowlOrder\n') > asm.index('.nextPosition:')
    assert 'wCalendarBowlOrderInput:: ds 16' in boot
    assert 'wCalendarBowlOrder:: ds 6' in boot
    assert 'wCalendarBowlOrderScratch:: ds 6' in boot
    assert 'STAGE1_BOWL_ORDER_NATIVE_BENCH' in boot
    assert 'RunCalendarBowlOrderBench' in bench
    assert 'build/calendar_bowl_order.gb' in makefile
    assert 'dmg-bowl-order-native:' in workflow
    assert 'db $1a,$90,$87,$91' in bench
    assert 'db 4,5,2,3,6,1' in bench

    assert len(ALL_ORDERS) == 720
    for rank in range(720):
        assert factoradic_unrank(rank) == ALL_ORDERS[rank]
    samples = [1, 2, 719, 720, 721, 722, M, M - 1,
               int.from_bytes(bytes.fromhex('1a90879100b953b0aec73f9eb1b3bb6a'),'little')]
    for i in range(1500):
        samples.append(1 + ((i * 0x9e3779b97f4a7c15) ^ (i << 71)) % M)
    for residue in samples:
        assert serial_remainder_720(residue) == residue % 720
        index = (serial_remainder_720(residue) - 1) % 720
        assert factoradic_unrank(index) == ALL_ORDERS[(residue-1) % 720]

    assert factoradic_unrank((M - 1) % 720) == (2, 1, 4, 3, 5, 6)
    assert factoradic_unrank((int.from_bytes(bytes.fromhex('1a90879100b953b0aec73f9eb1b3bb6a'),'little') -1)%720) == (4,5,2,3,6,1)
    print('HOST_STAGE1_BOWL_ORDER=PASS all_720=YES modular_samples=1509 '
          'signed127_limit=YES invalid_source=STATIC_GUARD native387=CI_REQUIRED', flush=True)


if __name__ == '__main__':
    main()
