#!/usr/bin/env python3
"""QA31F: offline audit of the original signed QA20/QA31A Native artifacts.

Usage: python qa/stage1_qa31f_original_latent_row32_audit.py \
  shard0.zip shard1.zip shard2.zip shard3.zip qa31a.zip \
  --source src/interleaved_work_counts.b98
No Befunge re-execution; this does not prove global reachability.
"""
import argparse
import collections
import gzip
import hashlib
import json
import pathlib
import zipfile

SHARDS = (
    "0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076",
    "0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea",
    "d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c",
    "d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07",
)
QA31A_ZIP = "235be0d04cc2f6ab113b3a809c3a2ef93513c07cb2233b2b8b457722d409a4cd"
QA31A_JSON = "39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c"
SOURCE_BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def verified_source(path):
    data = pathlib.Path(path).read_bytes()
    git_sha = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
    need(git_sha == SOURCE_BLOB, "immutable original source blob mismatch")
    rows = data.splitlines()
    need(all(rows[y][x] == ord(op) for (x,y,op) in (
        (10,29,">"),(57,29,"g"),(89,29,"j"),(150,29,"x"),
        (211,29,"x"),(10,32,">"),(344,26,"p"))),
        "original source opcode geometry changed")
    def literals(chunk):
        stack=[]
        for char in chunk.decode("ascii"):
            if char == " ":
                continue
            if char in "0123456789abcdef":
                stack.append(int(char,16))
            elif char in "+-*":
                need(len(stack)>=2, "unbalanced static literal builder")
                rhs,lhs=stack.pop(),stack.pop()
                stack.append(lhs+rhs if char=="+" else lhs-rhs if char=="-" else lhs*rhs)
            else:
                raise AssertionError("nonliteral static vector sequence")
        return stack
    pre=rows[29][10:90].decode("ascii")
    need(pre.startswith(">") and pre.endswith("*j") and pre.count("g")==1
         and pre.count("j")==1, "original row29 branch changed")
    before_g,after_g=pre[1:].split("g")
    need(literals(before_g.encode())==[3,49]
         and literals(after_g[:-2].encode())==[61],
         "row29 branch no longer computes 61 * FungeSpace(3,49)")
    need(literals(rows[29][90:150])==[-140,9]
         and literals(rows[29][151:211])==[-201,3],
         "row29 x landing vectors changed")
    # Original source read-only static zero initializers and the input-only put.
    need(rows[2][202] == ord("p") and rows[26][344] == ord("p")
         and rows[5][60] == ord("p") and rows[5][13] == ord("~")
         and literals(rows[2][155:202]) == [0, 3, 49]
         and literals(rows[26][297:344]) == [0, 3, 49]
         and literals(rows[5][14:60]) == [0, 49],
         "original zero put / stdin put ownership geometry drift")
    return True

def steps_at(trace, x, y, op):
    return [(i,s) for i,s in enumerate(trace)
            if s[1:3]==(x,y) and s[5]==ord(op) and s[6]==0]

