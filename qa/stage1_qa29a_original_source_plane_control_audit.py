#!/usr/bin/env python3
"""QA29A: original-source static-blank and directed-control explanation audit.

This is an independent finite QA28 reanalysis, not a new Native program run.
It proves source-plane static blank corridors and validates signed historical
transitions; it explicitly does NOT claim blank runtime memory, no intervening
p writes, the absence of alternate paths, or global dead code.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SOURCE_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA28_RAW_SHA256="c5a5beaab308df31222652484e5fb18af554bf75e7b492225b107197fb29aa6e"
QA28_RUN=39985923985
ORIGINAL_15={
    (10,32),(10,35),(57,32),(57,35),(113,32),
    (127,35),(152,35),(174,32),(199,35),(211,29),
    (235,23),(235,32),(248,35),(286,5),(309,35)
}
VECTOR_RESETS={(10,32),(10,35)}
STATIC_GAPS={(113,32),(199,35)}

def need(condition,why):
    if not condition:
        raise AssertionError(why)

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def bytes_at(rows,x,y):
    if y<0 or y>=len(rows) or x<0 or x>=len(rows[y]):
        return 32
    return rows[y][x]

def frozen_source(path):
    b=Path(path).read_bytes()
    name=hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+b"\0"+b).hexdigest()
    need(name==SOURCE_BLOB,"immutable signed production 2D source changed")
    return b.splitlines()

def frozen_qa28(path):
    b=Path(path).read_bytes()
    need(sha256(b)==QA28_RAW_SHA256,
         "QA28 original downloaded actual Native directed receipt changed")
    obj=json.loads(b)
    need(obj.get("schema")=="qa28-15-original-source-candidate-directed-native-triads-v1"
         and obj.get("original_source_git_blob")==SOURCE_BLOB
         and obj.get("original_qa28_run")==None  # QA28 predecessor is QA27
         and obj.get("original_qa20_run")==39761821210
         and obj.get("original_qa27_run")==39966335703
         and obj.get("exact_directed_witness_triads")==15
         and obj.get("eight_negative_controls_per_target_rejected")==120
         and obj.get("stage1_complete") is False
         and obj.get("no_missing_edge_is_universal_unreachability_claim") is True,
         "QA28 signed original finite provenance/limitations drifted")
    rows=obj.get("records")
    need(isinstance(rows,list) and len(rows)==15,
         "QA28 must contain every original unobserved candidate")
    return rows

def inspect(original,claimed,rows):
    # Compare exact immutable original fields separately from geometry.
    # The QA28 SHA pin anchors all original Native STEP facts.
    fields=("target","static_target_opcode","nearest_native_step",
            "predecessor_native_step","successor_native_step",
            "pre_execution_delta","actual_directed_exit_displacement",
            "actual_directed_entry_displacement","original_witness_tick",
            "original_case","minimum_original_l1",
            "actual_successor_equals_nominal","observed_predecessor_opcode_x")
    for field in fields:
        need(claimed.get(field)==original.get(field),
             "forged QA28 actual Native source control field: "+field)
    target=tuple(claimed["target"])
    need(target in ORIGINAL_15,
         "original fifteen candidate coordinates corrupted")
    preceding=claimed["predecessor_native_step"]
    here=claimed["nearest_native_step"]
    following=claimed["successor_native_step"]
    need(all(type(z) is list and len(z)==7
             for z in (preceding,here,following)),
         "original Native STEP tuple incomplete")
    need(preceding[0]+1==here[0] and here[0]+1==following[0],
         "original Native STEP indices not consecutive")
    x,y=here[1:3]
    tx,ty=target
    original_target=bytes_at(rows,tx,ty)
    static_anchor=bytes_at(rows,x,y)
    need(original_target==claimed["static_target_opcode"],
         "original target byte not present in source")
    need(static_anchor==here[5] and here[6]==0,
         "original anchor's static byte differs from fetched signed Native opcode")
    need(abs(x-tx)+abs(y-ty)==claimed["minimum_original_l1"],
         "original nearest candidate L1 distance forged")
    dx=following[1]-here[1]
    dy=following[2]-here[2]
    need([dx,dy]==claimed["actual_directed_exit_displacement"],
         "signed Native outgoing displacement forged")
    need([here[1]-preceding[1],here[2]-preceding[2]]==
         claimed["actual_directed_entry_displacement"],
         "signed Native incoming displacement forged")
    need(claimed["pre_execution_delta"]==here[3:5],
         "original Native pre-execution vector altered")
    nominal=[x+here[3],y+here[4]]
    need((nominal==following[1:3]) is claimed["actual_successor_equals_nominal"],
         "claimed original Native exit is not consistent with vector")
    need((preceding[5]==ord("x") and preceding[6]==0) is
         claimed["observed_predecessor_opcode_x"],
         "prior Native x execution source claim forged")
    if target in VECTOR_RESETS:
        need((x,y) in {(10,29),(10,38)}
             and static_anchor==ord(">")
             and preceding[5]==ord("x") and preceding[6]==0
             and (dx,dy)==(1,0)
             and here[3:5] != [1,0]
             and nominal!=following[1:3],
             "QA29 original x-to-direction-reset Native witness drifted")
        return {"target":list(target),"category":"observed_x_then_right_direction_reset",
                "signed_predecessor":preceding[1:7],
                "signed_anchor":here[1:7],
                "signed_successor":following[1:7],
                "source_anchor_byte":static_anchor,
                "pre_execution_delta":here[3:5],
                "observed_exit_delta":[dx,dy],
                "all_memory_mutation_paths_proven_absent":False}
    if target in STATIC_GAPS:
        need(((x,y),(following[1],following[2]))
             in {((112,29),(120,29)),((198,38),(206,38))}
             and static_anchor==ord("-")
             and here[3:5]==[1,0]
             and [dx,dy]==[8,0]
             and nominal!=following[1:3],
             "QA29 exact observed nonadjacent Native transition drifted")
        cells=[[i,y,bytes_at(rows,i,y)] for i in range(x+1,following[1])]
        need(len(cells)==7 and all(ch==32 for _,_,ch in cells),
             "original source does not contain seven consecutive static blanks")
        need(bytes_at(rows,following[1],y)==ord("0"),
             "original Native next executable opcode source is not digit zero")
        return {"target":list(target),"category":"observed_eight_cell_native_exit_seven_static_source_blanks",
                "signed_anchor":here[1:7],
                "signed_successor":following[1:7],
                "static_original_blank_cells":cells,
                "runtime_skipped_cells_verified_blank":False,
                "pyfunge_implementation_mechanism_proven":False,
                "all_memory_mutation_paths_proven_absent":False}
    need((dx,dy)==(1,0) and here[3:5]==[1,0]
         and nominal==following[1:3],
         "other original candidate does not have the expected unit horizontal exit")
    need(target not in VECTOR_RESETS|STATIC_GAPS,
         "a special source target got silently generalized")
    return {"target":list(target),"category":"observed_unit_horizontal_native_exit",
            "signed_anchor":here[1:7],
            "signed_successor":following[1:7],
            "static_anchor_byte":static_anchor,
            "runtime_mutation_proven_absent":False}

def adversarial_controls(record,source):
    tests=[
       ("change-target-byte",lambda x:x.__setitem__("static_target_opcode",ord("z"))),
       ("shift-anchor-x",lambda x:x["nearest_native_step"].__setitem__(1,x["nearest_native_step"][1]+1)),
       ("change-anchor-opcode",lambda x:x["nearest_native_step"].__setitem__(5,ord("z"))),
       ("change-anchor-vector",lambda x:x["pre_execution_delta"].__setitem__(0,0)),
       ("forge-directed-exit",lambda x:x["successor_native_step"].__setitem__(1,x["successor_native_step"][1]+1)),
       ("change-predecessor-opcode",lambda x:x["predecessor_native_step"].__setitem__(5,ord("z"))),
       ("change-witness-tick",lambda x:x.__setitem__("original_witness_tick",0)),
       ("change-corrupted-original-case",lambda x:x.__setitem__("original_case","forged"))]
    for name,attack in tests:
        bogus=copy.deepcopy(record)
        attack(bogus)
        try:inspect(record,bogus,source)
        except (AssertionError,IndexError,TypeError,KeyError):pass
        else:raise AssertionError("QA29 forged finite Native transition accepted: "+name)
    return len(tests)

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--source",required=True)
    p.add_argument("--qa28",required=True)
    p.add_argument("--output",required=True)
    a=p.parse_args()
    source=frozen_source(a.source)
    records=frozen_qa28(a.qa28)
    need({tuple(x["target"]) for x in records}==ORIGINAL_15,
         "QA29 lost any original 15 source-cell target")
    rows=[];negative=0
    for original in records:
        rows.append(inspect(original,original,source))
        negative+=adversarial_controls(original,source)
    counts={key:sum(r["category"]==key for r in rows) for key in (
        "observed_x_then_right_direction_reset",
        "observed_eight_cell_native_exit_seven_static_source_blanks",
        "observed_unit_horizontal_native_exit")}
    need(sorted(counts.values())==[2,2,11]
         and negative==120,
         "QA29 original signed directed transition classification changed")
    out={"schema":"qa29a-original-fifteen-source-plane-control-semantics-v1",
         "production_git_blob":SOURCE_BLOB,
         "signed_original_qa28_receipt_sha256":QA28_RAW_SHA256,
         "original_qa28_github_run":QA28_RUN,
         "original_control_frontier_targets":15,
         "new_native_program_executions":0,
         "x_to_right_direction_reset_observations":2,
         "eight_cell_exits_over_seven_original_static_blanks":2,
         "horizontal_unit_exits":11,
         "adversarial_signed_transition_mutations_rejected":negative,
         "physical_skipped_cell_memory_ownership_proven":False,
         "underlying_pyfunge_skip_algorithm_proven":False,
         "original_other_fifteen_source_cells_unreachable_proven":False,
         "global_memory_write_ownership_proven":False,
         "stage1_complete":False,
         "category_counts":counts,"records":rows}
    Path(a.output).write_text(json.dumps(out,sort_keys=True,indent=2)+"\n")
    print("QA29A_FIFTEEN_NATIVE_TRANSITIONS_SOURCE_CHECKED")
    print("QA29A_TWO_SEVEN_STATIC_BLANK_SOURCE_CORRIDORS_CONFIRMED")
    print("QA29A_ONE_HUNDRED_TWENTY_MUTATED_RECEIPTS_REJECTED")
    print("QA29A_RUNTIME_MEMORY_AND_GLOBAL_STAGE1_STILL_UNPROVEN")

if __name__=="__main__":
    main()
