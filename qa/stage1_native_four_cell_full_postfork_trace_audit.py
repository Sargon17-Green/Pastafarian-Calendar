#!/usr/bin/env python3
"""Independent complete post-| BF98 Native route + mutable byte verifier.

Four independent valid inputs, both Native branch directions, every IP step
from executed | to actual halt. Source-byte lifecycle is reconstructed from
the pinned BF98 candidate and chronologically preceding Native p writes.
No Python calendar arithmetic, no universal acceptance or production update.
"""
import copy,hashlib,json,sys
from collections import Counter,defaultdict
from pathlib import Path

SCHEMA="befunge-stage1-four-cell-native-full-postfork-trace-v1"
SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
CASES=("zero_equal","foundation_cross","forward_short","mixed_small")
OPS=("|","_","[","]","r","w","k","j","{","}","u","p","g","x")
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def gitblob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
def integer(s):
    return type(s) is str and (s=="0" or
        (bool(s) and s[0] in "123456789" and s.isdigit()) or
        (len(s)>1 and s[0]=="-" and s[1] in "123456789" and s[1:].isdigit()))

def verify_run(run,source):
    need(type(run) is dict and run.get("status")=="normal"
         and run.get("remaining_ips")==0
         and type(run.get("steps")) is int and 0<run["steps"]<=750000,
         "Native full-route execution/termination invalid")
    gate=run.get("gate")
    need(type(gate) is dict and type(gate.get("step")) is int
         and 0<gate["step"]<run["steps"]
         and type(gate.get("original")) is int and gate["original"] in (0,1)
         and type(gate.get("executed")) is int and gate["executed"] in (0,1),
         "Native fork operand/step witness invalid")
    trace=run.get("complete_postfork_trace")
    prefix=run.get("first_512_motion")
    need(type(trace) is list and len(trace)==run["steps"]-gate["step"]
         and len(trace)>512 and type(prefix) is list and len(prefix)==512,
         "complete post-fork Native trace truncated or inflated")
    writes=run.get("native_p_history")
    reads=run.get("native_g_history")
    need(type(writes) is list and type(reads) is list
         and type(run.get("total_p_writes")) is int
         and type(run.get("total_g_reads")) is int
         and len(writes)==run["total_p_writes"]
         and len(reads)==run["total_g_reads"],
         "Native p/g chronology counts missing")
    def source_byte(coord):
        x,y=coord
        if 0<=y<len(source) and 0<=x<len(source[y]):return source[y][x]
        return 32
    def events_of(seq,kind):
        last=0;events=[]
        for entry in seq:
            need(type(entry) is dict and type(entry.get("tick")) is int
                 and 1<=entry["tick"]<=run["steps"]
                 and entry["tick"]>last
                 and type(entry.get("coordinate")) is list
                 and len(entry["coordinate"])==2
                 and all(type(v) is int for v in entry["coordinate"]),
                 "Native "+kind+" coordinate/tick invalid")
            tick=entry["tick"]
            last=tick
            if kind=="p":
                need(integer(entry.get("value")),
                     "Native p-written value malformed")
            else:
                need(integer(entry.get("read_before"))
                     and integer(entry.get("returned"))
                     and entry["read_before"]==entry["returned"],
                     "Native g returned incorrect claimed read-before")
            events.append((tick,kind,tuple(entry["coordinate"]),entry))
        return events
    events=sorted(events_of(writes,"p")+events_of(reads,"g"))
    need(len({event[0] for event in events})==len(events),
         "one Native step cannot execute p and g simultaneously")
    # Independent complete p/g read-after-write reconstruction, including
    # all event ticks before the conditional fork.
    current={}
    for tick,kind,coord,entry in events:
        if kind=="p":current[coord]=int(entry["value"])
        else:
            need(int(entry["returned"])==current.get(coord,source_byte(coord)),
                 "Native g violates independent mutable-space write chronology")
    events_by_tick={e[0]:e for e in events}
    first_tick=gate["step"]+1
    current={}
    for tick,kind,coord,entry in events:
        if tick>=first_tick:break
        if kind=="p":current[coord]=int(entry["value"])
    nodes=set();edges=defaultdict(set);vectors=defaultdict(set)
    prior=None
    beyond512=set()
    executed_modified=0;ops=Counter()
    for i,datum in enumerate(trace):
        need(type(datum) is list and len(datum)==7
             and all(type(value) is int for value in datum),
             "Native full execution event has invalid type or shape")
        tick,x,y,dx,dy,byte,stringmode=datum
        need(tick==first_tick+i and (dx!=0 or dy!=0)
             and stringmode in (0,1),
             "Native exact IP execution chronology or vector malformed")
        xy=(x,y)
        original=source_byte(xy)
        need(byte==current.get(xy,original),
             "Native executed instruction does not match chronological p-mutated Funge-space")
        if byte!=original:executed_modified+=1
        if i<512:
            need(datum[1:5]==prefix[i],
                 "complete Native trace contradicts independent bounded observer")
        node=(x,y,dx,dy)
        nodes.add(node)
        vectors[xy].add((dx,dy))
        if i>=512:beyond512.add(node)
        if prior is not None:edges[prior].add(node)
        prior=node
        if stringmode==0 and byte in map(ord,OPS):
            ops[chr(byte)]+=1
        event=events_by_tick.get(tick)
        if event is not None:
            kind=event[1]
            need(byte==ord(kind),
                 "Native claimed p/g instruction does not match executed byte")
            if kind=="p":current[event[2]]=int(event[3]["value"])
    need(len(beyond512)>0,"full Native run added no states outside the prior window")
    return {
       "complete_postfork_events":len(trace),
       "unique_directed_nodes":len(nodes),
       "unique_edges":sum(len(v) for v in edges.values()),
       "fork_nodes":sum(len(v)>1 for v in edges.values()),
       "coordinates_with_multiple_directions":sum(
           len(v)>1 for v in vectors.values()),
       "states_visited_after_step_512":len(beyond512),
       "verified_p_writes":len(writes),
       "verified_g_reads":len(reads),
       "executed_modified_code_byte_events":executed_modified,
       "observed_native_control_opcode_counts":{op:ops[op] for op in OPS},
       "complete_trace_sha256":hashlib.sha256(
           json.dumps(trace,separators=(",",":")).encode("ascii")).hexdigest()
    }

