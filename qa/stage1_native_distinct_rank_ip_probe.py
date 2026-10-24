#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native IP diagnostic; no mathematical Pastafarian oracle."""
from __future__ import print_function
import os,subprocess,tempfile
CMD=["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
CAND="qa/unrank_distinct_names_strict_candidate.b98"
BASE="reference/unrank_distinct_names.b98"
for module in (CAND,BASE):
    for rank in (0,1):
        fd,trace=tempfile.mkstemp(suffix=".tsv")
        os.close(fd)
        env=os.environ.copy()
        env["BF98_TRACE_LOG"]=trace
        env["PYTHONPATH"]="/work/qa"
        cmd=["timeout","--kill-after=2s","2s"]+CMD+[module]
        child=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
        out,err=child.communicate("3 2 %d\n"%rank)
        steps=0;last=[];hits={}
        try:
            with open(trace,"r") as stream:
                for row in stream:
                    fields=row.rstrip("\n").split("\t")
                    if fields[0]!="STEP" or len(fields)!=9:continue
                    steps+=1
                    tick,ip,x,y,dx,dy,op,depth=tuple(map(int,fields[1:]))
                    event=(tick,x,y,dx,dy,op,depth)
                    last.append(event)
                    if len(last)>12:last.pop(0)
                    if (x,y) in ((20,0),(21,0),(20,1),(21,1),(440,1)) and (x,y) not in hits:
                        hits[(x,y)]=event
        finally:
            try: os.unlink(trace)
            except OSError:pass
        print("NATIVE_DISTINCT_RANK_IP_PROBE",module,"rank",rank,
              "exit",child.returncode,"stdout",out.split(),
              "steps",steps,"entry_hits",sorted(hits.items()),
              "trace_tail",last,"stderr",repr(err[-200:]))
        import sys;sys.stdout.flush()
print("NATIVE_DISTINCT_RANK_IP_PROBE_DIAGNOSTIC_ONLY")
