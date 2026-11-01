#!/usr/bin/env python3
"""ROM0 allocated-byte and gap comparison for two RGBDS linker map files.

Reads linker maps, not emulator output. Fail closed on missing ROM0 data,
overlapping sections, out-of-range addresses, or unexpected size delta.
"""
import re
import sys
from pathlib import Path

ROM0_SIZE = 0x4000
HEADER = re.compile(r'^ROM0 bank #0:\s*$', re.IGNORECASE)
NEXT_BANK = re.compile(r'^[^\s].*\bbank #\d+:\s*$', re.IGNORECASE)
SECTION = re.compile(r'^\s*SECTION:\s*\$([0-9a-f]+)-\$([0-9a-f]+)\b', re.IGNORECASE)


def rom0_usage(path):
    inside = False
    found = False
    spans = []
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if HEADER.match(line.strip()):
            if found:
                raise ValueError(f'{path}: multiple ROM0 headings')
            inside = True
            found = True
            continue
        if inside and NEXT_BANK.match(line):
            break
        if not inside:
            continue
        match = SECTION.match(line)
        if not match:
            continue
        lo, hi = (int(s, 16) for s in match.groups())
        if not (0 <= lo <= hi < ROM0_SIZE):
            raise ValueError(f'{path}: ROM0 section out of bounds: {line.strip()}')
        spans.append((lo, hi + 1))
    if not found or not spans:
        raise ValueError(f'{path}: missing ROM0 section map')
    spans.sort()
    end = 0
    gaps = []
    for lo, hi in spans:
        if lo < end:
            raise ValueError(f'{path}: overlapping ROM0 sections at {lo:#06x}')
        gaps.append(lo - end)
        end = hi
    gaps.append(ROM0_SIZE - end)
    allocated = sum(hi - lo for lo, hi in spans)
    free = sum(gaps)
    if allocated + free != ROM0_SIZE:
        raise ValueError(f'{path}: ROM0 accounting mismatch')
    return allocated, free, max(gaps), gaps[-1], len(spans)


def main():
    if len(sys.argv) != 4:
        raise SystemExit('Usage: test_rom0_budget.py BASELINE.map CANDIDATE.map EXPECTED_SAVED_BYTES')
    before = rom0_usage(sys.argv[1])
    after = rom0_usage(sys.argv[2])
    expected = int(sys.argv[3])
    saved = before[0] - after[0]
    print('ROM0_BUDGET_METER baseline_allocated={} candidate_allocated={} '
          'baseline_free={} candidate_free={} baseline_max_gap={} candidate_max_gap={} '
          'baseline_tail_gap={} candidate_tail_gap={} baseline_sections={} candidate_sections={} '
          'saved={}'.format(before[0], after[0], before[1], after[1], before[2], after[2],
                            before[3], after[3], before[4], after[4], saved))
    if saved != expected:
        raise AssertionError(f'ROM0 measured delta {saved} != expected {expected}')
    print('ROM0_BUDGET=PASS measured_saved_bytes={}'.format(saved))


if __name__ == '__main__':
    main()
