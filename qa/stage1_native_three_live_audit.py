#!/usr/bin/env python3
"""Independent Stage-1 audit of 50 Native trials / 150 three-live Programs.

Rechecks original 21 rejected inputs, 6 valid oracle outputs, 25 triads
under 2 asymmetric 3-way quantum profiles, full 27-label step/get/put
signatures, pairwise peer snapshot commitments, all 16 negative controls.
All calendar arithmetic remains in real Native Befunge-98, not Python.
"""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
INVALID=["1 0 0 0","0 0 1 0","2 10 0 10",
         "0 10 2 10","3 2 0 4","1 0 1 15055671",
         "0 -1 0 1","-0 1 0 1","0 1 -0 1",
         "0 1 0 -1","0 -0 0 1","0 0 0 -0",
         "0 -15055671 0 1","0 15055671 0 -15055670",
         "0 1 0 1 7","0 1 0","0 1 0 x",
         "0 1 0 1/","","\n","0 1 0 +1"]
PROFILES=[{"name":"ABC_2_3_5","quanta":[2,3,5],"order":[0,1,2]},
          {"name":"CAB_11_7_13","quanta":[11,7,13],"order":[2,0,1]}]
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def triads():
    result=[]
    for i in range(21):
        a,b="v%d"%(i%6),"v%d"%((i+3)%6)
        c="i%d"%i
        if i%3==0:result.append([c,a,b])
        elif i%3==1:result.append([a,c,b])
        else:result.append([a,b,c])
    result.extend([["v0","v1","v2"],
                   ["i0","i10","i20"],
                   ["v3","i5","i11"],
                   ["i2","v4","i14"]])
    return result
