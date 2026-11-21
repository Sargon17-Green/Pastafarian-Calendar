#!/usr/bin/env python3
"""Join QA31BH to the canonical archives and follow physical cell (61,1706) to overwrite or HALT."""
import argparse
import csv
import gzip
import hashlib
import io
import json
import zipfile
from bisect import bisect_left
from collections import Counter
from contextlib import ExitStack
from pathlib import Path

PROJECT = "PC-BRANCH-BEFUNGE98-KYRGYZ"
SOURCE = "560d6aa5807a7f766213a33835cce85eab0fa40c"
AI = "9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49"
AH = "4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271"
Y = "1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a"
BC = "2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77"
BG = "55ffd0b31d26c14b55b26666ec6705f9db6686ca80028cac71329b70899052d7"
BH = "5db9170c1c856fd6fe440a1a32155eceebf2db44a3812678445baac844d9a933"
LEDGER = "553b69d156d6c547c84a601bb7151e13142a16e6dbc1d3d856dba7f86892236d"
TARGET = [61, 1706]
MOD = (1 << 127) - 1


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()


def archive(data, pin):
    require(sha(data) == pin, "archive SHA256")
    z = zipfile.ZipFile(io.BytesIO(data))
    require(len(z.namelist()) == len(set(z.namelist())) and z.testzip() is None, "archive CRC/name")
    return z


def at(rows, tick):
    require(1 <= tick <= len(rows), "tick outside signed trace")
    e = rows[tick-1]
    require(e["t"] == tick, "signed event identity")
    return e


def anchor(rows, t, op, ip, args):
    ev = at(rows,t)
    require(not ev["string"] and ev["op"] == ord(op) and ev["ip"] == ip
            and ev["pre"][-len(args):] == args, "physical anchor "+str((t,op,ip)))
    return ev


def join_bh(rows, w, bg, csv_record):
    t = w["second_x_t"]
    require(sha(canonical(w)) == csv_record["window_record_sha256"], "window ledger digest")
    require(at(rows,t)["ip"] == [540,195] and at(rows,t)["next"] == [575,670], "second x")
    require(w["root_t"] == bg["g43b_t"] == t+901, "BG/BH root")
    a = anchor(rows,t+882,"g",[193,195],TARGET)["post"][-1]
    b = anchor(rows,t+901,"g",[174,195],[43,1702])["post"][-1]
    require(a >= 0 and b >= 0 and b == bg["p43_value"], "signed nonnegative operands")
    rem = anchor(rows,t+1270,"%",[860,205],[a+b,MOD])
    val = (a+b) % MOD
    require(rem["post"][-1] == val and w["first_consumer"]["operands"] == [a+b,MOD],
            "physical modulo operand/result")
    put = anchor(rows,t+1309,"p",[1440,575],[val,*TARGET])
    gate = w["first_dependent_gate"]
    require(w["first_consumer"]["t"] == rem["t"] and gate["t"] == put["t"]
            and gate["operands"] == [val,*TARGET] and gate["dependent"] == [True,False,False],
            "physical writer and operand roles")
    for n in (0,1):
        require(gate[f"conditional_{n}"] == [(a+n)%MOD,*TARGET], "fixed-g conditional value")
    require(w["stack_lineage_extinguished"]["t"] == put["t"] and not w["final_dependent_slots"]
            and w["extension_steps"] == 512 and w["divergence"] is None, "BH boundary and branch comparison")
    return a,b,put


def signature(ev, value):
    return [ev["t"],ev["ip"],value]


def forward(rows, writer_t):
    """Chronological scan. Include any opcode fetch on a replacing STEP before its data write."""
    value = at(rows,writer_t)["pre"][-3]
    reads, fetches = [], []
    for e in rows[writer_t:]:
        if e["ip"] == TARGET:
            require(e["op"] == value, "owned instruction fetch value")
            fetches.append(signature(e,e["op"]))
        if e["string"] or e["pre"][-2:] != TARGET:
            continue
        if e["op"] == ord("g"):
            require(e["post"] == e["pre"][:-2]+[value], "owned g physical value")
            reads.append(signature(e,value))
        elif e["op"] == ord("p"):
            require(e["post"] == e["pre"][:-3], "replacing p stack")
            return reads,fetches,signature(e,e["pre"][-3])
    require(rows[-1]["op"] == 64 and rows[-1]["next"] is None,"final HALT")
    return reads,fetches,None


