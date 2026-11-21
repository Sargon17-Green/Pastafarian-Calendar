#!/usr/bin/env python3
"""Independent fail-closed replay of BF98 512 Native binary suffix records."""
import copy,json,sys
from pathlib import Path
PIN="c5bd9dd06e227f9f31c8988a51bd114bf67b9af7"
CONTROL=(0,10,13,32,65,127,128,255)
def require(cond,msg):
    if not cond:raise AssertionError(msg)
def base():
    t=["0","100","0","0","9"]
    for g in range(9):t+=["0",str(g*42)]
    return " ".join(t+["1"]).encode("ascii")
def verify(doc):
    require(type(doc) is dict and
            doc.get("schema")=="befunge-stage1-raw-eof-binary-512-v1" and
            doc.get("source_git_blob")==PIN and
            doc.get("scope")=="TEST_ONLY_BINARY_FIRST_SUFFIX_NOT_PRODUCTION_STAGE1_OPEN" and
            doc.get("stage1_complete") is False and
            doc.get("full_functional_acceptance") is False and
            doc.get("geometric_acceptance") is False and
            type(doc.get("last_completed_stage")) is int and
            doc["last_completed_stage"]==0,
            "source or stage acceptance forgery")
    rows=doc.get("records")
    require(type(rows) is list and len(rows)==512 and
            type(doc.get("native_case_count")) is int and
            doc["native_case_count"]==512,"Native 512 binary rows missing")
    prefix=base()
    for octet in range(256):
        for suffix_idx,variant in enumerate(("after_lf","extra_raw_field")):
            idx=2*octet+suffix_idx
            row=rows[idx]
            given=(prefix+b"\n"+bytes([octet]) if variant=="after_lf"
                   else prefix+b" "+bytes([octet]))
            want=[1] if variant=="extra_raw_field" and octet in (9,10,32) else [-1]
            require(type(row) is dict and
                    type(row.get("octet")) is int and row["octet"]==octet and
                    row.get("variant")==variant and
                    row.get("raw_hex")==given.hex() and
                    row.get("expected")==want and
                    row.get("native_output")==want and
                    type(row.get("native_return_code")) is int and
                    row["native_return_code"]==0 and
                    (row.get("unguarded_native_output")==[1]
                     if variant=="after_lf" and octet in CONTROL else
                     "unguarded_native_output" not in row),
                    "falsified Native binary proof: %d %s"%(octet,variant))
    return len(rows)
def main(directory):
    root=Path(directory)
    doc=json.loads((root/"native_year5000_512_raw_binary.json").read_text("utf-8"))
    count=verify(doc)
    attacks=[
        ("scope",lambda z:z.__setitem__("scope","PRODUCTION_COMPLETE")),
        ("source",lambda z:z.__setitem__("source_git_blob","0"*40)),
        ("stage",lambda z:z.__setitem__("last_completed_stage",1)),
        ("final",lambda z:z.__setitem__("stage1_complete",True)),
        ("functional",lambda z:z.__setitem__("full_functional_acceptance",True)),
        ("geometry",lambda z:z.__setitem__("geometric_acceptance",True)),
        ("count",lambda z:z.__setitem__("native_case_count",511)),
        ("missing",lambda z:z["records"].pop()),
        ("reverse",lambda z:z["records"].reverse()),
        ("nul_bypass",lambda z:z["records"][0].__setitem__("native_output",[1])),
        ("high_byte_bypass",lambda z:z["records"][-2].__setitem__("native_output",[1])),
        ("tab_rejected",lambda z:z["records"][19].__setitem__("native_output",[-1])),
        ("suffix_launder",lambda z:z["records"][3].__setitem__("raw_hex","00")),
        ("return_code",lambda z:z["records"][0].__setitem__("native_return_code",1)),
        ("unguarded_hidden",lambda z:z["records"][0].__setitem__(
            "unguarded_native_output",[-1])),
    ]
    rejected=[]
    for name,change in attacks:
        x=copy.deepcopy(doc);change(x)
        try:verify(x)
        except AssertionError:rejected.append(name)
        else:raise AssertionError("accepted forged binary report "+name)
    evidence={"schema":"befunge-stage1-raw-eof-binary-512-audit-v1",
              "native_records":count,"hostile_reports_rejected":rejected,
              "stage1_complete":False,"last_completed_stage":0}
    (root/"native_year5000_512_raw_binary_audit.json").write_text(
        json.dumps(evidence,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_RAW_EOF_BINARY_512_AND_15_TAMPER_AUDIT_PASS")
if __name__=="__main__":
    require(len(sys.argv)==2,"expected evidence folder")
    main(sys.argv[1])
