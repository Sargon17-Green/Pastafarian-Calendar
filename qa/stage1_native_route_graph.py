#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Stage 1 native IP geometry / mutable-cell lifecycle evidence.

Analyzes *actual* PyFunge sitecustomize.py trace events. It is not a
calendar implementation, an oracle, or a substitute for the native runner.

The directed graph connects *observed successive* instruction positions;
transitions are labelled as observed edges, not falsely as adjacent cells:
dynamic vectors, #/j and Funge-space wrapping may skip coordinates.

For each STEP, the opcode is checked against the original source map plus
every prior completed native p write. Read/write event pairs are checked
against exactly that time-ordered memory image. An executable-cell rewrite
counts only when an actual subsequent STEP executes the written cell.
"""
import collections
import json
import os
import sys
import tempfile

FIELDS={"STEP":8,"READ_BEFORE":4,"READ_AFTER":4,
        "WRITE_BEFORE":5,"WRITE_AFTER":4}

def require(ok, message):
    if not ok:
        raise AssertionError(message)

def load_source(path):
    with open(path,"rb") as stream:
        data=stream.read()
    return data.decode("ascii").splitlines()

def initial_byte(rows,x,y):
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return ord(rows[y][x])
    return 32

def axis(a,b):
    dx=b[0]-a[0]
    dy=b[1]-a[1]
    if dx and not dy: return "horizontal"
    if dy and not dx: return "vertical"
    return "diagonal_or_standstill"

def analyze(rows,trace_path):
    changed={}
    pending_reads={}
    pending_writes={}
    latest_written={}
    write_history=[]
    ip_ids=set()
    current_step=0
    previous_step=None
    handoff=False
    incoming=collections.defaultdict(set)
    outgoing=collections.defaultdict(set)
    edges=collections.Counter()
    direction_by_position=collections.defaultdict(set)
    visits=collections.Counter()
    stats=collections.Counter()
    after=collections.Counter()
    opcodes=collections.Counter()
    arithmetic_opcodes=collections.Counter()
    compass=set()
    arith_compass=set()
    read_locations=collections.Counter()
    write_locations=collections.Counter()
    arith_points=set()
    arith_edges=set()
    executed_changed=0
    executed_written=0
    event_log_count=0

    with open(trace_path,"r",encoding="utf-8") as stream:
        for line_no,line in enumerate(stream,1):
            if not line.strip(): continue
            parts=line.rstrip("\n").split("\t")
            tag=parts[0]
            require(tag in FIELDS,"unknown trace event at line %d: %r" % (line_no,tag))
            require(len(parts)==FIELDS[tag]+1,
                    "invalid %s record width at line %d" % (tag,line_no))
            try:
                vals=tuple(int(x) for x in parts[1:])
            except ValueError:
                raise AssertionError("noninteger trace field at line %d" % line_no)
            event_log_count+=1

            if tag=="STEP":
                tick,ip,x,y,dx,dy,opcode,depth=vals
                current_step+=1
                require(tick==current_step,"nonsequential native STEP tick")
                require(depth>=0,"negative native stack depth")
                # In a single-IP --no-concurrent native run a zero vector
                # makes x/y stationary and can silently spin forever.
                # The strict rank-unrank candidate exposed this exact failure
                # in its separate native IP diagnostic.
                require((dx,dy)!=(0,0),
                        "native zero-velocity IP (nonprogress), tick=%d cell=(%d,%d)"%
                        (tick,x,y))
                ip_ids.add(ip)
                point=(x,y)
                actual=changed.get(point,initial_byte(rows,x,y))
                require(opcode==actual,
                        "executed memory-byte mismatch tick=%d (%d,%d) actual=%d logged=%d" %
                        (tick,x,y,actual,opcode))
                stats["steps"]+=1
                visits[point]+=1
                direction_by_position[point].add((dx,dy))
                opcodes[opcode]+=1
                compass.add((dx,dy))
                if point==(5,0) and (dx,dy)==(1,0) and not handoff:
                    handoff=True
                if handoff:
                    stats["arithmetic_steps"]+=1
                    arith_points.add(point)
                    arithmetic_opcodes[opcode]+=1
                    arith_compass.add((dx,dy))
                if previous_step is not None:
                    prev_tick,prev_pt,prev_handoff=previous_step
                    edge=(prev_pt[0],prev_pt[1],x,y)
                    edges[edge]+=1
                    incoming[point].add(prev_pt)
                    outgoing[prev_pt].add(point)
                    if prev_handoff and handoff:
                        arith_edges.add(edge)
                previous_step=(tick,point,handoff)
                if point in latest_written:
                    index=latest_written.pop(point)
                    record=write_history[index]
                    require(tick>record["tick"],
                            "executed write is not strictly later")
                    record["later_executed_tick"]=tick
                    executed_written+=1
                    if record["before"]!=record["after"]:
                        executed_changed+=1
                continue

            tick=vals[0]
            require(tick==current_step,
                    "native read/write event detached from current STEP")
            require(previous_step is not None,"native event without STEP")
            if tag=="READ_BEFORE":
                _,x,y,logged=vals
                point=(x,y)
                expected=changed.get(point,initial_byte(rows,x,y))
                require(logged==expected,
                        "g read does not match versioned Funge-space at tick=%d" % tick)
                require(tick not in pending_reads,"duplicate native read")
                pending_reads[tick]=(point,logged)
                read_locations[point]+=1
                stats["reads"]+=1
            elif tag=="READ_AFTER":
                _,x,y,actual=vals
                require(tick in pending_reads,"READ_AFTER missing READ_BEFORE")
                point,expected=pending_reads.pop(tick)
                require(point==(x,y) and expected==actual,
                        "g returned unexpected cell value at tick=%d" % tick)
                stats["reads_completed"]+=1
            elif tag=="WRITE_BEFORE":
                _,x,y,before,value=vals
                point=(x,y)
                expected=changed.get(point,initial_byte(rows,x,y))
                require(expected==before,
                        "p write before-image differs from runtime memory tick=%d" % tick)
                require(tick not in pending_writes,"duplicate native write")
                pending_writes[tick]=(point,before,value)
                write_locations[point]+=1
                stats["writes"]+=1
            elif tag=="WRITE_AFTER":
                _,x,y,actual=vals
                require(tick in pending_writes,"WRITE_AFTER missing WRITE_BEFORE")
                point,old,desired=pending_writes.pop(tick)
                require(point==(x,y) and actual==desired,
                        "p after-image mismatched actual value")
                changed[point]=actual
                if point in latest_written:
                    write_history[latest_written[point]]["overwritten_before_execution"]=True
                latest_written[point]=len(write_history)
                write_history.append({
                    "tick":tick,"x":x,"y":y,"before":old,"after":actual,
                    "source_byte":initial_byte(rows,x,y),
                    "later_executed_tick":None,
                    "overwritten_before_execution":False})
                stats["writes_completed"]+=1
                if old!=actual:stats["effective_changes"]+=1

    require(not pending_reads and not pending_writes,"unpaired native g/p records")
    require(len(ip_ids)==1,"multi-IP trace needs explicit per-IP edge separation")
    require(stats["reads"]==stats["reads_completed"],"incomplete g pair")
    require(stats["writes"]==stats["writes_completed"],"incomplete p pair")
    require(stats["steps"]>0,"missing actual interpreter steps")
    require(handoff,"arithmetic handoff not reached")
    intersections={p:(len(incoming[p]),len(outgoing[p])) for p in visits
                   if len(incoming[p])>=2 and len(outgoing[p])>=2}
    multi_delta={p for p,ds in direction_by_position.items() if len(ds)>=2}
    executed_gate_records=[w for w in write_history if w["later_executed_tick"] is not None]
    graph=[
        {"from":[x,y],"to":[xx,yy],"observations":count,
         "axis":axis((x,y),(xx,yy))}
        for (x,y,xx,yy),count in sorted(edges.items())
    ]
    source_map=[
        {"x":x,"y":y,"initial_byte":initial_byte(rows,x,y),
         "final_byte":changed.get((x,y),initial_byte(rows,x,y)),
         "visits":visits[(x,y)],
         "arrival_velocity_count":len(direction_by_position[(x,y)])}
        for (x,y) in sorted(visits)
    ]
    stats.update({
        "unique_coordinates":len(visits),
        "revisits":stats["steps"]-len(visits),
        "unique_directed_edges":len(edges),
        "repeated_directed_edges":sum(v-1 for v in edges.values()),
        "arithmetic_unique_coordinates":len(arith_points),
        "arithmetic_unique_directed_edges":len(arith_edges),
        "native_ip_ids":len(ip_ids),
        "executed_gate_writes":executed_written,
        "executed_content_changing_gate_writes":executed_changed,
        "multi_velocity_coordinates":len(multi_delta),
        "graph_merge_and_fork_nodes":len(intersections),
        "unique_read_targets":len(read_locations),
        "unique_write_targets":len(write_locations),
        "unique_compass_vectors":len(compass),
        "native_trace_events":event_log_count
    })
    require(stats["revisits"]>0 and stats["unique_directed_edges"]>0,
            "no meaningful traversed geometry")
    require(stats["executed_content_changing_gate_writes"]>=1,
            "no later-executed changed executable cells")
    require(stats["arithmetic_unique_coordinates"]>1000,
            "arithmetic path too small for existing 2D geometry contract")
    return {
        "schema":"befunge-native-route-graph-v1",
        "source_height":len(rows),
        "source_max_width":max(map(len,rows)),
        "statistics":dict(stats),
        "all_executed_opcodes":{chr(k) if 32<=k<=126 else str(k):v
                                for k,v in sorted(opcodes.items())},
        "arithmetic_executed_opcodes":{chr(k) if 32<=k<=126 else str(k):v
                                       for k,v in sorted(arithmetic_opcodes.items())},
        "all_velocities":[list(p) for p in sorted(compass)],
        "arithmetic_velocities":[list(p) for p in sorted(arith_compass)],
        "merge_fork_nodes":[{"x":x,"y":y,"incoming":a,"outgoing":b}
                            for (x,y),(a,b) in sorted(intersections.items())],
        "multi_velocity_nodes":[list(p) for p in sorted(multi_delta)],
        "read_targets":[{"x":x,"y":y,"count":n}
                        for (x,y),n in sorted(read_locations.items())],
        "write_targets":[{"x":x,"y":y,"count":n}
                         for (x,y),n in sorted(write_locations.items())],
        "native_write_lifecycle":write_history,
        "observed_directed_edges":graph,
        "executed_source_map":source_map
    }

def selftest():
    rows=["12+.@"]
    with tempfile.TemporaryDirectory() as directory:
        trace=os.path.join(directory,"tiny.tsv")
        with open(trace,"w",encoding="utf-8") as stream:
            for i,ch in enumerate(rows[0],1):
                stream.write("STEP\t%d\t1\t%d\t0\t1\t0\t%d\t1\n" %
                             (i,i-1,ord(ch)))
        # Tiny synthetic smoke validates the memory-address mismatch rejection;
        # real geometric gates run only on native trace files.
        try:
            analyze(rows,trace)
        except AssertionError as err:
            require("arithmetic handoff" in str(err),
                    "unexpected selftest error: %s" % err)
        else:
            raise AssertionError("synthetic input incorrectly passed native geometry gate")
        # Adversarial negative: reject a stationary IP, even if the
        # byte at the position is otherwise a valid Befunge opcode.
        with open(trace,"w",encoding="utf-8") as stream:
            stream.write("STEP\\t1\\t1\\t0\\t0\\t0\\t0\\t49\\t1\\n")
        try:
            analyze(rows,trace)
        except AssertionError as err:
            require("zero-velocity IP" in str(err),
                    "stationary native IP did not trip its exact guard")
        else:
            raise AssertionError("native zero-velocity IP falsely passed audit")
    print("NATIVE_ROUTE_GRAPH_ZERO_VELOCITY_NEGATIVE_CONTROL_PASS")
    print("NATIVE_ROUTE_GRAPH_SELFTEST_PASS")

def main(argv):
    if len(argv)==2 and argv[1]=="--selftest":
        selftest()
        return
    if len(argv)!=4:
        raise SystemExit("usage: stage1_native_route_graph.py SOURCE.b98 INPUT.tsv OUTPUT.json")
    source,trace,output=argv[1:]
    report=analyze(load_source(source),trace)
    with open(output,"w",encoding="utf-8") as stream:
        json.dump(report,stream,ensure_ascii=True,sort_keys=True,separators=(",",":"))
        stream.write("\n")
    print("NATIVE_STAGE1_DIRECTED_GRAPH_EVIDENCE_PASS",
          json.dumps(report["statistics"],sort_keys=True))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (additional opcode paths and full acceptance remain open)")

if __name__=="__main__":
    main(sys.argv)