class WriterIndex:
    """Attribute every observed read/fetch to the greatest strictly earlier write tick."""
    def __init__(self, rows):
        stores, uses = [], []
        for e in rows:
            ip, pre, t = e["ip"],e["pre"],e["t"]
            if ip[0] == 61 and ip[1] == 1706:
                uses.append((t,"fetch",[t,ip,e["op"]]))
            if e["string"] or len(pre)<2 or (pre[-2],pre[-1]) != (61,1706):
                continue
            if e["op"] == 112:
                stores.append([t,ip,pre[-3]])
            elif e["op"] == 103:
                uses.append((t,"g",[t,ip,e["post"][-1]]))
        self.epochs = {w[0]:([],[],following) for w,following in zip(stores,stores[1:]+[None])}
        times = [w[0] for w in stores]
        for tick, kind, observation in uses:
            i = bisect_left(times,tick)-1
            if i >= 0:
                self.epochs[times[i]][int(kind=="fetch")].append(observation)


def agree(a,b):
    require(a == b, "independent owner epochs disagree")


def hostile(rows, writer_t, outcome):
    """Synthetic edge graphs and deliberate corruptions of signed, independent proof fields."""
    def ev(t,op,ip,pre,post,string=False):
        return dict(t=t,op=op,ip=ip,pre=pre,post=post,string=string,next=None if op==64 else [0,0])
    # The last two g events have equal numeric values but different writer identities.
    test = [ev(1,112,[1,0],[7,*TARGET],[]),ev(2,103,[2,0],TARGET,[7]),
            ev(3,103,[3,0],TARGET,[7],True),ev(4,112,[4,0],[7,*TARGET],[]),
            ev(5,103,[5,0],TARGET,[7]),ev(6,64,[6,0],[],[])]
    ex1=([[2,[2,0],7]],[],[4,[4,0],7]); ex2=([[5,[5,0],7]],[],None)
    for tick, expected in ((1,ex1),(4,ex2)):
        agree(forward(test,tick), expected)
        agree(WriterIndex(test).epochs[tick],expected)
    # A cell containing numeric 112 is fetched as p and overwritten at the same physical tick.
    self_put = [ev(1,112,[1,0],[112,*TARGET],[]),ev(2,112,TARGET,[4,*TARGET],[]),
                ev(3,64,[3,0],[],[])]
    ex3=([],[[2,TARGET,112]],[2,TARGET,4])
    agree(forward(self_put,1),ex3)
    agree(WriterIndex(self_put).epochs[1],ex3)
    fake = [[[3,[6,7],88]], [[3,[6,7],88]], [writer_t+1,[6,7],88]]
    rejected = []
    from copy import deepcopy
    def expect(label, orig, bad):
        require(orig != bad, "no-op mutation "+label)
        try:
            agree(orig,bad)
        except ValueError as err:
            require(str(err) == "independent owner epochs disagree", "unexpected error")
            rejected.append(label)
        else:
            raise ValueError("accepted corruption "+label)
    for title, idx in (("forged-read",0),("forged-fetch",1),("wrong-next-writer",2)):
        mutant=deepcopy(list(outcome))
        if idx<2:
            mutant[idx] += fake[idx]
        else:
            mutant[idx] = fake[idx] if mutant[idx] != fake[idx] else None
        expect(title,outcome,tuple(mutant))
    for n,idx in enumerate((0,1,2)):
        bad=deepcopy(ex1); bad[0][0][idx] = [9,33] if idx==1 else 99
        expect(("read-tick","read-site","read-value")[n],ex1,bad)
        bad=deepcopy(ex1); bad[2][idx] = [9,33] if idx==1 else 99
        expect(("overwrite-tick","overwrite-site","overwrite-value")[n],ex1,bad)
    expect("read-after-equal-overwrite",ex1,(ex1[0]+ex2[0],[],ex1[2]))
    expect("string-mode-op-counted",ex1,(ex1[0]+[[3,[3,0],7]],[],ex1[2]))
    expect("missed-same-tick-fetch",ex3,([],[],ex3[2]))
    expect("invented-overwrite-at-HALT",ex2,(ex2[0],[],[6,[6,0],7]))
    # Alter actual records in the first original witness. Compare a new forward
    # scan against the independently indexed, unchanged signed epoch.
    read_tick = outcome[0][0][0]
    real_value = at(rows,writer_t)["pre"][-3]
    require(read_tick > writer_t+1, "signed mutation slots")
    actual_controls = []
    def changed_event(label, tick, edit, expected):
        sample = rows[:]
        original = at(rows,tick)
        altered = deepcopy(original)
        edit(altered)
        require(altered != original, "no-op signed event "+label)
        sample[tick-1] = altered
        try:
            agree(forward(sample,writer_t),outcome)
        except ValueError as error:
            require(str(error) == expected, "unexpected signed-mutant rejection "+label)
            actual_controls.append(label)
        else:
            raise ValueError("accepted signed-record mutation "+label)
    different = "independent owner epochs disagree"
    g_value = "owned g physical value"
    changed_event("reader-x",read_tick,lambda e:e["pre"].__setitem__(-2,62),different)
    changed_event("reader-y",read_tick,lambda e:e["pre"].__setitem__(-1,1707),different)
    changed_event("reader-in-string",read_tick,lambda e:e.update(string=True),different)
    changed_event("reader-elided",read_tick,lambda e:e.update(op=122),different)
    changed_event("reader-result",read_tick,lambda e:e["post"].__setitem__(-1,real_value+1),g_value)
    changed_event("reader-stack-shape",read_tick,lambda e:e["post"].insert(0,888),g_value)
    changed_event("reader-instruction-site",read_tick,lambda e:e["ip"].__setitem__(0,e["ip"][0]+1),different)
    changed_event("reader-clock",read_tick,lambda e:e.update(t=read_tick+1),different)
    changed_event("writer-numeric-value",writer_t,lambda e:e["pre"].__setitem__(-3,real_value+1),g_value)
    changed_event("interposed-equal-value-p",writer_t+1,
                  lambda e:e.update(op=112,string=False,pre=[real_value,*TARGET],post=[]),different)
    changed_event("interposed-g",writer_t+1,
                  lambda e:e.update(op=103,string=False,pre=TARGET[:],post=[real_value]),different)
    changed_event("interposed-code-fetch",writer_t+1,
                  lambda e:e.update(op=real_value,ip=TARGET[:],string=True),different)
    return rejected, actual_controls


