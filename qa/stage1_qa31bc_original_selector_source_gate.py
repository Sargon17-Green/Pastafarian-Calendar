#!/usr/bin/env python3
"""QA31BC: pinned original source + derived signed-count fixture only.
NO original 46MB signed case replay and NO new original Native in this CI.
"""
import hashlib,json,sys
from pathlib import Path
SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
ORIGINAL="9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49"
PREVIOUS="45c983db1e0ae97faa5a668e6e3d7a470981abbabfcc8fbcf253cab47ffec303"
H=">02a*8+a*8+-01a*2+a*7+a*0+-x"
V="v09a*2+a*5+-01a*5+a*8+a*3+-x"

def rpn(code):
    st=[("opaque incoming stack",)]
    for ch in code[1:-1]:
        if ch in "0123456789abcdef":st.append(int(ch,16))
        elif ch in "+-*":
            assert len(st)>=3,"source expression reads incoming stack"
            b,a=st.pop(),st.pop()
            st.append(a+b if ch=="+" else a-b if ch=="-" else a*b)
        else:raise AssertionError("source opcode not arithmetic "+ch)
    assert len(st)==3 and st[0]==("opaque incoming stack",)
    return tuple(st[1:])

def check():
    raw=Path("src/interleaved_work_counts.b98").read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    assert blob==SOURCE,("original source changed",blob)
    lines=raw.decode("utf8").splitlines()
    assert len(lines)==2016
    assert lines[1354][1335]=="p" and lines[1373][1335]=="x"
    assert lines[1750][1500]==" " and lines[1750][1501]==">" and lines[1751][1500]=="v"
    a=lines[1750][1501:1529]
    b="".join(lines[y][1500] for y in range(1751,1779))
    assert (a,b)==(H,V)
    assert rpn(a)==(-288,-1270) and rpn(b)==(-925,-1583)
    assert (1528-288,1750-1270)==(1240,480)
    assert (1500-925,1778-1583)==(575,195)
    f=json.loads(Path("qa/QA31BC_ORIGINAL_SELECTOR_PORTABLE_FIXTURE_2026-11-08.json").read_text(encoding="utf8"))
    assert f["schema"]=="qa31bc-original-signed200-derived-source-v1"
    assert f["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ"
    assert f["source_git_blob"]==SOURCE and f["original_signed_archive_sha256"]==ORIGINAL
    assert f["prior_qa31bb_sha256"]==PREVIOUS
    expected={"signed_cases_replayed_externally":200,"signed_steps_replayed_externally":3628390,"selector_executions":365,
      "selector_writes":365,"original_selector_x_validated":365,"source_corridor_verified_steps":10220,
      "physical_post_selector_gate_reentries":0,"physical_corridor_p_overwrites":0,"source_hostile_nonnoop_mutations_rejected":24,
      "new_original_native_executions":0}
    for k,v in expected.items():assert f[k]==v,k
    assert f["original_selector_values"]=={"62":140,"118":225}
    assert f["branch_routes"]==[
      {"selector_ascii":62,"source_x":[1528,1750],"dest":[1240,480],"delta":[-288,-1270],"events":140},
      {"selector_ascii":118,"source_x":[1500,1778],"dest":[575,195],"delta":[-925,-1583],"events":225}
    ]
    assert f["stage1_global_pass"] is False and f["unobserved_inputs"]=="UNKNOWN"
    mutants=[]
    for code,op in [(a,62),(b,118)]:
        count=0
        for i,ch in enumerate(code):
            if ch not in "0123456789abcdef":continue
            repl="1" if ch!="1" else "2"
            altered=code[:i]+repl+code[i+1:]
            assert altered!=code
            if rpn(altered)==rpn(code):continue
            mutants.append((op,i,rpn(altered)))
            count+=1
            if count==12:break
        assert count==12
    assert len(mutants)==24
    print(json.dumps({"source_blob":blob,"original_signed_archive_read_now":False,
      "source_corridor_authentication":"PASS","vectors":[rpn(a),rpn(b)],
      "derived_200_case_selector_count":f["selector_executions"],
      "source_nonnoop_mutants_rejected":len(mutants),"stage1_global_pass":False},indent=2))
if __name__=="__main__":check()
