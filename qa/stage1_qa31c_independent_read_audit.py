#!/usr/bin/env python3
"""QA31C independent finite raw STEP, IO receipt, and adversarial audit.
No universal input-ownership or Stage1 certification is inferred.
"""
import copy, gzip, hashlib, json, sys
from pathlib import Path

SOURCE = "560d6aa5807a7f766213a33835cce85eab0fa40c"
ROUTES = {
 "valid00": (0, "782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a", 9607, 17387, 61, 176),
 "invalid18": (1, "9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd", 1455, 1672, 0, 115)
}
def need(ok,msg):
    if not ok: raise AssertionError(msg)
def sha(b):
    return hashlib.sha256(b).hexdigest()
def original(root,label):
    shard,digest,tick,steps,operand,x=ROUTES[label]
    folder=root/label
    b=(folder/"qa20_manifest.json").read_bytes()
    need(sha(b)==digest,"signed manifest hash mismatch")
    manifest=json.loads(b)
    need(manifest["source_git_blob"]==SOURCE and manifest["shard"]==shard
         and manifest["source_modified"] is False and manifest["ip_relocated"] is False
         and manifest["stage1_final_acceptance"] is False,"original Native signature invalid")
    found=[r for r in manifest["records"] if r["label"]==label]
    need(len(found)==1,"original route missing")
    rec=found[0]
    z=(folder/rec["path"]).read_bytes()
    need(sha(z)==rec["compressed_trace_sha256"] and len(z)==rec["compressed_bytes"],
         "original step gzip drift")
    lines=gzip.decompress(z).splitlines(keepends=True)
    need(len(lines)==steps==rec["steps"] and rec["expected"]==rec["output"],
         "signed full original Native result drift")
    need(list(map(int,lines[tick-1].strip().split(b"\t")))==[tick,114,38,1,0,106,0],
         "signed j STEP invalid")
    need(int(lines[tick].split(b"\t")[1])==x,"signed j physical successor invalid")
    return rec, b"".join(lines)

def check_case(r,root,folder,label,mode,baseline,alternative):
    _,_,tick,steps,operand,x=ROUTES[label]
    rec,signed=original(root,label)
    need(r["mode"]==mode and r["signed_route"]==label,"case identity")
    raw=baseline if mode=="sham" else alternative
    need(r["raw_input_sha256"]==sha(raw),"delivered input hash")
    need(r["step_count"]==steps and r["output"]==rec["output"],"signed Native output/count")
    path="qa31c_"+mode+".steps.gz"
    need(r["step_trace_file"]==path,"unexpected trace path")
    zipped=(folder/path).read_bytes()
    need(sha(zipped)==r["step_trace_sha256"],"recorded gzip digest mismatch")
    unpacked=gzip.decompress(zipped)
    need(sha(unpacked)==r["uncompressed_step_sha256"] and unpacked==signed,
         "complete physical Native STEP signature mismatch")
    j=r["j"]
    need(j["tick"]==tick and j["operand"]==operand and j["successor_x"]==x,
         "Native pre-j stack/j geometry receipt mismatch")
    pre,post=j["pre_toss"],j["post_toss"]
    need(isinstance(pre,list) and isinstance(post,list) and len(pre)<100000
         and all(type(n) is int for n in pre+post)
         and (pre[-1] if pre else 0)==operand and
         post==(pre[:-1] if pre else []),"real Native operand/pop mismatch")
    e=r["read_events"]
    need(isinstance(e,list) and len(e)>0 and len(e)<10000,"Native IO reads missing/unbounded")
    for event in e:
        start,end=event["start"],event["end"]
        need(type(start) is int and type(end) is int and 0<=start<=end<=len(baseline),
             "illegal Native read cursor interval")
        need(event["method"] in ("read","readline") and type(event["tick"]) is int
             and 1<=event["tick"]<=steps and
             isinstance(event["ip"],list) and len(event["ip"])==5 and
             all(type(z) is int for z in event["ip"]) and
             isinstance(event["toss_sha256"],str) and len(event["toss_sha256"])==64,
             "Native read metadata invalid")
        need(event["baseline_hex"]==baseline[start:end].hex()
             and event["delivered_hex"]==raw[start:end].hex(),
             "observed stdin bytes not consistent with declared splice")
        row=list(map(int,signed.splitlines()[event["tick"]-1].split(b"\t")))
        need(event["ip"][:4]==row[1:5] and event["ip"][4]==row[6],
             "read not anchored to signed physical Native IP")
    return e

