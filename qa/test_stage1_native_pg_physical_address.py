#!/usr/bin/env python3
"""Native p/g receipt coordinate contract: offset + underflow, no PyFunge required."""
from stage1_native_pg_physical_address import physical_pg_operands


class Vector(tuple):
    def __new__(cls, values):
        return tuple.__new__(cls, values)


class IP:
    def __init__(self, stack, offset):
        self.stack = [stack]
        self.position = Vector((0, 0))
        self.offset = Vector(offset)


def verify(stack, offset, kind, expected_coord, expected_value):
    ip = IP(stack, offset)
    before = tuple(ip.stack[0])
    vector, coord, value = physical_pg_operands(ip, kind)
    if type(vector) is not Vector or coord != expected_coord or value != expected_value:
        raise AssertionError((kind, stack, offset, coord, value))
    if tuple(ip.stack[0]) != before:
        raise AssertionError('inspecting physical operands consumed caller stack')


def main():
    verify([7, 0, 0], (100, 200), 'p', (100, 200), 7)
    verify([0, 0], (100, 200), 'g', (100, 200), None)
    verify([], (100, 200), 'p', (100, 200), 0)
    verify([], (-17, 8), 'g', (-17, 8), None)
    verify([9], (-17, 8), 'p', (-17, 17), 0)
    verify([9], (-17, 8), 'g', (-17, 17), None)
    verify([13, -4, 2], (4, -10), 'p', (0, -8), 13)
    verify([99, 13, -4, 2], (4, -10), 'p', (0, -8), 13)
    try:
        physical_pg_operands(IP([], (0, 0)), 'x')
    except ValueError:
        pass
    else:
        raise AssertionError('non p/g opcode accepted')
    print('NATIVE_PG_PHYSICAL_OFFSET_AND_UNDERFLOW_9_CONTRACTS_PASS')


if __name__ == '__main__':
    main()
