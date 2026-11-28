"""Real PyFunge-98 signed-increment gate, with two switched-arm counterfactuals (Python 2.7)."""
from __future__ import print_function
import hashlib
import json
import StringIO
import sys

from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.program import Program
from stage1_native_diverse_geometry import expected_for

ENTER, GATE, PLUS, MINUS, JOIN = (959,1050),(1020,1046),(1021,1046),(1020,1047),(961,1050)
INC,SUM=(43,1702),(53,1704)


def need(ok, reason):
    if not ok: raise AssertionError(reason)


def run(code, fields, force=False, monitor=True):
    buf=StringIO.StringIO()
    raw=" ".join(map(str,fields))+"\n"
    p=Program(Befunge98,platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=buf))
    p.load_code(code)
    p.create_ip()
    original=p.execute_step
    captured=[]
    state={"ticks":0,"forced":False,"arithmetic_ticks":0}
    trace=hashlib.sha256()
    arithmetic_trace=hashlib.sha256()
    def step(self):
        state["ticks"]+=1
        need(state["ticks"]<=180000 and len(self.ips)==1,"bounded single IP")
        ip=self.ips[0]
        pos=tuple(ip.position)
        opcode=self.space.get(ip.position)
        motion="%d,%d,%d,%d,%d\n"%(pos[0],pos[1],ip.delta[0],ip.delta[1],opcode)
        trace.update(motion)
        if pos==(4,0) or state["arithmetic_ticks"]:
            state["arithmetic_ticks"]+=1
            arithmetic_trace.update(motion)
        if monitor:
            def read(xy): return int(self.space.get(type(ip.position)(xy)))
            stack=list(ip.stack[-1])
            if pos==ENTER:
                prior,inc=read(SUM),read(INC)
                need(stack==[prior,inc],"input is not the real loop sum and signed digit contribution")
                captured.append({"prior":prior,"inc":inc,"enter_tick":state["ticks"]})
            elif opcode==ord("p") and len(stack)>=3 and stack[-2:]==list(GATE):
                event=captured[-1]
                need("write" not in event and stack[-3]==(118 if event["inc"]<0 else 62),"detached physical write")
                event["write"]=[read(GATE),int(stack[-3])]
                event["write_tick"]=state["ticks"]
                result=original()
                need(read(GATE)==event["write"][1],"write not committed")
                return result
            elif pos==GATE:
                event=captured[-1]
                need(event["write"][1]==opcode and stack==[event["prior"],abs(event["inc"])],"gate fetch/payload")
                event["physical_fetch"]=chr(opcode)
                event["fetch_tick"]=state["ticks"]
                if force and not state["forced"] and event["inc"]:
                    self.space.put(ip.position,118 if opcode==62 else 62)
                    state["forced"]=True
                    event["forced"]=True
                event["executed"]=chr(read(GATE))
            elif pos in (PLUS,MINUS):
                e=captured[-1]
                need((pos,opcode)==((PLUS,ord("+")) if e["executed"]==">" else (MINUS,ord("-"))),"actual arithmetic arm")
                e["arm"]=chr(opcode)
                e["arm_tick"]=state["ticks"]
            elif pos==JOIN and captured and "after" not in captured[-1]:
                e=captured[-1]
                want=e["prior"]+(-e["inc"] if e.get("forced") else e["inc"])
                need(stack==[want,5],"wrong live sum at rejoin")
                e["after"]=int(stack[0])
                e["join_tick"]=state["ticks"]
        return original()
    p.execute_step=step.__get__(p,p.__class__)
    p.execute()
    need(not p.ips and all("after" in e for e in captured) and state["forced"]==force,"incomplete Native witness")
    return {"fields":fields,"output":buf.getvalue().split(),"ticks":state["ticks"],"route_sha256":trace.hexdigest(),
            "arithmetic_ticks":state["arithmetic_ticks"],"arithmetic_route_sha256":arithmetic_trace.hexdigest(),
            "crossings":captured,"forced":force}


def main():
    baseline,candidate,outfile=sys.argv[1:]
    sources=[]
    for path,pin in ((baseline,"560d6aa5807a7f766213a33835cce85eab0fa40c"),
                     (candidate,"7418e1ec5fe88fe5c14b75710dea2d5607527f28")):
        code=open(path,"rb").read()
        need(hashlib.sha1("blob %d\0"%len(code)+code).hexdigest()==pin,"physical source pin")
        sources.append(code)
    rows=[]
    for fields,incs in [((0,21,1,12),[-1,10]),((0,12,1,21),[1,-10]),
                        ((0,11,1,11),[0,0]),((0,0,0,0),[])]:
        expected=expected_for(*fields)
        old=run(sources[0],fields,monitor=False)
        healthy=run(sources[1],fields)
        need(old["output"]==healthy["output"]==expected and len(expected)==7,"independent native reference")
        need([e["inc"] for e in healthy["crossings"]]==incs,"incorrect numeric input to branch")
        row={"fields":fields,"baseline":old,"healthy":healthy,"native_reference":expected}
        if incs and incs[0]:
            mutation=run(sources[1],fields,True)
            shifted=[]
            for flag,mag in (fields[:2],fields[2:]):
                value=(1-2*flag)*mag-incs[0]
                shifted.extend((int(value<0),abs(value)))
            counter_expected=expected_for(*shifted)[:5]+expected[5:]
            need(len(mutation["output"])==7
                 and mutation["output"][0]!=expected[0] and mutation["output"][1]!=expected[1]
                 and mutation["output"]==counter_expected,"forced BF98 arm did not match the shifted native references")
            row["opposite_first_arm"]=mutation
            row["counterfactual_native_reference"]=counter_expected
        rows.append(row)
    need(rows[0]["baseline"]["arithmetic_route_sha256"]==rows[1]["baseline"]["arithmetic_route_sha256"]
         and rows[0]["healthy"]["arithmetic_route_sha256"]!=rows[1]["healthy"]["arithmetic_route_sha256"],
         "equal-width valid pair did not split relative to original arithmetic route")
    need([[e["arm"] for e in r["healthy"]["crossings"]] for r in rows[:2]]==[["-","+"],["+","-"]],"equal-length numeric routing")
    with open(outfile,"wb") as stream:
        stream.write(json.dumps(rows,indent=2,sort_keys=True)+"\n")
    print("NATIVE_SIGNED_INCREMENT_GATE_PASS four original/candidate pairs, two forced numeric divergences")


if __name__=="__main__": main()
