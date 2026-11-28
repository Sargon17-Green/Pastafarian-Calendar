#!/usr/bin/env python3
"""QA31E offline proof-bound audit of original QA20 Native STEP artifacts.
Usage: python qa/stage1_qa31e_signed_counter_audit.py shard0.zip shard1.zip shard2.zip shard3.zip qa31a.zip
No Befunge reexecution; requires the exact signed original GitHub Actions ZIP files.
"""
import collections
import gzip
import hashlib
import json
import pathlib
import sys
import zipfile

SHA = {
  0: "0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076",
  1: "0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea",
  2: "d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c",
  3: "d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07",
}
QA31A_ZIP = "235be0d04cc2f6ab113b3a809c3a2ef93513c07cb2233b2b8b457722d409a4cd"
QA31A_JSON = "39f017ea8cb4b6865df031639763f8546fb87427ca94b487e18493fc475a189c"
SOURCE = "560d6aa5807a7f766213a33835cce85eab0fa40c"

def digest(data):
    return hashlib.sha256(data).hexdigest()

def require(cond, message):
    if not cond:
        raise AssertionError(message)

def audit(paths):
    require(len(paths) == 5, "Expected four original QA20 ZIPs and QA31A ZIP")
    cases = []
    seen = set()
    for p in paths[:4]:
        with zipfile.ZipFile(p) as z:
            require(z.testzip() is None, "ZIP CRC failure: " + p)
            m = json.loads(z.read("qa20_manifest.json"))
            shard = m["shard"]
            require(shard in SHA and shard not in seen, "Wrong/duplicate shard")
            require(digest(pathlib.Path(p).read_bytes()) == SHA[shard], "Original ZIP SHA mismatch")
            require(m["source_git_blob"] == SOURCE, "Source blob mismatch")
            require(not m["source_modified"] and not m["ip_relocated"], "Not an original route")
            require(m["native_case_count"] == 12 and len(m["records"]) == 12, "Case count")
            seen.add(shard)
            for rec in m["records"]:
                raw = z.read(rec["path"])
                require(digest(raw) == rec["compressed_trace_sha256"], "STEP hash " + rec["label"])
                lines = gzip.decompress(raw).decode("ascii").splitlines()
                require(len(lines) == rec["steps"], "STEP length " + rec["label"])
                steps = [tuple(map(int, line.split("\t"))) for line in lines]
                require(all(len(s) == 7 and s[0] == n for n,s in enumerate(steps,1)), "STEP sequence")
                init = [s[0] for s in steps if s[1:3] == (106,2) and s[5] == 112]
                jumps = [i for i,s in enumerate(steps) if s[1:3] == (114,38) and s[5] == 106]
                reads = [s[0] for s in steps if s[1:3] == (57,38) and s[5] == 103]
                require(init == [146] and len(jumps) <= 1, "Unexpected init/j")
                record = {"label":rec["label"],"shard":shard,"valid":rec["valid"],
                          "step_count":len(steps),"j_tick":None}
                if jumps:
                    i = jumps[0]
                    j = steps[i]
                    inc = [s[0] for s in steps[:i] if s[1:3] == (248,26) and s[5] == 112]
                    require(i+1 < len(steps) and reads == [j[0]-50], "Missing pre-j read/next step")
                    require(all(t > 146 for t in inc), "Pre-init increment")
                    require(all(s[5] not in (123,125,117,107) for s in steps[:i]), "Offset/stack op")
                    next_step = steps[i+1]
                    require(j[3:5] == (1,0) and next_step[2] == 38, "Jump vector")
                    require(len(inc) in (0,3,4), "Unexpected count; investigate before acceptance")
                    require(next_step[1] == (176 if len(inc)==4 else 115), "Unexpected successor")
                    record.update(j_tick=j[0], g_tick=reads[0], increment_ticks=inc,
                                  increment_count=len(inc), next_x=next_step[1])
                else:
                    require(not reads, "Read without j")
                cases.append(record)
    require(seen == set(SHA) and len(cases) == 48, "Incomplete QA20 corpus")
    require(len({c["label"] for c in cases}) == 48, "Duplicate case")
    with zipfile.ZipFile(paths[4]) as z:
        require(z.testzip() is None, "QA31A ZIP CRC")
        require(digest(pathlib.Path(paths[4]).read_bytes()) == QA31A_ZIP, "QA31A ZIP SHA")
        data = z.read("qa31a_native_outcome_variation.json")
        require(digest(data) == QA31A_JSON, "QA31A JSON SHA")
        qa31a = json.loads(data)
        require(qa31a["immutable_production_source_blob"] == SOURCE, "QA31A source")
        require(qa31a["original_github_groups"]["QA20"]["cases"] == 48, "QA31A QA20 coverage")
        require(qa31a["stage1_complete"] is False, "Stage acceptance changed")
    counts = collections.Counter((c["valid"],c.get("increment_count"))
             for c in cases if c["j_tick"] is not None)
    require(sum(c["valid"] for c in cases) == 27, "Valid count")
    require(counts == {(True,4):27,(False,4):6,(False,3):1,(False,0):2}, "Distribution")
    print(json.dumps({"scope":"original QA20 48 cases; QA31A summary 136 programs",
          "stage1_pass":False,"qa20_valid_j":27,"qa20_invalid_j":9,
          "no_valid_counterexample_in_qa20":True,
          "cases":sorted(cases,key=lambda c:c["label"])},indent=2))

if __name__ == "__main__":
    audit(sys.argv[1:])
