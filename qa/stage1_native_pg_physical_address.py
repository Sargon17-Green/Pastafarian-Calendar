#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Physical BF98 p/g operands for Native QA receipts, not calendar semantics.

In Funge-98, p/g use storage-offset-relative x/y. A TOSS underflow
supplies implicit zeros. Return (physical Vector, physical (x,y), p value).
This module is pure Python 2/3 and does not mutate the interpreter IP.
"""

def physical_pg_operands(ip, kind):
    if kind not in ('p', 'g'):
        raise ValueError('expected physical p or g opcode')
    needed = 3 if kind == 'p' else 2
    stack = list(ip.stack[0])
    args = ([0] * max(0, needed - len(stack))) + stack[-needed:]
    args = [int(value) for value in args]
    if kind == 'p':
        value, x, y = args
    else:
        x, y = args
        value = None
    coordinate = (x + int(ip.offset[0]), y + int(ip.offset[1]))
    return ip.position.__class__(coordinate), coordinate, value
