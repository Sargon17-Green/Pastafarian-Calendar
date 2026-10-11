# -*- coding: utf-8 -*-
# Test-only native PyFunge trace hook. NEVER imported by production Befunge.
import os

if os.environ.get("BF98_TRACE_LOG"):
    import funge.program as _bfmod
    _bf_original_step = _bfmod.Program.execute_step
    _bf_original_execute = _bfmod.Program.execute
    _bf_log = open(os.environ["BF98_TRACE_LOG"], "w")
    _bf_tick = [0]

    def _bf_traced_step(self):
        pending = []
        pending_reads = []
        for ip in list(self.ips):
            position = tuple(ip.position)
            direction = tuple(ip.delta)
            opcode = self.space.get(ip.position)
            depth = len(ip.stack[_bfmod.TOSS])
            _bf_tick[0] += 1
            tick = _bf_tick[0]
            _bf_log.write(
                "STEP\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n" %
                (tick, ip.id, position[0], position[1],
                 direction[0], direction[1], opcode, depth))
            if opcode == ord("g") and not ip.stringmode:
                stack = list(ip.stack[_bfmod.TOSS])
                # Underflow in Funge-98 acts as implicit zero pops.
                px, py = ([0] * max(0, 2 - len(stack)) + stack[-2:])
                # Funge-98 g/p coordinates are relative to the active IP's
                # storage offset, which may be changed by { and }.
                # All trace coordinates must name the physical Space cell.
                point = ip.position.__class__((
                    int(px) + int(ip.offset[0]),
                    int(py) + int(ip.offset[1])))
                px, py = tuple(point)
                before = self.space.get(point)
                _bf_log.write(
                    "READ_BEFORE\t%d\t%d\t%d\t%d\n" %
                    (tick, px, py, before))
                pending_reads.append((tick, px, py, before, ip))
            if opcode == ord("p") and not ip.stringmode:
                stack = list(ip.stack[_bfmod.TOSS])
                # Pad absent bottom operands with implicit zeros.
                value, px, py = ([0] * max(0, 3 - len(stack)) + stack[-3:])
                # Funge-98 g/p coordinates are relative to the active IP's
                # storage offset, which may be changed by { and }.
                # All trace coordinates must name the physical Space cell.
                point = ip.position.__class__((
                    int(px) + int(ip.offset[0]),
                    int(py) + int(ip.offset[1])))
                px, py = tuple(point)
                before = self.space.get(point)
                _bf_log.write(
                    "WRITE_BEFORE\t%d\t%d\t%d\t%d\t%d\n" %
                    (tick, px, py, before, value))
                pending.append((tick, px, py, value, point))
        result = _bf_original_step(self)
        for tick, px, py, value, point in pending:
            actual = self.space.get(point)
            _bf_log.write("WRITE_AFTER\t%d\t%d\t%d\t%d\n" %
                          (tick, px, py, actual))
        for tick, px, py, expected, ip in pending_reads:
            top = list(ip.stack[_bfmod.TOSS])
            actual = top[-1] if top else -99999999
            _bf_log.write("READ_AFTER\t%d\t%d\t%d\t%d\n" %
                          (tick, px, py, actual))
        if _bf_tick[0] % 2048 == 0:
            _bf_log.flush()
        return result

    def _bf_traced_execute(self):
        self.execute_step = _bf_traced_step.__get__(self, self.__class__)
        try:
            return _bf_original_execute(self)
        finally:
            _bf_log.flush()

    _bfmod.Program.execute = _bf_traced_execute
