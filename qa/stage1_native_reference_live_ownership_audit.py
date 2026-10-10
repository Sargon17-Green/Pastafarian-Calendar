#!/usr/bin/env python3
"""Independent evidence audit, six Native Stage-1 reference Befunge programs."""
import copy
import hashlib
import json
import sys
from pathlib import Path

PINS={
"reference/count_bounded_compositions.b98":"90c0c45205cc6efca418367f02b6ee3116bcb2d7",
"reference/unrank_bounded_composition.b98":"f6ebb3980d3eecb4e159e42b2a01499323257dc6",
"reference/count_weavings.b98":"d57ef8da12e7cae7e62153407214f9f903eca280",
"reference/unrank_weaving.b98":"a48359619ab5391b156e6eefdd6d36a5e500611a",
"reference/year5000_from_gates_rank.b98":"c70f15354979aafdd0ea0c83045ef2a54dd996f9"
}
PAIRS=[("bc","wc"),("bu","wu"),("y0","wc"),
       ("y1","bu"),("y0","y1"),("bc","bu")]
PROFILES=["AB_1_1","BA_3_7"]
LABELS={"bc","bu","wc","wu","y0","y1"}

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def verify(data):
    need(data.get("schema")=="befunge-stage1-native-reference-live-owner-v1"
         and data.get("status")=="QA_ONLY_STAGE1_OPEN"
         and data.get("pairs")==12 and data.get("programs")==24
         and data.get("native_cli_baselines")==6
         and data.get("profiles")==PROFILES
         and data.get("source_blobs")==PINS
         and data.get("stage1_final_acceptance") is False,
         "native reference corpus or acceptance claim changed")
    refs=data.get("expected_by_label")
    need(isinstance(refs,dict) and set(refs)==LABELS,
         "native reference vector labels missing")
    need(refs["bc"]==["4"] and refs["wc"]==["26"]
         and refs["y0"]==["0","5000","0","6","0","252"]
         and refs["y1"]==["0","5000","0","6","1000","1252"],
         "known native structural/year5000 witness changed")
    need(len(refs["bu"])==2 and len(refs["wu"])==8
         and refs["wu"].count("1")==3 and refs["wu"].count("2")==3
         and refs["wu"].count("3")==2,
         "native structural unrank output malformed")
    rows=data.get("records")
    need(isinstance(rows,list) and len(rows)==12,
         "12 native live-program pair records missing")
    signatures={}
    total={"pairs":12,"programs":24,"steps":0,"reads":0,"writes":0,
           "overlap":0,"peer_snapshots":0}
    for ix,row in enumerate(rows):
        left,right=PAIRS[ix%6]
        need(row.get("left")==left and row.get("right")==right
             and row.get("schedule")==PROFILES[ix//6]
             and row.get("left_output")==refs[left]
             and row.get("right_output")==refs[right]
             and row.get("separate_programs_and_spaces") is True
             and row.get("all_space_apis_owned") is True
             and row.get("outputs_reference_equal") is True
             and row.get("terminated") is True,
             "native reference output, peer or ordered schedule changed")
        for col in ("left_steps","right_steps","left_get","right_get",
                    "left_put","right_put","left_putspace","right_putspace",
                    "overlap_rounds","peer_state_checks"):
            need(type(row.get(col)) is int and row[col]>=0,
                 "invalid native reference step/space value "+col)
        need(0<row["left_steps"]<=180000
             and 0<row["right_steps"]<=180000
             and row["left_get"]>0 and row["right_get"]>0
             and row["left_putspace"]==row["right_putspace"]==0
             and row["overlap_rounds"]>0 and row["peer_state_checks"]>=2,
             "native reference Funge-space ownership evidence incomplete")
        for side,label in (("left",left),("right",right)):
            sig=(row[side+"_steps"],row[side+"_get"],row[side+"_put"],
                 tuple(row[side+"_output"]))
            if label in signatures:
                need(signatures[label]==sig,
                     "same reference input varies by concurrent peer/schedule")
            else:signatures[label]=sig
            for field,col in (("steps","steps"),("reads","get"),("writes","put")):
                total[field]+=row[side+"_"+col]
        total["overlap"]+=row["overlap_rounds"]
        total["peer_snapshots"]+=row["peer_state_checks"]
    need(set(signatures)==LABELS,"not all six reference domains audited")
    return total

def main(folder):
    for path,pin in PINS.items():
        b=Path(path).read_bytes()
        sha=hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+
                         b"\0"+b).hexdigest()
        need(sha==pin,"source blob drift: "+path)
    data=json.loads((Path(folder)/"native_reference_live_ownership.json")
                    .read_text(encoding="utf-8"))
    result=verify(data)
    print("NATIVE_REFERENCE_OWNER_12_PAIR_INDEPENDENT_AUDIT_PASS",result)
    def reject(label,mutation):
        forged=copy.deepcopy(data)
        mutation(forged)
        try:verify(forged)
        except AssertionError:
            print("NATIVE_REFERENCE_OWNER_TAMPER_REJECT_PASS",label)
            return label
        raise AssertionError("forged reference ownership artifact accepted: "+label)
    rejected=[
        reject("source_pin",lambda x:x["source_blobs"].__setitem__(
            "reference/count_weavings.b98","0"*40)),
        reject("missing_pair",lambda x:x["records"].pop()),
        reject("pair_identity",lambda x:x["records"][0].__setitem__("right","bu")),
        reject("schedule_order",lambda x:x["records"][6].__setitem__("schedule","AB_1_1")),
        reject("year5000",lambda x:x["expected_by_label"]["y0"].__setitem__(1,"4999")),
        reject("weaving",lambda x:x["expected_by_label"]["wu"].__setitem__(0,"9")),
        reject("wrong_output",lambda x:x["records"][0]["left_output"].__setitem__(0,"10")),
        reject("shared_space",lambda x:x["records"][0].__setitem__("separate_programs_and_spaces",False)),
        reject("unowned_memory",lambda x:x["records"][0].__setitem__("all_space_apis_owned",False)),
        reject("putspace",lambda x:x["records"][0].__setitem__("left_putspace",1)),
        reject("read_schedule_drift",lambda x:x["records"][6].__setitem__("left_get",x["records"][6]["left_get"]+1)),
        reject("false_completion",lambda x:x.__setitem__("stage1_final_acceptance",True)),
    ]
    need(len(rejected)==12,"native reference negative controls incomplete")
    target=Path(folder)/"native_reference_live_ownership_audit.json"
    target.write_text(json.dumps({"schema":"befunge-stage1-reference-owner-audit-v1",
        "verified":result,"negative_reports_rejected":rejected,
        "stage1_final_acceptance":False},sort_keys=True,indent=2)+"\n",
        encoding="utf-8")
    print("NATIVE_REFERENCE_OWNER_12_HOSTILE_REPORTS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: native-reference-evidence-directory")
    main(sys.argv[1])
