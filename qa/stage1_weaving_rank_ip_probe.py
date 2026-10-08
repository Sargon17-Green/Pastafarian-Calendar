#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native diagnostic for a new QA-only 2D weaving rank lexer; NOT oracle."""
from __future__ import print_function
import os
import subprocess
import tempfile
CMD=["pyfunge","--disable-fprint","--no-concurrent",
     "--no-filesystem","-v98","-d2"]
for rank in (0,1):
    path="qa/unrank_weaving_strict_candidate.b98"
    fd,trace=tempfile.mkstemp(suffix=".tsv");os.close(fd)
    try:
        env=os.environ.copy();env["BF98_TRACE_LOG"]=trace
        env["PYTHONPATH"]="/work/qa"
        p=subprocess.Popen(["timeout","--kill-after=2s","3s"]+CMD+[path],
                  stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                  stderr=subprocess.PIPE,env=env)
        stdout,stderr=p.communicate("2 2 2 %d\n"%rank)
        steps=[]
        with open(trace,"r") as stream:
            for row in stream:
                if row.startswith("STEP\t"):
                    parts=row.strip().split("\t")
                    if len(parts)!=9:
                        continue  # truncated partial record after timeout
                    steps.append((int(parts[1]),int(parts[3]),
                                 int(parts[4]),int(parts[5]),
                                 int(parts[6]),int(parts[7])))
        seenentry=[(i,step) for i,step in enumerate(steps)
                   if step[1:3]==(292,0)]
        seenreturn=[(i,step) for i,step in enumerate(steps)
                    if step[1:3]==(293,0)]
        seenx=[(i,step) for i,step in enumerate(steps)
               if step[1:3]==(711,1)]
        print("NATIVE_WEAVING_RANK_IP_PROBE",
              "rank",rank,"exit",p.returncode,
              "out",stdout.split(),"steps",len(steps),
              "entry",seenentry[:3],"return",seenreturn[:3],
              "candidate_x",seenx[:3],
              "tail",steps[-9:])
    finally:
        try:os.unlink(trace)
        except OSError:pass
print("NATIVE_WEAVING_RANK_PROBE_DIAGNOSTIC_ONLY")
