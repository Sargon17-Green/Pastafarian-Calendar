#!/usr/bin/env python
"""QA-only production telemetry. Python 2.7, exact PyFunge archive required."""
from __future__ import print_function
import gzip, hashlib, json, os, sys, StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork
import stage1_native_diverse_geometry as diverse

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
RUNTIME = "e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac"
SOURCE = "src/interleaved_work_counts.b98"

def need(ok, msg):
    if not ok:
        raise AssertionError(msg)

def corpus():
    families = dict((n,(f,v)) for n,f,v in fork.native.CASES + fork.wide.CASES)
    owners = [(n, families[n][0], True, opposite, "owner")
              for n in fork.CASE_NAMES for opposite in (False,True)]
    geometry = [(n,f,v,False,"geometry") for n,f,v in diverse.CASES]
    need(len(owners)==64 and len(geometry)==17, "corpus size")
    return owners + geometry

def vector(v):
    return list(v) if v is not None else None

def state(ip):
    return [vector(ip.position),vector(ip.delta),vector(ip.offset),
            bool(ip.stringmode),bool(ip.queuemode),bool(ip.invertmode)]

def run(index, outdir, runtime):
    raw = open(SOURCE,"rb").read()
    need(fork.blob(raw)==PIN,"production source mismatch")
    need(hashlib.sha256(open(runtime,"rb").read()).hexdigest()==RUNTIME,"runtime mismatch")
    label, fields, valid, opposite, family = corpus()[index]
    stdout=StringIO.StringIO()
    program=Program(Befunge98,platform=BufferedPlatform([],{},stdin=StringIO.StringIO(
        " ".join(map(str,fields))+"\n"),stdout=stdout))
    program.load_code(raw)
    program.create_ip()
    ip=program.ips[0]
    space=program.space
    tick=[0]
    active=[]
    events=[]
    counts={}
    old_step=program.execute_step
    original={}
    gate=[]
    trace=gzip.open(os.path.join(outdir,"%03d.jsonl.gz"%index),"wb")
    def emit(e):
        events.append(e)
        counts[e[0]]=counts.get(e[0],0)+1
    def bounds():
        return [vector(space.boundmin),vector(space.boundmax),bool(space.rectchanged)]
    def wrapper(name, old):
        def call(*args,**kwargs):
            before=bounds()
            if name=="get":
                result=old(*args,**kwargs)
                if active and active[-1]=="g":
                    emit(["get",vector(args[0]),result])
                return result
            if name=="normalize":
                result=old(*args,**kwargs)
                emit([name,vector(args[0]),vector(args[1]),before,vector(result)])
                return result
            if name in ("scanwhile","scanuntil"):
                result=old(*args,**kwargs)
                emit([name,vector(args[0]),vector(args[1]),args[2],before,vector(result)])
                return result
            if name=="put":
                pos,val=args[:2]
                emit(["put",vector(pos),val,space.get(pos),before,list(active)])
                result=old(*args,**kwargs)
                emit(["put_after",vector(pos),space.get(pos),bounds()])
                return result
            if name=="putspace":
                emit([name,vector(args[0]),len(args[1]),before,list(active)])
                result=old(*args,**kwargs)
                emit(["putspace_after",bounds()])
                return result
            if name=="notifyrect":
                result=old(*args,**kwargs)
                emit([name,vector(args[0]),vector(args[1]),before,bounds()])
                return result
            if name=="getrect":
                result=old(*args,**kwargs)
                emit([name,before,bounds(),[vector(v) for v in result]])
                return result
            raise AssertionError(name)
        return call
    class WatchedDict(dict):
        def __setitem__(self,key,val):
            emit(["dict_set",vector(key),self.get(key,32),val,list(active)])
            return dict.__setitem__(self,key,val)
        def __delitem__(self,key):
            emit(["dict_del",vector(key),self.get(key,32),key in self,list(active)])
            return dict.__delitem__(self,key)
        def update(self,*a,**k): raise AssertionError("unclassified dict.update")
        def clear(self): raise AssertionError("unclassified dict.clear")
        def pop(self,*a): raise AssertionError("unclassified dict.pop")
        def popitem(self): raise AssertionError("unclassified dict.popitem")
        def setdefault(self,*a): raise AssertionError("unclassified dict.setdefault")
    space.space=WatchedDict(space.space)
    for name in ("get","put","putspace","notifyrect","getrect","normalize","scanwhile","scanuntil"):
        original[name]=getattr(space,name)
        setattr(space,name,wrapper(name,original[name]))
    def command_hook(op, old):
        def call(current):
            active.append(op)
            watched=op in "pgxj{}k"
            if watched:
                emit(["command",op,state(current),list(current.stack[-1]),len(current.stack),
                      [list(frame) for frame in current.stack.sstack] if op in "{}" else None])
            try:
                result=old(current)
            finally:
                if watched:
                    emit(["return",op,state(current),list(current.stack[-1]),len(current.stack),
                      [list(frame) for frame in current.stack.sstack] if op in "{}" else None])
                active.pop()
            return result
        return call
    # Every dispatch entry is instrumented, including nested k dispatch.
    for op,method in list(ip.commands.items()):
        ip.commands[op]=command_hook(chr(op),method)
    def step(self):
        tick[0]+=1
        need(tick[0]<=750000 and len(self.ips)==1 and self.ips[0] is ip,"single-IP/step bound")
        need(self.space.space is watched,"space backing replaced")
        need(not ip.fploaded,"fingerprint outside audit scope")
        del events[:]
        pre=state(ip)
        op=int(original["get"](ip.position))
        if tuple(ip.position)==fork.GATE and op==ord("|") and not ip.stringmode:
            toss=ip.stack[-1]
            end=0 if ip.queuemode else -1
            need(len(toss)>0,"gate operand absent")
            prev=toss[end]
            if opposite:
                toss[end]=0 if prev else 1
            gate.append([tick[0],prev,toss[end]])
        try:
            return old_step()
        finally:
            need(not active,"unbalanced dispatch")
            need(not ip.fploaded,"fingerprint outside audit scope")
            need(self.space.space is watched,"space backing replaced")
            trace.write(json.dumps([tick[0],pre,op,events,state(ip) if self.ips else None],
                                   separators=(",",":"))+"\n")
    watched=space.space
    program.execute_step=step.__get__(program,program.__class__)
    try:
        program.execute()
    finally:
        trace.close()
    need(not program.ips,"did not halt")
    output=stdout.getvalue().split()
    expected=diverse.expected_for(*fields) if valid else ["-1"]*7
    if not opposite:
        need(output==expected,"normal independent reference mismatch")
    if family=="owner":
        need(len(gate)==1,"owner intervention count")
        need(bool(gate[0][1])!=bool(gate[0][2]) if opposite else gate[0][1]==gate[0][2],
             "owner intervention identity")
    receipt={"schema":"qa31cy-production-telemetry-v2","index":index,"case":label,
        "fields":list(fields),"valid":valid,"opposite":opposite,"family":family,
        "source":PIN,"runtime":RUNTIME,"head":os.environ.get("QA_HEAD_SHA"),
        "trace_sha256":hashlib.sha256(open(os.path.join(outdir,"%03d.jsonl.gz"%index),"rb").read()).hexdigest(),
        "ticks":tick[0],"gate":gate,"output":output,"reference":expected,
        "reference_equal":output==expected,"event_counts":counts,"stage1_accepted":False}
    with open(os.path.join(outdir,"%03d.json"%index),"wb") as f:
        f.write(json.dumps(receipt,sort_keys=True)+"\n")
    print("PRODUCTION_TELEMETRY_CAPTURED",index,label,opposite,tick[0],counts)
if __name__=="__main__":
    run(int(sys.argv[1]),sys.argv[2],sys.argv[3])
