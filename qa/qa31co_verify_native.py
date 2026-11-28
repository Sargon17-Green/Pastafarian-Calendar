"""Reconcile a two-field PyFunge ZIP with the exact source equations and both local BF98 references."""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

from qa31cf_independent_native_audit import git_blob
from qa31ch_scanner_induction import need
from qa31cm_kernel_equations import execute
from qa31cn_two_field_scanners import SPECS, prove as scanner
from qa31co_standalone_equations import proof, references


def audit(archive, originals, candidates, refs):
    references(refs)
    normative = [(refs/(n+".b98")).read_bytes().splitlines() for n in ("day_count","save")]
    with ZipFile(archive) as pack:
        need(pack.testzip() is None and sorted(pack.namelist()) == ["induction.json","native.json"], "ZIP contents/CRC")
        raw = json.loads(pack.read("native.json"))
        induction = json.loads(pack.read("induction.json"))
    tables = {}
    for name,(old,new,width) in SPECS.items():
        a = (originals/(name+".b98")).read_bytes()
        b = (candidates/(name+".b98")).read_bytes()
        need((git_blob(a),git_blob(b)) == (old,new), "program identities")
        generated = dict(scanner(a,b,width),original=old,candidate=new)
        need(induction[name] == json.loads(json.dumps(generated)), "scanner certificate")
        tables[name]=proof(name,a)

    def reference(name,fields):
        s,m=fields
        inputs=(s,m) if s in (0,1) else (s,)
        refs_out=[execute(src,(0,0),(1,0),{},scope="reference",end=None,inputs=inputs)[0] for src in normative]
        out = {"day_count":refs_out[0],"save":refs_out[1],"interleaved_day_save":refs_out[0]+refs_out[1]}
        return list(map(str,out[name]))

    accepted = {b"0 0\n",b"0 1",b"\t1\r\n1 \t",b"1 15055671\n",b"1 15055672",
                b"0 170141183460469231731687303715884105727\n",b"1 "+b"9"*81,b"1 0\n",b"2 10\r\n"}
    malformed = {b"0 -1\n",b"0 +1\n",b"0 1 7\n",b"0 x1\n",b"-0 1\n",b"",b"0",b"0\n",
                 b"1 2x",b"0 1\x00",b"0 1\xff",b"0\v1",b"0\f1"}
    reds = {b"0 -1\n",b"0 +1\n",b"0 1 7\n",b"0 x1\n",b"-0 1\n"}
    step_count = original_red = 0
    for key,inputs in (("exact_suffixes",accepted),("lexical_rejections",malformed)):
        rows = raw[key]
        need(len(rows) == len(inputs)*len(SPECS) and
             {(r["name"],bytes.fromhex(r["raw_hex"])) for r in rows} == {(n,x) for n in SPECS for x in inputs},
             "receipt input matrix")
        for row in rows:
            name,code = row["name"],bytes.fromhex(row["raw_hex"])
            new=row["candidate"]
            if key=="lexical_rejections":
                need(new["output"] == ["-1"]*SPECS[name][2] and not new["suffix_steps"] and
                     new["suffix_sha256"] == hashlib.sha256(b"").hexdigest(), "malformed input reached body")
                need(("original" in row)==(code in reds),"original RED case set")
                if code in reds:
                    need(row["original"]["output"] == reference(name,(0,1)), "original misparse evidence")
                    original_red += 1
                continue
            s,m=map(int,code.split())
            expected=reference(name,(s,m))
            valid=s==0 or (s==1 and m>0)
            t=tables[name]
            digits=len(str(m)) if m else 0
            count=t["initial_steps"]+digits*t["steps_per_decimal_digit"]+t["exit_steps"]["valid" if valid else "invalid"]
            old=row["original"]
            need(count==new["suffix_steps"]==old["suffix_steps"], "source-predicted native suffix length")
            need(old["output"]==new["output"]==expected==row["native_reference"], "reference output")
            for field in ("suffix_g","suffix_p","suffix_sha256"):
                need(old[field]==new[field] and old[field],"arithmetic motion or memory parity")
            step_count += count
    return {"signed_zip_sha256":hashlib.sha256(archive.read_bytes()).hexdigest(),
            "native_suffix_comparisons":len(accepted)*3,"compared_suffix_steps":step_count,
            "native_lexical_rejections":len(malformed)*3,"verified_original_red":original_red}


if __name__ == "__main__":
    p=argparse.ArgumentParser(description=__doc__)
    for arg in ("archive","originals","candidates","refs"): p.add_argument(arg,type=Path)
    args=p.parse_args()
    print(json.dumps(audit(args.archive,args.originals,args.candidates,args.refs),sort_keys=True))
