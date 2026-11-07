#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Native post-handoff equivalence: original vs test-only scanner integration.

Compare ACTUAL PyFunge interpreter instruction, g, p observations, including
direction and stack depth, after the scanner returns to original arithmetic.
Pre-handoff differences are intentional. This test computes no calendar values
or mathematical reference; independently run native oracle suites must also pass.
"""
import json
import sys

HANDOFF=(5,0)
EVENTS={"STEP":8, "WRITE_BEFORE":5, "WRITE_AFTER":4,
        "READ_BEFORE":4, "READ_AFTER":4}

def extract(path):
    events=[]
    saw_handoff=False
    saw_before=0
    scanner_char_reads=0
    ip_ids=set()
    with open(path,"r",encoding="utf-8") as source:
        for line_no,line in enumerate(source,1):
            fields=line.rstrip("\n").split("\t")
            tag=fields[0]
            if tag not in EVENTS:
                raise AssertionError("%s:%d unexpected event %s" %
                                     (path,line_no,tag))
            if len(fields)!=EVENTS[tag]+1:
                raise AssertionError("%s:%d invalid %s event width" %
                                     (path,line_no,tag))
            try: vals=tuple(map(int,fields[1:]))
            except ValueError:
                raise AssertionError("%s:%d noninteger event" % (path,line_no))
            if tag=="STEP":
                tick,ip,x,y,dx,dy,opcode,depth=vals
                ip_ids.add(ip)
                if not saw_handoff:
                    saw_before+=1
                    scanner_char_reads+=int(opcode==ord("~"))
                    if (x,y)==HANDOFF:
                        saw_handoff=True
                        if (dx,dy)!=(1,0):
                            raise AssertionError("handoff IP not moving right")
                if saw_handoff:
                    events.append((tag,x,y,dx,dy,opcode,depth))
            elif saw_handoff:
                # Tick numbering differs because scanner executes first.
                events.append((tag,)+vals[1:])
    if not saw_handoff:
        raise AssertionError("native interpreter never reached arithmetic handoff")
    if len(ip_ids)!=1:
        raise AssertionError("native trace has multiple IP identities")
    if len(events)<100:
        raise AssertionError("native trace too small for arithmetic replay")
    return {"events":events,"pre_handoff_steps":saw_before-1,
            "pre_handoff_character_reads":scanner_char_reads,
            "post_handoff_events":len(events)}

def compare(original,scanner):
    a=extract(original)
    b=extract(scanner)
    if b["pre_handoff_steps"]<=a["pre_handoff_steps"]:
        raise AssertionError("scanner added no native lexical execution path")
    if b["pre_handoff_character_reads"]<1:
        raise AssertionError("native scanner did not execute any character input ~")
    if len(a["events"])!=len(b["events"]):
        raise AssertionError("post-handoff event count mismatch: %d vs %d" %
                             (len(a["events"]),len(b["events"])))
    for i,(e1,e2) in enumerate(zip(a["events"],b["events"])):
        if e1!=e2:
            raise AssertionError("native post-handoff event %d mismatch:\n%r\n%r" %
                                 (i,e1,e2))
    return {"original_pre_handoff_steps":a["pre_handoff_steps"],
            "scanner_pre_handoff_steps":b["pre_handoff_steps"],
            "matching_post_handoff_events":len(a["events"]),
            "scanner_char_input_reads":b["pre_handoff_character_reads"]}

def verify_output(oldout,newout):
    with open(oldout,"rb") as src:
        old=src.read().split()
    with open(newout,"rb") as src:
        new=src.read().split()
    if len(old)!=7 or old!=new:
        raise AssertionError("native output mismatch or incomplete seven-value result")
    return len(old)

def main():
    if len(sys.argv)!=9:
        raise SystemExit(
            "usage: auditor old_valid.tsv new_valid.tsv old_invalid.tsv "
            "new_invalid.tsv old_valid.out new_valid.out old_invalid.out new_invalid.out")
    ov,nv,oi,ni,oov,nov,ooi,noi=sys.argv[1:]
    summary={
        "valid":compare(ov,nv),
        "invalid":compare(oi,ni),
        "valid_output_fields":verify_output(oov,nov),
        "invalid_output_fields":verify_output(ooi,noi)}
    print("NATIVE_POST_HANDOFF_FULL_EVENT_PARITY_PASS",
          json.dumps(summary,sort_keys=True))
    print("Scope: native 2-input trace sample; full calendar Stage 1 still open")

if __name__=="__main__":
    main()
