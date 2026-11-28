"""Collect real PyFunge-98 paths, writes and self-modifying opcodes for the five stateful Bootstrap programs (Python 2.7)."""
from __future__ import print_function
import gzip
import hashlib
import json
import os
import StringIO
import sys

from funge.exception import IPQuitted, IPStopped
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.program import Program
from stage1_native_diverse_geometry import expected_for, native

CASES=[
    ("bootstrap","0"),("bootstrap","10"),
    ("day_count","0 12"),("day_count","1 0"),
    ("save","1 21"),("save","2 12"),
    ("interleaved_day_save","1 12"),("interleaved_day_save","1 0"),
    ("work_counts","0 21 1 12"),("work_counts","0 12 1 21"),
    ("work_counts","1 2 0 1"),("work_counts","2 1 0 2"),
]
GATE=(1020,1046)


def need(ok,why):
    if not ok: raise AssertionError(why)


def fresh(source,raw):
    stdout=StringIO.StringIO()
    program=Program(Befunge98,platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw+"\n"),stdout=stdout))
    program.load_code(source)
    program.create_ip()
    need(len(program.ips)==1,"expected one new IP")
    return program,stdout


def advance(program):
    ip=program.ips[0]
    try: program.execute_step()
    except IPStopped:
        if program.ips: program.remove_ip(ip)
    except IPQuitted:
        for active in list(program.ips): program.remove_ip(active)


def expected(name,raw):
    fields=list(map(int,raw.split()))
    if name=="work_counts":
        if fields[0] not in (0,1) or fields[2] not in (0,1): return ["-1"]*7
        return expected_for(*fields)
    if name=="bootstrap": return ["1" if fields[0]==0 else "0"]
    if name=="interleaved_day_save":
        return native("reference/day_count.b98",raw+"\n")+native("reference/save.b98",raw+"\n")
    return native("reference/"+name+".b98",raw+"\n")


def capture(name,raw,ordinal,out,source):
    p,stdout=fresh(source,raw)
    stream_name="route-%02d.jsonl.gz"%ordinal
    stream=gzip.open(os.path.join(out,stream_name),"wb",5)
    writes=[]
    space=p.space
    cls=type(space)
    original=cls.put
    def measured(receiver,address,value,*args,**kwargs):
        need(receiver is space,"foreign space write")
        old=receiver.get(address)
        result=original(receiver,address,value,*args,**kwargs)
        writes.append([int(address[0]),int(address[1]),int(old),int(receiver.get(address))])
        need(writes[-1][3]==int(value),"physical write failed")
        return result
    cls.put=measured
    ticks=0
    try:
        while p.ips:
            ticks+=1
            need(ticks<=85000 and len(p.ips)==1,"route exceeded the bounded single-IP case")
            ip=p.ips[0]
            x,y=ip.position
            dx,dy=ip.delta
            op=p.space.get(ip.position)
            stack=ip.stack[-1]
            event=[ticks,int(ip.id),int(x),int(y),int(dx),int(dy),int(op),len(stack),len(ip.stack),None]
            del writes[:]
            if op==ord("g") and not ip.stringmode:
                need(len(stack)>=2,"missing g operands")
                address=type(ip.position)((int(stack[-2])+int(ip.offset[0]),int(stack[-1])+int(ip.offset[1])))
                event[-1]=["g",int(address[0]),int(address[1]),int(p.space.get(address))]
            advance(p)
            if writes:
                need(len(writes)==1 and op==ord("p") and event[-1] is None,"unexpected memory-write mechanism")
                event[-1]=["p"]+writes[0]
            stream.write(json.dumps(event,separators=(",",":"))+"\n")
    finally:
        cls.put=original
        stream.close()
    result=stdout.getvalue().split()
    wanted=expected(name,raw)
    need(wanted==result,"independent native result")
    return dict(program=name,raw=raw,source_blob=hashlib.sha1("blob %d\0"%len(source)+source).hexdigest(),
                output=result,native_expected=wanted,ticks=ticks,trace=stream_name)


def peer_trial(source,order):
    inputs=["0 21 1 12","0 12 1 21"]
    pairs=[fresh(source,s) for s in inputs]
    programs=[pair[0] for pair in pairs]
    vectors=[type(p.ips[0].position) for p in programs]
    need(programs[0].space is not programs[1].space and programs[0].semantics is not programs[1].semantics,
         "two live programs share space or semantics")
    def gates(): return [int(p.space.get(v(GATE))) for p,v in zip(programs,vectors)]
    def until_gate(p):
        for i in range(85000):
            if p.ips and tuple(p.ips[0].position)==GATE: return i
            need(bool(p.ips),"peer halted before its gate")
            advance(p)
        raise ValueError("peer did not reach gate")
    need(gates()==[32,32],"gate initially occupied")
    snapshots=[]
    for digit in range(2):
        for index in order:
            before=gates()
            if digit:
                advance(programs[index])
            elapsed=until_gate(programs[index])
            after=gates()
            need(before[1-index]==after[1-index] and after[index]==((118,62),(62,118))[digit][index],
                 "paused peer changed or lost its direction")
            snapshots.append([digit,index,before,after,elapsed])
        need(gates()[0]!=gates()[1],"coincident opposite gates were not observed")
    for index in order:
        peer_value=gates()[1-index]
        programs[index].execute()
        need(not programs[index].ips and gates()[1-index]==peer_value,"peer changed while other program finished")
    outputs=[s.getvalue().split() for _,s in pairs]
    need(outputs==[expected("work_counts",s) for s in inputs],"peer results changed with schedule")
    return dict(order=order,snapshots=snapshots,outputs=outputs)


def main(out):
    sources={}
    for name,_ in CASES:
        if name not in sources:
            with open("src/"+name+".b98","rb") as f: sources[name]=f.read()
    runs=[capture(n,s,i,out,sources[n]) for i,(n,s) in enumerate(CASES)]
    peers=[peer_trial(sources["work_counts"],order) for order in ((0,1),(1,0))]
    with open(os.path.join(out,"runs.json"),"wb") as f:
        f.write(json.dumps({"runs":runs,"peer_schedules":peers},sort_keys=True,indent=2)+"\n")
    print("NATIVE_STAGE1_LIVE_GEOMETRY_PASS",len(runs),"physical paths",sum(r["ticks"] for r in runs),"ticks")


if __name__=="__main__": main(sys.argv[1])
