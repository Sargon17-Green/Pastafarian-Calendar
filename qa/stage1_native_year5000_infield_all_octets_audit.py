#!/usr/bin/env python3
"""Fail-closed independent BF98 in-field raw-byte corpus verification."""
import json,copy,sys
from pathlib import Path
PIN="c5bd9dd06e227f9f31c8988a51bd114bf67b9af7"
ROLES=(("zero_magnitude_sign",2),("unsigned_origin_magnitude",3),("rank_token",23))
def need(value,why):
    if not value:raise AssertionError(why)
def seed():
    fields=["0","100","0","0","9"]
    for gate in range(9):fields+=["0",str(42*gate)]
    return fields+["1"]
def valid(role,byte):
    return ((role=="zero_magnitude_sign" and byte==48) or
            (role=="unsigned_origin_magnitude" and 48<=byte<=57) or
            (role=="rank_token" and 49<=byte<=57))
def verify(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-native-infield-1536-v1" and
         doc.get("source_git_blob")==PIN and
         doc.get("scope")=="THREE_TOKEN_ROLES_BINARY_INPUT_TEST_ONLY_STAGE1_OPEN" and
         doc.get("test_only") is True and
         type(doc.get("last_completed_stage")) is int and
         doc["last_completed_stage"]==0 and
         doc.get("full_functional_qa_pass") is False and
         doc.get("geometric_qa_pass") is False,
         "Native lexical source or final Stage1 scope forged")
    records=doc.get("records")
    need(type(records) is list and len(records)==1536 and
         type(doc.get("native_input_count")) is int and doc["native_input_count"]==1536,
         "Native lexical matrix truncated")
    reference=seed();k=0
    for role,index in ROLES:
        for byte in range(256):
            content=list(reference);content[index]=bytes([byte])
            for terminator in ("raw_eof","final_lf"):
                row=records[k];k+=1
                serialized=b" ".join(v.encode("ascii") if isinstance(v,str) else v
                                      for v in content)
                if terminator=="final_lf":serialized+=b"\n"
                expected=[1] if valid(role,byte) else [-1]
                need(type(row) is dict and
                     row.get("role")==role and
                     type(row.get("field_index")) is int and row["field_index"]==index and
                     type(row.get("octet")) is int and row["octet"]==byte and
                     row.get("ending")==terminator and
                     row.get("raw_hex")==serialized.hex() and
                     row.get("expected")==expected and
                     row.get("native_output")==expected and
                     type(row.get("native_exit")) is int and row["native_exit"]==0,
                     "Native in-field byte evidence manipulated %s byte=%d ending=%s"%
                     (role,byte,terminator))
    return k
def main(folder):
    root=Path(folder)
    evidence=json.loads((root/"native_infield_all_octets.json").read_text("utf-8"))
    n=verify(evidence)
    attacks=(
      ("scope",lambda d:d.__setitem__("scope","STAGE1_COMPLETE")),
      ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
      ("stage",lambda d:d.__setitem__("last_completed_stage",1)),
      ("functional",lambda d:d.__setitem__("full_functional_qa_pass",True)),
      ("geometry",lambda d:d.__setitem__("geometric_qa_pass",True)),
      ("type",lambda d:d.__setitem__("test_only",False)),
      ("count",lambda d:d.__setitem__("native_input_count",1535)),
      ("drop",lambda d:d["records"].pop()),
      ("reorder",lambda d:d["records"].reverse()),
      ("bad_sign_accept",lambda d:d["records"][98].__setitem__("native_output",[1])),
      ("valid_sign_reject",lambda d:d["records"][96].__setitem__("native_output",[-1])),
      ("valid_magnitude_reject",lambda d:d["records"][608].__setitem__("native_output",[-1])),
      ("bad_rank_accept",lambda d:d["records"][1120].__setitem__("native_output",[1])),
      ("raw_bytes",lambda d:d["records"][768].__setitem__("raw_hex","00")),
      ("exit",lambda d:d["records"][0].__setitem__("native_exit",1)),
      ("role",lambda d:d["records"][0].__setitem__("role","some_other_role")),
    )
    rejected=[]
    for label,modify in attacks:
        mutant=copy.deepcopy(evidence);modify(mutant)
        try:verify(mutant)
        except AssertionError:rejected.append(label)
        else:raise AssertionError("accepted forged BF98 in-field report "+label)
    result={"schema":"befunge-stage1-native-infield-audit-v1",
            "native_cases_verified":n,"adversarial_reports_rejected":rejected,
            "last_completed_stage":0,"stage1_complete":False}
    (root/"native_infield_all_octets_audit.json").write_text(
        json.dumps(result,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_INFIELD_1536_AND_16_HOSTILE_AUDIT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"evidence directory argument required")
    main(sys.argv[1])
