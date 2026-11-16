#!/usr/bin/env python3
"""Independent Host Python-int oracle; not Native/ROM execution evidence."""
def step(active, owner, owned, banks, delta, sign, length):
    before = {k: bytes(v) for k, v in banks.items()}
    def reject(status):
        assert all(bytes(banks[k]) == v for k, v in before.items())
        return status, sign, length
    if not active:
        return reject(6)
    if delta not in (0, 1) or sign not in (0, 1):
        return reject(2)
    if not 1 <= owner <= 253 or not 1 <= len(owned) <= 13:
        return reject(2)
    if len(set(owned)) != len(owned) or any(b not in banks for b in owned):
        return reject(2)
    raw = b"".join(before[b] for b in owned)
    if length < 0 or length > len(raw):
        return reject(2)
    if (length == 0 and sign) or (length and raw[length - 1] == 0):
        return reject(2)
    value = int.from_bytes(raw[:length], "little")
    value = -value if sign else value
    value += (1 if delta == 0 else -1)
    mag = abs(value)
    new_length = (mag.bit_length() + 7) // 8
    if new_length > len(raw):
        return reject(2)
    out = bytearray(raw)
    span = max(length, new_length)
    out[:span] = mag.to_bytes(new_length, "little").ljust(span, b"\x00")
    for i, p in enumerate(owned):
        banks[p][:] = out[i * 8192:(i + 1) * 8192]
    assert all(bytes(banks[k]) == v for k, v in before.items() if k not in owned)
    return 0, int(value < 0), new_length


def main():
    cases = 0
    def check(number, delta, owned, expected_status=0):
        nonlocal cases
        physical = {b: bytearray([0x5a] * 8192) for b in range(2, 16)}
        physical[4][:] = bytes([0xd7] * 8192)
        initial_peer = bytes(physical[4])
        mag = abs(number)
        encoded = mag.to_bytes((mag.bit_length() + 7) // 8, "little")
        assert len(encoded) <= len(owned) * 8192
        raw = encoded.ljust(len(owned) * 8192, b"\x00")
        for i, b in enumerate(owned):
            physical[b][:] = raw[i * 8192:(i + 1) * 8192]
        before = {k: bytes(v) for k, v in physical.items()}
        status, sign, length = step(True, 61, owned, physical, delta,
                                    int(number < 0), len(encoded))
        assert status == expected_status
        assert bytes(physical[4]) == initial_peer
        if status == 0:
            expected = number + (1 if delta == 0 else -1)
            out = b"".join(physical[b] for b in owned)
            assert int.from_bytes(out[:length], "little") * (-1 if sign else 1) == expected
            assert (sign, length) == (
                int(expected < 0), (abs(expected).bit_length() + 7) // 8)
        else:
            assert all(bytes(physical[k]) == v for k, v in before.items())
        cases += 1
    sets = ((3,), (3, 5), tuple([2, 3, 5] + list(range(6, 16))))
    for owned in sets:
        capacity = len(owned) * 8192
        numbers = (0, 1, -1, 255, -255, 256, -256, 65535, -65536,
                   1 << 16, -(1 << 16),
                   (1 << (8 * 8192)) - 1, -((1 << (8 * 8192)) - 1),
                   -(1 << (8 * 8192)))
        for number in numbers:
            if (abs(number).bit_length() + 7) // 8 > capacity:
                continue
            for delta in (0, 1):
                expected_length = (abs(number + (1 if delta == 0 else -1)).bit_length() + 7) // 8
                check(number, delta, owned, 2 if expected_length > capacity else 0)
    check((1 << (8192 * 8)) - 1, 0, (3,), 2)
    check((1 << (8192 * 8)) - 1, 0, (3, 5))
    check(-(1 << (8192 * 8)), 0, (3, 5))
    banks = {3: bytearray(8192), 5: bytearray(8192), 4: bytearray([0x71] * 8192)}
    banks[3][0] = 1
    for active, delta, sign, length, owner in (
        (False, 0, 0, 1, 61), (True, 2, 0, 1, 61),
        (True, 0, 1, 0, 61), (True, 1, 2, 1, 61),
        (True, 0, 0, 8193, 61), (True, 1, 0, 2, 61),
        (True, 0, 0, 1, 254)):
        status, s, n = step(active, owner, (3,), banks, delta, sign, length)
        assert status in (2, 6) and (s, n) == (sign, length)
        cases += 1
    print(f"HOST_STAGE1_ORDINAL_UNIT_ORACLE=PASS cases={cases} "
          "signed_bigint=YES boundaries_255_256=YES "
          "logical_8192_8193=YES fragmented_leases=YES "
          "unowned_SRAM_immutable=YES failure_immutable=YES "
          "native_execution=NOT_CLAIMED")


if __name__ == "__main__":
    main()
