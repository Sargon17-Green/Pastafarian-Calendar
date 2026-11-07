#!/usr/bin/env python3
"""Independent 64-case executed Native g read-after-write evidence audit."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def require(cond,msg):
    if not cond:raise AssertionError(msg)
def source():
    data=Path("src/interleaved_work_counts.b98").read_bytes()
    h=hashlib.sha1(b"blob "+str(len(data)).encode("ascii")+b"\0"+data).hexdigest()
    require(h==PIN,"Native source unexpectedly changed")
    return data.split(b"\n")
def srcbyte(rows,point):
    x,y=point
    return rows[y][x] if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32
def verify(report,original,rows):
    require(report.get("schema")=="befunge-stage1-native-all-g-lineage-v1" and
            report.get("source_git_blob")==PIN and
            report.get("status")=="QA_ONLY_EXECUTED_TOP_LEVEL_G_LINEAGE" and
            report.get("real_programs")==64 and
            report.get("valid_cases")==32 and
            report.get("nested_k_g_not_excluded") is True and
            report.get("other_mutation_apis_audited") is False and
            report.get("stage1_final_accepted") is False and
            original.get("production_git_blob")==PIN,
            "Native read-lineage scope or source inconsistent")
    out=report.get("records");writes=original.get("records")
    require(isinstance(out,list) and isinstance(writes,list) and
            len(out)==len(writes)==64,"Native 64-case pairing incomplete")
    total_p=total_g=linked=0
    for x,ref in zip(out,writes):
        require(x.get("case")==ref["case"] and
                x.get("opposite")==ref["opposite"] and
                x.get("status")==ref["status"] and
                x.get("ticks")==ref["ticks"] and
                x.get("matched_engine_put_count")==len(ref["native_put_events"]),
                "native replay/engine write inventory out of sync")
        total_p+=len(ref["native_put_events"])
        reads=x.get("g_reads");require(isinstance(reads,list),"g read list missing")
        cursor=0;seen={};last_tick=0
        for ev in reads:
            t=ev.get("tick");point=ev.get("target")
            require(type(t) is int and last_tick<t<=x["ticks"] and
                    isinstance(point,list) and len(point)==2 and
                    all(type(v) is int for v in point),
                    "malformed Native g coordinate/tick")
            last_tick=t
            while (cursor<len(ref["native_put_events"]) and
                   ref["native_put_events"][cursor]["tick"]<t):
                old=ref["native_put_events"][cursor]
                seen[tuple(old["target"])]=(cursor,old["value"])
                cursor+=1
            prev=seen.get(tuple(point))
            original_value=srcbyte(rows,point)
            expect=prev[1] if prev else original_value
            require(ev.get("value")==ev.get("returned")==expect and
                    ev.get("previous_p_index")==(prev[0] if prev else -1) and
                    ev.get("initial_source_byte")==original_value and
                    isinstance(ev.get("ip"),list) and len(ev["ip"])==2,
                    "Native g value not explained by preceding engine p or source")
            linked+=int(prev is not None);total_g+=1
    require(total_g>0 and linked>0 and
            report.get("p_events_cross_checked")==total_p==
            original.get("total_space_put_calls") and
            report.get("g_reads")==total_g and
            report.get("p_dependent_g_reads")==linked and
            report.get("source_origin_g_reads")==total_g-linked,
            "Native read lineage totals inconsistent")
    return total_p,total_g,linked
def main(folder):
    path=Path(folder)
    with (path/"native_all_g_lineage.json").open(encoding="utf-8") as f:data=json.load(f)
    with (path/"native_fungespace_put_inventory.json").open(encoding="utf-8") as f:writer=json.load(f)
    rows=source();totals=verify(data,writer,rows)
    index=next(i for i,r in enumerate(data["records"]) if r["g_reads"])
    def reject(label,mutation):
        test=copy.deepcopy(data);mutation(test)
        try:verify(test,writer,rows)
        except AssertionError:
            print("NATIVE_G_LINEAGE_TAMPER_REJECT_PASS",label);return label
        raise AssertionError("Native g audit accepted "+label)
    rejects=[
        reject("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        reject("missing_case",lambda d:d["records"].pop()),
        reject("forged_g_return",lambda d:d["records"][index]["g_reads"][0].__setitem__("returned",999)),
        reject("forged_origin",lambda d:d["records"][index]["g_reads"][0].__setitem__("previous_p_index",999)),
        reject("forged_tick",lambda d:d["records"][index]["g_reads"][0].__setitem__("tick",-1)),
        reject("forged_target",lambda d:d["records"][index]["g_reads"][0].__setitem__("target",[999,999])),
        reject("false_universal",lambda d:d.__setitem__("other_mutation_apis_audited",True)),
        reject("summary",lambda d:d.__setitem__("p_dependent_g_reads",-1))
    ]
    require(len(rejects)==8,"g evidence tamper test incomplete")
    result={"schema":"befunge-stage1-native-all-g-audit-v1",
            "native_programs":64,"put_writes":totals[0],
            "g_reads":totals[1],"read_after_p":totals[2],
            "tampered_reports_rejected":rejects,
            "stage1_final_acceptance":False}
    with (path/"native_all_g_lineage_audit.json").open("w",encoding="utf-8") as f:
        json.dump(result,f,sort_keys=True,indent=2);f.write("\n")
    print("NATIVE_ALL_G_LINEAGE_INDEPENDENT_8_TAMPERS_PASS",totals)
if __name__=="__main__":
    require(len(sys.argv)==2,"expected Native evidence directory");main(sys.argv[1])