def audit(shards,qa31a_path,source):
    verified_source(source)
    raw=pathlib.Path(qa31a_path).read_bytes()
    need(digest(raw)==QA31A_ZIP,"QA31A ZIP hash")
    with zipfile.ZipFile(qa31a_path) as z:
        need(z.testzip() is None,"QA31A ZIP CRC")
        data=z.read("qa31a_native_outcome_variation.json")
        need(digest(data)==QA31A_JSON,"QA31A JSON hash")
        q=json.loads(data)
    near=q["per_original_unobserved_target"]["10,32"]
    need(q["immutable_production_source_blob"]==SOURCE_BLOB
         and q["original_native_programs"]==136
         and q["original_native_steps"]==4513423
         and q["original_unobserved_targets_still_not_reached"]==15
         and near["observed_distinct_control_states_within_l1_9"]==5
         and near["observed_differential_control_states"]==0
         and q["stage1_complete"] is False,"QA31A finite baseline drift")
    counts=collections.Counter()
    last_zero_put=collections.Counter()
    intervening_input_puts=collections.Counter()
    all_labels=set()
    for shard,p in enumerate(shards):
        need(digest(pathlib.Path(p).read_bytes())==SHARDS[shard],
             "Original QA20 ZIP hash mismatch "+str(shard))
        with zipfile.ZipFile(p) as z:
            need(z.testzip() is None,"QA20 ZIP CRC")
            m=json.loads(z.read("qa20_manifest.json"))
            need(m["shard"]==shard and m["source_git_blob"]==SOURCE_BLOB
                 and not m["source_modified"] and not m["ip_relocated"]
                 and len(m["records"])==12,"QA20 provenance drift")
            for rec in m["records"]:
                need(rec["label"] not in all_labels,"duplicate QA20 case")
                all_labels.add(rec["label"])
                blob=z.read(rec["path"])
                need(digest(blob)==rec["compressed_trace_sha256"],
                     "signed compressed STEP hash drift")
                trace=[tuple(map(int,ln.split(b"\t")))
                       for ln in gzip.decompress(blob).splitlines()]
                need(len(trace)==rec["steps"] and all(
                     len(s)==7 and s[0]==i for i,s in enumerate(trace,1)),
                     "Native STEP numbering drift")
                j=steps_at(trace,89,29,"j")
                x0=steps_at(trace,150,29,"x")
                x1=steps_at(trace,211,29,"x")
                target=steps_at(trace,10,32,">")
                read=steps_at(trace,57,29,"g")
                need(len(j)<=1 and len(x0)<=1 and not x1 and not target,
                     "QA20 latent branch unexpectedly executed")
                if j:
                    i,step=j[0]
                    need(i+1<len(trace) and trace[i+1][1:5]==(90,29,1,0),
                         "signed original j successor not (90,29)")
                    need(len(x0)==1 and len(read)==1 and read[0][1][0]<step[0],
                         "missing original read / x150 witness")
                    # Finite physical lineage only: genuine signed opcode coordinates.
                    # This is not a direct memory-value measurement or an all-input proof.
                    p202=steps_at(trace,202,2,"p")
                    p344=steps_at(trace,344,26,"p")
                    need(len(p202)==1 and p202[0][0]<i
                         and all(t<i for t,_ in p344),
                         "missing or late original startup zero put")
                    # No recorded storage-offset/stack-stack mutation can rebase
                    # the literal physical destinations between startup and this gate.
                    need(not any(s[6]==0 and s[5] in (ord("{"),ord("}"),ord("u"))
                                 for s in trace[p202[0][0]:i]),
                         "unaccounted ownership / storage-offset instruction")
                    origin=p344[-1] if p344 else p202[0]
                    later_puts=[s for s in trace[origin[0]+1:i]
                                if s[5]==ord("p") and s[6]==0]
                    need(all(s[1:3]==(60,5) for s in later_puts),
                         "other actual put before original row29 gate")
                    # p(60,5) has literal target (0,49), not the gate's (3,49).
                    need(not p344 or not later_puts,
                         "unexpected put after row26 zero initializer")
                    last_zero_put[(rec["valid"],origin[1][1:3])]+=1
                    intervening_input_puts[len(later_puts)]+=1
                else:
                    need(not read and not x0,"control observed without row29 jump")
                counts[(rec["valid"],bool(j))]+=1
    need(len(all_labels)==48 and counts=={(True,True):27,
         (False,True):9,(False,False):12},
         "Original QA20 corpus distribution drift")
    need(last_zero_put == {(True,(344,26)):27, (False,(344,26)):7,
                           (False,(202,2)):2}
         and intervening_input_puts == {0:34,1:1,2:1},
         "QA20 original pre-j zero put lineage drift")
    return {
        "schema":"qa31f-latent-row32-original-native-offline-v1",
        "signed_original_native_qa20_cases":48,
        "signed_original_qa31a_programs":136,
        "new_native_executions":0,"original_source_blob_verified":True,
        "j_89_29_observed":36,"j_successor_90_29":36,
        "x_150_29_observed":36,"x_211_29_observed":0,
        "target_10_32_observed":0,"valid_j29":27,"invalid_j29":9,
        "near_l1_9_control_states":5,"near_differential_states":0,
        "conditional_m_1_route":"j89 -> x151 -> x211 -> (10,32)",
        "qa20_pre_j_startup_zero_put_202_2":36,
        "qa20_last_zero_put_344_26":34,
        "qa20_last_zero_put_202_2":2,
        "qa20_intervening_input_put_60_5_cases":2,
        "qa20_intervening_other_puts_to_gate_after_zero":0,
        "qa20_recorded_storage_offset_rebases_pre_j":0,
        "qa20_ownership_scope":"finite signed STEP sites plus pinned original static operands",
        "m_equals_1_natural_input_witness_proven":False,
        "global_reachability_proven":False,"stage1_complete":False,
    }

def main():
    p=argparse.ArgumentParser()
    p.add_argument("shards",nargs=4)
    p.add_argument("qa31a")
    p.add_argument("--source",required=True)
    a=p.parse_args()
    print(json.dumps(audit(a.shards,a.qa31a,a.source),indent=2))

if __name__=="__main__":
    main()
