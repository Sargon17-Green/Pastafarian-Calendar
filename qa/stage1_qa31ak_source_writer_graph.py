#!/usr/bin/env python3
"""QA31AK: finite source-pinned opcode/writer and canonical-ingress audit.
Only bounded conditional Funge-98 segments; not a whole-program Native interpreter.
"""
import argparse
import collections
import hashlib
import json
from pathlib import Path

BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"
PROJECT = "PC-BRANCH-BEFUNGE98-KYRGYZ"
FOCUS_ROWS = (2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38)
P_SITES = [(58,2),(106,2),(154,2),(202,2),(60,5),
           (200,14),(248,14),(152,26),(248,26),(296,26),
           (344,26),(152,35),(248,35)]
TARGETS = (20, 23, 29, 32)
WS = frozenset((9,10,13,32))


def require(ok, why):
    if not ok:
        raise AssertionError(why)


def git_blob(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def load_source(raw):
    require(git_blob(raw) == BLOB, "source Git blob mismatch")
    rows = raw.splitlines()
    require(len(rows) == 2015 and rows[49] == b"", "source row layout changed")
    points = [(x,y) for y,row in enumerate(rows) for x,c in enumerate(row) if c == ord("p")]
    focus = [(x,y) for x,y in points if y < 45]
    outer = [(x,y) for x,y in points if y >= 45]
    require(points[:13] == P_SITES and focus == P_SITES, "first 45 rows p-site mismatch")
    require(len(points) == 57 and len(outer) == 44, "source-wide glyph-p inventory changed")
    return rows, outer


def space(q=0, m=0, byte=32):
    return {(0,49):byte,(1,49):q,(2,49):0,(3,49):m,(4,49):0}


def run_row(rows, entry, cells, stdin_byte=None):
    """Original-source linear region, fresh empty stack. Fail closed on unknown control."""
    x,y,dx,dy = 10,entry,1,0
    stack = []
    puts = []
    gets = []
    def pop():
        return stack.pop() if stack else 0
    def source_cell(a,b):
        return rows[b][a] if 0 <= b < len(rows) and 0 <= a < len(rows[b]) else 32
    for tick in range(1,550):
        require(0<=y<len(rows) and 0<=x<len(rows[y]),
                "source vector left modeled segment")
        op = chr(rows[y][x])
        if op in "0123456789abcdef":
            stack.append(int(op,16))
        elif op in "+-*":
            b,a=pop(),pop()
            stack.append(a+b if op=="+" else a-b if op=="-" else a*b)
        elif op == chr(96):
            b,a=pop(),pop();stack.append(int(a>b))
        elif op=="!":
            stack.append(int(pop()==0))
        elif op=="g":
            yy,xx=pop(),pop()
            v=cells.get((xx,yy),source_cell(xx,yy))
            stack.append(v)
            gets.append([x,y,xx,yy,v])
        elif op=="p":
            yy,xx,v=pop(),pop(),pop()
            cells[xx,yy]=v
            puts.append([x,y,xx,yy,v])
        elif op=="j":
            n=pop();x+=n*dx;y+=n*dy
        elif op=="x":
            dy,dx=pop(),pop()
        elif op==">":
            dx,dy=1,0
        elif op=="#":
            x+=dx;y+=dy
        elif op=="~":
            require(entry==5 and stdin_byte is not None and
                    isinstance(stdin_byte,int) and 0<=stdin_byte<=255,
                    "modeled stdin cannot be EOF or negative")
            stack.append(stdin_byte)
        elif op!=" ":
            raise AssertionError(f"unmodeled opcode {op!r} at {(x,y)}")
        x+=dx;y+=dy
        if y!=entry:
            require(not stack, "nonempty stack at canonical region boundary")
            return {"entry":entry,"exit":[x,y],"steps":tick,"puts":puts,
                    "gets":gets}
    raise AssertionError("source segment exceeded 549 STEP")


def conditional_edges(rows):
    records=[]
    # Source-only independent entry probes, not natural-input witnesses.
    for b in range(256):
        for row in (5,8,17):
            mem=space(2,1,b)
            t=run_row(rows,row,mem,b if row==5 else None)
            records.append({"entry":row,"parameter":{"byte":b},
                            "exit":t["exit"],"puts":t["puts"]})
    for q in range(7):
        for m in (0,1):
            for row in (11,14,20,23,26,29,32,35,38):
                mem=space(q,m,48)
                t=run_row(rows,row,mem)
                records.append({"entry":row,"parameter":{"q":q,"m":m},
                                "exit":t["exit"],"puts":t["puts"]})
    init=run_row(rows,2,space(0,0))
    records.append({"entry":2,"parameter":{"reset":True},
                    "exit":init["exit"],"puts":init["puts"]})
    require(len(records)==895, "conditional source probe case count")
    owners={"q":[],"m":[]}
    for item in records:
        for px,py,xx,yy,v in item["puts"]:
            if (xx,yy)==(1,49):
                owners["q"].append((px,py))
            if (xx,yy)==(3,49):
                owners["m"].append((px,py))
    unique={k:sorted(set(v)) for k,v in owners.items()}
    require(unique=={"q":[(106,2),(248,26),(248,35)],
                    "m":[(202,2),(248,14),(344,26)]},
            "conditional source q/m writer locations changed")
    pred={str(y):sorted(set(item["entry"] for item in records
                         if item["exit"]==[10,y])) for y in TARGETS}
    require(pred=={"20":[17],"23":[20],"29":[],"32":[29]},
            "modeled predecessor set mismatch")
    return records, unique, pred


def run_cycle(rows, q, m, byte):
    mem=space(q,m)
    line=5; path=[]; total=0
    for _ in range(8):
        path.append(line)
        require(line in FOCUS_ROWS, "unexpected source region on canonical input route")
        step=run_row(rows,line,mem,byte if line==5 else None)
        total+=step["steps"]
        require(step["exit"][0]==10, "noncanonical x on input-cycle boundary")
        line=step["exit"][1]
        if line in (5,44):
            return {"start":[q,m],"byte":byte,"path":path,"exit_row":line,
                    "after":[mem[1,49],mem[3,49]],"steps":total}
    raise AssertionError("canonical input cycle exceeds eight source rows")


def class_of(byte):
    return "digit" if 48<=byte<=57 else "space" if byte in WS else "other"


def canonical_closure(rows):
    # Discover canonical q,m states using actual original-source transitions.
    sample=(48,32,65)
    pending=collections.deque([(0,0)])
    found={(0,0)}
    while pending:
        q,m=pending.popleft()
        for b in sample:
            a=run_cycle(rows,q,m,b)
            if a["exit_row"]==5:
                target=tuple(a["after"])
                require(0<=target[0]<=4 and target[1] in (0,1),
                        "new canonical state outside finite domain")
                if target not in found:
                    found.add(target);pending.append(target)
    states=sorted(found)
    require(states==[(0,0),(0,1),(1,0),(1,1),(2,0),
                     (2,1),(3,0),(3,1),(4,0)],
            "canonical state closure differs")
    cases=[]
    reference={}
    for q,m in states:
        for b in sample:
            reference[(q,m,class_of(b))]=run_cycle(rows,q,m,b)
        for b in range(256):
            actual=run_cycle(rows,q,m,b)
            model=reference[(q,m,class_of(b))]
            require(actual["exit_row"]==model["exit_row"] and
                    actual["after"]==model["after"] and
                    actual["path"]==model["path"],
                    f"nonuniform byte classification q={q} m={m} byte={b}")
            cases.append(actual)
    require(len(cases)==2304,"full canonical-state by byte count")
    require(all(a["exit_row"] not in (23,29,32) for a in cases),
            "unseen inner entry in canonical cycles")
    assert all(not (q>3 and m==1) for q,m in states)
    return states,cases


def test_controls(rows):
    caught=0
    for x,y in ((106,2),(202,2),(60,5),(248,14),(248,26),
                (344,26),(248,35)):
        altered=[bytearray(z) for z in rows]
        altered[y][x]=ord(" ")
        # Independent geometric pin check for source p positions.
        try:
            require(all(altered[py][px]==ord("p") for px,py in P_SITES),
                    "original source p site mutation")
        except AssertionError:
            caught+=1
        else:raise AssertionError("source p mutation evaded source-site check")
    require(caught==7,"source control count")
    return caught


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",required=True);ap.add_argument("--out",required=True)
    a=ap.parse_args()
    rows,outer=load_source(Path(a.source).read_bytes())
    entries,writers,pred=conditional_edges(rows)
    states,cases=canonical_closure(rows)
    controls=test_controls(rows)
    document={
        "schema":"qa31ak-source-conditional-writer-closure-v1",
        "project_id":PROJECT,"source_blob":BLOB,
        "raw_p_glyphs_full_source":57,
        "raw_p_glyphs_rows_0_to_44":13,
        "raw_p_glyphs_outside_focus":44,
        "outside_focus_p_sites":outer,
        "outside_focus_memory_write_targets":"UNKNOWN - source glyph inventory only",
        "canonical_q_m_source_writer_sites":writers,
        "conditional_source_probe_cases":len(entries),
        "conditional_predecessors_of_20_23_29_32":pred,
        "conditional_probe_records":entries,
        "canonical_source_reachable_q_m_states":[list(s) for s in states],
        "canonical_state_byte_cases":len(cases),
        "canonical_per_byte_probes":cases,
        "induction_scope":"conditional row5 canonical empty-stack entry, exact unchanged source, nonnegative 0..255 byte returns, no alternative IP ingress",
        "canonical_no_q_gt3_and_m1":True,
        "forward_hostile_source_mutations_rejected":controls,
        "new_native_runs":0,"original_native_replayed":False,
        "global_reachability_proven":False,"stage1_pass":False
    }
    Path(a.out).write_text(json.dumps(document,sort_keys=True,
                                      separators=(",",":"))+"\n",encoding="utf-8")
    print("QA31AK_SOURCE_WRITERS",57,13,44,
          "SOURCE_PROBES",len(entries),"CANONICAL_STATES",len(states),
          "STATE_BYTE_CASES",len(cases),"HOSTILE_SOURCE",controls)
    print("QA31AK_PREDECESSORS",pred)
    print("QA31AK_FINITE_CONDITIONAL_NOT_NATIVE_OR_GLOBAL_PASS")


if __name__=="__main__":
    main()
