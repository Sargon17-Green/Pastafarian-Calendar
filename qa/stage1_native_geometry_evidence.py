#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fail-closed observational native geometry evidence, NOT final Stage-1 acceptance.

Only native PyFunge STEP and p/g events are authoritative here. Calculate
executed (not static) path coverage, directions, edge revisits and actual
post-write re-execution. Produce compact heatmaps that show measured executed
cells, not invented or unused source routes. No calendar math in Python.

Invocation: python3 qa/stage1_native_geometry_evidence.py TRACE_DIR
"""
import collections
import hashlib
import json
import os
import sys

HANDOFF = (5, 0)
WATCHED = "_|[]rwjk{}ut()"
FORBIDDEN_EXTERNAL = "io="
DIRECTIONS = ((1,0),(-1,0),(0,1),(0,-1))

def require(ok, why):
    if not ok:
        raise AssertionError(why)

def load_trace(path):
    points=[]
    writes_before={}
    writes=[]
    rd=wr=0
    sha=hashlib.sha256()
    with open(path,"rb") as stream:
        for line in stream:
            sha.update(line)
            fields=line.decode("ascii").strip().split("\t")
            tag=fields[0]
            require(tag in ("STEP","READ_BEFORE","READ_AFTER",
                            "WRITE_BEFORE","WRITE_AFTER"),
                    "unexpected native trace tag "+tag)
            numbers=tuple(int(t) for t in fields[1:])
            if tag=="STEP":
                require(len(numbers)==8,"invalid STEP layout")
                points.append(numbers)
            elif tag=="READ_BEFORE":
                rd+=1
            elif tag=="WRITE_BEFORE":
                require(len(numbers)==5,"invalid write-before")
                tick,x,y,old,new=numbers
                require(tick not in writes_before,"duplicate write tick")
                writes_before[tick]=(x,y,old,new)
            elif tag=="WRITE_AFTER":
                require(len(numbers)==4,"invalid write-after")
                tick,x,y,actual=numbers
                require(tick in writes_before,"unpaired native write-after")
                bx,by,old,new=writes_before.pop(tick)
                require((bx,by,new)==(x,y,actual),"write after differs")
                writes.append((tick,x,y,old,new))
                wr+=1
    require(not writes_before,"unfinished native write events")
    require(points and all(tick==i+1 for i,(tick,*_) in enumerate(points)),
            "nonmonotone or empty native STEP stream")
    idx=next((i for i,(_,_,x,y,*rest) in enumerate(points)
              if (x,y)==HANDOFF),None)
    require(idx is not None,"no arithmetic handoff")
    post=points[idx:]
    require(post[0][4:6]==(1,0),"invalid handoff direction")
    require(len(set(p[1] for p in post))==1,"multiple native IP identities")
    return {"sha256":sha.hexdigest(),"post":post,"pre_steps":idx,
            "trace_steps":len(points),"native_g_reads":rd,
            "native_p_writes":wr,"writes":writes}

def summarize(data):
    steps=data["post"]
    ops=collections.Counter(chr(op) if 32<=op<=126 else "NON_ASCII"
                            for tick,ip,x,y,dx,dy,op,depth in steps)
    unique=set((x,y) for tick,ip,x,y,dx,dy,op,depth in steps)
    dirs=collections.Counter((dx,dy) for _,_,_,_,dx,dy,_,_ in steps)
    per_cell=collections.defaultdict(set)
    directed_edges=collections.Counter()
    for i,event in enumerate(steps):
        tick,ip,x,y,dx,dy,op,depth=event
        per_cell[(x,y)].add((dx,dy))
        if i+1<len(steps):
            nxt=steps[i+1]
            directed_edges[((x,y),(nxt[2],nxt[3]))]+=1
    writes=[w for w in data["writes"] if w[0]>=steps[0][0]]
    # For each write, only the most recent pending value at a position
    # controls the subsequent execution; no static source counts accepted.
    pending={}
    last_tick=-1
    executed_gates=[]
    changed_gates=[]
    events=sorted(
        [(s[0],0,s) for s in steps] +
        [(w[0],1,w) for w in writes],
        key=lambda item:(item[0],item[1]))
    for tick,kind,e in events:
        if kind==1:
            pending[(e[1],e[2])]=(tick,e[4],e[3]!=e[4])
        else:
            _,_,x,y,dx,dy,opcode,depth=e
            record=pending.pop((x,y),None)
            if record is not None and tick>record[0]:
                require(opcode==record[1],"modified executable cell differs from native write")
                executed_gates.append((x,y))
                if record[2]:
                    changed_gates.append((x,y))
    xs=[s[2] for s in steps];ys=[s[3] for s in steps]
    counts={
        "post_handoff_steps":len(steps),
        "unique_executed_cells":len(unique),
        "revisited_steps":len(steps)-len(unique),
        "unique_directed_edges":len(directed_edges),
        "repeated_directed_edge_types":sum(n>1 for n in directed_edges.values()),
        "distinct_direction_vectors":len(dirs),
        "cardinal_step_counts":{str(v):dirs[v] for v in DIRECTIONS},
        "non_cardinal_steps":sum(n for v,n in dirs.items() if v not in DIRECTIONS),
        "multi_direction_executed_cells":sum(len(v)>1 for v in per_cell.values()),
        "executed_dynamic_vector_x":ops.get("x",0),
        "executed_p":ops.get("p",0),
        "executed_g":ops.get("g",0),
        "executed_write_then_reexecuted_gate":len(executed_gates),
        "executed_changed_gate":len(changed_gates),
        "executed_conditional_not":ops.get("!",0),
        "advanced_opcode_executions":{key:ops.get(key,0) for key in WATCHED},
        "forbidden_external_opcode_executions":{key:ops.get(key,0) for key in FORBIDDEN_EXTERNAL},
        "bounds":{"min_x":min(xs),"max_x":max(xs),"min_y":min(ys),"max_y":max(ys)}
    }
    require(len(unique)>5000 and counts["revisited_steps"]>2000,
            "native route not sufficiently executed for geometry evidence")
    require(all(dirs[v]>=20 for v in DIRECTIONS),
            "missing meaningful execution of a cardinal direction")
    require(counts["non_cardinal_steps"]>=100 and ops.get("x",0)>=100,
            "dynamic two-axis vectors were not genuinely executed")
    require(ops.get("p",0)>=40 and ops.get("g",0)>=40,
            "mutable native Funge-space evidence missing")
    require(len(executed_gates)>=4 and len(changed_gates)>=2,
            "runtime written executable gate not sufficiently re-executed")
    require(not any(ops.get(ch,0) for ch in FORBIDDEN_EXTERNAL),
            "native execution used prohibited external execution/file operator")
    require(max(xs)-min(xs)>=100 and max(ys)-min(ys)>=100,
            "native execution did not travel across both spatial axes")
    return counts,unique,set(directed_edges),executed_gates,changed_gates

def render_svg(path,title,steps,stats,executed):
    # These SVG tiles represent ONLY cells executed by PyFunge.
    xs=[p[2] for p in steps];ys=[p[3] for p in steps]
    lowx=min(xs);lowy=min(ys)
    width=max(xs)-lowx+1;height=max(ys)-lowy+1
    scale=min(830.0/width,830.0/height)
    tiles=collections.Counter((int((x-lowx)*scale)//6,
                               int((y-lowy)*scale)//6)
                              for tick,ip,x,y,dx,dy,op,depth in steps)
    cells=[]
    for (cx,cy),count in sorted(tiles.items()):
        opacity=min(.87,.16+(.055*min(count,12)))
        cells.append('<rect x="%d" y="%d" width="6" height="6" fill="#394a62" opacity="%.2f"/>'%
                     (30+cx*6,85+cy*6,opacity))
    highlights=set(executed)
    for x,y in sorted(highlights):
        cells.append('<circle cx="%.1f" cy="%.1f" r="4.3" fill="#c15333"/>'%
                     (30+(x-lowx)*scale,85+(y-lowy)*scale))
    meta=[
      ("Executed steps",stats["post_handoff_steps"]),
      ("Executed cells",stats["unique_executed_cells"]),
      ("Revisited steps",stats["revisited_steps"]),
      ("Dynamic vector x",stats["executed_dynamic_vector_x"]),
      ("Native p / g","%d / %d"%(stats["executed_p"],stats["executed_g"])),
      ("Reexecuted gates",stats["executed_write_then_reexecuted_gate"]),
      ("Changed + executed",stats["executed_changed_gate"]),
      ("Spatial crossings",stats["multi_direction_executed_cells"]),
      ("Noncardinal steps",stats["non_cardinal_steps"])
    ]
    legend=["<text x='890' y='%d' font-size='16' fill='#162132'>%s: %s</text>"%
            (120+i*33,k,v) for i,(k,v) in enumerate(meta)]
    svg=("<?xml version='1.0' encoding='utf-8'?>\n"
         "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1250 1010'>"
         "<rect width='1250' height='1010' fill='#f8fafc'/>"
         "<text x='30' y='43' font-size='23' font-family='sans-serif'>%s</text>"
         "<rect x='23' y='77' width='840' height='844' fill='#fff' stroke='#a8b1bf'/>"
         "%s"
         "<g font-family='sans-serif'>%s"
         "<text x='890' y='495' font-size='15' fill='#6b4e40'>Orange: executed modified gates</text>"
         "<text x='890' y='535' font-size='14' fill='#49576a'>Native trace only; no static filler</text>"
         "<text x='890' y='575' font-size='14' fill='#49576a'>NOT full geometry acceptance</text>"
         "</g></svg>\n")%(title,"".join(cells),"".join(legend))
    with open(path,"w",encoding="utf-8") as out:out.write(svg)

def main():
    require(len(sys.argv)==2,"usage: ... TRACE_DIR")
    folder=sys.argv[1]
    labels=("valid","invalid")
    report={
        "claim":"NATIVE_OBSERVED_GEOMETRY_CORE_ONLY_NOT_FULL_SPAGHETTI_ACCEPTANCE",
        "traces":{},
        "known_unproven_geometry":["full end-to-end stage-1 route graph",
            "advanced Funge-98 directional and stack-stack opcodes",
            "crossing and dead-code resistance across broad inputs",
            "full source cell-version lifecycle and geometric acceptance"]}
    coords={}
    for label in labels:
        old=load_trace(os.path.join(folder,label+".tsv"))
        scanner=load_trace(os.path.join(folder,"scanner_"+label+".tsv"))
        new=load_trace(os.path.join(folder,"candidate_"+label+".tsv"))
        metric,positions,edges,gates,changed=summarize(new)
        baseline,old_positions,old_edges,_,_=summarize(old)
        frozen,scanner_positions,scanner_edges,_,_=summarize(scanner)
        # Exact legacy arithmetic route parity remains mandatory for the
        # frozen native lexical-only scanner; it is not silently removed
        # because QA production now executes an approved additional circuit.
        require(frozen==baseline,
                "frozen lexical scanner altered native arithmetic metrics")
        require(scanner_positions==old_positions and scanner_edges==old_edges,
                "frozen scanner changed native post-handoff directed route")
        # Source-level checks and native k+ differential independently pin
        # the circuit. This proof counts ONLY native executed instructions.
        require(metric["advanced_opcode_executions"]["k"]>=1 and
                frozen["advanced_opcode_executions"]["k"]==0,
                "production's arithmetic k detour not actually executed")
        require(any(x==1475 and y==101 and op==ord("k")
                    for tick,ip,x,y,dx,dy,op,depth in new["post"]),
                "expected Native arithmetic k opcode missing at exact cell")
        require((1475,101) in positions and (1475,101) not in scanner_positions,
                "k executed path is not a genuinely new spatial excursion")
        require(len(positions ^ scanner_positions)>=8,
                "native k detour lacked minimum actual geometric impact")
        report["traces"][label]=dict(metric,sha256=new["sha256"],
            baseline_sha256=old["sha256"],
            frozen_scanner_sha256=scanner["sha256"],
            frozen_scanner_post_handoff_exact_parity=True,
            measured_executed_k_detour=metric["advanced_opcode_executions"]["k"],
            new_native_coordinates=len(positions-scanner_positions),
            scanner_steps=new["pre_steps"],baseline_steps=old["pre_steps"],
            native_total_steps=new["trace_steps"])
        render_svg(os.path.join(folder,"candidate_"+label+"_native_route.svg"),
                   "Befunge Stage 1 Native executed "+label+" route",
                   new["post"],metric,changed)
        coords[label]=positions
    require(len(coords["valid"]^coords["invalid"])>50,
            "valid and invalid cases did not show distinct native route behavior")
    report["native_case_executed_coordinate_symmetric_difference"]=len(
        coords["valid"]^coords["invalid"])
    report["advanced_architecture_gate"]="OPEN_NOT_SILENTLY_PASSED"
    with open(os.path.join(folder,"geometry_evidence.json"),"w",
              encoding="utf-8") as stream:
        json.dump(report,stream,sort_keys=True,indent=2)
    print("NATIVE_STAGE1_CORE_GEOMETRY_OBSERVATION_PASS",
          json.dumps({k:report["traces"][k]["post_handoff_steps"]
                      for k in labels},sort_keys=True))
    print("NATIVE_STAGE1_ADVANCED_SPAGHETTI_GEOMETRY_ACCEPTANCE_OPEN",
          "see geometry_evidence.json and two SVG native route maps")
if __name__=="__main__":main()
