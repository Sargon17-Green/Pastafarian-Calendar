#!/usr/bin/env python3
"""Cross-check actual Native BF98 clean and recovered execution reports."""
import json,sys
from pathlib import Path
import stage1_native_four_live_programs_audit as clean_audit
import stage1_native_four_live_p_fault_recovery_audit as fault_audit
def sig(p,after_fault):
    return (p["steps"] if after_fault else p["ticks"],p["native_get"],
            p["native_put"],tuple(p["output"]))
def main(clean_dir,fault_dir):
    c,f=Path(clean_dir),Path(fault_dir)
    clean=json.loads((c/"native_four_live_programs.json").read_text("utf-8"))
    fault=json.loads((f/"native_quad_fault_recovery.json").read_text("utf-8"))
    clean_audit.verify(clean)
    fault_audit.verify(fault)
    assert clean["source_git_blob"]==fault["source_git_blob"]
    reference={}
    for trial in clean["records"]:
        for p in trial["programs"]:
            label=p["label"]
            assert label not in reference or reference[label]==sig(p,False)
            reference[label]=sig(p,False)
    assert len(reference)==19
    count=0
    for trial in fault["records"]:
        for p in trial["programs"]:
            label=p["label"]
            assert sig(p,True)==reference[label],label
            assert p["output"]==clean["oracle"][label]==fault["oracle"][label]
            count+=1
    assert count==32
    print("NATIVE_FOUR_FAULT_VS_CLEAN_32_EXACT_SIGNATURES_PASS_STAGE1_OPEN")
if __name__=="__main__":
    main(sys.argv[1],sys.argv[2])
