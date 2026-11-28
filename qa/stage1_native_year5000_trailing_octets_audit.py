#!/usr/bin/env python3
"""Independent fail-closed BF98 256-octet suffix Native evidence audit."""
import copy,json,sys
from pathlib import Path
PIN="fb6513605febc92c4cd1b453295253cb1cb49740"
CONTROLS=(0,10,13,32,65,127,128,255)
def need(condition,reason):
    if not condition:raise AssertionError(reason)
def prefix():
    fields=["0","100","0","0","9"]
    for x in range(9):fields.extend(["0",str(x*42)])
    return (" ".join(fields+["1"])+"\n").encode("ascii")
def verify(report):
    need(type(report) is dict and
         report.get("schema")=="befunge-stage1-all-trailing-octets-native-v1" and
         report.get("integrated_source_git_blob")==PIN and
         report.get("scope")=="LF_TERMINATED_BINARY_SUFFIX_ONLY_NOT_NO_LF_STAGE1_OPEN" and
         report.get("baseline_valid_native_output")==[1] and
         report.get("full_production_acceptance") is False and
         report.get("no_lf_input_certified") is False and
         type(report.get("last_completed_stage")) is int and
         report["last_completed_stage"]==0,
         "Native source or acceptance scope forgery")
    rows=report.get("records")
    need(type(report.get("octet_count")) is int and report["octet_count"]==256
         and type(rows) is list and len(rows)==256 and
         report.get("historical_controls")==list(CONTROLS),
         "Native octet evidence cardinality or witness count manipulated")
    start=prefix()
    for octet in range(256):
        row=rows[octet]
        expected=(start+bytes([octet])).hex()
        need(type(row) is dict and
             type(row.get("octet")) is int and row["octet"]==octet and
             row.get("raw_hex")==expected and row.get("native_output")==[-1] and
             type(row.get("native_return_code")) is int and
             row["native_return_code"]==0 and
             (row.get("unguarded_native_output")==[1] if octet in CONTROLS
              else "unguarded_native_output" not in row),
             "Native BF98 binary suffix evidence forged for octet %d"%octet)
    return 256
def main(root):
    folder=Path(root)
    doc=json.loads((folder/"native_all_256_trailing_octets.json").read_text("utf-8"))
    length=verify(doc)
    mutations=[
      ("scope",lambda d:d.__setitem__("scope","COMPLETE")),
      ("source",lambda d:d.__setitem__("integrated_source_git_blob","0"*40)),
      ("stage",lambda d:d.__setitem__("last_completed_stage",1)),
      ("no_lf",lambda d:d.__setitem__("no_lf_input_certified",True)),
      ("production",lambda d:d.__setitem__("full_production_acceptance",True)),
      ("count",lambda d:d.__setitem__("octet_count",255)),
      ("missing",lambda d:d["records"].pop()),
      ("reverse",lambda d:d["records"].reverse()),
      ("nul_accepted",lambda d:d["records"][0].__setitem__("native_output",[1])),
      ("ascii_accepted",lambda d:d["records"][65].__setitem__("native_output",[1])),
      ("highbyte_accepted",lambda d:d["records"][255].__setitem__("native_output",[1])),
      ("laundered_hex",lambda d:d["records"][128].__setitem__("raw_hex","00")),
      ("incorrect_exit",lambda d:d["records"][13].__setitem__("native_return_code",1)),
      ("unguarded_hidden",lambda d:d["records"][255].__setitem__(
            "unguarded_native_output",[-1])),
    ]
    refused=[]
    for name,edit in mutations:
        trial=copy.deepcopy(doc);edit(trial)
        try:verify(trial)
        except AssertionError:refused.append(name)
        else:raise AssertionError("accepted forged binary suffix proof "+name)
    result={"schema":"befunge-stage1-all-256-octets-independent-audit-v1",
            "native_records_verified":length,
            "hostile_evidence_rejected":refused,
            "last_completed_stage":0,"no_lf_input_certified":False}
    (folder/"native_all_256_trailing_octets_audit.json").write_text(
        json.dumps(result,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_ALL_256_OCTETS_14_TAMPER_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native evidence directory required")
    main(sys.argv[1])
