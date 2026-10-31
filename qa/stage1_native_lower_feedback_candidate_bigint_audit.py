#!/usr/bin/env python3
"""Independent reject-on-tamper audit of giant Native four-cell QA candidate.

Derives the thirteen wide integer inputs independently, validates all
three input-layout SHA-256 digests and exact seven-field Native outputs.
Does NOT implement or calculate the calendar. Verifies exactly four
physical 2D Befunge bytes in the archived candidate and 15 hostile reports.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
PATCHES=[[948,1331,"6","7"],[951,1337,"^","1"],
         [951,1338," ","^"],[952,1336,"1"," "]]
BIG=(
 ("pow255_neighbor",(0,2**255-1,0,2**255)),
 ("pow256_forward",(0,2**256-1,0,2**256)),
 ("pow256_reverse",(0,2**256,0,2**256-1)),
 ("pow256_negative_forward",(1,2**256,1,2**256+1)),
 ("pow256_negative_reverse",(1,2**256+1,1,2**256)),
 ("pow257_cross_forward",(1,2**257,0,2**257)),
 ("pow257_cross_reverse",(0,2**257,1,2**257)),
 ("pow512_boundary",(0,2**512-1,0,2**512)),
 ("pow512_negative_reverse",(1,2**512,1,2**512-1)),
 ("decimal155_cross",(0,10**155+17,1,10**155+19)),
 ("decimal240_cross_forward",(1,10**240+23,0,10**240+29)),
 ("decimal240_cross_reverse",(0,10**240+29,1,10**240+23)),
 ("pow1024_boundary",(0,2**1024-1,0,2**1024)),
)

def need(x,why):
    if not x:raise AssertionError(why)
def blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()

def layouts(fields):
    s=[str(x) for x in fields]
    return [" ".join(s)+"\n",
            "\t"+s[0]+" "+s[1]+"\r\n"+s[2]+"\t"+s[3]+"\n",
            s[0]+"\t"+s[1]+" "+s[2]+"\t"+s[3]+" \n"]

def check(d):
    need(d.get("schema")=="befunge-stage1-four-cell-wide-native-oracle-v1"
         and d.get("status")=="FOUR_CELL_QA_ONLY_BEYOND_128_BIT_STAGE1_OPEN"
         and d.get("production_git_blob")==PIN
         and d.get("candidate_git_blob")==CANDIDATE
         and d.get("exact_four_changes")==PATCHES
         and d.get("native_integer_domain_cases")==13
         and d.get("native_reference_executions")==39
         and d.get("native_candidate_executions")==39
         and d.get("native_input_whitespace_layouts")==3
         and d.get("numeric_bit_boundaries")==[255,256,257,512,1024]
         and d.get("all_39_candidate_differentials_pass") is True
         and d.get("canonical_unchanged") is True
         and d.get("qa_production_unchanged") is True
         and d.get("stage1_functional_gate")=="OPEN"
         and d.get("stage1_geometry_gate")=="OPEN",
         "Native wide source, bit-domain, or Stage-1 contract invalid")
    rows=d.get("records")
    need(isinstance(rows,list) and len(rows)==len(BIG),"wide native cases missing")
    for rec,(name,inputs) in zip(rows,BIG):
        expected=[str(x) for x in inputs]
        forms=layouts(inputs)
        sha=[hashlib.sha256(x.encode("ascii")).hexdigest() for x in forms]
        reference=rec.get("native_reference_7")
        outputs=rec.get("native_candidate_form_outputs")
        need(rec.get("case")==name
             and rec.get("input_fields")==expected
             and rec.get("valid") is True
             and rec.get("native_input_form_sha256")==sha
             and isinstance(reference,list) and len(reference)==7
             and all(isinstance(x,str) and x.lstrip("-").isdigit()
                     for x in reference)
             and isinstance(outputs,list) and len(outputs)==3
             and all(x==reference for x in outputs)
             and rec.get("native_candidate_three_layouts_pass") is True
             and rec.get("native_reference_modules_invoked")==3
             and rec.get("native_candidate_executions")==3,
             "forged real Native 13-domain 3-layout numerical oracle evidence")
    return {"verified_native_inputs":13,"verified_reference_executions":39,
            "verified_candidate_layouts":39,"qa_only":True}

def main(folder):
    root=Path(folder)
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    candidate=(root/"four_cell_candidate.b98").read_bytes()
    need(blob(source)==PIN and blob(candidate)==CANDIDATE,
         "Native production/candidate Git blob changed")
    old=source.split(b"\n")
    new=candidate.split(b"\n")
    need(len(old)==len(new),"Native source 2D row count changed")
    changes=[]
    for y,(a,b) in enumerate(zip(old,new)):
        need(len(a)==len(b),"Native source Funge-space row width changed")
        for x,(u,v) in enumerate(zip(a,b)):
            if u!=v:changes.append([x,y,chr(u),chr(v)])
    need(changes==sorted(PATCHES,key=lambda z:(z[1],z[0])),
         "Native candidate byte edits not confined to four pinned cells")
    d=json.loads((root/"four_cell_wide_native_oracle.json").read_text("utf-8"))
    result=check(d)
    print("NATIVE_FOUR_CELL_1024_BIT_INDEPENDENT_ORACLE_AUDIT_PASS",
          json.dumps(result,sort_keys=True))
    rejected=[]
    def reject(label,fn):
        bad=copy.deepcopy(d)
        fn(bad)
        try:check(bad)
        except AssertionError:
            rejected.append(label)
            print("NATIVE_FOUR_CELL_BIGINT_TAMPER_REJECT_PASS",label)
            return
        raise AssertionError("forged Native wide oracle report accepted: "+label)
    reject("source",lambda x:x.__setitem__("candidate_git_blob","0"*40))
    reject("missing_case",lambda x:x["records"].pop())
    reject("reorder",lambda x:x["records"][0].__setitem__("case","pow256_forward"))
    reject("wrong_integer",lambda x:x["records"][0]["input_fields"].__setitem__(1,"0"))
    reject("wrong_layout",lambda x:x["records"][0]["native_input_form_sha256"].__setitem__(2,"0"*64))
    reject("wrong_reference",lambda x:x["records"][0]["native_reference_7"].__setitem__(0,"BAD"))
    reject("wrong_candidate_0",lambda x:x["records"][0]["native_candidate_form_outputs"][0].__setitem__(0,"BAD"))
    reject("wrong_candidate_2",lambda x:x["records"][0]["native_candidate_form_outputs"][2].__setitem__(0,"BAD"))
    reject("wrong_layout_count",lambda x:x.__setitem__("native_input_whitespace_layouts",2))
    reject("fake_oracle_count",lambda x:x.__setitem__("native_reference_executions",38))
    reject("fake_source_edits",lambda x:x.__setitem__("exact_four_changes",[]))
    reject("premature_functional",lambda x:x.__setitem__("stage1_functional_gate","PASS"))
    reject("premature_geometric",lambda x:x.__setitem__("stage1_geometry_gate","PASS"))
    reject("fake_canonical",lambda x:x.__setitem__("canonical_unchanged",False))
    reject("false_case_status",lambda x:x["records"][0].__setitem__("valid",False))
    need(len(rejected)==15,"negative tamper test coverage incomplete")
    (root/"four_cell_wide_native_oracle_audit.json").write_text(json.dumps(
        {"schema":"befunge-stage1-four-cell-1024bit-audit-v1",
         "verified":result,"adversarial_reports_rejected":rejected,
         "stage1_completed":False},sort_keys=True,indent=2)+"\n",
        encoding="utf-8")
    print("NATIVE_FOUR_CELL_1024_BIT_FIFTEEN_FALSIFIED_REPORTS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: candidate wide Native artifact directory")
    main(sys.argv[1])
