#!/usr/bin/env python3
"""Research adapter only. Requires Linux, Chapel 2.10.0, original selected-rank artifact ZIP."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import zipfile
from itertools import product
from weaving_small_exact_oracle import brute_words
from weaving_native_median_evidence_gate import MONTH_LENGTHS, ROOT_SHA256, digest_word, verify_fifo_word

sys.set_int_max_str_digits(10000)
BASE = "31a81db88d747dc8b4fd989b07a628a9a039d164"
ZIP_SHA = "7178d5d68bb3dcba8bd823d675aea463b7b9816f24dc199f21301e775cf626e3"
RANK0_SHA = "8e0af63f025b7bd47520a13164a458484687e2c983137dfaec6546cb6e905c22"
RSS_KIB = 524288
OLD = "    var counter: SparseWeavingCounter;\n    counter.lengths = monthLengths;\n    const stream = askBowl(structureSauce, 4, SEAL_MONTH_WEAVING);\n    return counter.unrank1(chooseRank(stream, counter.countAll()));"
NEW = "    const m = monthLengths.size;\n    if m < 1 then halt(\"Adapter empty month family\");\n    const D = {1..m};\n    var lens: [D] int;\n    for j in D {\n      lens[j] = monthLengths[j-1];\n      if lens[j] < 1 then halt(\"Adapter nonpositive month length\");\n    }\n    var specs: [D] SparseWeavingGapSpec;\n    var states: [D] SparseWeavingVec;\n    var sizes: [D] int;\n    var total = sparseWeavingSetup(lens,states,sizes,specs);\n    const root = total;\n    const stream = askBowl(structureSauce, 4, SEAL_MONTH_WEAVING);\n    const rank1 = chooseRank(stream,root);\n    if rank1 < 1 || rank1 > root then halt(\"Adapter rank1 outside root\");\n    writeln(\"ADAPTER_ROOT=\",root);\n    writeln(\"ADAPTER_RANK1=\",rank1);\n    writeln(\"ADAPTER_LENGTHS=\",adapterCsv(monthLengths));\n    const word = sparseWeavingUnrankFromState(lens,states,sizes,specs,total,rank1-new bigint(1));\n    writeln(\"ADAPTER_WORD=\",adapterCsv(word));\n    return word;"
EXTRA = "proc researchSparseTransposeWindowed(const ref after: SparseWeavingVec,\n                                      n: int, k: int,\n                                      spec: SparseWeavingGapSpec): SparseWeavingVec {\n  var dense: [0..n] bigint;\n  const lo = max(0, after.first - 1);\n  const hi = min(n, after.first + after.values.size - 2);\n  if hi < lo then return sparseWeavingPack(dense);\n  var suffix = new bigint(0);\n  const lowActive = max(spec.q, after.first-1);\n  const highActive = hi;\n  const useRecurrence = spec.fixedSum == 0 && spec.tail == 0 &&\n                        k >= 8 && highActive-lowActive >= 8;\n  var coefficient = new bigint(0);\n  if useRecurrence then\n    coefficient = sparseWeavingChooseBig(k-2+n-highActive,n-highActive);\n  for i in lo..hi by -1 {\n    const a = after.at(i+1);\n    if a != 0 {\n      if useRecurrence && i >= lowActive && i <= highActive {\n        if coefficient != 0 then suffix += a*coefficient;\n      } else {\n        const factor = sparseWeavingWeight(i,n,k,spec);\n        if factor != 0 then suffix += a*factor;\n      }\n    }\n    dense[i] = suffix;\n    if useRecurrence && i <= highActive && i > lowActive then\n      coefficient = (coefficient * new bigint(k-1+n-i)) /\n                    new bigint(n-i+1);\n  }\n  for i in 0..<lo do dense[i] = suffix;\n  return sparseWeavingPack(dense);\n}\n\nproc researchForwardSingletonEligible(spec: SparseWeavingGapSpec): bool {\n  return spec.fixedSum > 0 || (spec.tail > 0 && spec.firstFixed < 0);\n}\n\nproc researchSparseForwardSingleton(const ref previous: SparseWeavingVec,\n                                    n: int, k: int,\n                                    spec: SparseWeavingGapSpec): SparseWeavingVec {\n  if !researchForwardSingletonEligible(spec) then\n    return sparseWeavingTransfer(previous,n,k,spec);\n  var result: SparseWeavingVec;\n  var i = spec.q;\n  if spec.fixedSum > 0 then i = spec.firstFixed;\n  if i < 0 || i > n || (spec.fixedSum > 0 && i >= spec.q) then return result;\n  var cumulative = new bigint(0);\n  const count = max(0,min(previous.values.size,i-previous.first+1));\n  for t in 0..<count do cumulative += previous.values[t];\n  if cumulative == 0 then return result;\n  const value = cumulative*sparseWeavingWeight(i,n,k,spec);\n  if value != 0 {\n    result.first = i+1;\n    result.values.pushBack(value);\n  }\n  return result;\n}\n\nproc researchSparseForwardWindowedEligible(\n    const ref previous: SparseWeavingVec, n: int,\n    spec: SparseWeavingGapSpec): bool {\n  return spec.fixedSum == 0 && spec.tail == 0 && spec.firstFixed < 0 &&\n         previous.values.size > 0 && max(spec.q,previous.first) <= n;\n}\n\nproc researchSparseForwardWindowed(const ref previous: SparseWeavingVec,\n                                   n: int, k: int,\n                                   spec: SparseWeavingGapSpec): SparseWeavingVec {\n  if !researchSparseForwardWindowedEligible(previous,n,spec) then\n    return sparseWeavingTransfer(previous,n,k,spec);\n\n  const firstActive = max(spec.q,previous.first);\n  var cumulative = new bigint(0);\n  const prefixCount = max(0,min(previous.values.size,\n                                firstActive-previous.first));\n  for t in 0..<prefixCount do cumulative += previous.values[t];\n\n  var dense: [firstActive+1..n+1] bigint;\n  const useRecurrence = k >= 8 && n-firstActive >= 8;\n  var coefficient = new bigint(0);\n  if useRecurrence then\n    coefficient = sparseWeavingChooseBig(k-2+n-firstActive,n-firstActive);\n\n  for i in firstActive..n {\n    cumulative += previous.at(i);\n    if cumulative != 0 {\n      if useRecurrence {\n        if coefficient != 0 then dense[i+1] = cumulative*coefficient;\n      } else {\n        const factor = sparseWeavingWeight(i,n,k,spec);\n        if factor != 0 then dense[i+1] = cumulative*factor;\n      }\n    }\n    if useRecurrence && i < n then\n      coefficient = (coefficient * new bigint(n-i)) /\n                    new bigint(k-2+n-i);\n  }\n  return sparseWeavingPack(dense);\n}\nproc adapterForward(const ref previous: SparseWeavingVec, n: int, k: int,\n                    spec: SparseWeavingGapSpec): SparseWeavingVec {\n  if researchForwardSingletonEligible(spec) then\n    return researchSparseForwardSingleton(previous,n,k,spec);\n  return researchSparseForwardWindowed(previous,n,k,spec);\n}\nproc adapterCsv(const ref values: list(int)): string {\n  var result = \"\";\n  for value in values {\n    if result != \"\" then result += \",\";\n    result += value:string;\n  }\n  return result;\n}\n"
ANCHOR = "  proc sparseWeavingSetup("

def require(ok, message):
    if not ok:
        raise RuntimeError(message)

def sha(b):
    return hashlib.sha256(b).hexdigest()

def git(*args):
    return subprocess.check_output(["git", *args])

def transform(src):
    require(src.count(ANCHOR) == 1 and src.count(OLD) == 1, "Source anchors changed")
    before, tail = src.split(ANCHOR, 1)
    require(tail.count("sparseWeavingTransfer(") == 3 and
            tail.count("sparseWeavingTranspose(") == 1, "Kernel call sites changed")
    tail = tail.replace("sparseWeavingTransfer(", "adapterForward(")
    tail = tail.replace("sparseWeavingTranspose(", "researchSparseTransposeWindowed(")
    return before + EXTRA + "\n" + ANCHOR + tail.replace(OLD, NEW)

def rss_tree(pid):
    try:
        status = Path(f"/proc/{pid}/status").read_text()
        rss = next((int(x.split()[1]) for x in status.splitlines()
                    if x.startswith("VmRSS:")), 0)
        kids = Path(f"/proc/{pid}/task/{pid}/children").read_text().split()
        return rss + sum(rss_tree(int(c)) for c in kids)
    except (FileNotFoundError, ProcessLookupError):
        return 0

def run(argv, out, label, seconds, runtime=True):
    stdout = out / (label + ".stdout")
    stderr = out / (label + ".stderr")
    metrics = out / (label + ".os-time")
    command = ["/usr/bin/time", "-f", "%e %M %x", "-o", str(metrics), *map(str, argv)]
    (out / (label + ".command.json")).write_text(json.dumps(command) + "\n")
    begin = time.monotonic()
    peak = 0
    reason = None
    with stdout.open("wb") as o, stderr.open("wb") as e:
        p = subprocess.Popen(command, stdout=o, stderr=e, start_new_session=True)
        while p.poll() is None:
            peak = max(peak, rss_tree(p.pid))
            elapsed = time.monotonic() - begin
            if elapsed >= seconds or (runtime and peak > RSS_KIB):
                reason = "TIMEOUT" if elapsed >= seconds else "RSS_LIMIT"
                try:
                    os.killpg(p.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                break
            time.sleep(0.05)
        rc = p.wait()
    elapsed = time.monotonic() - begin
    os_rss = None
    if metrics.exists():
        fields = metrics.read_text().splitlines()[-1].split()
        if len(fields) == 3:
            os_rss = int(fields[1])
    passed = (reason is None and rc == 0 and elapsed <= seconds and
              (not runtime or (os_rss is not None and 0 < max(peak,os_rss) <= RSS_KIB)))
    report = dict(argv=command, exit=rc, wall_seconds=elapsed, sampled_tree_rss_kib=peak,
                  os_peak_rss_kib=os_rss, passed=passed, reason=reason)
    (out / (label + ".result.json")).write_text(json.dumps(report, sort_keys=True)+"\n")
    print(label, json.dumps(report, sort_keys=True), flush=True)
    return passed, stdout

def one(lines, key):
    matches = [x[len(key)+1:] for x in lines if x.startswith(key+"=")]
    require(len(matches) == 1, "Missing or duplicate marker: "+key)
    return matches[0]

def reference(path):
    raw = path.read_bytes()
    require(sha(raw) == ZIP_SHA, "Historical selected artifact digest mismatch")
    with zipfile.ZipFile(path) as z:
        def member(basename):
            names = [n for n in z.namelist() if n.rsplit("/",1)[-1] == basename]
            require(len(names) == 1, "Missing/duplicate artifact member: "+basename)
            return z.read(names[0])
        data = json.loads(member("validated.json"))
        raw_word = member("selected.word")
    require(data["source_sha"] == BASE and data["project_id"] == "PC-BRANCH-CHAPEL-UKRAINIAN"
            and data["status"] == "PASS_RESEARCH_ONLY"
            and data["independent_gmp_result"] == "PASS"
            and data["independent_gmp_rank"] == data["selected_rank0"]
            and data["root_sha256"] == ROOT_SHA256
            and sha(data["selected_rank0"].encode("ascii")) == RANK0_SHA,
            "Selected reference provenance mismatch")
    word = tuple(map(int, raw_word.decode("ascii").strip().split(",")))
    require(len(word)==4244 and digest_word(word)==data["witness_sha256"], "Reference word identity")
    verify_fifo_word(MONTH_LENGTHS,word)
    return data, word

def cases():
    result = [p for m in range(1,5) for p in product(range(1,5),repeat=m) if sum(p)<=8]
    result += [(2,2,2,2,2),(2,3,2,2),(3,2,3,2),(2,2,3,3),(3,3,2,2),
               (4,3,2),(2,4,3),(1,2,1,3),(3,1,2,2)]
    return list(dict.fromkeys(result))

def csv(values):
    return ",".join(map(str,values))

def finite_expected(families):
    lines = []
    checks = 0
    for lens in families:
        family = csv(lens)
        words = brute_words(lens)
        lines.append(f"ROOT={family};{len(words)}")
        for i,word in enumerate(words,1):
            lines.append(f"WORD={family};{i};{csv(word)};{i}")
            checks += 2
    require(len(families)==137 and checks==1982,"Independent finite domain mismatch")
    return lines+[f"FINITE_CHECKS={checks}"]

def full_validate(log, data, word, marker):
    lines=log.read_text(encoding="utf-8").splitlines()
    require(one(lines,marker)=="PASS", "Missing checked pass")
    root=int(one(lines,"ADAPTER_ROOT"))
    require(root.bit_length()==22470 and sha(root.to_bytes((root.bit_length()+7)//8,"big"))==ROOT_SHA256,
            "Canonical root mismatch")
    require(int(one(lines,"ADAPTER_RANK1"))==int(data["selected_rank0"])+1,"Rank1 mismatch")
    require(tuple(map(int,one(lines,"ADAPTER_LENGTHS").split(",")))==tuple(MONTH_LENGTHS),"45 lengths mismatch")
    actual=tuple(map(int,one(lines,"ADAPTER_WORD").split(",")))
    require(actual==word,"Selected word mismatch")
    verify_fifo_word(MONTH_LENGTHS,actual)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--reference-zip",type=Path)
    p.add_argument("--outdir",type=Path,required=True)
    p.add_argument("--static-only",action="store_true")
    args=p.parse_args()
    repo=Path(git("rev-parse","--show-toplevel").decode().strip())
    os.chdir(repo)
    out=args.outdir.resolve()
    out.mkdir(parents=True,exist_ok=False)
    source_sha=git("rev-parse","HEAD").decode().strip()
    require(not git("status","--porcelain","--untracked-files=no").strip(),"Dirty tracked source")
    for directory in ("src","test"):
        require(not git("diff","--name-only",BASE,"HEAD","--",directory).decode().strip().replace(
            "test/weaving_checked_adapter.py","").replace("test/weaving_adapter_finite.chpl","").strip(),
            "Unexpected source change from reference base")
    original=Path("src/NormativeOracle.chpl").read_text(encoding="utf-8")
    modified=transform(original)
    families=cases()
    expected=finite_expected(families)
    (out/"candidate.NormativeOracle.chpl").write_text(modified,encoding="utf-8")
    (out/"finite.expected").write_text("\n".join(expected)+"\n",encoding="ascii")
    provenance={"project_id":"PC-BRANCH-CHAPEL-UKRAINIAN","base":BASE,"source_sha":source_sha,
                "production_sha256":sha(original.encode()),"candidate_sha256":sha(modified.encode()),
                "finite_families":len(families),"finite_rank_checks":1982,
                "stage6":"NOT_CLAIMED"}
    (out/"provenance.json").write_text(json.dumps(provenance,sort_keys=True)+"\n")
    print("ADAPTER_STATIC=PASS",flush=True)
    if args.static_only:
        print("ADAPTER_NATIVE=NOT_RUN")
        return 0
    require(args.reference_zip is not None,"Reference ZIP required")
    data,word=reference(args.reference_zip)
    version=subprocess.check_output(["chpl","--version"],text=True)
    require("2.10.0" in version,"Unexpected Chapel version")
    (out/"chapel-version.txt").write_text(version)
    with tempfile.TemporaryDirectory(prefix="chapel-adapter-") as tmp:
        scratch=Path(tmp)
        shutil.copytree(repo/"src",scratch/"src")
        shutil.copytree(repo/"test",scratch/"test")
        (scratch/"src/NormativeOracle.chpl").write_text(modified,encoding="utf-8")
        for name,file in (("finite","weaving_adapter_finite.chpl"),
                          ("structure","year_boundary_probe.chpl"),
                          ("api","calendar_date_api_probe.chpl")):
            binary=scratch/name
            ok,_=run(["chpl","-M",scratch/"src","-M",scratch/"test",
                      scratch/"test"/file,"-o",binary],out,name+".compile",150,False)
            require(ok,name+" checked compilation failed")
            (out/(name+".binary.sha256")).write_text(sha(binary.read_bytes())+"\n")
            opts={"finite":["--casesInput="+";".join(map(csv,families))],
                  "structure":["--structureOnly=true"],"api":[]}[name]
            ok,log=run([binary,*opts],out,name,240)
            require(ok,name+" checked execution not accepted")
            if name=="finite":
                require(log.read_text().splitlines()==expected,"Finite exact oracle mismatch")
                print("ADAPTER_FINITE_137_1982=PASS",flush=True)
            else:
                full_validate(log,data,word,{"structure":"YEAR_BOUNDARY_STRUCTURE_RESULT",
                                            "api":"YEAR_BOUNDARY_CALENDAR_DATE_API_RESULT"}[name])
                print("ADAPTER_"+name.upper()+"=PASS_RESEARCH_ONLY",flush=True)
        ok,_=run([sys.executable,repo/"test/compare_calendar_date_results.py",
                  out/"structure.stdout",out/"api.stdout"],out,"calendar-differential",30)
        require(ok,"Structure/API field differential failed")
    print("ADAPTER_RESULT=PASS_RESEARCH_ONLY")
    print("PRODUCTION_GATE=NOT_ACCEPTED")
    print("STAGE6=NOT_CLAIMED")
    return 0

if __name__=="__main__":
    sys.exit(main())