def verify(doc,source):
    need(type(doc) is dict and doc.get("schema")==SCHEMA
         and doc.get("status")=="QA_ONLY_COMPLETE_POSTFORK_FOUR_INPUT_PAIRS_STAGE1_OPEN"
         and doc.get("source_git_blob")==SOURCE
         and doc.get("candidate_git_blob")==CANDIDATE
         and doc.get("selected_cases")==list(CASES)
         and doc.get("native_executions")==8
         and type(doc.get("last_completed_stage")) is int
         and doc["last_completed_stage"]==0
         and doc.get("stage1_complete") is False
         and doc.get("full_functional_acceptance") is False
         and doc.get("geometric_acceptance") is False
         and doc.get("automatic_promotion") is False,
         "Native execution report source or acceptance scope forged")
    rows=doc.get("records")
    need(type(rows) is list and len(rows)==4
         and [r.get("label") for r in rows]==list(CASES),
         "four distinct selected Native input pairs missing")
    result=[]
    for row in rows:
        ref=row.get("reference_7")
        a=row.get("control");b=row.get("forced")
        need(type(ref) is list and len(ref)==7
             and all(integer(v) for v in ref)
             and type(a) is dict and type(b) is dict
             and a.get("output")==ref
             and type(row.get("changed_final_output")) is bool
             and row["changed_final_output"]==(b.get("output")!=ref),
             "Native original seven-field oracle or causal outcome altered")
        ga=a.get("gate");gb=b.get("gate")
        need(type(ga) is dict and type(gb) is dict
             and ga.get("step")==gb.get("step")
             and ga.get("original")==ga.get("executed")==gb.get("original")
             and gb.get("executed")==1-ga.get("executed"),
             "Native original and forced opposite physical gate disagree")
        result.append({"label":row["label"],
                       "control":verify_run(a,source),
                       "forced":verify_run(b,source),
                       "changed_final_output":row["changed_final_output"]})
    need(sum(int(x["changed_final_output"]) for x in result)==2,
         "2 expected output-causal genuine fork interventions not reproduced")
    return result

