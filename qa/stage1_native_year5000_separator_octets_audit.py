#!/usr/bin/env python3
"""Independent, fail-closed 1536-case BF98 separator audit and tamper controls."""
import copy,json,sys
from pathlib import Path
PIN="c5bd9dd06e227f9f31c8988a51bd114bf67b9af7"
GAPS=(("after_day_sign",0),("after_gate_count",4),("before_rank",22))
ENDINGS=("raw_eof","final_lf")
def need(ok,why):
    if not ok:raise AssertionError(why)
def fields():
    seq=["0","100","0","0","9"]
    for gate in range(9):seq.extend(["0",str(gate*42)])
    return seq+["1"]
def verify(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-native-separator-octets-1536-v1" and
         doc.get("source_git_blob")==PIN and
         doc.get("scope")=="THREE_TOKEN_GAPS_NATIVE_BINARY_TEST_ONLY_STAGE1_OPEN" and
         type(doc.get("last_completed_stage")) is int and
         doc["last_completed_stage"]==0 and
         doc.get("functional_acceptance") is False and
         doc.get("geometric_acceptance") is False and
         doc.get("production_modified") is False,
         "native separator source or stage acceptance forged")
    rows=doc.get("records")
    need(type(rows) is list and len(rows)==1536 and
         type(doc.get("case_count")) is int and doc["case_count"]==1536,
         "Native separator evidence is truncated")
    seed=fields()
    for g,(name,idx) in enumerate(GAPS):
        for octet in range(256):
            binary=b" ".join(x.encode("ascii") for x in seed[:idx+1])+bytes([octet])+b" ".join(x.encode("ascii") for x in seed[idx+1:])
            for e,ending in enumerate(ENDINGS):
                k=g*512+octet*2+e
                row=rows[k]
                content=binary+(b"\n" if ending=="final_lf" else b"")
                expected=[1] if octet in (9,32) else [-1]
                need(type(row) is dict and row.get("boundary")==name and
                     type(row.get("index")) is int and row["index"]==idx and
                     type(row.get("octet")) is int and row["octet"]==octet and
                     row.get("ending")==ending and row.get("raw_hex")==content.hex() and
                     row.get("expected")==expected and row.get("native_output")==expected and
                     type(row.get("native_exit")) is int and row["native_exit"]==0,
                     "falsified Native separator gap=%s octet=%d ending=%s"%(name,octet,ending))
    return 1536
def main(folder):
    root=Path(folder)
    doc=json.loads((root/"native_separator_octets.json").read_text("utf-8"))
    size=verify(doc)
    attacks=(
      ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
      ("stage",lambda x:x.__setitem__("last_completed_stage",1)),
      ("functional",lambda x:x.__setitem__("functional_acceptance",True)),
      ("geometry",lambda x:x.__setitem__("geometric_acceptance",True)),
      ("production",lambda x:x.__setitem__("production_modified",True)),
      ("scope",lambda x:x.__setitem__("scope","PRODUCTION_GRAMMAR_FULL_ACCEPTED")),
      ("count",lambda x:x.__setitem__("case_count",1535)),
      ("missing",lambda x:x["records"].pop()),
      ("reverse",lambda x:x["records"].reverse()),
      ("nul_accepted",lambda x:x["records"][0].__setitem__("native_output",[1])),
      ("tab_rejected",lambda x:x["records"][9*2].__setitem__("native_output",[-1])),
      ("space_rejected",lambda x:x["records"][32*2].__setitem__("native_output",[-1])),
      ("high_byte_accepted",lambda x:x["records"][-2].__setitem__("native_output",[1])),
      ("end_laundered",lambda x:x["records"][1].__setitem__("ending","raw_eof")),
      ("boundary_laundered",lambda x:x["records"][512].__setitem__("boundary","before_rank")),
      ("exit",lambda x:x["records"][0].__setitem__("native_exit",1)),
    )
    declined=[]
    for name,modify in attacks:
        changed=copy.deepcopy(doc);modify(changed)
        try:verify(changed)
        except AssertionError:declined.append(name)
        else:raise AssertionError("accepted forged Native boundary "+name)
    report={"schema":"befunge-stage1-native-separator-audit-v1",
            "native_records_verified":size,
            "hostile_reports_rejected":declined,
            "last_completed_stage":0,"final_acceptance":False}
    (root/"native_separator_octets_audit.json").write_text(
        json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_SEPARATOR_1536_AND_16_TAMPER_AUDIT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native separator evidence path required")
    main(sys.argv[1])
