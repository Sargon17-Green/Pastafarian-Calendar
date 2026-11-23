#!/usr/bin/env python3
"""Exact frozen ORIGINAL witness -> existing corrected GMP component-chain QA.

No original F(c,t), Calendar_Date, normative oracle or Sauce is executed.
The reference is reconstructed from immutable one-day evidence #14864488555
using a separate Python prefix-count recurrence and original seal32 stream.
"""
import hashlib,json,math,os,re,resource,signal,subprocess,sys,time
from pathlib import Path
sys.set_int_max_str_digits(20000)
BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
ORIGINAL="e17ab44aa3fd1d08eb14644164735a7c5c87721d"
MAIN="56bc4173aae4975ded019ef5ab5a36249f1424df"
BRANCH="qa/issue29-foundation-witness-gmp-replay-v189"
ACTIVATION="ci(issue29-v189): frozen foundation witness GMP Count-Rank-Unrank; no original F"
SOURCES={
 "src/canonical_full_weave_gmp_v164.adb":"845bd8905943a54e63d6aba0334404a5051fe666",
 "src/canonical_full_weave_gmp_v164.ads":"0b68edf7eddbc33869358bcfcc21e32465fc591e",
 "src/canonical_wide_rank_gmp_v164.adb":"52b8814c2ab1924cdebafe893a65d97cd3ccfa61",
 "src/canonical_wide_rank_gmp_v164.ads":"14b94e81534e98cfdb07be3824076bd7082385ea",
 "src/normative_oracle.adb":"0be8f8ab4ddef26d34963d5567707a511ebda50b"
}
HISTORICAL={
 "a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72:src/normative_oracle.adb":"923733d4f8face03586aee304640bf7540c28b4c",
 "a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72:src/month_weaving.adb":"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
 "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4:tests/normative_reference.py":"d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
}
PATHS={
 ".github/workflows/issue29-v189-frozen-foundation-gmp.yml",
 "issue29_v189_foundation_gmp.gpr",
 "tests/issue29_v189_foundation_gmp_tests.adb",
 "tests/issue29_v189_frozen_oracle.py"
}
EV=Path("evidence")
REF=EV/"v189-frozen-original-foundation-reference.dat"
BIN=Path("bin_v189/issue29_v189_foundation_gmp_tests")
SCHEMA="ISSUE29_V189_FROZEN_ORIGINAL_FOUNDATION_GMP_COMPONENT_CHAIN_NO_F/1"
ORIGINAL_ARTIFACT_ID=14864488555
ORIGINAL_ZIP_SHA256="479fc8c6b45c426368d75f18e26bb3e669d6af0c8168b6cc043965f7df7c5b1f"
ORIGINAL_VERDICT_SHA256="edc23d34d043a0701f750b5d7e4c4ede4d131238418c164c9a5783a03e96ef9a"
MONTH_LENGTHS=(115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,97,50,122,110,81,54,101,83,88,40,25,77,98,122,105)
MONTH_NAMES=(18,14,37,28,24,42,6,20,19,41,16,39,25,1,9,38,3,46,27,40,12,43,35,32,29,10,44,36,23,17,33,5,30,15,11,45,8,4,7,31,34,22,13,2,26)
FIRST=106458209471735273212934705135928382248
STEP=-1
MOD=(1<<127)-1
OFFSET0=2031
PY_WEAVE_SHA="e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29"
ADA_WEAVE_SHA="efd9a1dc5ee5398ad9c69061ff9e4793eacc1c434e3eb78c6708eedaad1c7eeb"
COUNT_SHA="c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8"
RANK_SHA="160ca5c4a8ee5d0ec29c583a0d7ab91a71d8be4b7dc4c139ebaae066596dcff3"

def check(ok,reason):
 if not ok:raise RuntimeError(reason)
def sha(b):return hashlib.sha256(b).hexdigest()
def blob(b):return hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()
def git(*args):return subprocess.check_output(["git",*args],stderr=subprocess.DEVNULL).decode().strip()
def save(path,b):
 with path.open("xb") as f:f.write(b);f.flush();os.fsync(f.fileno())
def jwrite(path,value):save(path,(json.dumps(value,sort_keys=True,indent=2)+"\n").encode())

