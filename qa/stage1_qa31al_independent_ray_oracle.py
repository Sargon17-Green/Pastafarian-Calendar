#!/usr/bin/env python3
"""QA31AL independent source-coordinate/seeded B98 corridor verifier.
No import of the forward checker; conditional results are not Native traces.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SHA="560d6aa5807a7f766213a33835cce85eab0fa40c"
D={"E":(1,0,">"),"W":(-1,0,"<"),
   "S":(0,1,"v"),"N":(0,-1,"^")}
FIXED={(399,195):1698,(1030,385):1705,(860,846):1691,
       (405,860):1701,(195,1036):1715,(480,1070):1704,
       (876,1240):1699,(986,1334):1600,(1335,1354):1750,
       (1430,1540):1716,(670,1598):1708}
ENTRY_ROWS=(20,23,29,32)
SAMPLES=[[],[1]*24,[49,1,3,49,2,99,17,23]*3,
         [0,49,-4,128,-49,3,7,11]*3,
         [91,-52,13,0,49,72,-22,32]*3]
PURE=set("0123456789abcdef+-*/%!:$\\ "+chr(96))
def need(p,msg):
    if not p: raise AssertionError(msg)

def original(raw):
    h=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    need(h==SHA,"untrusted original source")
    rows=raw.splitlines()
    need(len(rows)==2015 and rows[49]==b"","source rows")
    coords=[(x,y) for y,line in enumerate(rows)
            for x,v in enumerate(line) if v==ord("p")]
    need(len(coords)==57 and
         len([p for p in coords if p[1]<45])==13,"source p inventory")
    return rows, [list(p) for p in coords if p[1]>=45]

def cell(rows,x,y):
    return (chr(rows[y][x]) if 0<=y<len(rows)
            and 0<=x<len(rows[y]) else None)

def direct_source_segment(rows,point,cor):
    direction=cor["direction"]
    need(direction in D,"vector")
    dx,dy,arrow=D[direction]
    x,y=point
    ax,ay=cor["anchor"]
    distance=cor["steps"]
    need(isinstance(distance,int) and 1<=distance<=60,
         "source distance")
    need((ax+distance*dx,ay+distance*dy)==(x,y),"bad ray geometry")
    reconstructed=[]
    for i in range(distance+1):
        pos=cell(rows,ax+i*dx,ay+i*dy)
        need(pos is not None,"source ray out of bounds")
        reconstructed.append(pos)
    sequence="".join(reconstructed)
    need(sequence[0]==arrow and sequence[-1]=="p" and
         sequence==cor["ops"],"source corridor not reproduced")
    need(all(x in PURE for x in sequence[1:-1]),
         "unhandled mid-corridor opcode")
    return sequence

def execute_sample(segment,initial):
    stack=list(initial)
    def pop():
        return stack.pop() if stack else 0
    for c in segment[1:-1]:
        if c in "0123456789abcdef":
            stack.append(int(c,16))
        elif c in "+-*/%"+chr(96):
            b,a=pop(),pop()
            if c=="+": stack.append(a+b)
            elif c=="-":stack.append(a-b)
            elif c=="*":stack.append(a*b)
            elif c==chr(96):stack.append(int(a>b))
            elif b==0:return None
            elif c=="/":stack.append(int(a/b))
            else:stack.append(a-int(a/b)*b)
        elif c=="!":stack.append(int(pop()==0))
        elif c==":":a=pop();stack.extend((a,a))
        elif c=="\\":a,b=pop(),pop();stack.extend((a,b))
        elif c=="$":pop()
        elif c==" ":pass
        else:raise AssertionError("sample unsupported instruction")
    yy,xx,v=pop(),pop(),pop()
    return (xx,yy,v)

def verify(report,rows,sites):
    need(report["schema"]=="qa31al-pinned-bounded-corridor-v1" and
         report["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ" and
         report["source_git_blob"]==SHA, "schema/identity")
    need((report["corridor_limit"],report["literal_p_full_source"],
          report["literal_p_prologue"],report["literal_p_outside"])==
         (60,57,13,44),"source aggregate")
    records=report["outer_sites"]
    need(len(records)==len(sites)==44,"outside site count")
    need([item["site"] for item in records]==sites,
         "out-of-prologue source coordinate order")
    tested=0
    discovered={}
    unknown=0
    for item in records:
        point=item["site"]
        need(cell(rows,*point)=="p" and
             item["source_byte"]=="p" and
             item["unrestricted_write_target"]=="UNKNOWN" and
             item["unrestricted_IP_and_stack_reachability"]=="UNKNOWN",
             "forbidden unrestricted ownership claim")
        for cor in item["bounded_straight_candidates"]:
            seq=direct_source_segment(rows,point,cor)
            need(cor["direction"] not in discovered.get(tuple(point),[]),
                 "duplicate directional corridor")
            discovered.setdefault(tuple(point),[]).append(cor["direction"])
            need(isinstance(cor["external_stack_pops"],int) and
                 cor["external_stack_pops"]>=0,"invalid pre-stack dependency")
            truth=FIXED.get(tuple(point))
            if truth is not None:
                need(cor["static_y"]==truth and
                     cor["conditionally_excludes_counter_y49"] is True,
                     "fixed-y source exclusion changed")
                for seed in SAMPLES:
                    concrete=execute_sample(seq,seed)
                    need(concrete is not None and concrete[1]==truth,
                         "independent sample disagrees with static y")
                    tested+=1
            else:
                need(cor["static_y"] is None and
                     cor["conditionally_excludes_counter_y49"] is False,
                     "unproved source y promoted to constant")
                for seed in SAMPLES:
                    concrete=execute_sample(seq,seed)
                    if concrete is not None:
                        tested+=1
                unknown+=1
    pure_count=sum(len(x["bounded_straight_candidates"]) for x in records)
    need(pure_count==report["source_straight_corridors"]==43,
         "corridor coverage")
    need(len(FIXED)==report["conditional_fixed_non49_y_corridors"]==11,
         "fixed-y corridor total")
    need(unknown==report["conditional_unknown_y_corridors"]==32,
         "unknown source corridor total")
    need(report["no_bounded_straight_anchor"]==[[369,575]],
         "unmodeled original site")
    expected_fixed=[list(point) for point in sites if tuple(point) in FIXED]
    need(report["conditional_fixed_non49_sites"]==expected_fixed,
         "fixed site list or ordering")
    geometry=report["alternate_ingress_local_geometry"]
    need(len(geometry)==4,"missing ingress row")
    for item,yy in zip(geometry,ENTRY_ROWS):
        need(item["target"]==[10,yy] and
             cell(rows,10,yy)==item["entry_opcode"]==">",
             "counter row ingress anchor")
        expected={"north":cell(rows,10,yy-1),
                  "south":cell(rows,10,yy+1),
                  "west":cell(rows,9,yy)}
        need(item["geometric_neighbor_cells"]==expected and
             all(c==" " or c is None for c in expected.values()) and
             item["unrestricted_IP_reachability"]=="UNKNOWN",
             "source geometry forged as reachability")
    need(report["forward_source_mutants_rejected"]==10,
         "forward source mutations")
    need(report["outer_p_counter_targets_globally_proven"]=="UNKNOWN" and
         report["alternate_ingress_reachability"]=="UNKNOWN" and
         report["new_native_runs"]==0 and
         report["replayed_native_runs"]==0 and
         report["stage1_global_pass"] is False,
         "unjustified Stage1 or Native claim")
    need(tested>=55, "independent seeded executions absent")
    return tested

def hostile(report,rows,sites):
    def mutate(i,r):
        if i==0:r["source_git_blob"]="0"
        elif i==1:r["literal_p_outside"]=43
        elif i==2:r["outer_sites"].pop()
        elif i==3:r["outer_sites"][0]["site"]=[861,99]
        elif i==4:r["outer_sites"][2]["bounded_straight_candidates"][0]["ops"]+="0"
        elif i==5:r["outer_sites"][2]["bounded_straight_candidates"][0]["static_y"]=49
        elif i==6:r["outer_sites"][0]["bounded_straight_candidates"][0]["static_y"]=0
        elif i==7:r["no_bounded_straight_anchor"]=[]
        elif i==8:r["conditional_fixed_non49_sites"].pop()
        elif i==9:r["alternate_ingress_local_geometry"][0]["target"]=[11,20]
        elif i==10:r["alternate_ingress_local_geometry"][0]["unrestricted_IP_reachability"]="YES"
        elif i==11:r["outer_p_counter_targets_globally_proven"]="NONE"
        elif i==12:r["new_native_runs"]=1
        elif i==13:r["stage1_global_pass"]=True
    found=0
    for i in range(14):
        changed=copy.deepcopy(report)
        mutate(i,changed)
        try:verify(changed,rows,sites)
        except (AssertionError,ValueError,KeyError,TypeError,IndexError):found+=1
        else:raise AssertionError("hostile tampering not rejected "+str(i))
    need(found==14,"hostile test count")
    return found

def main():
    a=argparse.ArgumentParser()
    for k in ("source","forward","out"):
        a.add_argument("--"+k,required=True)
    opts=a.parse_args()
    rows,sites=original(Path(opts.source).read_bytes())
    report=json.loads(Path(opts.forward).read_text(encoding="utf-8"))
    tested=verify(report,rows,sites)
    hostile_count=hostile(report,rows,sites)
    out={"schema":"qa31al-independent-ray-and-seeded-oracle-v1",
         "source_git_blob":SHA,
         "source_outer_sites_verified":44,
         "source_pure_corridors_verified":43,
         "conditional_fixed_y_non49_verified":11,
         "conditional_unknown_y_verified":32,
         "sample_interpretations":tested,
         "independent_hostile_rejections":hostile_count,
         "new_native_runs":0,"stage1_global_pass":False}
    Path(opts.out).write_text(json.dumps(out,sort_keys=True,
                         indent=2)+"\n",encoding="utf-8")
    print("QA31AL_INDEPENDENT_PASS 44_SITES 43_CORRIDORS 11_CONDITIONAL_FIXED_NON49 32_UNKNOWN")
    print("QA31AL_SEEDED_INTERPRETATIONS",tested,"HOSTILE",hostile_count,
          "NATIVE 0 STAGE1 OPEN")

if __name__=="__main__":
    main()
