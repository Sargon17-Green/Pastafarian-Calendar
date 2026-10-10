#!/usr/bin/env python3
"""Independent source-pinned audit of real PyFunge wide-magnitude differential.

Reconstructs 13 255/256/257/512/1024-bit boundary inputs and every plain
input SHA256, checks all seven oracle output tokens, 3-layout producer
counters, actual g/p/k runtime measurements and rejects ten forgeries.
Python does NOT compute calendar expected values.
"""
from pathlib import Path
import copy
import hashlib
import json
import sys

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=[
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
]
def require(ok,why):
    if not ok:raise AssertionError(why)
def source_hash():
    data=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(data)).encode("ascii")+
                     b"\0"+data).hexdigest()
    require(sha==PIN,"Native QA Befunge source changed")
def verify(p):
    require(p.get("schema")=="befunge-stage1-native-wide-magnitude-v1"
            and p.get("source_git_blob")==PIN
            and p.get("real_cases")==13
            and p.get("native_cli_invocations")==78
            and p.get("native_instrumented_invocations")==13
            and p.get("native_reference_invocations")==39
            and p.get("native_production_cli_invocations")==39
            and p.get("numeric_bit_boundaries")==[255,256,257,512,1024]
            and p.get("all_programs_really_executed") is True
            and p.get("other_runtime_mutation_apis_not_proven") is True
            and p.get("stage1_final_accepted") is False,
            "Native wide-input evidence metadata or scope forged")
    entries=p.get("records")
    require(isinstance(entries,list) and len(entries)==13,
            "Native 13-wide-input source case record incomplete")
    read_count=0
    write_count=0
    traces=0
    for row,(label,fields) in zip(entries,CASES):
        s=[str(n) for n in fields]
        expected_hash=hashlib.sha256(
            (" ".join(s)+"\n").encode("ascii")).hexdigest()
        require(row.get("label")==label and row.get("fields")==s
                and row.get("plain_input_sha256")==expected_hash
                and row.get("input_digit_lengths")==[len(a) for a in s]
                and row.get("whitespace_forms_checked")==3
                and row.get("oracle_invocations")==3
                and row.get("source_invocations")==3
                and row.get("instrumented_native_execution") is True,
                "Native input identity, magnitude, source SHA or formats forged")
        ref=row.get("valid_reference_7")
        require(isinstance(ref,list) and len(ref)==7
                and all(isinstance(n,str) and n.lstrip("-").isdigit()
                        for n in ref)
                and row.get("canonical_spaced_output")==ref,
                "native Befunge seven-value oracle/candidate changed")
        memory=row.get("native_memory")
        require(isinstance(memory,dict)
                and type(memory.get("native_steps")) is int
                and 0<memory["native_steps"]<=5000000
                and type(memory.get("engine_puts")) is int
                and 0<memory["engine_puts"]<memory["native_steps"]
                and type(memory.get("direct_g_reads")) is int
                and memory["direct_g_reads"]>0
                and type(memory.get("reads_from_prior_put")) is int
                and 0<memory["reads_from_prior_put"]<=memory["direct_g_reads"]
                and type(memory.get("actual_k_executions")) is int
                and memory["actual_k_executions"]>=0
                and memory.get("runtime_putspace_calls")==0,
                "Native actual g/p/k physical read/write evidence invalid")
        read_count+=memory["direct_g_reads"]
        write_count+=memory["engine_puts"]
        traces+=memory["native_steps"]
    require(read_count>=13 and write_count>=13 and traces>0,
            "Native extended-domain physical memory audit empty")
    return {"source_cases":13,"real_native_executions":91,
            "independent_Befunge_reference_runs":39,
            "actual_physical_g_reads":read_count,
            "actual_engine_p_writes":write_count,
            "native_instruction_steps":traces,
            "largest_input_decimal_digits":max(
                len(str(a)) for _,nums in CASES for a in nums)}
def main(folder):
    source_hash()
    with (Path(folder)/"native_wide_magnitude.json").open(
            encoding="utf-8") as stream:
        evidence=json.load(stream)
    counts=verify(evidence)
    print("NATIVE_WIDE_13_CASES_INDEPENDENT_AUDIT_PASS",counts)
    def reject(name,fn):
        p=copy.deepcopy(evidence)
        fn(p)
        try:verify(p)
        except AssertionError:
            print("NATIVE_WIDE_REPORT_TAMPER_REJECT_PASS",name)
            return name
        raise AssertionError("accepted forged Native wide-input evidence: "+name)
    tests=[
        reject("source_sha",lambda x:x.__setitem__("source_git_blob","0"*40)),
        reject("dropped_last_case",lambda x:x["records"].pop()),
        reject("forged_input",lambda x:x["records"][0]["fields"].__setitem__(1,"1")),
        reject("forged_input_sha",lambda x:x["records"][0].__setitem__(
                "plain_input_sha256","0"*64)),
        reject("missing_layout",lambda x:x["records"][0].__setitem__(
                "whitespace_forms_checked",1)),
        reject("source_mismatch",lambda x:x["records"][0]["canonical_spaced_output"]
               .__setitem__(0,"NAN")),
        reject("wrong_native_g",lambda x:x["records"][0]["native_memory"]
               .__setitem__("direct_g_reads",0)),
        reject("unknown_memory_write",lambda x:x["records"][0]["native_memory"]
               .__setitem__("runtime_putspace_calls",1)),
        reject("premature_final_accept",lambda x:x.__setitem__(
                "stage1_final_accepted",True)),
        reject("false_universal_memory",lambda x:x.__setitem__(
                "other_runtime_mutation_apis_not_proven",False))
    ]
    require(len(tests)==10,"wide-input adversarial evidence incomplete")
    audit={"schema":"befunge-stage1-native-wide-input-audit-v1",
           "verified_counts":counts,"tamper_reports_rejected":tests,
           "stage1_final_acceptance":False}
    with (Path(folder)/"native_wide_magnitude_audit.json").open(
            "w",encoding="utf-8") as out:
        json.dump(audit,out,sort_keys=True,indent=2);out.write("\n")
    print("NATIVE_WIDE_10_NEGATIVE_EVIDENCE_REPORTS_PASS")
if __name__=="__main__":
    require(len(sys.argv)==2,"usage: NATIVE_WIDE_EVIDENCE_DIR")
    main(sys.argv[1])
