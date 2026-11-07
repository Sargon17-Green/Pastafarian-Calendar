#!/usr/bin/env python3
"""QA31D independent signed Native full-trace and hostile-receipt audit.
No global or Stage 1 certification. Do not infer causal variation if absent.
"""
import copy, gzip, hashlib, json, sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES={
 "valid00":(0,"782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a","0 0 0 0\n"),
 "valid01":(1,"9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd","0 0 0 1\n")
}
def need(cond,msg):
    if not cond: raise AssertionError(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def orig(root,label):
    shard,digest,raw=CASES[label]
    folder=root/label
    b=(folder/"qa20_manifest.json").read_bytes()
    need(sha(b)==digest,"signed manifest digest drift")
    m=json.loads(b)
    need(m["schema"]=="qa20-native-natural-route-21-controls-v1" and
         m["source_git_blob"]==PIN and m["shard"]==shard and
         m["source_modified"] is False and m["ip_relocated"] is False and
         m["stage1_final_acceptance"] is False,"original manifest invalid")
    rs=[r for r in m["records"] if r["label"]==label]
    need(len(rs)==1,"original route absent")
    r=rs[0]
    need(r["raw_input"]==raw and r["valid"] is True and
         r["natural_ip_no_intervention"] is True and
         r["output"]==r["expected"] and len(r["output"])==7,
         "original Native route output/identity drift")
    z=(folder/r["path"]).read_bytes()
    need(len(z)==r["compressed_bytes"] and sha(z)==r["compressed_trace_sha256"],
         "signed original STEP hash drift")
    lines=gzip.decompress(z).splitlines()
    need(len(lines)==r["steps"],"signed physical STEP count drift")
    return r,lines

def validate_row(row,label,root,out):
    r,original=orig(root,label)
    need(row["label"]==label and row["shard"]==CASES[label][0] and
         row["input_sha256"]==sha(CASES[label][2].encode()) and
         row["original_trace_sha256"]==r["compressed_trace_sha256"] and
         row["steps"]==r["steps"] and row["output"]==r["output"],
         "original evidence identity drift")
    fname="qa31d_"+label+".steps.gz"
    need(row["step_trace_file"]==fname,"trace basename drift")
    z=(out/fname).read_bytes()
    need(sha(z)==row["step_trace_sha256"],"generated trace digest drift")
    rows=gzip.decompress(z).splitlines()
    need(rows==original,"every physical Native step must match signed source")
    jumps=[]
    for tick,line in enumerate(rows,1):
        fields=list(map(int,line.split(b"\t")))
        need(len(fields)==7 and fields[0]==tick,"not seven complete STEP fields")
        if fields[1:]==[114,38,1,0,106,0]:
            need(tick<len(rows),"targeted j lacks signed successor")
            jumps.append((tick,fields,list(map(int,rows[tick].split(b"\t")))))
    js=row["j_observations"]
    need(type(js) is list and len(js)==len(jumps),"missing or extra pre-j witness")
    for w,(tick,pre,post) in zip(js,jumps):
        stack=w["pre_toss"];after=w["post_toss"]
        need(w["tick"]==tick and w["pre_step"]==pre and w["next_step"]==post and
             type(stack) is list and type(after) is list and
             len(stack)<100000 and all(type(v) is int for v in stack+after) and
             after==(stack[:-1] if stack else []) and
             type(w["stack_stack_depth"]) is int and 1<=w["stack_stack_depth"]<100 and
             w["operand"]==(stack[-1] if stack else 0) and
             post[1]==114+w["operand"]+1,
             "j hidden-stack receipt inconsistent with signed jump")
    events=row["read_events"]
    need(type(events) is list and events,"original real read events missing")
    baseline=CASES["valid00"][2].encode()
    alternative=CASES[label][2].encode()
    for e in events:
        need(e["method"] in ("read","readline") and
             type(e["tick"]) is int and 1<=e["tick"]<=r["steps"] and
             type(e["start"]) is int and type(e["end"]) is int and
             0<=e["start"]<=e["end"]<=len(baseline) and
             bytes.fromhex(e["baseline_hex"])==baseline[e["start"]:e["end"]] and
             bytes.fromhex(e["delivered_hex"])==alternative[e["start"]:e["end"]] and
             len(e["ip"])==5 and len(e["toss_sha256"])==64,
             "read-return or cursor provenance invalid")

def verify(report,root,out):
    need(report["schema"]=="qa31d-finite-valid-pair-original-native-pre-j-v1" and
         report["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ" and
         report["source_git_blob"]==PIN and
         report["source_modified"] is False and report["ip_relocated"] is False and
         report["initial_buffer_sha256"]==sha(CASES["valid00"][2].encode()) and
         report["same_pre_read_state"] is True and
         report["scope"]=="finite-equal-length-valid-pair-only" and
         report["stage1_complete"] is False and
         report["global_input_ownership_proven"] is False,
         "unsupported origin or global acceptance")
    a,b=report["records"]
    validate_row(a,"valid00",root,out)
    validate_row(b,"valid01",root,out)
    x=a["read_events"];y=b["read_events"]
    changed=[i for i,e in enumerate(y) if e["baseline_hex"]!=e["delivered_hex"]]
    need(changed and report["first_changed_read_index"]==changed[0] and
         changed[0]<len(x),"changed Native read absent")
    first=changed[0]
    keys=("tick","method","start","end","ip","toss_sha256")
    need(all(x[first][k]==y[first][k] for k in keys) and
         all(x[i]==y[i] for i in range(first)) and
         x[first]["baseline_hex"]==x[first]["delivered_hex"] and
         y[first]["baseline_hex"]==x[first]["baseline_hex"],
         "pre-read Native state not identical")
    aj=a["j_observations"];bj=b["j_observations"]
    both=bool(aj and bj)
    diff=bool(both and [x["operand"] for x in aj]!=[x["operand"] for x in bj])
    need(report["both_routes_reach_target_j"] is both and
         report["pre_j_operand_difference_observed"] is diff,
         "falsely asserted pre-j causal difference")
    return sum(row["steps"] for row in (a,b)), len(aj),len(bj),diff

def main(source,root,out):
    b=Path(source).read_bytes()
    need(hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()==PIN,
         "original Befunge production blob drift")
    root,out=Path(root),Path(out)
    report=json.loads((out/"qa31d_native.json").read_bytes())
    steps,ja,jb,diff=verify(report,root,out)
    adversarial=[
        ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        ("stage",lambda d:d.__setitem__("stage1_complete",True)),
        ("scope",lambda d:d.__setitem__("scope","global")),
        ("result",lambda d:d.__setitem__("pre_j_operand_difference_observed",not diff)),
        ("read",lambda d:d["records"][1]["read_events"][0].__setitem__("ip",[0,0,0,0,0])),
        ("stdin",lambda d:d["records"][1]["read_events"][0].__setitem__("delivered_hex","00")),
        ("operand",lambda d:d["records"][0]["j_observations"][0].__setitem__("operand",999) if ja else d["records"][0].__setitem__("j_observations",[{"tick":1}])),
        ("trace",lambda d:d["records"][0].__setitem__("step_trace_sha256","0"*64)),
        ("identity",lambda d:d["records"][0].__setitem__("label","valid01")),
        ("input",lambda d:d["records"][1].__setitem__("input_sha256","0"*64))]
    for name,mutate in adversarial:
        fake=copy.deepcopy(report)
        mutate(fake)
        try: verify(fake,root,out)
        except (AssertionError,KeyError,IndexError,ValueError,TypeError): pass
        else: raise AssertionError("hostile evidence accepted "+name)
    result={"schema":"qa31d-independent-valid-pair-audit-v1","steps":steps,
            "j_visits":[ja,jb],"pre_j_operand_difference_observed":diff,
            "hostile_receipts_rejected":len(adversarial),
            "stage1_complete":False}
    (out/"qa31d_independent.json").write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("QA31D_INDEPENDENT_SIGNED_NATIVE_STEPS",steps)
    print("QA31D_INDEPENDENT_HOSTILE_REJECTIONS",len(adversarial))
    print("QA31D_FINITE_PRE_J_VARIATION",diff)
    print("QA31D_STAGE1_OPEN")
if __name__=="__main__":
    need(len(sys.argv)==4,"usage: QA31D_AUDIT SOURCE ROOT OUTPUT")
    main(*sys.argv[1:])
