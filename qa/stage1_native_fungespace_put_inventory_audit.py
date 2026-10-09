#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent 64-program Git-pinned Native Funge-space write-surface audit.

The producer uses REAL Python-2.7 PyFunge-98 engine instrumentation
during execute(), rather than a Python reimplementation of Befunge.
This separate Python-3 verifier checks every observed write against
unchanged source bytes and rejects seven deliberately forged manifests.

Scope is limited to the 32 valid domain inputs and two real fork arms;
this does not prove absence of other interpreter mutation APIs.
"""
import copy
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

SOURCE=Path("src/interleaved_work_counts.b98")
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SCHEMA="befunge-stage1-native-fungespace-put-surface-v1"
FORBIDDEN="sio=()t"
SPECIAL_DATA={(43,1702),(47,1703),(53,1704),(61,1706)}
EXPECTED_G_TARGET_TOTALS={(43,1702):2176,(47,1703):2176,
                          (53,1704):1216,(61,1706):1216}
EXPECTED_LITERAL_G_READS={(43,1702,40):20,(47,1703,40):8,
                          (53,1704,41):4,(61,1706,41):4}
EXPECTED_SPECIAL={
    (43,1702,40):10,
    (47,1703,40):4,
    (53,1704,41):4,
    (61,1706,41):4,
}

def require(ok,message):
    if not ok:
        raise AssertionError(message)

def source_verified():
    source=SOURCE.read_bytes()
    digest=hashlib.sha1(b"blob "+str(len(source)).encode("ascii")+
                        b"\x00"+source).hexdigest()
    require(digest==PIN,"current Funge source blob changed")
    rows=source.split(b"\n")
    mutators={chr(c):source.count(c) for c in FORBIDDEN.encode("ascii")}
    require(all(v==0 for v in mutators.values()) and len(rows)==2016,
            "source contains extra mutators or wrong row geometry")
    return rows,mutators

def verify(data,rows,source_mutators):
    require(data.get("schema")==SCHEMA and
            data.get("production_git_blob")==PIN and
            data.get("status")=="QA_ONLY_NOT_COMPLETE_SEMANTIC_OWNERSHIP" and
            data.get("real_native_program_runs")==64 and
            data.get("valid_inputs")==32 and
            data.get("source_forbidden_mutator_count")==source_mutators and
            data.get("stage1_final_acceptance") is False and
            data.get("other_space_mutation_APIs_audited") is False,
            "source, status, 64-case geometry or audit limitations drifted")
    records=data.get("records")
    require(isinstance(records,list) and len(records)==64,
            "64 real Native execution records missing")
    labels=set()
    all_special=Counter()
    total=0
    indirect=0
    visits=0
    g_reads=0
    g_by_target=Counter()
    g_literal=Counter()
    for pair in range(0,64,2):
        a,b=records[pair:pair+2]
        label=a.get("case")
        require(isinstance(label,str) and label and
                label==b.get("case") and label not in labels and
                a.get("opposite") is False and
                b.get("opposite") is True,
                "real native input/fork case pairing broken")
        labels.add(label)
        original=a.get("gate")
        forced=b.get("gate")
        require(type(original) is list and type(forced) is list and
                len(original)==len(forced)==2 and
                all(type(x) is int and x in (0,1)
                    for x in original+forced) and
                original[0]==forced[0]==original[1] and
                forced[1]==1-original[0],
                "actual native fork selection not paired")
        require(a.get("status")=="normal" and
                a.get("remaining_ips")==0 and
                a.get("oracle_correct") is True,
                "normal Native output differs from independent Befunge oracle")
    for record in records:
        events=record.get("native_put_events")
        require(isinstance(events,list) and len(events)>0 and
                len(events)==record.get("put_calls")==
                record.get("direct_p_steps") and
                record.get("non_p_attributed_puts")==0,
                "native executable p count differs from real engine .put calls")
        require(record.get("generated_byte_ip_visits")==[],
                "IP executed a previously dynamically written mutator byte")
        observed=record.get("direct_g_reads_of_special_cells")
        require(isinstance(observed,list),
                "missing native g data-cell observations")
        for read in observed:
            point=read.get("target")
            reader=read.get("ip")
            tick=read.get("tick")
            require(isinstance(point,list) and tuple(point) in SPECIAL_DATA and
                    isinstance(reader,list) and len(reader)==2 and
                    all(type(v) is int for v in reader) and
                    type(tick) is int and 0<tick<=record["ticks"] and
                    type(read.get("before")) is int and
                    read.get("returned")==read["before"],
                    "invalid Native g read of stored mutator-looking data")
            require(0<=reader[1]<len(rows) and
                    0<=reader[0]<len(rows[reader[1]]) and
                    rows[reader[1]][reader[0]]==ord("g"),
                    "Native direct g data-read not executed at original g source")
            prior=[event for event in record["native_put_events"]
                   if event["target"]==point and event["tick"]<tick]
            if prior:
                expected=prior[-1]["value"]
            else:
                x,y=point
                expected=(rows[y][x] if 0<=y<len(rows) and
                          0<=x<len(rows[y]) else 32)
            require(read["before"]==expected,
                    "Native g read not consistent with physical latest p write")
            g_by_target[tuple(point)]+=1
            if read["returned"] in (40,41):
                require(prior and prior[-1]["value"]==read["returned"],
                        "Native literal opcode-like data was not previously written")
                g_literal[(point[0],point[1],read["returned"])]+=1
        g_reads+=len(observed)
        require(type(record.get("ticks")) is int and
                record["ticks"]>len(events),
                "Native writer instruction clock invalid")
        seen_ticks=set()
        local_special=0
        for event in events:
            tick=event.get("tick")
            coord=event.get("ip")
            target=event.get("target")
            value=event.get("value")
            require(type(tick) is int and
                    0<tick<=record["ticks"] and tick not in seen_ticks,
                    "Native p/space.put write has duplicate/nonpositive clock")
            seen_ticks.add(tick)
            require(isinstance(coord,list) and len(coord)==2 and
                    all(type(v) is int and v>=0 for v in coord) and
                    coord[1]<len(rows) and coord[0]<len(rows[coord[1]]) and
                    rows[coord[1]][coord[0]]==ord("p") and
                    event.get("opcode")==ord("p"),
                    "engine-level put did not execute the expected original p source")
            require(isinstance(target,list) and len(target)==2 and
                    all(type(v) is int for v in target) and
                    type(value) is int,
                    "native put target/value corrupted")
            if value in [ord(c) for c in FORBIDDEN]:
                key=(target[0],target[1],value)
                all_special[key]+=1
                local_special+=1
        require(record.get("created_other_mutator_cells")==local_special,
                "source-byte-derived generated mutator count differs from raw puts")
        total+=len(events)
        indirect+=record["non_p_attributed_puts"]
        visits+=len(record["generated_byte_ip_visits"])
    require(g_reads==6784 and
            dict(g_by_target)==EXPECTED_G_TARGET_TOTALS and
            dict(g_literal)==EXPECTED_LITERAL_G_READS,
            "Native direct g data-byte read frequency/class changed")
    require(data.get("direct_g_reads_of_special_cells")==g_reads and
            data.get("indirect_or_non_g_memory_reads_not_audited") is True,
            "Native direct-g data read totals and scope drifted")
    require(len(labels)==32 and
            total==data.get("total_space_put_calls")==23488 and
            indirect==data.get("indirect_or_non_p_attributed_put_calls")==0 and
            visits==data.get("generated_mutator_byte_ip_visits")==0 and
            sum(all_special.values())==
            data.get("new_forbidden_mutator_bytes_written")==22 and
            dict(all_special)==EXPECTED_SPECIAL,
            "Native total p/space.put or four data-target byte counts mismatch")
    return {"native_runs":64,"cases":32,"write_calls":total,
            "special_numeric_writes":22,
            "actual_generated_instruction_visits":0,
            "real_direct_g_data_reads":g_reads,
            "real_opcode_looking_byte_g_reads":sum(g_literal.values()),
            "direct_g_read_target_counts":dict(
                (str(p),count) for p,count in g_by_target.items()),
            "other_mutation_apis_excluded":True}

def must_reject(name,source,rows,mutators,mutate):
    probe=copy.deepcopy(source)
    mutate(probe)
    try:
        verify(probe,rows,mutators)
    except AssertionError as exc:
        print("NATIVE_SPACE_PUT_EVIDENCE_TAMPER_REJECT_PASS",
              name,str(exc)[:105])
        return name
    raise AssertionError("forged Native engine write inventory accepted: "+name)

def main(folder):
    rows,mutators=source_verified()
    with (Path(folder)/"native_fungespace_put_inventory.json").open(
            encoding="utf-8") as handle:
        report=json.load(handle)
    result=verify(report,rows,mutators)
    print("NATIVE_SPACE_PUT_64_REAL_RECORDS_INDEPENDENT_AUDIT_PASS",
          result)
    rejections=[
        must_reject("wrong_source",report,rows,mutators,
                    lambda p:p.__setitem__("production_git_blob","0"*40)),
        must_reject("dropped_run",report,rows,mutators,
                    lambda p:p["records"].pop()),
        must_reject("forged_put_opcode",report,rows,mutators,
                    lambda p:p["records"][0]["native_put_events"][0]
                    .__setitem__("opcode",ord("s"))),
        must_reject("forged_native_put_clock",report,rows,mutators,
                    lambda p:p["records"][0]["native_put_events"][1]
                    .__setitem__("tick",
                        p["records"][0]["native_put_events"][0]["tick"])),
        must_reject("fake_dynamic_opcode_execution",report,rows,mutators,
                    lambda p:p["records"][0]["generated_byte_ip_visits"]
                    .append({"tick":1,"ip":[43,1702],"byte":40,
                             "stringmode":False})),
        must_reject("forged_source_data_target",report,rows,mutators,
                    lambda p:next(event for row in p["records"]
                                  for event in row["native_put_events"]
                                  if event["value"] in (40,41))
                    .__setitem__("target",[999,1702])),
        must_reject("forged_total",report,rows,mutators,
                    lambda p:p.__setitem__("total_space_put_calls",1)),
        must_reject("forged_g_data_read",report,rows,mutators,
                    lambda p:p["records"][0]["direct_g_reads_of_special_cells"]
                    .append({"tick":1,"ip":[0,0],"target":[43,1702],
                             "before":40,"returned":40})),
        must_reject("forged_g_literal_value",report,rows,mutators,
                    lambda p:next(entry for row in p["records"]
                        for entry in row["direct_g_reads_of_special_cells"]
                        if entry["returned"] in (40,41))
                    .__setitem__("returned",42)),
    ]
    require(len(rejections)==9,"Native write adversaries not fully exercised")
    output={"schema":"befunge-stage1-native-fungespace-put-audit-v3",
            "source_git_blob":PIN,"real_native_records_verified":64,
            "proof_scope":"finite corpus and observable Funge-space.put method",
            "stage1_final_acceptance":False,"verified_counts":result,
            "negative_reports_rejected":rejections}
    with (Path(folder)/"native_fungespace_put_audit.json").open(
            "w",encoding="utf-8") as out:
        json.dump(output,out,sort_keys=True,indent=2)
        out.write("\n")
    print("NATIVE_SPACE_PUT_INDEPENDENT_9_NEGATIVE_REPORTS_PASS")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: NATIVE_WRITER_EVIDENCE_DIR")
    main(sys.argv[1])