def main(folder):
    root=Path(folder)
    src=(root/"four_cell_candidate.b98").read_bytes()
    need(gitblob(src)==CANDIDATE,"BF98 test-only candidate blob mismatch")
    source=src.split(b"\n")
    data=json.loads((root/"native_full_postfork_four_pairs.json").read_text("utf-8"))
    measured=verify(data,source)
    tamper=[
        ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        ("stage",lambda d:d.__setitem__("stage1_complete",True)),
        ("case",lambda d:d["records"].pop()),
        ("gate",lambda d:d["records"][0]["forced"]["gate"].__setitem__(
            "executed",d["records"][0]["control"]["gate"]["executed"])),
        ("step",lambda d:d["records"][0]["control"][
            "complete_postfork_trace"][100].__setitem__(0,0)),
        ("opcode",lambda d:d["records"][0]["control"][
            "complete_postfork_trace"][100].__setitem__(5,255)),
        ("direction",lambda d:d["records"][0]["control"][
            "complete_postfork_trace"][100].__setitem__(3,0)),
        ("direction_stopped",lambda d:d["records"][0]["control"][
            "complete_postfork_trace"][100].__setitem__(4,0)),
        ("prefix",lambda d:d["records"][0]["control"][
            "first_512_motion"][100].__setitem__(0,999999)),
        ("p",lambda d:d["records"][0]["control"][
            "native_p_history"][0].__setitem__("value","BOGUS")),
        ("g",lambda d:d["records"][0]["control"][
            "native_g_history"][0].__setitem__("returned","BOGUS")),
        ("truncated",lambda d:d["records"][0]["forced"][
            "complete_postfork_trace"].pop())
    ]
    # Both direction mutations may target a vector whose other component is
    # nonzero. Force the whole delta to zero for the direction forgery.
    def bad_dir(d):
        p=d["records"][0]["control"]["complete_postfork_trace"][100]
        p[3]=0;p[4]=0
    tamper[6]=("forged_zero_vector",bad_dir)
    tamper.pop(7)
    rejected=[]
    for name,mutation in tamper:
        false=copy.deepcopy(data)
        mutation(false)
        try:verify(false,source)
        except (AssertionError,KeyError,IndexError,TypeError):
            rejected.append(name)
        else:raise AssertionError("accepted falsified complete Native trajectory: "+name)
    need(len(rejected)==11,"full Native post-fork tamper suite incomplete")
    summary={
      "schema":"befunge-stage1-four-pair-complete-native-postfork-audit-v1",
      "scope":"FOUR_VALID_INPUT_PAIRS_COMPLETE_POSTFORK_UNTIL_HALT",
      "not_all_possible_inputs":True,
      "pre_fork_trajectory_not_included":True,
      "stage1_complete":False,
      "full_functional_acceptance":False,
      "geometric_acceptance":False,
      "automatic_promotion":False,
      "runs":measured,"falsifications_rejected":rejected}
    (root/"full_postfork_independent_audit.json").write_text(
        json.dumps(summary,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_EIGHT_COMPLETE_POSTFORK_TRAJECTORIES_SOURCE_BYTE_REPLAY_PASS",
          json.dumps([{"case":r["label"],
                       "control":r["control"]["complete_postfork_events"],
                       "forced":r["forced"]["complete_postfork_events"]}
                      for r in measured],sort_keys=True))
    print("NATIVE_FULL_POSTFORK_ELEVEN_FALSIFICATIONS_REJECT_PASS")
    print("CURRENT_STAGE=1 LAST_COMPLETED_STAGE=0 GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    need(len(sys.argv)==2,"complete native postfork artifact folder required")
    main(sys.argv[1])
