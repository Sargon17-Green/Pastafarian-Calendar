#!/usr/bin/env python3
"""Independent audit of 21 real Native invalid-path Funge memory traces."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
NUMERIC=["1 0 0 0","0 0 1 0","2 10 0 10",
         "0 10 2 10","3 2 0 4","1 0 1 15055671"]
LEXICAL=["0 -1 0 1","-0 1 0 1","0 1 -0 1",
         "0 1 0 -1","0 -0 0 1","0 0 0 -0",
         "0 -15055671 0 1","0 15055671 0 -15055670",
         "0 1 0 1 7","0 1 0","0 1 0 x",
         "0 1 0 1/","","\n","0 1 0 +1"]
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def initial(rows,point):
    x,y=point
    return rows[y][x] if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32
def source():
    blob=Path("src/interleaved_work_counts.b98").read_bytes()
    digest=hashlib.sha1(b"blob "+str(len(blob)).encode("ascii")+
                        b"\0"+blob).hexdigest()
    need(digest==PIN,"native QA Funge source drift")
    return blob.split(b"\n")
def verify(data,rows):
    need(data.get("schema")=="befunge-stage1-invalid-memory-v1" and
         data.get("source_git_blob")==PIN and
         data.get("status")=="QA_ONLY_STAGE1_OPEN" and
         data.get("numeric_cases")==6 and data.get("lexical_cases")==15 and
         data.get("native_runs")==21 and data.get("native_putspace")==0 and
         data.get("nested_k_g_proof") is False and
         data.get("other_apis_proven") is False and
         data.get("final_stage1_accepted") is False,
         "native invalid source/corpus/limitations forged")
    items=data.get("records")
    need(isinstance(items,list) and len(items)==21,
         "21 native invalid records incomplete")
    total_p=total_g=total_k=0
    for i,record in enumerate(items):
        family="numeric" if i<6 else "lexical"
        number=i if i<6 else i-6
        raw=(NUMERIC if i<6 else LEXICAL)[number]
        need(record.get("kind")==family and record.get("index")==number and
             record.get("raw")==raw and record.get("status")=="normal" and
             record.get("remaining_ips")==0 and
             record.get("output")==["-1"]*7 and
             type(record.get("ticks")) is int and record["ticks"]>0 and
             record.get("putspace")==[],
             "native invalid corpus pairing/status/sentinels changed")
        puts=record.get("puts");gets=record.get("gets");ks=record.get("ks")
        need(isinstance(puts,list) and isinstance(gets,list) and
             isinstance(ks,list) and record.get("direct_p_count")==len(puts),
             "native invalid event vectors or p step counts corrupted")
        last_tick=0
        for w in puts:
            t=w.get("tick");ip=w.get("ip");target=w.get("target")
            need(type(t) is int and last_tick<t<=record["ticks"] and
                 isinstance(ip,list) and len(ip)==2 and
                 all(type(n) is int and n>=0 for n in ip) and
                 ip[1]<len(rows) and ip[0]<len(rows[ip[1]]) and
                 rows[ip[1]][ip[0]]==112 and w.get("opcode")==112 and
                 isinstance(target,list) and len(target)==2 and
                 all(type(n) is int for n in target) and
                 type(w.get("value")) is int,
                 "native invalid Space.put event not original p")
            last_tick=t
        cursor=0;latest={};prev_g=0
        for event in gets:
            t=event.get("tick");target=event.get("target")
            ip=event.get("ip")
            need(type(t) is int and prev_g<t<=record["ticks"] and
                 isinstance(target,list) and len(target)==2 and
                 all(type(n) is int for n in target) and
                 isinstance(ip,list) and len(ip)==2 and
                 all(type(n) is int and n>=0 for n in ip) and
                 ip[1]<len(rows) and ip[0]<len(rows[ip[1]]) and
                 rows[ip[1]][ip[0]]==103,
                 "invalid native g event time/source malformed")
            prev_g=t
            while cursor<len(puts) and puts[cursor]["tick"]<t:
                w=puts[cursor];latest[tuple(w["target"])]=(cursor,w["value"])
                cursor+=1
            prior=latest.get(tuple(target))
            expected=prior[1] if prior else initial(rows,target)
            need(event.get("value")==event.get("returned")==expected and
                 event.get("source_value")==initial(rows,target) and
                 event.get("last_p_index")==(prior[0] if prior else -1),
                 "invalid Native g value not causally explained by latest p")
        for event in ks:
            t=event.get("tick");ip=event.get("ip");point=event.get("target")
            need(type(t) is int and 0<t<=record["ticks"] and
                 isinstance(ip,list) and len(ip)==2 and
                 isinstance(point,list) and len(point)==2 and
                 all(type(n) is int for n in ip+point) and
                 initial(rows,ip)==107,
                 "invalid native k execution geometry forged")
            preceding=[w for w in puts
                       if w["tick"]<t and w["target"]==point]
            value=preceding[-1]["value"] if preceding else initial(rows,point)
            need(event.get("nextbyte")==value and value not in (103,112),
                 "hidden memory g/p native k execution in invalid path")
        total_p+=len(puts);total_g+=len(gets);total_k+=len(ks)
    need(data.get("native_puts")==total_p and
         data.get("native_gets")==total_g and
         data.get("native_k")==total_k,
         "native invalid evidence totals manipulated")
    return total_p,total_g,total_k

def main(path):
    with (Path(path)/"native_invalid_memory.json").open(
         encoding="utf-8") as f: report=json.load(f)
    rows=source();counts=verify(report,rows)
    def reject(name,change):
        item=copy.deepcopy(report);change(item)
        try:verify(item,rows)
        except AssertionError:
            print("NATIVE_INVALID_MEMORY_TAMPER_REJECT_PASS",name)
            return name
        raise AssertionError("tampered invalid-input Native report accepted: "+name)
    attacks=[
        reject("forged_source",lambda x:x.__setitem__("source_git_blob","0"*40)),
        reject("dropped_case",lambda x:x["records"].pop()),
        reject("swapped_input",lambda x:x["records"][0].__setitem__("raw","0 0 0 0")),
        reject("wrong_sentinel",lambda x:x["records"][0]["output"].__setitem__(0,"0")),
        reject("fake_putspace",lambda x:x["records"][0]["putspace"].append(123)),
        reject("fake_write_count",lambda x:x.__setitem__("native_puts",-1)),
        reject("fake_full_coverage",lambda x:x.__setitem__("other_apis_proven",True)),
        reject("fake_completion",lambda x:x["records"][0].__setitem__("remaining_ips",1))
    ]
    need(len(attacks)==8,"Native invalid tamper suite incomplete")
    result={"schema":"befunge-stage1-invalid-memory-audit-v1",
            "cases":21,"writes":counts[0],"reads":counts[1],
            "k_dispatches":counts[2],"negative_reports_rejected":attacks,
            "stage1_final_acceptance":False}
    with (Path(path)/"native_invalid_memory_audit.json").open(
         "w",encoding="utf-8") as f:
        json.dump(result,f,sort_keys=True,indent=2);f.write("\n")
    print("NATIVE_INVALID_MEMORY_21_REAL_INPUTS_INDEPENDENT_AUDIT_PASS",counts)
    print("NATIVE_INVALID_MEMORY_8_TAMPERS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"usage: NATIVE_INVALID_EVIDENCE_DIR")
    main(sys.argv[1])
