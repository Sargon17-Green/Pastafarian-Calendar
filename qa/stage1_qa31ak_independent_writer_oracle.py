#!/usr/bin/env python3
"""QA31AK independent inverse opcode and q/m state oracle.
Never imports the forward interpreter and never infers Native reachability.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SRC="560d6aa5807a7f766213a33835cce85eab0fa40c"
WS={9,10,13,32}
FOCUS={(58,2),(106,2),(154,2),(202,2),(60,5),
       (200,14),(248,14),(152,26),(248,26),(296,26),
       (344,26),(152,35),(248,35)}
TARGETS={"20":[17],"23":[20],"29":[],"32":[29]}
Q_WRITERS=[[106,2],[248,26],[248,35]]
M_WRITERS=[[202,2],[248,14],[344,26]]
STATES=[[0,0],[0,1],[1,0],[1,1],[2,0],[2,1],
        [3,0],[3,1],[4,0]]


def must(value,message):
    if not value:
        raise AssertionError(message)


def inspect_source(raw):
    digest=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    must(digest==SRC,"source blob not original")
    rows=raw.splitlines()
    must(len(rows)==2015 and rows[49]==b"","original shape changed")
    all_p={(x,y) for y,line in enumerate(rows) for x,ch in enumerate(line)
           if ch==ord("p")}
    must(len(all_p)==57 and {p for p in all_p if p[1]<45}==FOCUS,
         "raw p source inventory changed")
    distinct={
        (57,8):103,(151,8):103,(185,8):106,
        (57,11):103,(113,11):106,(248,14):112,
        (57,17):103,(89,20):106,(113,23):106,
        (248,26):112,(344,26):112,(89,29):106,
        (113,32):106,(248,35):112,(114,38):106
    }
    for (x,y),opcode in distinct.items():
        must(rows[y][x]==opcode, "independent opcode pin failed "+str((x,y)))
    return sorted([list(p) for p in all_p if p[1]>=45],key=lambda z:(z[1],z[0])),len(distinct)


def class_for(b):
    if 48<=b<=57:return "digit"
    if b in WS:return "space"
    return "other"


def inverse_row(entry,params):
    # Derived from the original source's comparisons and vector operands.
    if entry==2:
        return [10,5]
    if entry==5:
        return [10,8]
    if entry==8:
        return [10,11] if class_for(params["byte"])=="digit" else [10,17]
    if entry==11:
        return [10,14] if params["q"]<=3 else [10,44]
    if entry==14:
        return [10,5]
    if entry==17:
        return [10,20] if class_for(params["byte"])=="space" else [10,44]
    if entry==20:
        return [10,23] if params["m"]==1 else [10,5]
    if entry==23:
        return [10,26] if params["q"]<=3 else [10,44]
    if entry==26:
        return [10,5]
    if entry==29:
        return [10,32] if params["m"]==1 else [10,38]
    if entry==32:
        return [10,35] if params["q"]<=3 else [10,44]
    if entry==35:
        return [10,38]
    if entry==38:
        return [10,41] if params["q"]==4 else [10,44]
    raise AssertionError("unrecognized original source row")


def expected_writes(entry,params):
    if entry==2:
        return [[58,2,0,49,0],[106,2,1,49,0],
                [154,2,2,49,0],[202,2,3,49,0]]
    if entry==5:
        return [[60,5,0,49,params["byte"]]]
    if entry==14:
        # Second p site sets the control m=1; c=(2,49) is data-dependent.
        return [[200,14,2,49,None],[248,14,3,49,1]]
    if entry==26:
        q=params["q"]
        return [[152,26,10+q,49,1],[248,26,1,49,q+1],
                [296,26,2,49,0],[344,26,3,49,0]]
    if entry==35:
        q=params["q"]
        return [[152,35,10+q,49,1],[248,35,1,49,q+1]]
    return []


def inverse_cycle(q,m,byte):
    c=class_for(byte)
    if c=="digit":
        if q<=3:
            return {"path":[5,8,11,14],"exit_row":5,"after":[q,1]}
        return {"path":[5,8,11],"exit_row":44,"after":[q,m]}
    if c=="other":
        return {"path":[5,8,17],"exit_row":44,"after":[q,m]}
    if m==0:
        return {"path":[5,8,17,20],"exit_row":5,"after":[q,0]}
    if q>3:
        return {"path":[5,8,17,20,23],"exit_row":44,"after":[q,1]}
    return {"path":[5,8,17,20,23,26],"exit_row":5,"after":[q+1,0]}


def independently_reachable_states():
    waiting=[(0,0)];visited={(0,0)}
    while waiting:
        q,m=waiting.pop(0)
        for byte in (48,32,65):
            v=inverse_cycle(q,m,byte)
            if v["exit_row"]==5:
                state=tuple(v["after"])
                must(state[0]<=4 and state[1] in (0,1),
                     "independent state grammar diverged")
                if state not in visited:
                    visited.add(state);waiting.append(state)
    return sorted([list(z) for z in visited])


def verify(data,outer):
    must(data["schema"]=="qa31ak-source-conditional-writer-closure-v1",
         "wrong schema")
    must(data["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ" and
         data["source_blob"]==SRC,"identity")
    must((data["raw_p_glyphs_full_source"],
          data["raw_p_glyphs_rows_0_to_44"],
          data["raw_p_glyphs_outside_focus"])==(57,13,44),
         "glyph counts")
    must(data["outside_focus_p_sites"]==outer,"outside p glyph list")
    must(data["outside_focus_memory_write_targets"].startswith("UNKNOWN"),
         "outside source writes falsely resolved")
    must(data["canonical_q_m_source_writer_sites"]==
         {"q":Q_WRITERS,"m":M_WRITERS},"q/m owners")
    must(data["conditional_predecessors_of_20_23_29_32"]==TARGETS,
         "conditional ingress inverse")
    records=data["conditional_probe_records"]
    must(data["conditional_source_probe_cases"]==895 and len(records)==895,
         "source conditional case count")
    unique=set()
    for rec in records:
        entry=rec["entry"];param=rec["parameter"]
        identity=(entry,tuple(sorted(param.items())))
        must(identity not in unique,"duplicated conditional source probe")
        unique.add(identity)
        must(rec["exit"]==inverse_row(entry,param),
             "inverted source edge failed "+str(identity))
        expected=expected_writes(entry,param)
        actual=rec["puts"]
        must(len(actual)==len(expected),"conditional writer count mismatch")
        for e,a in zip(expected,actual):
            must(a[:4]==e[:4] and (e[4] is None or a[4]==e[4]),
                 "writer source/target drift "+str(identity))
    must(data["canonical_source_reachable_q_m_states"]==STATES and
         independently_reachable_states()==STATES,
         "incorrect induction closure")
    cases=data["canonical_per_byte_probes"]
    must(data["canonical_state_byte_cases"]==2304 and len(cases)==2304,
         "source full-state byte coverage")
    idx=0
    for q,m in STATES:
        for byte in range(256):
            rec=cases[idx];idx+=1
            inv=inverse_cycle(q,m,byte)
            must(rec["start"]==[q,m] and rec["byte"]==byte,
                 "missing or reordered byte class")
            must(rec["path"]==inv["path"] and
                 rec["exit_row"]==inv["exit_row"] and
                 rec["after"]==inv["after"],
                 "independent route/transition disagrees "+str((q,m,byte)))
            must(0<rec["steps"]<=8*549,"invalid bounded step count")
    must(data["canonical_no_q_gt3_and_m1"] is True,
         "lost canonical invariant")
    must(data["forward_hostile_source_mutations_rejected"]==7,
         "forward hostile count")
    must(data["new_native_runs"]==0 and
         data["original_native_replayed"] is False and
         data["global_reachability_proven"] is False and
         data["stage1_pass"] is False,
         "unjustified global or Native claim")
    must("conditional" in data["induction_scope"] and
         "no alternative IP ingress" in data["induction_scope"],
         "conditional theorem promoted to universal")
    return len(records),len(cases)


def hostile(data,outer):
    # Separate report mutations, never interpreted as original Native failures.
    mutations=[
        lambda v:v.__setitem__("source_blob","0000"),
        lambda v:v.__setitem__("raw_p_glyphs_full_source",56),
        lambda v:v["outside_focus_p_sites"].pop(),
        lambda v:v.__setitem__("outside_focus_memory_write_targets","NONE"),
        lambda v:v["canonical_q_m_source_writer_sites"]["m"].pop(),
        lambda v:v["conditional_predecessors_of_20_23_29_32"].__setitem__("29",[5]),
        lambda v:v["conditional_probe_records"][0].__setitem__("exit",[10,29]),
        lambda v:v["conditional_probe_records"][-1]["puts"].pop(),
        lambda v:v["canonical_source_reachable_q_m_states"].append([4,1]),
        lambda v:v["canonical_per_byte_probes"][48].__setitem__("exit_row",23),
        lambda v:v["canonical_per_byte_probes"][8].__setitem__("after",[4,1]),
        lambda v:v.__setitem__("canonical_no_q_gt3_and_m1",False),
        lambda v:v.__setitem__("forward_hostile_source_mutations_rejected",6),
        lambda v:v.__setitem__("new_native_runs",1),
        lambda v:v.__setitem__("global_reachability_proven",True),
        lambda v:v.__setitem__("stage1_pass",True),
    ]
    count=0
    for i,mut in enumerate(mutations):
        v=copy.deepcopy(data);mut(v)
        try:
            verify(v,outer)
        except (AssertionError,KeyError,TypeError,IndexError):
            count+=1
        else:
            raise AssertionError("hostile mutation escaped "+str(i))
    must(count==16,"independent hostile total")
    return count


def main():
    ap=argparse.ArgumentParser()
    for arg in ("source","forward","out"):
        ap.add_argument("--"+arg,required=True)
    a=ap.parse_args()
    outside,pins=inspect_source(Path(a.source).read_bytes())
    d=json.loads(Path(a.forward).read_text(encoding="utf-8"))
    conditional,full=verify(d,outside)
    controls=hostile(d,outside)
    result={"schema":"qa31ak-independent-inverse-v1","source_blob":SRC,
            "independent_opcode_pins":pins,
            "verified_source_conditional_cases":conditional,
            "verified_full_state_byte_cases":full,
            "canonical_states":len(STATES),
            "hostile_report_mutations_rejected":controls,
            "new_native_runs":0,"stage1_pass":False}
    Path(a.out).write_text(json.dumps(result,sort_keys=True,indent=2)+"\n",
                           encoding="utf-8")
    print("QA31AK_INDEPENDENT_INVERSE_OK",conditional,full,
          "canonical_states",len(STATES),"hostile",controls)
    print("QA31AK_NO_NATIVE_NO_GLOBAL_PASS")


if __name__=="__main__":
    main()