def preflight():
 check(os.environ.get("GITHUB_EVENT_NAME")=="push","push only")
 check(os.environ.get("GITHUB_RUN_ATTEMPT")=="1","one attempt only")
 check(os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"wrong QA branch")
 head=git("rev-parse","HEAD")
 check(head==os.environ.get("GITHUB_SHA"),"HEAD changed")
 event=json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_bytes())
 check(event.get("head_commit",{}).get("message")==ACTIVATION,"unexpected activation")
 check(subprocess.run(["git","merge-base","--is-ancestor",BASE,head],capture_output=True).returncode==0,"base ancestor")
 paths=git("diff","--name-only",BASE+"...HEAD").splitlines()
 check(len(paths)==4 and set(paths)==PATHS,"unexpected source modification")
 check(blob(subprocess.check_output(["git","show",MAIN+":README.md"]))=="74c424b44eadd4ece3f29072ddbf873236557604","main README drift")
 pins={}
 for path,expected in SOURCES.items():
  b=Path(path).read_bytes()
  check(blob(b)==expected and git("rev-parse",ORIGINAL+":"+path)==expected,"GMP source drift "+path)
  pins[path]={"blob":expected,"sha256":sha(b)}
 for path,expected in HISTORICAL.items():
  check(git("rev-parse",path)==expected,"original historical source drift "+path)
 lock=Path(".github/workflows/canonical-names-lock.yml").read_text()
 check(lock.count("    if: "+"$"+"{{ false }}")==42 and lock.count("  verify:\n")==1,"legacy native jobs not halted")
 ada=Path("tests/issue29_v189_foundation_gmp_tests.adb").read_text().lower()
 check("with normative_oracle;" not in ada and "with calendar_date;" not in ada
       and "with canonical_full_weave_gmp_v164;" in ada
       and "with canonical_wide_rank_gmp_v164;" in ada,"forbidden original F linkage")
 check('with "gnatcoll_gmp.gpr";' in Path("issue29_v189_foundation_gmp.gpr").read_text(),"GNATCOLL GPR absent")
 return {"head":head,"base":BASE,"branch":BRANCH,"attempt":1,"run_id":os.environ["GITHUB_RUN_ID"]},pins

def global_reference(lengths):
 from math import comb
 prefix=[0]
 for n in lengths:prefix.append(prefix[-1]+n)
 m=len(lengths);h=[None]*(m+1)
 h[m]=[1]*(prefix[m]+1)
 for opened in range(m-1,-1,-1):
  n=lengths[opened];weighted=[];running=0
  for y in range(prefix[opened+1]):
   if y>=n-1:running+=comb(y-1,n-2)*h[opened+1][y]
   weighted.append(running)
  h[opened]=[weighted[x+n-1] for x in range(prefix[opened]+1)]
 return h

