# -*- coding: utf-8 -*-
"""Native PyFunge-only controlled counterfactual for a runtime-written gate.

This is loaded ONLY through PYTHONPATH in a standalone native QA process.
It never changes repository production code or calendar reference values.
"""
from __future__ import print_function
import os
import sys

if os.environ.get("BF98_GATE_COUNTERFACTUAL"):
    import funge.program as _program
    _original_step=_program.Program.execute_step
    _original_execute=_program.Program.execute
    sys.stderr.write("CF_HOOK_LOADED executable gate test\n")
    sys.stderr.flush()
    _target=(1500,1750)
    _observed=[0]
    _mutated=[False]
    _steps_after=[0]
    _window=[[]]

    def _test_step(self):
        for ip in list(self.ips):
            point=tuple(ip.position)
            if _mutated[0] and _steps_after[0]<5:
                _window[0].append((point,tuple(ip.delta),
                                    self.space.get(ip.position)))
                _steps_after[0]+=1
                if _steps_after[0]==5:
                    sys.stderr.write("CF_GATE_POST_WINDOW %r\n" %
                                     (_window[0],))
                    sys.stderr.flush()
            if point==_target:
                observed=self.space.get(ip.position)
                _observed[0]+=1
                if not _mutated[0] and observed==ord("v"):
                    # The original dynamic x-vector reaches this gate with
                    # noncardinal delta; native 'v' turns it to (0,+1).
                    # Counterfactual does not change the stack or any
                    # original p calculation, only one executed code cell.
                    self.space.put(ip.position,ord(" "))
                    _mutated[0]=True
                    sys.stderr.write(
                      "CF_GATE_TRIGGER position=(1500,1750) "
                      "opcode_before=118 opcode_after=32 "
                      "observed_visit=%d delta_before=%r\n" %
                      (_observed[0],tuple(ip.delta)))
                    sys.stderr.flush()
        return _original_step(self)
    def _traced_execute(self):
        sys.stderr.write("CF_HOOK_BOUND to native Program.execute\n")
        sys.stderr.flush()
        # Match the already native-verified qa/sitecustomize.py trace hook:
        # bind to the *instance*, not only the Program class.
        self.execute_step=_test_step.__get__(self,self.__class__)
        return _original_execute(self)
    _program.Program.execute=_traced_execute
