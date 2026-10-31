#!/usr/bin/env python3
"""Fail-closed static initialization check for real BF98 quad-live recovery.

This narrow preflight detects a previously encountered NameError where the
Native harness declared aborted_set but later used abandoned_set. It runs
before the expensive Native job and tests its own detector against mutations.
It does NOT certify execution, isolation, arithmetic, or Stage 1 acceptance.
"""
import re
import symtable
from pathlib import Path

SOURCE=Path("qa/stage1_native_four_live_p_fault_recovery.py")
REQUIRED=(
    "active","fired","recovered",
    "first_fault_round","live_at_fault",
    "old_space","old_io","old_memory","old_vec",
    "abandoned_set","initial_fault_ticks","first_recovered_round",
    "dirty_stats","wrote",
)
def require(ok,msg):
    if not ok:
        raise AssertionError(msg)
def audit(text):
    table=symtable.symtable(text,str(SOURCE),"exec")
    functions=[x for x in table.get_children()
               if x.get_type()=="function" and x.get_name()=="trial"]
    require(len(functions)==1,"missing or duplicate trial scope")
    trial=functions[0]
    for name in REQUIRED:
        try:
            symbol=trial.lookup(name)
        except KeyError:
            raise AssertionError("required Native ownership state missing: "+name)
        require(symbol.is_local() and symbol.is_assigned() and
                symbol.is_referenced() and not symbol.is_global(),
                "Native recovery state has no bound local initializer: "+name)
        # No global declaration or free-variable loophole.
        require(re.search(r"\b"+name+r"\s*=\s*\[",text) is not None,
                "Native recovery state initializer missing: "+name)
    require("aborted_set" not in text,
            "obsolete aborted_set typo reintroduced")
    return len(REQUIRED)

def main():
    text=SOURCE.read_text(encoding="utf-8")
    count=audit(text)
    rejected=[]
    for name in REQUIRED:
        mutated,changed=re.subn(r"\b"+name+r"(?=\s*=\s*\[)",
                                "bad_"+name,text,count=1)
        require(changed==1,"not a single assignment to mutate: "+name)
        try:
            audit(mutated)
        except AssertionError:
            rejected.append(name)
        else:
            raise AssertionError("missed unbound local Native state: "+name)
    require(len(rejected)==len(REQUIRED),"unrejected binding mutants")
    print("NATIVE_FOUR_LIVE_P_FAULT_STATE_BINDING_PREFLIGHT_PASS",
          count,"LOCAL_STATE_INITIALIZERS",
          len(rejected),"INVALID_DECLARATION_MUTANTS_REJECTED",
          "NATIVE_EXECUTION_REQUIRED_STAGE1_OPEN")
if __name__=="__main__":
    main()
