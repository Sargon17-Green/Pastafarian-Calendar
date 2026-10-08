# -*- coding: utf-8 -*-
"""TEST-ONLY native PyFunge operand observation; no arithmetic oracle or mutation.

Activated only by BF98_OPERAND_LOG. Outside this opt-in PYTHONPATH,
production and the established native trace hook remain byte-for-byte intact.
"""
import os
if os.environ.get("BF98_OPERAND_LOG"):
    import funge.program as _f
    _original_execute = _f.Program.execute
    _original_step = _f.Program.execute_step
    _sink = open(os.environ["BF98_OPERAND_LOG"], "w")
    _watch = frozenset(((132,5),(308,1430),(951,1335),
                        (1470,100),(1475,101),(1476,101)))
    _hits = [0]
    def _step_with_operands(program):
        for ip in list(program.ips):
            xy = tuple(ip.position)
            if xy not in _watch:
                continue
            values = list(ip.stack[_f.TOSS])
            opcode = program.space.get(ip.position)
            _hits[0] += 1
            # Log the actual native top two operand integers verbatim.
            # The observation does not pop, push or write Funge-space.
            _sink.write("HIT\t%d\t%d\t%d\t%d\t%d\t%s\t%s\n" %
                        (ip.id,xy[0],xy[1],opcode,len(values),
                         str(values[-2]) if len(values)>1 else "EMPTY",
                         str(values[-1]) if values else "EMPTY"))
        return _original_step(program)
    def _execute_with_operands(program):
        program.execute_step = _step_with_operands.__get__(program,program.__class__)
        try:
            return _original_execute(program)
        finally:
            _sink.flush()
    _f.Program.execute = _execute_with_operands
