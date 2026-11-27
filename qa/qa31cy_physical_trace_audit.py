#!/usr/bin/env python3
"""Independent finite replay of QA31CY physical trace; no import of collector/runtime.
Checks every fetched opcode against original bytes or last physical write, every
p/g operand and result, separate synthetic writes, trace digests and gate edges.
Does not claim full instruction-set semantic replay or global ownership."""
import gzip, hashlib, json, pathlib, sys
SOURCE_PIN="7418e1ec5fe88fe5c14b75710dea2d5607527f28"
GATE=(1020,1046)
ENTER=(959,1050)
JOIN=(961,1050)
CASES={
 "same_positive": ((0,909909,0,808808),[17,0,1700,17000,0,1700000],
 "31931161 31728959 101102 63660120 1 909909 808808",
 "28531127 28328925 101102 56860052 1 909909 808808"),
 "same_negative": ((1,909909,1,808808),[-17,0,-1700,-17000,0,-1700000],
 "28291525 28493727 101102 56785252 3 170141183460469231731687303715883195818 170141183460469231731687303715883296919",
 "31691559 31893761 101102 63585320 3 170141183460469231731687303715883195818 170141183460469231731687303715883296919")}
def need(ok,msg):
    if not ok: raise AssertionError(msg)
def load(p): return json.loads(p.read_text())
def replay(source, path, receipt, selected, increments):
    rows=source.splitlines()
    def initial(xy):
        x,y=xy
        return rows[y][x] if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32
    values={}; owners={}; writes=reads=0
    def value(xy): return values.get(xy,initial(xy))
    digest=hashlib.sha256(); legacy=hashlib.sha256()
    steps=0; gates=[]; pending=None; total=0; stage=None; last=None
    with gzip.open(path,"rb") as f:
        for line in f:
            digest.update(line); r=json.loads(line); steps+=1
            need(steps==r["tick"] and steps<=300000,"tick sequence")
            xy=tuple(r["pos"]); dx,dy=r["delta"]; raw=r["raw"]; actual=r["actual"]
            stack=r["stack"]; off=r["offset"]; string=r["string"]
            need(raw==value(xy),"fetch/last writer mismatch at "+str(steps))
            legacy.update(("%d,%d,%d,%d,%d\n"%(*xy,dx,dy,raw)).encode())
            if pending is not None:
                need(xy==pending and actual in (43,45),"gate successor")
                pending=None
            if xy==ENTER:
                need(stage is None and len(gates)<6 and stack==[total,increments[len(gates)]],"ENTER")
                stage={"enter":steps,"prior":total,"inc":increments[len(gates)]}
            if r["synthetic"]:
                need(stage is not None and owners.get(GATE)==("p",stage.get("write")),"forced last physical writer")
                need(xy==GATE and len(gates) in selected and actual=={62:118,118:62}.get(raw),"synthetic opcode")
                values[xy]=actual; owners[xy]=("synthetic",steps)
            else: need(actual==raw,"unaccounted opcode change")
            pg=r["pg"]
            if not string and actual in (112,103):
                n=3 if actual==112 else 2
                operands=[0]*max(0,n-len(stack))+stack[-n:]
                target=(operands[-2]+off[0],operands[-1]+off[1])
                need(pg is not None and tuple(pg["xy"])==target and pg["before"]==value(target),"p/g address or before")
                if actual==112:
                    need(pg["value"]==pg["after"]==operands[0],"p write value")
                    values[target]=operands[0]; owners[target]=("p",steps); writes+=1
                    need(r["post_stack"]==stack[:-3],"p post stack")
                    if target==GATE and stage is not None:
                        need("write" not in stage,"duplicate gate write")
                        stage["write"]=steps
                else:
                    need(pg["value"] is None and pg["after"]==value(target),"g read")
                    need(r["post_stack"]==stack[:-2]+[pg["after"]],"g post stack")
                    reads+=1
            else: need(pg is None,"unexpected p/g")
            if xy==GATE:
                need(stage is not None and "write" in stage and "fetch" not in stage,"gate order")
                idx=len(gates); inc=stage["inc"]
                need(raw==(118 if inc<0 else 62) and stack==[total,abs(inc)],"gate prestate")
                need(r["synthetic"]==(idx in selected),"forced set")
                # Last physical write is recorded by the replay, not by summary.
                # At forced fetch the synthetic owner replaces the natural owner.
                if idx not in selected: need(owners.get(GATE)==("p",stage["write"]),"gate owner")
                stage["fetch"]=steps; stage["actual"]=actual
                pending=(1021,1046) if actual==62 else (1020,1047)
            elif xy in ((1021,1046),(1020,1047)):
                need(stage is not None and "fetch" in stage and "arm" not in stage and
                     steps==stage["fetch"]+1 and actual==(43 if stage["actual"]==62 else 45),"arm")
                stage["arm"]=steps
            elif xy==JOIN and stage is not None and "arm" in stage:
                idx=len(gates); total+=(-1 if idx in selected else 1)*stage["inc"]
                need(stack==[total,5],"JOIN")
                stage["join"]=steps; gates.append(stage); stage=None
            last=r
    need(last is not None and last["actual"]==64 and not last["string"],"terminal halt")
    need(steps==receipt["ticks"] and digest.hexdigest()==receipt["actual_trace_sha256"] and legacy.hexdigest()==receipt["route_sha256"],"digest/length")
    need(len(gates)==6 and stage is None and pending is None,"crossing count")
    for a,b in zip(gates,receipt["crossings"]):
        need(all(a[k]==b[k+"_tick"] for k in ("enter","write","fetch","arm","join")),"summary crossing mismatch")
    return {"steps":steps,"p":writes,"g":reads,"crossings":len(gates),"trace_sha256":digest.hexdigest()}
def main():
    src=pathlib.Path(sys.argv[1]).read_bytes(); root=pathlib.Path(sys.argv[2])
    need(hashlib.sha1(("blob %d\0"%len(src)).encode()+src).hexdigest()==SOURCE_PIN,"source pin")
    report=load(root/"qa31cy_receipt.json")
    need(report["status"]=="PASS" and report["reference_invocations"]==8,"collector status")
    results={}
    for label,(fields,inc,h,f) in CASES.items():
        for tag,expected,selected in ((label+".healthy",h,[]),(label+".mask_33",f,[0,5])):
            rec=load(root/(tag+".candidate.json")); req=load(root/(tag+".request.json"))
            need(req["fields"]==list(fields) and req["increments"]==inc and req["forced_indices"]==selected,"request identity")
            need(rec["output"]==expected.split() and rec["raw_output"].split()==expected.split(),"seven fields")
            reference=load(root/(tag+".reference.json"))
            need(reference["output"]==expected.split(),"native reference parity")
            results[tag]=replay(src,root/(tag+".candidate.json.steps.jsonl.gz"),rec,selected,inc)
    need(sum(x["crossings"] for x in results.values())==24,"aggregate")
    print(json.dumps({"status":"PASS","scope":"finite physical p/g and gate provenance","stage1_complete":False,"results":results},sort_keys=True))
if __name__=="__main__": main()
