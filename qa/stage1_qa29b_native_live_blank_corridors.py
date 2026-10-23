#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA29B actual PyFunge live FungeSpace memory at two signed blank skips.

Replays ONE original QA20 valid00 Native program from input origin, without
moving IP or changing the actual production bytecode. Requires exact parity
with every original signed QA20 STEP and the final seven native oracle tokens.
At two identified '-' instructions, observe the seven skipped FungeSpace
cells before and after executing the real Native instruction.
"""
from __future__ import print_function
import gzip
import hashlib
import json
import os
import sys
import StringIO

import stage1_qa20_native_input_route_scan as q20

SOURCE_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA20_MANIFEST_SHA="782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a"
QA28_RECEIPT_SHA="c5a5beaab308df31222652484e5fb18af554bf75e7b492225b107197fb29aa6e"
TARGETS=((113,32),(199,35))

def need(cond,msg):
    if not cond:raise AssertionError(msg)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def actual_state(p):
    ip=p['program'].ips[0]
    return [int(z) for z in ip.position]+[int(z) for z in ip.delta]+[
        int(p['program'].space.get(ip.position)),int(bool(ip.stringmode))]

def main(folder,qa28_path):
    rawsource=open(q20.SOURCE,'rb').read()
    need(q20.pin(rawsource)==SOURCE_BLOB==q20.PIN,
         "original 2D production source changed")
    qa20_path=os.path.join(folder,"qa20_manifest.json")
    manifest_data=open(qa20_path,'rb').read()
    need(sha(manifest_data)==QA20_MANIFEST_SHA,
         "original QA20 Native shard0 manifest SHA drifted")
    m=json.loads(manifest_data)
    need(m['shard']==0 and m['source_git_blob']==SOURCE_BLOB
         and m['source_modified'] is False and m['ip_relocated'] is False
         and m['stage1_final_acceptance'] is False and len(m['records'])==12,
         "QA20 original source shard provenance changed")
    original=[r for r in m['records'] if r['label']=="valid00"]
    need(len(original)==1,"QA20 input-origin original valid00 case unavailable")
    case=original[0]
    need(case['raw_input']=="0 0 0 0\n" and case['valid'] is True
         and len(case['output'])==7 and case['output']==case['expected']
         and case['natural_ip_no_intervention'] is True,
         "original QA20 valid00 Native input/output changed")
    receipt_data=open(qa28_path,'rb').read()
    need(sha(receipt_data)==QA28_RECEIPT_SHA,
         "accepted QA28 actual Native signed triads drifted")
    q28=json.loads(receipt_data)
    need(q28['schema']=="qa28-15-original-source-candidate-directed-native-triads-v1"
         and len(q28['records'])==15 and q28['stage1_complete'] is False,
         "QA28 original witness provenance altered")
    selected=[r for r in q28['records'] if tuple(r['target']) in TARGETS]
    need(len(selected)==2
         and all(r['original_case']=="valid00" for r in selected),
         "two original nonadjacent blank-skip witnesses must be valid00")
    witness={}
    all_corridor=set()
    original_rows=rawsource.splitlines()
    for r in selected:
        a=r["nearest_native_step"]
        b=r["successor_native_step"]
        x,y=a[1:3]
        need((x,y) in ((112,29),(198,38)) and a[5]==ord('-')
             and a[6]==0 and a[3:5]==[1,0]
             and b[1:3]==[x+8,y] and b[5]==ord('0'),
             "signed QA28 blank-skip Native transition altered")
        cells=tuple((i,y) for i in range(x+1,x+8))
        need(len(cells)==7 and all(original_rows[yy][xx]==ord(' ')
                                   for xx,yy in cells),
             "original static source no longer has the seven blanks")
        all_corridor.update(cells)
        witness[a[0]]={"target":r["target"],"anchor":a,"successor":b,
                       "cells":cells}
    need(len(all_corridor)==14 and len(witness)==2,
         "QA29B source corridor locations not exact")
    zipped=open(os.path.join(folder,case['path']),'rb').read()
    need(len(zipped)==case['compressed_bytes']
         and sha(zipped)==case['compressed_trace_sha256'],
         "original QA20 Native full raw STEP trace changed")
    expected=gzip.GzipFile(fileobj=StringIO.StringIO(zipped),mode='rb').read().splitlines()
    need(len(expected)==case['steps'],
         "original QA20 Native trace is incomplete")
    current=q20.create_program(rawsource,case['raw_input'],case['label'])
    program=current["program"];space=program.space
    cls=type(space);old_put=cls.put
    writes=[];total_put=[0];inside_step=[0];snapshots=[]
    def track_put(self,*args,**kwargs):
        need(self is space and len(args)>=2,
             "unexpected Native physical FungeSpace.put call")
        point=tuple(map(int,args[0]))
        before=int(self.get(args[0]))
        rv=old_put(self,*args,**kwargs)
        after=int(self.get(args[0]))
        total_put[0]+=1
        if point in all_corridor:
            writes.append({"tick":inside_step[0],"coord":list(point),
                           "before":before,"after":after})
        return rv
    try:
        cls.put=track_put
        while program.ips:
            need(len(program.ips)==1,"original Native program became multi-IP")
            tick=current['steps']+1
            need(tick<=len(expected),"new Native replay extends original QA20 trace")
            state=actual_state(current)
            line="%d\t%s"%(tick,"\t".join(map(str,state)))
            need(line==expected[tick-1],
                 "original Native full STEP replay changed at tick "+str(tick))
            event=witness.get(tick)
            if event is not None:
                need([tick]+state==event['anchor'],
                     "live Native anchor state not equal to signed QA28")
                prior=[int(space.get(current['point'](*xy))) for xy in event['cells']]
                need(all(v==32 for v in prior),
                     "runtime seven skipped FungeSpace values are NOT blanks before '-'")
                writes_before=len(writes)
            inside_step[0]=tick
            q20.tick_qa20(current)
            if event is not None:
                posterior=[int(space.get(current['point'](*xy))) for xy in event['cells']]
                need(all(v==32 for v in posterior),
                     "runtime skipped FungeSpace changed during Native '-'")
                need(len(writes)==writes_before,
                     "actual Native '-' step wrote into a skipped source corridor")
                snapshots.append({
                  "target":event["target"],"original_anchor_tick":tick,
                  "anchor":event["anchor"],"successor":event["successor"],
                  "corridor_cells":[list(x) for x in event["cells"]],
                  "live_memory_before_instruction":prior,
                  "live_memory_after_instruction":posterior,
                  "put_calls_to_corridors_before_tick":writes_before,
                  "put_calls_to_corridors_during_tick":0,
                  "state_read_from_actual_native_fungespace":True})
        need(current['steps']==case['steps'],
             "QA29B actual Native program terminated at different STEP length")
    finally:
        cls.put=old_put
    need(current['stdout'].getvalue().split()==case['output'],
         "new actual Native final output differs from accepted QA20")
    need(len(snapshots)==2,"original two source-blank Native events not both replayed")
    report={
       "schema":"qa29b-original-native-two-runtime-blank-corridors-v1",
       "original_source_git_blob":SOURCE_BLOB,
       "original_qa20_shard0_manifest_sha256":QA20_MANIFEST_SHA,
       "original_qa28_receipt_sha256":QA28_RECEIPT_SHA,
       "qa20_original_run":39761821210,"qa28_original_run":39985923985,
       "new_native_program_executions":1,
       "native_input_label":"valid00","original_native_full_steps":case['steps'],
       "full_original_native_step_replay":True,
       "original_native_trace_compressed_sha256":sha(zipped),
       "original_native_output":case['output'],
       "actual_program_fungespace_put_calls":total_put[0],
       "all_corridor_put_events":writes,
       "two_signed_native_blank_corridor_runtime_snapshots":snapshots,
       "full_program_native_ip_relocated":False,
       "production_source_modified":False,
       "proof_scoped_to_recorded_fungespace_get_and_put":True,
       "alternative_interpreter_mutation_apis_globally_ruled_out":False,
       "all_input_global_blank_or_dead_code_proven":False,
       "stage1_complete":False}
    out=os.path.join(folder,"qa29b_native_live_blank_snapshot.json")
    with open(out,"wb") as fp:fp.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("QA29B_ORIGINAL_NATIVE_FULL_STEP_REPLAY_PASS",current['steps'])
    print("QA29B_TWO_LIVE_NATIVE_SEVEN_CELL_BLANK_SNAPSHOTS_PASS")
    print("QA29B_RUNTIME_CONCLUSION_SCOPED_TO_THE_TWO_ACTUAL_NATIVE_EXECUTIONS")
if __name__=="__main__":
    need(len(sys.argv)==3,"usage: qa29b.py restored_QA20_shard0_dir original_QA28_json")
    main(sys.argv[1],sys.argv[2])
