#!/usr/bin/env python3
"""QA31AJ inverse oracle from source predicates; imports no forward-model code."""
import argparse,copy,hashlib,json
from pathlib import Path
SHA="560d6aa5807a7f766213a33835cce85eab0fa40c"
WS={9,10,13,32}
def req(ok,msg):
    if not ok:raise AssertionError(msg)
def source(raw):
    req(hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==SHA,"SHA")
    rows=raw.splitlines();req(len(rows)==2015 and rows[49]==b"","geometry")
    pins={(57,8):103,(151,8):103,(185,8):106,(113,11):106,(89,20):106,(113,23):106,(248,26):112,(344,26):112,(113,32):106}
    for (x,y),op in pins.items():req(rows[y][x]==op,f"pin {(x,y)}")
    return len(pins)
def verify(v):
    req(v["schema"]=="qa31aj-finite-q4-cycle-v1" and v["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ","identity")
    req(v["source_blob"]==SHA and v["site_pins"]==16,"source")
    req(v["byte_cases"]==256 and v["per_segment_step_bound"]==549,"bounds")
    b=v["boundary"]
    req((b["row23_next"],b["row26_next"],b["q_after"],b["m_after"])==([10,26],[10,5],4,0),"row26 postcondition")
    req([248,26] in b["row26_write_sites"] and [344,26] in b["row26_write_sites"],"writers")
    req(b["row35_next"]==[10,38] and b["row35_q_after"]==4,"row35 alternate")
    req(v["counts"]=={"digits":10,"whitespace":4,"other":242},"counts")
    req(len(v["cases"])==256,"cases count")
    for byte,case in enumerate(v["cases"]):
        if 48<=byte<=57:path,end,kind=[5,8,11],44,"digits"
        elif byte in WS:path,end,kind=[5,8,17,20],5,"whitespace"
        else:path,end,kind=[5,8,17],44,"other"
        req(case=={"byte":byte,"path":path,"exit":end,"kind":kind,"q":4,"m":0},f"byte {byte}")
    req(v["forward_controls"]==8,"controls")
    req(v["source_only"] is True and v["original_native_replayed"] is False and v["new_native_runs"]==0,"Native claim")
    req(v["canonical_q4_m0_candidate"] is False and v["global_reachability_proven"] is False and v["stage1_pass"] is False,"global claim")
    return 256
def adversarial(v):
    edits=[
      lambda x:x["boundary"].__setitem__("q_after",3),
      lambda x:x["boundary"].__setitem__("m_after",1),
      lambda x:x["boundary"].__setitem__("row26_next",[10,29]),
      lambda x:x["boundary"].__setitem__("row35_next",[10,32]),
      lambda x:x["cases"][48].__setitem__("path",[5,8,17]),
      lambda x:x["cases"][32].__setitem__("exit",23),
      lambda x:x["cases"][9].__setitem__("kind","digits"),
      lambda x:x["cases"][255].__setitem__("m",1),
      lambda x:x["counts"].__setitem__("other",241),
      lambda x:x.__setitem__("new_native_runs",1),
      lambda x:x.__setitem__("canonical_q4_m0_candidate",True),
      lambda x:x.__setitem__("stage1_pass",True)]
    n=0
    for i,f in enumerate(edits):
        z=copy.deepcopy(v);f(z)
        try:verify(z)
        except (AssertionError,KeyError,TypeError):n+=1
        else:raise AssertionError(f"hostile {i} accepted")
    req(n==12,"hostile count")
    return n
def main():
    p=argparse.ArgumentParser()
    for x in ("source","forward","out"):p.add_argument("--"+x,required=True)
    a=p.parse_args();pins=source(Path(a.source).read_bytes())
    v=json.loads(Path(a.forward).read_text(encoding="utf-8"))
    cases=verify(v);n=adversarial(v)
    result={"schema":"qa31aj-inverse-v1","source_blob":SHA,"source_pins":pins,"bytes_verified":cases,"hostile_rejected":n,"new_native_runs":0,"stage1_pass":False}
    Path(a.out).write_text(json.dumps(result,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("QA31AJ_INVERSE_PASS",cases,"bytes",n,"hostile rejected")
if __name__=="__main__":main()
