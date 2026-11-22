#!/usr/bin/env python3
"""Independent prefix-state DP vs production GMP component; never invokes F."""
from functools import lru_cache
from pathlib import Path
import hashlib, json, math, os, re, resource, signal, subprocess, sys, time
BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
SOURCE_BASE="e17ab44aa3fd1d08eb14644164735a7c5c87721d"
MAIN="56bc4173aae4975ded019ef5ab5a36249f1424df"
BRANCH="qa/issue29-ada-gmp-independent-state-dp-v178"
ACTIVATION="ci(issue29-v178): one-shot independent state-DP GMP witness; zero calendar F"
PATHS={".github/workflows/issue29-v178-gmp-independent-state-dp.yml",
       "issue29_v178_gmp_state_dp.gpr",
       "tests/issue29_v178_gmp_state_dp_tests.adb",
       "tests/issue29_v178_independent_state_dp.py"}
SOURCE={
 "src/canonical_full_weave_gmp_v164.adb":"845bd8905943a54e63d6aba0334404a5051fe666",
 "src/canonical_full_weave_gmp_v164.ads":"0b68edf7eddbc33869358bcfcc21e32465fc591e",
 "src/normative_oracle.adb":"0be8f8ab4ddef26d34963d5567707a511ebda50b"}
FAMILIES=((2,4,3),(3,5,4,2),(4,3,5,2,3),(6,2,4,3,5),
 (5,4,3,5,4),(2,7,2,7,2),(3,3,3,3,3,3),(8,2,5,2,4,3),
 (2,123),(123,2),(7,9,8,6,5),(2,2,2,2,2,2,2),(3,4,2,5,3,6),
 (9,11,8,10,9),(2,)*47)
EV=Path("evidence")
FIX=EV/"v178-reference.dat"
EXE=Path("bin_v178/issue29_v178_gmp_state_dp_tests")
def check(ok,msg):
 if not ok:raise ValueError(msg)
def hashdata(b):return hashlib.sha256(b).hexdigest()
def blob(b):return hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()
def git(*args):
 return subprocess.check_output(["git",*args],stderr=subprocess.DEVNULL).decode().strip()
def save(p,b):
 with p.open("xb") as f:f.write(b);f.flush();os.fsync(f.fileno())
def savejson(p,x):save(p,(json.dumps(x,sort_keys=True,indent=2)+"\n").encode())
def guard():
 check(os.environ.get("GITHUB_EVENT_NAME")=="push","event not push")
 check(os.environ.get("GITHUB_RUN_ATTEMPT")=="1","rerun forbidden")
 check(os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"branch mismatch")
 event=Path(os.environ.get("GITHUB_EVENT_PATH","/does-not-exist"))
 check(event.is_file(),"event file absent")
 check(json.loads(event.read_bytes()).get("head_commit",{}).get("message")==ACTIVATION,"not activation commit")
 head=git("rev-parse","HEAD")
 check(head==os.environ.get("GITHUB_SHA"),"head mismatch")
 check(subprocess.run(["git","merge-base","--is-ancestor",BASE,head]).returncode==0,"base not ancestor")
 changed=git("diff","--name-only",BASE+"...HEAD").splitlines()
 check(set(changed)==PATHS and len(changed)==4,"unreviewed changed paths")
 lock=Path(".github/workflows/canonical-names-lock.yml").read_text()
 check(lock.count("    if: "+"$"+"{{ false }}")==42 and lock.count("  verify:\n")==1,"native dispatch not blocked")
 check(blob(subprocess.check_output(["git","show",MAIN+":README.md"]))=="74c424b44eadd4ece3f29072ddbf873236557604","README pin")
 for path,expected in SOURCE.items():
  check(blob(Path(path).read_bytes())==expected and git("rev-parse",SOURCE_BASE+":"+path)==expected,"source drift "+path)
 test=Path("tests/issue29_v178_gmp_state_dp_tests.adb").read_text()
 check("with Canonical_Full_Weave_GMP_V164;" in test and "with Normative_Oracle;" not in test and "with Month_Weaving;" not in test,"forbidden main F import")
 check('with "gnatcoll_gmp.gpr";' in Path("issue29_v178_gmp_state_dp.gpr").read_text(),"GMP GPR absent")
 return {"head":head,"branch":BRANCH,"run_id":os.environ.get("GITHUB_RUN_ID"),"attempt":1}
def independent(lengths):
 m=len(lengths)
 @lru_cache(None)
 def ways(rem,opened,closed):
  if not any(rem):return int(opened==closed==m)
  result=0
  for j in range(closed,min(opened+1,m)):
   if rem[j] and (j==opened or rem[j]>1 or j==closed):
    nextrem=list(rem);nextrem[j]-=1
    result+=ways(tuple(nextrem),opened+(j==opened),closed+(rem[j]==1))
  return result
 total=ways(lengths,0,0)
 check(total>0 and ways.cache_info().currsize<1_000_000,"DP state budget")
 def unrank(r):
  check(1<=r<=total,"rank bounds")
  rem=lengths;opened=closed=0;out=[]
  for _ in range(sum(lengths)):
   found=False
   for j in range(closed,min(opened+1,m)):
    if rem[j] and (j==opened or rem[j]>1 or j==closed):
     nxt=list(rem);nxt[j]-=1;nxt=tuple(nxt)
     no=opened+(j==opened);nc=closed+(rem[j]==1)
     block=ways(nxt,no,nc)
     if r>block:r-=block
     else:
      out.append(j+1);rem=nxt;opened=no;closed=nc;found=True;break
   check(found,"DP unrank missing transition")
  check(r==1 and opened==closed==m and not any(rem),"DP terminal state")
  return tuple(out)
 return total,unrank,ways.cache_info().currsize
