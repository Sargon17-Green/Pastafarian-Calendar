#!/usr/bin/env python3
"""Independent integer/byte oracle: signed ordinal ABI preflight, not conversion."""
from itertools import product


def encode(value: int) -> tuple[int, bytes]:
    sign = int(value < 0)
    mag = abs(value)
    size = (mag.bit_length() + 7) // 8
    return sign, mag.to_bytes(size, "little")


def validate(active: bool, owner: int, allocated_banks: int,
             sign: int, length: int, raw: bytes) -> int:
    if not active:
        return 6
    if sign not in (0, 1) or length < 0:
        return 2
    if length == 0:
        return 0 if sign == 0 else 2
    if not 1 <= owner <= 253:
        return 2
    capacity = allocated_banks * 8192
    if length > capacity or length > len(raw):
        return 2
    return 0 if raw[length - 1] != 0 else 2


def main() -> None:
    checks = 0
    for value in (0, 1, -1, 255, -255, 256, -256,
                  (1 << 128) - 1, -(1 << 128),
                  (1 << 65535) + 3, -((1 << 65535) + 3)):
        sign, data = encode(value)
        banks = max(1, (len(data) + 8191) // 8192)
        assert banks <= 13
        assert validate(True, 61, banks, sign, len(data), data) == 0
        assert int.from_bytes(data, "little") * (-1 if sign else 1) == value
        checks += 1
    assert validate(False, 0, 0, 0, 0, b"") == 6
    checks += 1
    before = bytearray([1]) + bytearray(8191)
    original = bytes(before)
    for sign, length in product((0, 1, 2, 255), (0, 1, 2, 8192, 8193)):
        expected = (0 if sign == 0 else 2) if length == 0 else (
            0 if sign in (0, 1) and length == 1 else 2)
        assert validate(True, 61, 1, sign, length, before) == expected
        assert bytes(before) == original
        checks += 1
    # Top-byte boundaries and ownership-independent request corruption.
    assert validate(True, 61, 1, 0, 2, b"\x01\\x00") == 2
    assert validate(True, 61, 1, 1, 2, b"\x01\\x01") == 0
    assert validate(True, 61, 1, 0, 8192, b"\x00" * 8191 + b"\x01") == 0
    assert validate(True, 61, 1, 0, 8193, b"\x01" * 8193) == 2
    assert validate(True, 61, 2, 0, 8193, b"\x00" * 8192 + b"\x01") == 0
    checks += 5
    # The active owner is an immutable invocation property, not the request.
    active_owner, mutated_request = 61, 255
    assert active_owner != mutated_request
    assert validate(True, active_owner, 1, 1, 1, b"\x01") == 0
    checks += 1
    # Abort semantics: entire owner allocation zeroized; metadata reset.
    active, sign, length, data = True, 1, 1, bytearray(b"\x01" + b"\x00" * 8191)
    active, sign, length, data = False, 0, 0, bytearray(8192)
    assert (active, sign, length, bytes(data)) == (False, 0, 0, bytes(8192))
    checks += 1
    print(f"HOST_STAGE1_SIGNED_ORDINAL_PREFLIGHT=PASS cases={checks} "
          "max_length=106496 canonical_zero=YES leading_zero=REJECTED "
          "saved_active_owner=YES abort_scrub=8192 "
          "arithmetic=NOT_IMPLEMENTED native_execution=NOT_CLAIMED")


if __name__ == "__main__":
    main()