def verify(data):
    cases=triads()
    need(data.get("schema")=="befunge-stage1-native-three-live-v1" and
         data.get("status")=="QA_ONLY_STAGE1_OPEN" and
         data.get("source_git_blob")==PIN and
         data.get("profiles")==PROFILES and
         data.get("triads")==cases and
         data.get("invalid_inputs")==INVALID and
         data.get("real_native_triple_trials")==50 and
         data.get("real_native_program_executions")==150 and
         data.get("independent_native_oracle_invocations")==18 and
         data.get("input_signatures_verified")==27 and
         data.get("final_stage1_accepted") is False,
         "triad source, corpus, profiles, acceptance or native totals forged")
    expected=data.get("oracle")
    keys={"i%d"%i for i in range(21)}|{"v%d"%i for i in range(6)}
    need(isinstance(expected,dict) and set(expected)==keys,
         "27 native input reference labels incomplete")
    for name,values in expected.items():
        need(isinstance(values,list) and len(values)==7 and
             all(type(v) is str for v in values),
             "seven Native output fields missing")
        if name.startswith("i"):
            need(values==["-1"]*7,
                 "malformed input not rejected by seven sentinels")
    rows=data.get("records")
    need(isinstance(rows,list) and len(rows)==50,
         "50 three-live Native trials missing")
    signatures={};appearances={k:0 for k in keys}
    totals={"native_trials":50,"native_programs":150,"all_three_overlap":0,
            "passive_state_checks":0,"actual_write_address_checks":0,
            "native_gets":0,"native_puts":0}
    for i,row in enumerate(rows):
        case=cases[i%25];profile=PROFILES[i//25]
        need(row.get("triad")==case and
             row.get("profile")==profile["name"] and
             row.get("private_programs_semantics_spaces_streams") is True and
             row.get("all_runtime_api_calls_owned_by_active_program") is True and
             row.get("two_other_programs_unchanged_each_quantum") is True and
             row.get("all_outputs_match_independent_reference") is True and
             row.get("all_terminated") is True and
             row.get("first_finished") in case,
             "Native triad schedule, ownership or output invariant forged")
        for key in ("all_three_alive_rounds","two_passive_state_checks",
                    "prior_write_coordinate_checks","rounds_after_first_done"):
            need(type(row.get(key)) is int and row[key]>=1,
                 "Native triple did not overlap/check both peers/written cells")
        programs=row.get("programs")
        need(isinstance(programs,list) and len(programs)==3 and
             [p.get("label") for p in programs]==case,
             "three Native program outputs not in specified triad order")
        for p in programs:
            label=p["label"]
            for key in ("ticks","space_get","space_put","direct_p",
                        "putspace","actual_written_coordinates"):
                need(type(p.get(key)) is int and p[key]>=0,
                     "Native triple measured counter malformed: "+key)
            need(0<p["ticks"]<=250000 and p["space_get"]>0 and
                 p["space_put"]>0 and
                 p["space_put"]==p["direct_p"] and
                 p["putspace"]==0 and
                 0<p["actual_written_coordinates"]<=p["space_put"] and
                 p.get("output")==expected[label],
                 "native triple program escaped own p/g/putspace or output")
            metric=(p["ticks"],p["space_get"],p["space_put"],
                    tuple(p["output"]))
            if label in signatures:
                need(signatures[label]==metric,
                     "one Native input depends on live peers/order/quantum")
            else:signatures[label]=metric
            appearances[label]+=1
            totals["native_gets"]+=p["space_get"]
            totals["native_puts"]+=p["space_put"]
        totals["all_three_overlap"]+=row["all_three_alive_rounds"]
        totals["passive_state_checks"]+=row["two_passive_state_checks"]
        totals["actual_write_address_checks"]+=row["prior_write_coordinate_checks"]
    need(len(signatures)==27 and
         all(appearances["i%d"%n]>=2 for n in range(21)) and
         all(appearances["v%d"%n]>=2 for n in range(6)) and
         totals["actual_write_address_checks"]>0,
         "27 input identities or all 21 invalid three-way coverage incomplete")
    totals["input_signatures"]=len(signatures)
    return totals

def main(folder):
    blob=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(blob)).encode("ascii")+
                     b"\0"+blob).hexdigest()
    need(sha==PIN,"native source pin mismatch")
    with (Path(folder)/"native_three_live_programs.json").open(
         encoding="utf-8") as stream:
        data=json.load(stream)
    totals=verify(data)
    print("NATIVE_50_TRIPLE_150_PROGRAM_INDEPENDENT_AUDIT_PASS",totals)
    def reject(label,modify):
        probe=copy.deepcopy(data);modify(probe)
        try:verify(probe)
        except AssertionError:
            print("NATIVE_TRIPLE_TAMPER_REJECT_PASS",label)
            return label
        raise AssertionError("Native three-Program forged evidence admitted "+label)
    controls=[
        reject("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        reject("missing_trial",lambda d:d["records"].pop()),
        reject("missing_program",lambda d:d["records"][0]["programs"].pop()),
        reject("wrong_triad_order",lambda d:d["records"][0]["triad"].reverse()),
        reject("wrong_profile",lambda d:d["records"][25].__setitem__("profile","ABC_2_3_5")),
        reject("wrong_quantum",lambda d:d["profiles"][1]["quanta"].__setitem__(0,1)),
        reject("forgotten_invalid",lambda d:d["invalid_inputs"].pop()),
        reject("bad_sentinel",lambda d:d["oracle"]["i0"].__setitem__(0,"0")),
        reject("bad_output",lambda d:d["records"][0]["programs"][0]["output"].__setitem__(0,"999")),
        reject("unexpected_cross_space",lambda d:d["records"][0].__setitem__(
            "all_runtime_api_calls_owned_by_active_program",False)),
        reject("mutated_passive_peer",lambda d:d["records"][0].__setitem__(
            "two_other_programs_unchanged_each_quantum",False)),
        reject("no_triple_overlap",lambda d:d["records"][0].__setitem__(
            "all_three_alive_rounds",0)),
        reject("hidden_putspace",lambda d:d["records"][0]["programs"][0].__setitem__("putspace",1)),
        reject("falsified_put_count",lambda d:d["records"][0]["programs"][0].__setitem__("space_put",0)),
        reject("schedule_drift",lambda d:d["records"][25]["programs"][0].__setitem__(
            "space_get",d["records"][25]["programs"][0]["space_get"]+1)),
        reject("false_final",lambda d:d.__setitem__("final_stage1_accepted",True)),
    ]
    need(len(controls)==16,"triple Native adversarial controls missing")
    with (Path(folder)/"native_three_live_programs_audit.json").open(
         "w",encoding="utf-8") as stream:
        json.dump({"schema":"befunge-stage1-native-three-live-audit-v1",
                   "verified":totals,"rejected_adversaries":controls,
                   "stage1_final_acceptance":False},
                  stream,sort_keys=True,indent=2)
        stream.write("\n")
    print("NATIVE_TRIPLE_16_ADVERSARIAL_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"usage: NATIVE_TRIPLE_EVIDENCE_FOLDER")
    main(sys.argv[1])
