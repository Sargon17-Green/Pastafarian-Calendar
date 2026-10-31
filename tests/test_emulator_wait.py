#!/usr/bin/env python3
"""Dependency-free regression tests for the asynchronous emulator wait gate."""
from __future__ import annotations
from pathlib import Path
from tempfile import TemporaryDirectory
from test_rom import FAILURE, SUCCESS, discover_case_high_byte, wait_for_completion


class SimulatedPyBoy:
    def __init__(self, completion_frame: int, result: int = SUCCESS, case: int = 22, high_address: int | None = None):
        self.frame = 0
        self.completion_frame = completion_frame
        self.final_result = result
        self.final_case = case
        self.high_address = high_address
        self.memory = {0xC000: 0, 0xC001: 0, 0xC002: 0}
        if high_address is not None:
            self.memory[high_address] = 0

    def tick(self, count: int, *, render: bool, sound: bool) -> None:
        assert count == 1 and not render and not sound
        self.frame += count
        if self.frame >= 75:
            self.memory[0xC001] = 1
        if self.frame >= self.completion_frame:
            self.memory[0xC000] = self.final_result
            self.memory[0xC001] = self.final_case & 0xFF
            if self.high_address is not None:
                self.memory[self.high_address] = self.final_case >> 8
            self.memory[0xC002] = 0x40


def main() -> None:
    delayed = SimulatedPyBoy(completion_frame=180)
    result, case, stage, frame = wait_for_completion(delayed, 400)
    assert (result, case, stage, frame) == (SUCCESS, 22, 0x40, 180)
    failed = SimulatedPyBoy(completion_frame=190, result=FAILURE, case=16)
    result, case, stage, frame = wait_for_completion(failed, 400)
    assert (result, case, stage, frame) == (FAILURE, 16, 0x40, 190)
    never = SimulatedPyBoy(completion_frame=2000)
    try:
        wait_for_completion(never, 100)
    except AssertionError as exc:
        assert "last_case=1" in str(exc), str(exc)
    else:
        raise AssertionError("missing timeout failure")
    with TemporaryDirectory() as temporary:
        sym = Path(temporary) / "calendar.sym"
        sym.write_text(
            "00:C000 wTestResult\n00:C001 wTestCase\n"
            "00:C002 wRunStatus\n00:C0FF wTestCaseHi\n", encoding="utf-8"
        )
        high_address = discover_case_high_byte(sym)
        assert high_address == 0xC0FF
        boundary = SimulatedPyBoy(completion_frame=210, case=256, high_address=high_address)
        result, case, stage, frame = wait_for_completion(
            boundary, 400, high_byte_address=high_address
        )
        assert (result, case, stage, frame) == (SUCCESS, 256, 0x40, 210)
        next_case = SimulatedPyBoy(completion_frame=211, case=257, high_address=high_address)
        assert wait_for_completion(next_case, 400, high_byte_address=high_address) == (
            SUCCESS, 257, 0x40, 211
        )
        assert next_case.memory[0xC002] == 0x40, "dispatch ABI corrupted"
        sym.write_text(
            "00:C000 wTestResult\n00:C001 wTestCase\n"
            "00:C002 wRunStatus\n00:C002 wTestCaseHi\n", encoding="utf-8"
        )
        try:
            discover_case_high_byte(sym)
        except AssertionError:
            pass
        else:
            raise AssertionError("high case byte collided with dispatch")
    print("EMULATOR_WAIT_GATE_TESTS=PASS delayed_boot=YES native_fail_preserved=YES timeout=YES case16_boundary=2 sym_collision_rejected=YES")


if __name__ == "__main__":
    main()