def verify(r,source,root,folder):
    src=source.read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(src)).encode()+b"\0"+src).hexdigest()
    need(blob==SOURCE==r.get("source_git_blob"),"original source Git blob mismatch")
    need(r.get("schema")=="qa31c-original-native-stdin-splice-diagnostic-v1"
         and r.get("source_modified") is False and r.get("ip_relocated") is False
         and r.get("qa31c_accepted") is False and r.get("stage1_complete") is False
         and r.get("global_input_ownership_proven") is False,"scope/acceptance overclaim")
    valid,_=original(root,"valid00")
    invalid,_=original(root,"invalid18")
    baseline=valid["raw_input"].encode("ascii")
    alternative=invalid["raw_input"].encode("ascii")
    need(len(baseline)==len(alternative) and baseline!=alternative,"bad intervention corpus")
    first=next(i for i in range(len(baseline)) if baseline[i]!=alternative[i])
    need(first>=1 and r["shared_prefix_bytes"]==first
         and r["baseline_input_sha256"]==sha(baseline)
         and r["alternative_input_sha256"]==sha(alternative),"non-identical baseline")
    sham=check_case(r["sham"],root,folder,"valid00","sham",baseline,alternative)
    changed=check_case(r["splice"],root,folder,"invalid18","splice",baseline,alternative)
    ix=r["first_changed_read_index"]
    altered=[i for i,e in enumerate(changed) if e["baseline_hex"]!=e["delivered_hex"]]
    need(altered and type(ix) is int and ix==altered[0] and ix<len(sham),
         "no actual observed Native read intervention")
    need(r["first_changed_tick"]==changed[ix]["tick"],"intervention physical tick forged")
    for i in range(ix):
        need(sham[i]==changed[i],"IO prefixes diverge before controlled intervention")
    keys=("tick","method","start","end","ip","toss_sha256")
    need(all(sham[ix][k]==changed[ix][k] for k in keys),"pre-read state mismatch")
    need(any(baseline[z]!=alternative[z]
             for z in range(changed[ix]["start"],changed[ix]["end"])),
         "no changed input at first affected physical read")
    need(r["sham"]["j"]["operand"]==61 and r["splice"]["j"]["operand"]==0,
         "measured stack operand unaffected or forged")
    return len(sham)+len(changed)

def attacks(report,source,root,outdir):
    edits=[
      ("source",lambda r:r.__setitem__("source_git_blob","0"*40)),
      ("status",lambda r:r.__setitem__("stage1_complete",True)),
      ("input-hash",lambda r:r.__setitem__("alternative_input_sha256","0"*64)),
      ("prefix",lambda r:r.__setitem__("shared_prefix_bytes",7)),
      ("first-read-index",lambda r:r.__setitem__("first_changed_read_index",999)),
      ("first-read-tick",lambda r:r.__setitem__("first_changed_tick",999)),
      ("operand",lambda r:r["splice"]["j"].__setitem__("operand",61)),
      ("stack",lambda r:r["sham"]["j"]["pre_toss"].append(999)),
      ("trace-hash",lambda r:r["splice"].__setitem__("step_trace_sha256","0"*64)),
      ("read-byte",lambda r:r["splice"]["read_events"][r["first_changed_read_index"]].__setitem__("delivered_hex","00")),
      ("read-ip",lambda r:r["splice"]["read_events"][r["first_changed_read_index"]]["ip"].__setitem__(0,999)),
      ("read-state",lambda r:r["splice"]["read_events"][r["first_changed_read_index"]].__setitem__("toss_sha256","0"*64))
    ]
    for name,mutate in edits:
        fake=copy.deepcopy(report)
        mutate(fake)
        try:verify(fake,source,root,outdir)
        except (AssertionError,KeyError,IndexError,TypeError,ValueError):pass
        else:raise AssertionError("adversarial receipt was accepted: "+name)
    return len(edits)

def main(source,root,outdir):
    p=outdir/"qa31c_read_probe.json"
    report=json.loads(p.read_bytes())
    event_count=verify(report,source,root,outdir)
    count=attacks(report,source,root,outdir)
    need(count==12,"independent forgery corpus incomplete")
    evidence={"schema":"qa31c-independent-physical-native-audit-v1",
              "source_git_blob":SOURCE,"signed_full_native_steps":19059,
              "observed_stdin_read_events":event_count,
              "forgery_receipts_rejected":count,
              "qa31c_accepted":False,"stage1_complete":False}
    (outdir/"qa31c_independent.json").write_text(json.dumps(evidence,sort_keys=True,indent=2)+"\n")
    print("QA31C_INDEPENDENT_19059_FULL_NATIVE_STEPS")
    print("QA31C_INDEPENDENT_FORGERIES_REJECTED",count)
    print("QA31C_STAGE1_REMAINS_OPEN_PENDING_REVIEW")
if __name__=="__main__":
    need(len(sys.argv)==4,"usage: AUDITOR SOURCE QA20_ROOT OUTDIR")
    main(Path(sys.argv[1]),Path(sys.argv[2]),Path(sys.argv[3]))
