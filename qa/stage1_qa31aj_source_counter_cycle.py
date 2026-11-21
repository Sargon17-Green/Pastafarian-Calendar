#!/usr/bin/env python3
"""QA31AJ finite source-only q4 counter-cycle model; not Native or global proof."""
import argparse, hashlib, json
from pathlib import Path
BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
PINS={(13,5):"~",(57,8):"g",(151,8):"g",(185,8):"j",(57,11):"g",(113,11):"j",(235,11):"x",(57,20):"g",(89,20):"j",(113,23):"j",(248,26):"p",(344,26):"p",(57,29):"g",(89,29):"j",(113,32):"j",(248,35):"p"}
WS={9,10,13,32}
def insist(v,msg):
    if not v: raise AssertionError(msg)
def source(raw):
    digest=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    insist(digest==BLOB,"original source SHA")
    rows=raw.splitlines()
    insist(len(rows)==2015 and rows[49]==b"","source geometry")
    for (x,y),op in PINS.items(): insist(rows[y][x]==ord(op),f"pin {(x,y)}")
    return rows
def state(q=4,m=0):
    return {(0,49):32,(1,49):q,(2,49):0,(3,49):m,(4,49):0}
def segment(rows,y0,mem,byte=None):
    x,y,dx,dy=10,y0,1,0
    stack=[];writes=[]
    def pop(): return stack.pop() if stack else 0
    def cell(cx,cy):
        return rows[cy][cx] if 0<=cy<len(rows) and 0<=cx<len(rows[cy]) else 32
    for t in range(1,550):
        insist(0<=y<len(rows) and 0<=x<len(rows[y]),"source bound")
        op=chr(rows[y][x])
        if op in "0123456789abcdef": stack.append(int(op,16))
        elif op in "+-*" or op==chr(96):
            b,a=pop(),pop()
            stack.append(a+b if op=="+" else a-b if op=="-" else a*b if op=="*" else int(a>b))
        elif op=="!": stack.append(int(pop()==0))
        elif op=="g":
            yy,xx=pop(),pop();stack.append(mem.get((xx,yy),cell(xx,yy)))
        elif op=="p":
            yy,xx,v=pop(),pop(),pop()
            mem[xx,yy]=v;writes.append([x,y,xx,yy,v])
        elif op=="j":
            n=pop();x+=n*dx;y+=n*dy
        elif op=="x":dy,dx=pop(),pop()
        elif op==">":dx,dy=1,0
        elif op=="#":x+=dx;y+=dy
        elif op=="~":
            insist(y0==5 and byte is not None and 0<=byte<=255,"no physical negative or EOF return")
            stack.append(byte)
        elif op!=" ":raise AssertionError(f"unsupported opcode {op} at {(x,y)}")
        x+=dx;y+=dy
        if y!=y0:return {"next":[x,y],"ticks":t,"writes":writes}
    raise AssertionError("549 STEP segment limit")
def boundary(rows):
    s=state(3,1)
    a=segment(rows,23,s);insist(a["next"]==[10,26],"row23")
    b=segment(rows,26,s)
    insist(b["next"]==[10,5],"row26 exit")
    insist((s[1,49],s[2,49],s[3,49])==(4,0,0),"row26 q4,m0")
    insist([w for w in b["writes"] if w[:2]==[248,26]]==[[248,26,1,49,4]],"p248")
    insist([w for w in b["writes"] if w[:2]==[344,26]]==[[344,26,3,49,0]],"p344")
    t=state(3,1);alt=segment(rows,35,t)
    insist(alt["next"]==[10,38] and t[1,49]==4,"row35")
    return {"row23_next":a["next"],"row26_next":b["next"],"q_after":4,"m_after":0,"row35_next":alt["next"],"row35_q_after":4,"row26_write_sites":[w[:2] for w in b["writes"]]}
def exhaustive(rows):
    cases=[];counts={"digits":0,"whitespace":0,"other":0}
    for byte in range(256):
        mem=state();row=5;path=[]
        for _ in range(6):
            path.append(row)
            z=segment(rows,row,mem,byte if row==5 else None)
            insist(z["next"][0]==10,"entry x")
            row=z["next"][1]
            if row in (5,23,32,44):break
        else:raise AssertionError("row bound")
        kind="digits" if 48<=byte<=57 else "whitespace" if byte in WS else "other"
        counts[kind]+=1
        insist(row==(5 if kind=="whitespace" else 44),"classified route")
        insist((mem[1,49],mem[3,49])==(4,0),"q,m altered")
        cases.append({"byte":byte,"path":path,"exit":row,"kind":kind,"q":4,"m":0})
    insist(counts=={"digits":10,"whitespace":4,"other":242},"population")
    return cases,counts
def controls(rows):
    rejected=0
    for x,y in [(13,5),(185,8),(113,11),(89,20),(248,26),(344,26)]:
        z=[bytearray(v) for v in rows];z[y][x]=32
        try:insist(all(z[yy][xx]==ord(op) for (xx,yy),op in PINS.items()),"pin changed")
        except AssertionError:rejected+=1
        else:raise AssertionError("source mutation escaped")
    insist(segment(rows,11,state(3,0))["next"]==[10,14],"q premise")
    insist(segment(rows,20,state(4,1))["next"]==[10,23],"m premise")
    rejected+=2
    insist(rejected==8,"control total")
    return rejected
def main():
    p=argparse.ArgumentParser();p.add_argument("--source",required=True);p.add_argument("--out",required=True)
    args=p.parse_args();rows=source(Path(args.source).read_bytes())
    b=boundary(rows);cases,count=exhaustive(rows);n=controls(rows)
    out={"schema":"qa31aj-finite-q4-cycle-v1","project_id":"PC-BRANCH-BEFUNGE98-KYRGYZ","source_blob":BLOB,"site_pins":16,"byte_cases":256,"per_segment_step_bound":549,"boundary":b,"counts":count,"cases":cases,"forward_controls":n,"source_only":True,"original_native_replayed":False,"new_native_runs":0,"canonical_q4_m0_candidate":False,"global_reachability_proven":False,"stage1_pass":False}
    Path(args.out).write_text(json.dumps(out,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("QA31AJ_SOURCE_FINITE_PASS",count,"8 forward controls; no Native")
if __name__=="__main__":main()
