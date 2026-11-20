#!/usr/bin/env python3
"""Independent endpoint-46 Python-int oracle for optional separate Native371 ROM."""
from __future__ import annotations

from pathlib import Path
from test_sm83_stage1_stone_range_abi import oracle_range
from test_sm83_stage1_stone_transition_abi import MODULUS, table

ROOT = Path(__file__).resolve().parents[1]
ASM = ROOT / "src/tests/calendar_stone_i46_native_test.asm"
BOOT = ROOT / "src/boot.asm"
WORKFLOW = ROOT / ".github/workflows/canonical-names-lock.yml"
MAKE = ROOT / "Makefile"


def main() -> None:
    source = ASM.read_text(encoding="utf-8")
    expected = oracle_range((17, 29, 43, 71, 101), 46)
    fixture = table(source, "expected46")
    assert len(fixture) == 5 and fixture == expected
    assert all(1 <= v <= MODULUS for v in fixture)
    assert "call CalendarStoneTransitionRange" in source
    assert "ld a, 46" in source and "ld a, 115" in source
    assert ".compareSource:" in source and ".compareIdle:" in source
    assert "call CalendarInvocationAbort" in source
    boot = BOOT.read_text(encoding="utf-8")
    assert boot.count("IF DEF(STAGE1_I46_NATIVE_BENCH)") == 2
    assert "RunCalendarStoneI46Bench" in boot
    assert "build/calendar_i46.gb:" in MAKE.read_text(encoding="utf-8")
    assert "dmg-stone-i46-native:" in WORKFLOW.read_text(encoding="utf-8")
    from test_rom import TOTAL_CASES, MAX_BOOT_AND_TEST_FRAMES
    assert (TOTAL_CASES, MAX_BOOT_AND_TEST_FRAMES) == (370, 9000)
    print("HOST_STAGE1_STONE_I46_FIXTURE=PASS residues=5 bytes=80 "
          "immutable_source_and_idle=STATIC_ASSERTIONS independent_python_int=YES "
          "Native371=CI_REQUIRED standard370_max9000=PRESERVED", flush=True)


if __name__ == "__main__":
    main()
