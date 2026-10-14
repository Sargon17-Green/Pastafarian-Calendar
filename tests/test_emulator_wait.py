#!/usr/bin/env python3
"""Dependency-free regression tests for the asynchronous emulator wait gate."""
from __future__ import annotations
from test_rom import FAILURE, SUCCESS, wait_for_completion


class SimulatedPyBoy:
    def __init__(self, completion_frame: int, result: int = SUCCESS, case: int = 22):
        self.frame = 0
        self.completion_frame = completion_frame
        self.final_result = result
        self.final_case = case
        self.memory = {0xC000: 0, 0xC001: 0, 0xC002: 0}

    def tick(self, count: int, *, render: bool, sound: bool) -> None:
        assert count == 1 and not render and not sound
        self.frame += count
        if self.frame >= 75:
            self.memory[0xC001] = 1
        if self.frame >= self.completion_frame:
            self.memory[0xC000] = self.final_result
            self.memory[0xC001] = self.final_case
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
    print("EMULATOR_WAIT_GATE_TESTS=PASS delayed_boot=YES native_fail_preserved=YES timeout=YES")


if __name__ == "__main__":
    main()