def wide_rank(n):
 places=1;space=MOD
 while space<n:places+=1;space*=MOD
 candidate=1;weight=1
 for j in range(places):
  candidate+=((FIRST-1+STEP*j)%MOD)*weight
  weight*=MOD
 limit=(space//n)*n
 if candidate>limit:candidate=limit if STEP<0 else 1
 return (candidate-1)%n+1,places

def global_unrank(lengths,h,r):
 m=len(lengths);remaining=list(lengths)
 out=[];opened=closed=0
 for _ in range(sum(lengths)):
  for j in range(closed,min(opened+1,m)):
   if j<opened and (remaining[j]<=0 or (remaining[j]==1 and j!=closed)):continue
   nxt=remaining.copy();nxt[j]-=1
   no=opened+(j==opened);nc=closed+(nxt[j]==0)
   base=0;ways=1
   for t in range(nc,no):
    n=nxt[t]
    if n<=0:ways=0;break
    if base:ways*=math.comb(n+base-1,base);base+=n
    else:base=n
   block=ways*h[no][base]
   if r>block:r-=block
   else:
    out.append(j+1);remaining=nxt;opened=no;closed=nc;break
  else:raise AssertionError("reference unrank failed")
 check(r==1 and not any(remaining) and opened==closed==m,"reference terminal not exhausted")
 return out

def ada_fixed_rail_source_only(lengths):
 m=len(lengths);k=sum(lengths)-2*m
 rem=[n-2 for n in lengths]
 seq=list(range(1,m+1));tickets=[]
 for i in range(k):
  slots=k-i
  ans=1+(FIRST-1+STEP*i)%MOD
  bound=(MOD//slots)*slots
  if ans>bound:ans=bound if STEP<0 else 1
  pick=(ans-1)%slots+1
  tickets.append(pick)
  for j,n in enumerate(rem):
   if pick>n:pick-=n
   else:rem[j]-=1;seq.append(j+1);break
  else:raise AssertionError("Ada rail ticket not decoded")
 check(not any(rem),"Ada rail interior residual")
 return seq+list(range(1,m+1)),tickets

def independent_reference():
 lengths=MONTH_LENGTHS
 check(len(lengths)==45 and sum(lengths)==4244,"frozen witness lengths")
 check(all(4<=x<=123 for x in lengths),"frozen legal month lengths")
 h=global_reference(lengths)
 n=h[0][0]
 check(n.bit_length()==22470 and sha(str(n).encode())==COUNT_SHA,"global family exact Count")
 r,places=wide_rank(n)
 check(places==177 and sha(str(r).encode())==RANK_SHA,"global sealed wide rank")
 py=global_unrank(lengths,h,r)
 ada,tickets=ada_fixed_rail_source_only(lengths)
 check(len(py)==len(ada)==4244,"full witness length")
 check(sha(bytes(py))==PY_WEAVE_SHA and sha(bytes(ada))==ADA_WEAVE_SHA,"frozen original traces")
 check(len(tickets)==4154,"all source original Ada tickets reconstructed")
 check(all(py.count(j)==lengths[j-1] for j in range(1,46)),"global length multiplicity")
 check(all(ada.count(j)==lengths[j-1] for j in range(1,46)),"Ada length multiplicity")
 check([i for i,(a,b) in enumerate(zip(ada,py)) if a!=b][0]==7,"first actual mismatch offset")
 diff=sum(a!=b for a,b in zip(ada,py))
 check(diff==4122,"exact divergent weave positions")
 py_label=py[OFFSET0];ada_label=ada[OFFSET0]
 py_day=py[:OFFSET0+1].count(py_label);ada_day=ada[:OFFSET0+1].count(ada_label)
 check((py_label,MONTH_NAMES[py_label-1],py_day)==(8,20,56),"Python original output projection")
 check((ada_label,MONTH_NAMES[ada_label-1],ada_day)==(33,30,52),"Ada original output projection")
 return n,r,py,ada,{"count_bits":n.bit_length(),"count_sha256":COUNT_SHA,
  "rank_bits":r.bit_length(),"rank_sha256":RANK_SHA,"rank_radix_places":places,
  "python_weave_sha256":PY_WEAVE_SHA,"ada_weave_sha256":ADA_WEAVE_SHA,
  "first_different_offset0":7,"different_positions":diff,
  "selected_offset0":OFFSET0,"python_id_name_day":[py_label,20,py_day],
  "ada_id_name_day":[ada_label,30,ada_day],
  "original_artifact_id":ORIGINAL_ARTIFACT_ID,
  "original_artifact_zip_sha256":ORIGINAL_ZIP_SHA256,
  "original_verdict_sha256":ORIGINAL_VERDICT_SHA256}

def prepare():
 identity,pins=preflight()
 EV.mkdir(exist_ok=True)
 n,r,py,ada,proof=independent_reference()
 values=[str(len(MONTH_LENGTHS))]
 values.extend(str(x) for x in MONTH_LENGTHS)
 values.extend([str(FIRST),str(STEP),str(n),str(r),str(len(py))])
 values.extend(str(x) for x in py)
 save(REF,("\n".join(values)+"\n").encode())
 jwrite(EV/"preflight.json",{"schema":SCHEMA,"status":"SOURCE_LOCKED_ZERO_F",
  "identity":identity,"source_blobs":pins,"historical_blob_pins":HISTORICAL,
  "frozen_witness_proof":proof,"fixture_sha256":sha(REF.read_bytes()),
  "native_invocations_before_run":0,"calendar_F_calls":0,"soak_years":0})
 print("V189_FROZEN_ORIGINAL_SOURCE_REFERENCE_READY_4244_ZERO_F")

def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(180,180))
 resource.setrlimit(resource.RLIMIT_AS,(1024*1024*1024,1024*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def stop(p):
 try:os.killpg(p.pid,signal.SIGKILL)
 except ProcessLookupError:pass

def run_once():
 identity,_=preflight()
 pre=json.loads((EV/"preflight.json").read_bytes())
 check(pre["identity"]==identity,"preflight SHA drift")
 check(sha(REF.read_bytes())==pre["fixture_sha256"],"fixture corrupted")
 check(BIN.is_file(),"GNAT binary missing")
 symbols=subprocess.run(["nm",str(BIN)],capture_output=True,check=True)
 check(b"normative_oracle" not in symbols.stdout.lower(),"original F symbol linked")
 check(not (EV/"RUN_STARTED_ONCE").exists(),"no original native reruns")
 binary_sha=sha(BIN.read_bytes())
 jwrite(EV/"RUN_STARTED_ONCE",{"head":identity["head"],"binary_sha256":binary_sha,"native_invocations":1,"calendar_F_calls":0})
 result={"schema":SCHEMA,"status":"FAIL_CLOSED","identity":identity,
  "binary_sha256":binary_sha,"native_invocations":1,"original_F_calls":0,"soak_years":0,
  "fixture_sha256":pre["fixture_sha256"]}
 stdout=EV/"native.stdout";stderr=EV/"native.stderr";p=None;start=time.monotonic()
 try:
  with stdout.open("xb") as a,stderr.open("xb") as b:
   p=subprocess.Popen([str(BIN.resolve())],stdin=subprocess.DEVNULL,stdout=a,stderr=b,
      start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    rc=p.poll()
    if stdout.stat().st_size+stderr.stat().st_size>65536:
     violation="OUTPUT_CAP";stop(p);break
    if time.monotonic()-start>185:
     violation="WALL_CAP";stop(p);break
    if rc is not None:break
    time.sleep(.1)
   p.wait(timeout=5)
  text=stdout.read_text("ascii");errors=stderr.read_bytes()
  result.update({"exit_code":p.returncode,"stderr_bytes":len(errors),
       "elapsed_seconds":round(time.monotonic()-start,4),
       "peak_rss_kib":resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
       "resource_violation":violation})
  check(p.returncode==0 and len(errors)==0 and violation is None,"native GMP witness failed")
  def field(k):
   numbers=re.findall("^"+re.escape(k)+r"=\s*([0-9]+)\s*$",text,re.M)
   check(len(numbers)==1,"missing native number "+k)
   return int(numbers[0])
  n_tokens=field("V189_TOKENS");assertions=field("V189_ASSERTIONS")
  check(n_tokens==4244 and assertions>=8500,"native full-token comparison missing")
  check("V189_ORIGINAL_FOUNDATION_GMP_4244_EXACT_PASS_ZERO_F" in text,"pass marker absent")
  result.update({"status":"PASS_ORIGINAL_FOUNDATION_GMP_COMPONENT_REPLAY_ZERO_F",
     "tokens":n_tokens,"assertions":assertions})
 except Exception as ex:
  result["error"]=str(ex)
  if p is not None and p.poll() is None:stop(p);p.wait(timeout=5)
 finally:
  for key,path in (("stdout",stdout),("stderr",stderr)):
   if path.exists():result[key+"_sha256"]=sha(path.read_bytes());result[key+"_bytes"]=path.stat().st_size
  jwrite(EV/"result.json",result)
 check(result["status"]=="PASS_ORIGINAL_FOUNDATION_GMP_COMPONENT_REPLAY_ZERO_F","no automatic retry")
 print("V189_NATIVE_FROZEN_ORIGINAL_FOUNDATION_4244_TOKEN_GMP_PASS_ZERO_F")

if __name__=="__main__":
 check(len(sys.argv)==2 and sys.argv[1] in ("prepare","run-once"),"mode")
 if sys.argv[1]=="prepare":prepare()
 else:run_once()