def check_sequence(lengths,seq):
 check(len(seq)==sum(lengths),"independent length")
 check(all(seq.count(j)==lengths[j-1] for j in range(1,len(lengths)+1)),"independent multiplicity")
 first=[];last={}
 for idx,j in enumerate(seq):
  if j not in last:first.append(j)
  last[j]=idx
 check(first==list(range(1,len(lengths)+1)),"independent first order")
 check(sorted(last,key=last.get)==list(range(1,len(lengths)+1)),"independent last order")
def preflight():
 ident=guard()
 check(len(FAMILIES)==15,"family size")
 lines=[str(len(FAMILIES))];cases=[];total_samples=0
 for ls in FAMILIES:
  check(len(ls)<=47 and min(ls)>=2 and max(ls)<=123 and sum(ls)<=5778,"length bound")
  n,unrank,states=independent(ls)
  if len(ls)==2:check(n==math.comb(sum(ls)-2,ls[0]-1),"binomial invariant")
  if ls==(2,)*47:check(n==math.comb(94,47)//48,"Catalan47 invariant")
  ranks=sorted({1,2,max(1,n//3),max(1,n//2),max(1,2*n//3),max(1,n-1),n})
  lines.extend([str(len(ls)),*(str(x) for x in ls),str(n),str(len(ranks))])
  prev=()
  for rank in ranks:
   seq=unrank(rank);check_sequence(ls,seq)
   if prev:check(prev<seq,"lex monotonic")
   prev=seq
   lines.append(str(rank));lines.extend(map(str,seq))
  total_samples+=len(ranks)
  cases.append({"lengths":list(ls),"count":str(n),"bits":n.bit_length(),"memo_states":states,"ranks":[str(x) for x in ranks]})
 data=("\n".join(lines)+"\n").encode()
 save(FIX,data)
 savejson(EV/"preflight.json",{"status":"REFERENCE_ONLY_ZERO_F","identity":ident,"cases":cases,
     "sample_total":total_samples,"fixture_sha256":hashdata(data),"source_base":BASE,"calendar_calls":0,"soak_years":0})
 print("V178_INDEPENDENT_STATE_DP_REFERENCE_READY_NO_F")
 print("V178_REFERENCE_SAMPLES="+str(total_samples))
def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(90,90))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def kill(p):
 try:os.killpg(p.pid,signal.SIGKILL)
 except ProcessLookupError:pass
def run():
 ident=guard()
 pre=json.loads((EV/"preflight.json").read_bytes())
 check(pre["identity"]==ident and hashdata(FIX.read_bytes())==pre["fixture_sha256"],"reference drift")
 check(EXE.is_file(),"binary absent")
 syms=subprocess.run(["nm",str(EXE)],capture_output=True,check=True).stdout
 check(b"normative_oracle" not in syms.lower(),"F linked")
 check(not (EV/"RUN_STARTED_ONCE").exists(),"already ran")
 bh=hashdata(EXE.read_bytes())
 savejson(EV/"RUN_STARTED_ONCE",{"sha":bh,"head":ident["head"],"native_invocations":1,"calendar_calls":0})
 stdout=EV/"native.stdout";stderr=EV/"native.stderr"
 result={"status":"FAIL_CLOSED","binary_sha256":bh,"head":ident["head"],"fixture_sha256":pre["fixture_sha256"],"calendar_calls":0,"soak_years":0,"native_invocations":1}
 begin=time.monotonic();p=None
 try:
  with stdout.open("xb") as fo,stderr.open("xb") as fe:
   p=subprocess.Popen([str(EXE.resolve())],stdin=subprocess.DEVNULL,stdout=fo,stderr=fe,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    code=p.poll()
    if stdout.stat().st_size+stderr.stat().st_size>131072:
     violation="OUTPUT_LIMIT";kill(p);break
    if time.monotonic()-begin>90:
     violation="WALL_TIMEOUT";kill(p);break
    if code is not None:break
    time.sleep(.05)
   p.wait(timeout=5)
  raw=stdout.read_bytes();errors=stderr.read_bytes()
  result.update({"exit_code":p.returncode,"stderr_bytes":len(errors),"elapsed_seconds":round(time.monotonic()-begin,4),"violation":violation})
  check(p.returncode==0 and violation is None and len(errors)==0,"native failure")
  s=raw.decode()
  def num(k):
   matches=re.findall("^"+k+r"=\s*([0-9]+)\s*$",s,re.M)
   check(len(matches)==1,"native field missing "+k)
   return int(matches[0])
  c=num("V178_FAMILIES");n=num("V178_SAMPLES");a=num("V178_ASSERTIONS")
  check(c==len(pre["cases"])==15 and n==pre["sample_total"] and a>2000,"assertion or sample mismatch")
  result.update({"status":"PASS_STATE_DP_VS_GMP_NO_F","families":c,"samples":n,"assertions":a})
 except Exception as exc:
  result["failure"]=str(exc)
  if p is not None and p.poll() is None:kill(p);p.wait(timeout=5)
 finally:
  for key,path in [("stdout",stdout),("stderr",stderr)]:
   if path.exists():
    result[key+"_sha256"]=hashdata(path.read_bytes())
    result[key+"_bytes"]=path.stat().st_size
  savejson(EV/"result.json",result)
 check(result["status"]=="PASS_STATE_DP_VS_GMP_NO_F","v178 not accepted; no automatic rerun")
 print("V178_INDEPENDENT_PREFIX_STATE_DP_GMP_PASS_ZERO_F")
if __name__=="__main__":
 check(len(sys.argv)==2 and sys.argv[1] in ("preflight","run-once"),"mode")
 if sys.argv[1]=="preflight":preflight()
 else:run()
