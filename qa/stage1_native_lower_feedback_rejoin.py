#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1 QA: actual Native six-input lower feedback semantic rejoin.

One genuinely executed ']' at (951,1336) is substituted with '[' for
EXACTLY ONE native instruction, then immediately restored. Compare actual
first common five consecutive executed motion events, full stack frames,
IP offset/modes, input cursor and p-written Funge-space cells. Record the
18-step shortcut; no Befunge calendar math is computed by Python.
This bounded evidence DOES NOT certify full semantic state or Stage 1.
"""
from __future__ import print_function
import hashlib
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as native

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
GATE=(951,1336)
CASES=("foundation_cross","mixed_small","negative_positive",
       "invalid_zero_sign","foundation_neighbor_forward",
       "foundation_neighbor_reverse")
CAPTURE=256
STEP_LIMIT=210000
OUT="/lower-rejoin/native_lower_feedback_rejoin.json"

def need(ok,why):
    if not ok: raise AssertionError(why)
class Limit(Exception): pass

def sha(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def run(source,raw,mutate):
    output=StringIO.StringIO()
    stdin=StringIO.StringIO(raw)
    program=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=stdin,stdout=output))
    program.load_code(source)
    program.create_ip()
    need(len(program.ips)==1,"native lower loop requires one active IP")
    original_step=program.execute_step
    steps=[0]
    changed_p={}
    post=[]
    gate=[None]
    p_after=[0]
    g_after=[0]
    rows=source.splitlines()
    def initial_byte(x,y):
        if 0<=y<len(rows) and 0<=x<len(rows[y]):
            return ord(rows[y][x])
        return 32
    def snapshot(ip):
        return {
          "motion":[int(ip.position[0]),int(ip.position[1]),
                    int(ip.delta[0]),int(ip.delta[1])],
          "opcode":int(program.space.get(ip.position)),
          "frames":[[str(v) for v in frame] for frame in ip.stack],
          "ip_context":{
              "offset":[int(c) for c in ip.offset],
              "stringmode":bool(ip.stringmode),
              "invertmode":bool(ip.invertmode),
              "queuemode":bool(ip.queuemode),
              "stdin_cursor":int(stdin.tell())
          },
          "p_modified_cells":[[x,y,str(v)] for (x,y),v in sorted(changed_p.items())],
          "stdout_prefix":output.getvalue()
        }
    def hook(self):
        steps[0]+=1
        if steps[0]>STEP_LIMIT:
            raise Limit("bounded native lower-feedback diagnosis")
        if self.ips:
            need(len(self.ips)==1,"no t concurrent IP in lower route")
            ip=self.ips[0]
            xy=tuple(ip.position)
            opcode=int(self.space.get(ip.position))
            if xy==GATE and gate[0] is None:
                need(opcode==ord("]"),"lower feedback source byte no longer ]")
                before=[int(v) for v in ip.delta]
                pt=ip.position.__class__(GATE)
                if mutate:self.space.put(pt,ord("["))
                try: result=original_step()
                finally:
                    if mutate:self.space.put(pt,ord("]"))
                need(int(self.space.get(pt))==ord("]"),
                     "one-time native edited instruction not restored")
                gate[0]={"tick":steps[0],
                         "direction_before":before,
                         "direction_after":[int(v) for v in ip.delta],
                         "executed_opcode":"[" if mutate else "]",
                         "restored":True}
                return result
            if gate[0] is not None and len(post)<CAPTURE:
                post.append(snapshot(ip))
            pending_p=None
            if gate[0] is not None and opcode==ord("p"):
                st=ip.stack[0]
                need(len(st)>=3,"native p has no operands")
                value,x,y=map(int,list(st)[-3:])
                pending_p=(x,y,value,ip.position.__class__((x,y)))
                p_after[0]+=1
            if gate[0] is not None and opcode==ord("g"):
                g_after[0]+=1
            result=original_step()
            if pending_p is not None:
                x,y,value,pt=pending_p
                need(int(self.space.get(pt))==value,
                     "native p write diverged from physical memory")
                if value==initial_byte(x,y):
                    changed_p.pop((x,y),None)
                else:
                    changed_p[(x,y)]=value
            return result
        return original_step()
    program.execute_step=hook.__get__(program,program.__class__)
    status="normal"
    try: program.execute()
    except Limit:status="step_limit"
    finally:del program.execute_step
    need(gate[0] is not None and len(post)>=32,
         "Native lower-route intervention never executed/followed")
    return {"status":status,"steps":steps[0],"remaining_ips":len(program.ips),
            "output":output.getvalue().split(),"gate":gate[0],
            "post":post,"post_p_instructions":p_after[0],
            "post_g_instructions":g_after[0]}

def common_motion(a,b,window):
    keys={}
    for i in range(len(a)-window+1):
        key=tuple(tuple(z["motion"])+tuple([z["opcode"]])
                  for z in a[i:i+window])
        keys.setdefault(key,i)
    for j in range(len(b)-window+1):
        key=tuple(tuple(z["motion"])+tuple([z["opcode"]])
                  for z in b[j:j+window])
        if key in keys:
            return keys[key],j
    return None

def main():
    need(os.path.isdir("/lower-rejoin"),"expected Native lower rejoin volume")
    source=open(SOURCE,"rb").read()
    need(sha(source)==PIN,"Native production code changed")
    catalog=dict((name,(fields,valid)) for name,fields,valid in native.CASES)
    records=[]
    for label in CASES:
        fields,valid=catalog[label]
        raw=" ".join(map(str,fields))+"\n"
        expected=native.expected_for(*fields) if valid else ["-1"]*7
        need(len(expected)==7,"independent Native Befunge oracle incomplete")
        baseline=run(source,raw,False)
        altered=run(source,raw,True)
        need(baseline["status"]==altered["status"]=="normal"
             and baseline["remaining_ips"]==altered["remaining_ips"]==0
             and baseline["output"]==altered["output"]==expected,
             "original/mutated lower Native output differs from independent oracle")
        need(baseline["steps"]-altered["steps"]==18,
             "native lower route shortcut no longer exactly 18 executed instructions")
        need(baseline["gate"]["tick"]==altered["gate"]["tick"]
             and baseline["gate"]["direction_before"]==altered["gate"]["direction_before"]
             and baseline["gate"]["direction_after"]!=altered["gate"]["direction_after"]
             and baseline["gate"]["executed_opcode"]=="]"
             and altered["gate"]["executed_opcode"]=="["
             and baseline["gate"]["restored"] and altered["gate"]["restored"],
             "live native turn instruction substitution was not isolated")
        matched=common_motion(baseline["post"],altered["post"],5)
        need(matched is not None,
             "lower feedback paths never geometrically rejoin within 256 real instructions")
        a,b=matched
        common=[]
        for i in range(5):
            x=baseline["post"][a+i]
            y=altered["post"][b+i]
            need(x["motion"]==y["motion"] and x["opcode"]==y["opcode"],
                 "reported Native 5-instruction rejoin is not identical motion")
            common.append({
                "motion":x["motion"],"opcode":x["opcode"],
                "frames_equal":x["frames"]==y["frames"],
                "context_equal":x["ip_context"]==y["ip_context"],
                "input_cursor_equal":
                    x["ip_context"]["stdin_cursor"]==y["ip_context"]["stdin_cursor"],
                "p_mutated_cells_equal":
                    x["p_modified_cells"]==y["p_modified_cells"],
                "stdout_prefix_equal":x["stdout_prefix"]==y["stdout_prefix"],
                "frames_control":x["frames"],"frames_mutant":y["frames"],
                "context_control":x["ip_context"],
                "context_mutant":y["ip_context"],
                "p_modified_control":x["p_modified_cells"],
                "p_modified_mutant":y["p_modified_cells"],
                "stdout_control":x["stdout_prefix"],
                "stdout_mutant":y["stdout_prefix"]
            })
        row={
            "case":label,"valid":bool(valid),"input_fields":list(fields),
            "native_expected":expected,"control_steps":baseline["steps"],
            "mutant_steps":altered["steps"],
            "saved_steps":baseline["steps"]-altered["steps"],
            "control_gate":baseline["gate"],"mutant_gate":altered["gate"],
            "first_shared_motion_indices":[a,b],
            "capture_count_control":len(baseline["post"]),
            "capture_count_mutant":len(altered["post"]),
            "rejoin_5":common,
            "control_window_p_steps":baseline["post_p_instructions"],
            "mutant_window_p_steps":altered["post_p_instructions"],
            "control_window_g_steps":baseline["post_g_instructions"],
            "mutant_window_g_steps":altered["post_g_instructions"],
            "all_five_frames_equal":all(z["frames_equal"] for z in common),
            "all_five_context_equal":all(z["context_equal"] for z in common),
            "all_five_p_cells_equal":all(z["p_mutated_cells_equal"] for z in common),
            "all_five_stdout_equal":all(z["stdout_prefix_equal"] for z in common)
        }
        records.append(row)
        print("NATIVE_LOWER_ROUTE_REAL_REJOIN_PASS",label,
              "first_common",a,b,
              "same_frames",row["all_five_frames_equal"],
              "same_context",row["all_five_context_equal"],
              "same_p_cells",row["all_five_p_cells_equal"],
              "same_stdout",row["all_five_stdout_equal"])
        sys.stdout.flush()
    report={
       "schema":"befunge-stage1-native-lower-feedback-rejoin-v1",
       "source_git_blob":PIN,"status":"FINITE_NATIVE_LOWER_ROUTE_REJOIN_STAGE1_OPEN",
       "native_cases":6,"native_programs":12,
       "source_geometry_artifact_id":11664135758,
       "saved_steps_each":18,
       "distinct_ip_semantic_snapshots":60,
       "all_frames_equal_cases":sum(x["all_five_frames_equal"] for x in records),
       "all_context_equal_cases":sum(x["all_five_context_equal"] for x in records),
       "all_p_cells_equal_cases":sum(x["all_five_p_cells_equal"] for x in records),
       "all_stdout_equal_cases":sum(x["all_five_stdout_equal"] for x in records),
       "stage1_geometry_pass":False,"stage1_functional_pass":False,
       "records":records
    }
    with open(OUT,"wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_LOWER_FEEDBACK_SIX_NATIVE_REJOINS_MEASURED_PASS",
          "frames",report["all_frames_equal_cases"],
          "context",report["all_context_equal_cases"],
          "p_cells",report["all_p_cells_equal_cases"])
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":main()
