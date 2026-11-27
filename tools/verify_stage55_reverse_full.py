import hashlib,json,os,sys
from pathlib import Path
sys.set_int_max_str_digits(0)
d=Path("logs/stage55_reverse_full")
sha=lambda b:hashlib.sha256(b).hexdigest()
assert (d/"checkout.txt").read_text().strip()==os.environ["GITHUB_SHA"]
T=(d/"root_count.txt").read_bytes(); R=(d/"root_rank.txt").read_bytes()
assert sha(T)=="c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8"
assert sha(R)=="cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6"
assert int(R)==int(T)//2+1
assert json.loads((d/"tiny.json").read_text())=={"families":115,"states":1335,"blocks":1697}
a=json.loads((d/"small_division_comparison.json").read_text()); assert a["checks"]==4252 and not a["adopted"]
L=json.loads(Path("tests/fixtures/stage55_year5000_appendix_a_metadata.json").read_text())["month_lengths"]
W=json.loads(Path("tests/fixtures/stage55_year5000_middle_word.json").read_text())
remaining=L.copy(); previous=int(T); k=c=0; trace=[]; word=[]
for p,line in enumerate((d/"trace.tsv").read_text().splitlines(),1):
    pos,s,count,rank,b,opened,closed=line.split("\t")
    pos,s,b,opened,closed=map(int,(pos,s,b,opened,closed))
    assert pos==p and s==W[p-1]
    assert 1<=int(rank)<=int(count)<=previous
    choices=[i+1 for i in range(c,min(45,k+1)) if remaining[i]>1 or i==c]
    assert s in choices and b==len(choices)
    if remaining[s-1]==L[s-1]:k+=1
    if remaining[s-1]==1:c+=1
    remaining[s-1]-=1
    assert (opened,closed)==(k,c)
    trace.append(json.dumps([p,s,sha(count.encode()),sha(rank.encode()),b,k,c],separators=(",",":")))
    word.append(s);previous=int(count)
assert len(word)==4244 and not any(remaining) and previous==int(rank)==1 and k==c==45
raw=("\n".join(trace)+"\n").encode()
assert sha(raw)=="07e607ff8e17d4fac4f34a9e8564d1a4923b5b118100087c134a3da1553aa408"
assert sha((d/"word.json").read_bytes())=="82042fef5a65cc8b08120d069fa9d8f31c05e6761040f82c3341328ded9b44e5"
assert json.loads((d/"word.json").read_text())==word
last=json.loads((d/"last_cursor.json").read_text())
assert last["position"]==4244 and last["sha"]==os.environ["GITHUB_SHA"] and 0<last["peak_rss_kib"]<3*1024*1024
report=json.loads((d/"native_complete.json").read_text())
assert report["positions"]==4244 and report["sha"]==os.environ["GITHUB_SHA"] and not report["production_used"] and not report["stage55_accepted"] and report["elapsed"]<9600
print("REVERSE_FULL_DIFFERENTIAL_PASS 4244/4244; STAGE55 OPEN")