def run(args):
    lists, counts, categories = [], Counter(), Counter()
    verdicts, signed_controls = [], []
    with ExitStack() as st:
        def openzip(data, pin):
            return st.enter_context(archive(data,pin))
        ai,bc,bg,bh = [openzip(p.read_bytes(),h) for p,h in zip(
            (args.ai,args.bc,args.bg,args.bh),(AI,BC,BG,BH))]
        ah = openzip(ai.read("QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip"),AH)
        y = openzip(ah.read("QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip"),Y)
        crc_members = len(bh.namelist())
        manifest = json.loads(bh.read("SHA256.json"))
        require(set(manifest)==set(bh.namelist())-{"SHA256.json"} and
                all(sha(bh.read(n))==h for n,h in manifest.items()),"CI artifact member manifest")
        ledger = bh.read("witnesses.csv")
        require(sha(ledger)==LEDGER,"CI ledger SHA256")
        csv_refs={(r["trace_sha256"],int(r["second_x_t"])):r for r in csv.DictReader(io.StringIO(ledger.decode()))}
        ci=json.loads(bh.read("summary.json"))
        index=json.loads(bc.read("qa31bc_full_original_selector_routes.json"))
        require(ci["source_blob"]==index["source_git_blob"]==SOURCE and
                index["original_signed_archive_sha256"]==AI,"source/corpus identity")
        cases={(r["shard"],r["trace_sha256"]):r for r in index["per_case"]}
        by_key={(r["shard"],r["raw_hex"]):r["trace_sha256"] for r in index["per_case"]}
        vertical={(by_key[(r["shard"],r["raw_hex"])],r["select_t"]+64) for r in index["events"]
                  if r["selector_value"]==118}
        prior=json.loads(bg.read("QA31BG_PHYSICAL.json"))
        bg_refs={(r["trace_sha256"],r["second_x_t"]):r for r in prior["witnesses"]}
        require(len(cases)==200 and len(vertical)==225 and vertical==set(csv_refs)==set(bg_refs),
                "canonical BC/BG/BH witness sets")
        for sn,(_,pin) in enumerate(ci["shard_ids_and_hashes"]):
            with archive(y.read(f"QA31V_SHARD{sn}.zip"),pin) as sh:
                recs=json.loads(sh.read("qa31v_receipt.json"))
                require(recs["shard"]==sn and recs["source_blob"]==SOURCE and len(recs["cases"])==25,
                        "shard identity")
                for rec in recs["cases"]:
                    blob=sh.read(rec["trace"]); dg=sha(blob); meta=cases.pop((sn,dg))
                    label=rec["label"]; derived=json.loads(bh.read(label+".json"))
                    require(rec["status"]=="HALT" and rec["error"] is None and rec["steps"]<=25000
                            and dg==rec["trace_sha256"]==derived["trace_sha256"]
                            and meta["trace"]==rec["trace"] and meta["raw_hex"]==rec["raw_hex"]==derived["raw_hex"]
                            and sha(bytes.fromhex(rec["raw_hex"]))==rec["raw_sha256"]==derived["raw_sha256"],
                            "case input or compressed trace identity")
                    rows=[json.loads(line) for line in gzip.decompress(blob).splitlines()]
                    require(len(rows)==rec["steps"]==meta["steps"]==derived["case_steps"] and
                            all(i==r["t"] for i,r in enumerate(rows,1)) and
                            all(a["next"]==b["ip"] and a["next_delta"]==b["delta"] and a["post"]==b["pre"]
                                for a,b in zip(rows,rows[1:])) and
                            rows[-1]["op"]==64 and rows[-1]["next"] is None,"signed continuity/HALT")
                    idx=WriterIndex(rows)
                    physical_x={r["t"] for r in rows if not r["string"] and r["op"]==120
                                and r["ip"]==[540,195] and r["next"]==[575,670]}
                    require(physical_x=={w["second_x_t"] for w in derived["windows"]},"original second x set")
                    counts.update(cases=1,steps=len(rows))
                    for w in derived["windows"]:
                        t=w["second_x_t"]; key=(dg,t); old,root,p=join_bh(rows,w,bg_refs.pop(key),csv_refs.pop(key))
                        origin=p["t"]; evidence=forward(rows,origin)
                        agree(evidence,idx.epochs[origin])
                        reads,fetches,next_put=evidence
                        for ob in reads+fetches:
                            require(ob[2]==p["pre"][-3],"physical read with wrong last writer")
                        if not verdicts:
                            verdicts,signed_controls=hostile(rows,origin,evidence)
                        end=next_put[0] if next_put else rows[-1]["t"]
                        categories[("reads_then_" if reads else "no_reads_then_")
                                   +("overwrite" if next_put else "HALT")]+=1
                        lists.append(dict(case=label,trace_sha256=dg,second_x_t=t,
                            old61=old,root43=root,p61_tick=origin,p61_value=p["pre"][-3],
                            hold_0=old%MOD,hold_1=(old+1)%MOD,reads=reads,fetches=fetches,
                            next_put=next_put,halt_t=rows[-1]["t"],lifetime_steps=end-origin))
                        counts.update(windows=1,owned_reads=len(reads),owned_fetches=len(fetches),
                            overwritten=int(next_put is not None),reached_halt=int(next_put is None),
                            original_formula_checks=1,conditional_pairs=1,independent_epochs=1)
    require(not cases and not csv_refs and not bg_refs and
            (counts["cases"],counts["steps"],counts["windows"])==(200,3628390,225), "corpus coverage")
    require(len(verdicts)==13 and len(signed_controls)==12,"negative controls")
    args.out.mkdir(parents=True,exist_ok=False)
    with (args.out/"witnesses.jsonl").open("wb") as dst:
        for r in lists: dst.write(canonical(r)+b"\n")
    summary=dict(project=PROJECT,source_blob=SOURCE,canonical_archives=dict(AI=AI,AH=AH,Y=Y,BC=BC,BG=BG),
        bh_artifact_sha256=BH,bh_ledger_sha256=LEDGER,ci_member_crc_count=crc_members,
        ci_member_manifest_count=len(manifest),counts=dict(counts),outcomes=dict(categories),
        reader_sites=dict(Counter(str(ob[1]) for r in lists for ob in r["reads"])),
        overwrite_sites=dict(Counter(str(r["next_put"][1]) for r in lists if r["next_put"])),
        first_reader_offset_from_second_x=dict(Counter(str(r["reads"][0][0]-r["second_x_t"]) for r in lists if r["reads"])),
        reads_per_writer=dict(Counter(len(r["reads"]) for r in lists)),
        lifetime_step_range=[min(r["lifetime_steps"] for r in lists),max(r["lifetime_steps"] for r in lists)],
        signed_record_mutations_rejected=signed_controls,projection_and_edge_mutations_rejected=verdicts,
        synthetic_positive_epochs=3,unique_cases_with_windows=len({r["case"] for r in lists}),
        old61_range=[min(r["old61"] for r in lists),max(r["old61"] for r in lists)],
        root43_range=[min(r["root43"] for r in lists),max(r["root43"] for r in lists)],
        stored61_range=[min(r["p61_value"] for r in lists),max(r["p61_value"] for r in lists)],
        actual_modulus_reductions=sum(r["p61_value"] != r["old61"]+r["root43"] for r in lists),
        conditional_unit_increments=sum(r["hold_1"]-r["hold_0"]==1 for r in lists),
        equal_value_overwrites=sum(r["next_put"] is not None and r["p61_value"]==r["next_put"][2] for r in lists),
        witnesses_sha256=sha((args.out/"witnesses.jsonl").read_bytes()),new_native=0,stage1_pass=False)
    (args.out/"summary.json").write_text(json.dumps(summary,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps(summary,sort_keys=True))


if __name__ == "__main__":
    ap=argparse.ArgumentParser(description=__doc__)
    for name in ("ai","bc","bg","bh","out"):
        ap.add_argument("--"+name,type=Path,required=True)
    run(ap.parse_args())
