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
            if opcode == ord("p"):
                stack = list(ip.stack[_bfmod.TOSS])
                if len(stack) < 3:
                    _bf_log.write("INSUFFICIENT_P_STACK\t%d\t%d\n" %
                                  (tick, len(stack)))
                else:
                    value, px, py = stack[-3:]
                    point = ip.position.__class__((px, py))
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
