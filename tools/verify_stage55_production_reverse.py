import hashlib,json,os
from pathlib import Path
d=Path("logs/stage55_production_reverse")
sha=lambda p:hashlib.sha256((d/p).read_bytes()).hexdigest()
assert sha("count.txt")=="c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8"
assert sha("rank.txt")=="cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6"
assert sha("word.json")=="82042fef5a65cc8b08120d069fa9d8f31c05e6761040f82c3341328ded9b44e5"
r=json.loads((d/"report.json").read_text())
assert r["sha"]==os.environ["GITHUB_SHA"] and r["production_used"] is True
assert (r["families"],r["words"],r["positions"])==(115,1408,4244)
assert 0<r["rss_kib"]<3*1024*1024 and 0<r["elapsed"]<9600
print("PRODUCTION_REVERSE_DIFFERENTIAL_PASS 4244/4244; Stage55 OPEN")
