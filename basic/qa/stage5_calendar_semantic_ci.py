#!/usr/bin/env python3
"""Stage5 native StarBasic characterization and independent Python semantic checks."""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import random
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import traceback
import unicodedata

F, SEED = -15055671, 0x20261118
PROBE_TIMEOUTS = {"S5Day": 30, "S5Work": 30, "S5Gate": 90, "S5Year": 300, "S5Date": 300, "S5Production": 30}
LOCKS = {
 "Standard/BigInt.xba": "b89dd817bb4f18fef6297d43ecfd04969e6cdca0",
 "Standard/CalendarSpaghetti.xba": "bc753e64dba2f691ec8916ffd8cc7e062bf681a2",
 "Standard/Tests.xba": "7a1efac6b851a97874589dc5e72ef8274b5c0fc5",
 "Standard/Catalog.xba": "d211dd28ab4a4bf4da5f9b16c35942aef4b6eb24",
 "Standard/Oracle.xba": "82dfc537453ad2b4653c4042ff63c2a115c913d0",
}
PROBE = """
' Stage5 temporary test probe, never checked into source module.
Public Function S5Day(ByVal d As String) As String
 S5Day = OracleDayCount(d)
End Function
Public Function S5Work(ByVal c As String, ByVal t As String) As String
 Dim v As Variant
 v=OracleWorkCounts(c,t)
 S5Work=CStr(v(0)) & "|" & CStr(v(1)) & "|" & CStr(v(2)) & "|" & CStr(v(3)) & "|" & CStr(v(4))
End Function
Public Function S5Gate(ByVal k As String) As String
 Dim a As String, b As String
 a=OracleGateDay(k)
 b=OracleGateDay(BI_AddSmall(k,1))
 S5Gate=a & "|" & b & "|" & OracleGateIndexAtOrBefore(BI_AddSmall(a,-1)) & "|" & OracleGateIndexAtOrBefore(a) & "|" & OracleGateIndexAtOrBefore(BI_AddSmall(a,1)) & "|" & OracleGateIndexAtOrBefore(b)
End Function
Public Function S5Year(ByVal c As String, ByVal t As String) As String
 Dim y As Variant, s As Variant, lens As Variant, i As Long, total As Long
 y=OracleFindTargetYear(c,t)
 s=OracleBuildYearStructure(c,y)
 lens=s(6)
 total=0
 For i=1 To CLng(s(5))
  total=total+CLng(lens(i))
 Next i
 S5Year=CStr(y(0)) & "|" & CStr(y(3)) & "|" & CStr(y(4)) & "|" & CStr(s(0)) & "|" & CStr(s(5)) & "|" & CStr(total)
End Function
Public Function S5Date(ByVal c As String, ByVal t As String) As String
 Dim v As Variant
 v=OracleCalendarDate(c,t)
 S5Date=CStr(v(0)) & "|" & CStr(v(1)) & "|" & CStr(v(2)) & "|" & CStr(v(3)) & "|" & CStr(v(4))
End Function
Public Function S5Production(ByVal c As String, ByVal t As String) As String
 On Error GoTo expectedError
 Dim v As Variant
 v=calendarDateSpaghetti(c,t)
 S5Production="UNEXPECTED_RETURN"
 Exit Function
expectedError:
 S5Production=CStr(Err) & "|" & Error$
End Function
"""
def sha(raw):
 return hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
def preflight(basic):
 for path,expected in LOCKS.items():
  got=sha((basic/path).read_bytes())
  if got!=expected: raise AssertionError("SOURCE_LOCK_FAIL "+path+" "+got)
 txt=(basic/"Standard/Catalog.xba").read_text(encoding="utf-8")
 names=[]
 for label,count in (("cutletNames",17),("monthNames",47)):
  matches=re.findall(r'^\s*'+label+r'\((\d+)\)\s*=\s*"([^"]+)"',txt,re.M)
  if [int(i) for i,_ in matches]!=list(range(1,count+1)): raise AssertionError("CATALOG_INDEX_FAIL")
  names.append(set(unicodedata.normalize("NFC",v) for _,v in matches))
 return names
def day(d):
 return 2*(F-d) if d<F else 2*(d-F)+1
def work(c,t):
 return [day(c),day(t),abs(t-c)+1,day(c)+day(t),1 if t<c else 2 if t==c else 3]
def inputs():
 rng=random.Random(SEED)
 days=[str(x) for x in (F-2,F-1,F,F+1,F+2,0,-278522,2**127-1,2**127,-2**127,10**40+37,-10**40-37)]
 days+=["-015055671","+0000000","+0000001","-0000001"]
 days += [str(rng.randint(-10**20,10**20)) for _ in range(8)]
 pairs=[(str(c),str(t)) for c,t in ((F,F),(F-1,F),(F,F-1),(F,F+1),(F+1,F),(0,0),(-278522,F),(F,-278522),(2**127,-2**127),(10**40,F),(F,10**40))]
 assert len(days)==24 and len(set(days))==24 and len(pairs)==11
 assert day(F-1)==2 and day(F)==1 and day(F+1)==3
 assert work(F-1,F)==[2,1,2,3,3]
 return days,pairs
def inject(target):
 path=target/"Standard/Tests.xba"; s=path.read_text(encoding="utf-8")
 mark="]]></script:module>"
 if s.count(mark)!=1 or "Public Function S5Day" in s: raise AssertionError("TEMP_INJECTION_REFUSED")
 path.write_text(s.replace(mark,PROBE+mark),encoding="utf-8")
def run(basic,out):
 import stage3_native_ci as office
 out.mkdir(parents=True,exist_ok=True)
 (out/"status.txt").write_text("STARTED\n",encoding="utf-8")
 progress_path=out/"progress.log"
 def progress(event):
  line="%.3f\t%s\n"%(time.time(),event)
  with progress_path.open("a",encoding="utf-8") as f:
   f.write(line); f.flush(); os.fsync(f.fileno())
  print("[STAGE5] "+event,flush=True)
 progress("RUN_START")
 rows=[]; errors=[]
 counters=dict(independent_oracle_checks=0,structural_only_checks=0,boundary_checks=0,production_expected_error_checks=0,native_invocations=0)
 metadata=dict(stage=5,project="PC-BRANCH-BASIC-PUNJABI",source_stage3_lock="74aa087b81094f34eab9a0e04e395cc693dd83b1",parent_contract_commit="1be9a87bfa5ace1d905bf86fcd4b158a4f7e8455",candidate_commit=os.getenv("GITHUB_SHA","LOCAL"),blob_locks=LOCKS,seed=SEED,probe_timeouts_seconds=PROBE_TIMEOUTS,full_production_calendar="NOT_IMPLEMENTED")
 def check(id,cat,args,got,expected,provenance,passed,counter):
  counters[counter]+=1
  rows.append([id,cat,json.dumps(args,ensure_ascii=False,sort_keys=True),str(got),str(expected),provenance,"PASS" if passed else "FAIL"])
  progress("CHECK "+id+" "+("PASS" if passed else "FAIL"))
  if not passed: errors.append(id+": actual="+repr(got)+" expected="+repr(expected))
 try:
  progress("PREFLIGHT_START")
  cutlets,months=preflight(basic)
  progress("PREFLIGHT_PASS")
  days,pairs=inputs()
  progress("INPUTS_READY days=%d pairs=%d"%(len(days),len(pairs)))
  metadata["lo_version"]=subprocess.run(["libreoffice","--version"],check=True,capture_output=True,text=True,timeout=15).stdout.strip()
  metadata["python_version"]=sys.version.split()[0]
  with tempfile.TemporaryDirectory(prefix="pc-basic-punjabi-stage5-") as root:
   profile=Path(root)/"isolated-lo-profile"
   progress("OFFICE_SESSION_START")
   proc,context=office.office_session(profile,out/"lo-startup.log")
   progress("OFFICE_SESSION_READY")
   office.stop_office(proc,context)
   progress("OFFICE_SESSION_STOPPED")
   target=profile/"user"/"basic"
   if target.exists(): shutil.rmtree(target) # only new owned profile
   target.parent.mkdir(parents=True,exist_ok=True)
   shutil.copytree(basic,target)
   inject(target)
   progress("TEMP_TEST_PROBE_INJECTED")
   progress("OFFICE_SESSION_START")
   proc,context=office.office_session(profile,out/"lo-startup.log")
   progress("OFFICE_SESSION_READY")
   try:
    factory=context.ServiceManager.createInstanceWithContext("com.sun.star.script.provider.MasterScriptProviderFactory",context)
    provider=factory.createScriptProvider("")
    cache={}
    def native(case_id,name,*args):
     timeout=PROBE_TIMEOUTS.get(name,60)
     started=time.monotonic()
     progress("START "+case_id+" function="+name+" timeout_s="+str(timeout))
     finished=threading.Event()
     timed_out=threading.Event()
     def expire():
      if finished.is_set(): return
      timed_out.set()
      try: proc.kill()
      except Exception: pass
     watchdog=threading.Timer(timeout,expire)
     watchdog.daemon=True
     watchdog.start()
     value=None
     call_error=None
     try:
      if name not in cache: cache[name]=provider.getScript("vnd.sun.star.script:Standard.Tests."+name+"?language=Basic&location=application")
      value=cache[name].invoke(tuple(str(a) for a in args),(),())[0]
     except Exception as exc:
      call_error=exc
     finally:
      finished.set()
      watchdog.cancel()
     elapsed=time.monotonic()-started
     if timed_out.is_set():
      progress("TIMEOUT "+case_id+" function="+name+" elapsed_s=%.3f"%elapsed)
      raise TimeoutError("NATIVE_PROBE_TIMEOUT "+case_id+" "+name+" after "+str(timeout)+" seconds") from call_error
     if call_error is not None:
      progress("ERROR "+case_id+" function="+name+" elapsed_s=%.3f error="%elapsed+type(call_error).__name__)
      raise call_error
     counters["native_invocations"]+=1
     if not isinstance(value,str):
      progress("ERROR "+case_id+" function="+name+" reason=UNO_NONSTRING")
      raise AssertionError("UNO_NONSTRING "+name+" "+repr(value))
     progress("RETURN "+case_id+" function="+name+" elapsed_s=%.3f"%elapsed)
     return value
    for j,s in enumerate(days,1):
     got=native("S5_DAY_%03d"%j,"S5Day",s); want=str(day(int(s)))
     check("S5_DAY_%03d"%j,"day",{"d":s},got,want,"independent_python_int",got==want,"independent_oracle_checks")
    for j,(c,t) in enumerate(pairs,1):
     got=native("S5_WORK_%03d"%j,"S5Work",c,t); want="|".join(map(str,work(int(c),int(t))))
     check("S5_WORK_%03d"%j,"work",{"c":c,"t":t},got,want,"independent_python_int",got==want,"independent_oracle_checks")
    for k in range(-3,4):
     v=native("S5_GATE_%+03d"%k,"S5Gate",k).split("|"); ok=False
     if len(v)==6:
      g,h=map(int,v[:2])
      ok=42<=h-g<=963 and v[2:]==list(map(str,(k-1,k,k,k+1)))
     check("S5_GATE_%+03d"%k,"gate",{"k":k},"|".join(v),"gap 42..963; predecessor and successor indices","structural_boundary_no_independent_gate_oracle",ok,"boundary_checks")
    c,t=str(F),str(F+1)
    v=native("S5_YEAR_001","S5Year",c,t).split("|"); ok=False
    if len(v)==6:
     y,first,last,ncut,nmonth,total=map(int,v)
     ok=y==5000 and first<int(t)<=last and 252<=last-first<=5778 and 6<=ncut<=17 and 3<=nmonth<=47 and total==last-first
    check("S5_YEAR_001","year",{"c":c,"t":t},"|".join(v),"year 5000; bounded span and full month sum","structural_only_shared_reference",ok,"structural_only_checks")
    d=native("S5_DATE_001","S5Date",c,t).split("|")
    ok=len(d)==5 and d[0]==v[0] and unicodedata.normalize("NFC",d[1]) in cutlets and unicodedata.normalize("NFC",d[3]) in months and d[2].isdigit() and 1<=int(d[2])<=5778 and d[4].isdigit() and 1<=int(d[4])<=123
    check("S5_DATE_001","date",{"c":c,"t":t},"|".join(d),"five fields; year and locked catalog; bounded day indices","structural_only_shared_reference",ok,"structural_only_checks")
    for j,(c,t) in enumerate(((str(F),str(F+1)),(str(F+1),str(F))),1):
     got=native("S5_PROD_%03d"%j,"S5Production",c,t); code,sep,message=got.partition("|")
     ok=sep=="|" and code=="9302" and "E_STAGE_02_DISCOVERY_ONLY" in message
     check("S5_PROD_%03d"%j,"production",{"c":c,"t":t},got,"9302|E_STAGE_02_DISCOVERY_ONLY","EXPECTED_ERROR_NOT_CALENDAR_IMPLEMENTATION",ok,"production_expected_error_checks")
   finally: office.stop_office(proc,context)
  if len({r[0] for r in rows})!=len(rows): errors.append("DUPLICATE_IDS")
  if len(rows)!=len(days)+len(pairs)+7+1+1+2: errors.append("MISSING_NATIVE_ROWS")
  if min(counters.values())<=0: errors.append("COVERAGE_ZERO")
 except Exception:
  progress("RUN_EXCEPTION "+traceback.format_exc().splitlines()[-1])
  errors.append("UNHANDLED: "+traceback.format_exc().splitlines()[-1])
  (out/"error.txt").write_text(traceback.format_exc(),encoding="utf-8")
  traceback.print_exc()
 finally:
  with (out/"cases.tsv").open("w",encoding="utf-8",newline="") as f:
   w=csv.writer(f,delimiter="\t",lineterminator="\n")
   w.writerow(("id","category","inputs_json","actual","expected","provenance","result"));w.writerows(rows)
  report=dict(stage=5,scope="CHARACTERIZATION_AND_STRUCTURAL_QA_ONLY",full_production_calendar="NOT_IMPLEMENTED_NOT_ACCEPTED",cases=len(rows),unique_cases=len({r[0] for r in rows}),**counters,failures=len(errors),errors=errors[:40])
  (out/"assertions.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
  (out/"source_metadata.json").write_text(json.dumps(metadata,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
  (out/"status.txt").write_text("PASS\n" if not errors else "FAILED\n",encoding="utf-8")
  progress("RUN_END status="+("PASS" if not errors else "FAILED")+" cases=%d failures=%d"%(len(rows),len(errors)))
  print(json.dumps(report,ensure_ascii=False,sort_keys=True),flush=True)
 return 0 if not errors else 1
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--self-test",action="store_true")
 p.add_argument("--basic-dir",type=Path)
 p.add_argument("--output-dir",type=Path)
 a=p.parse_args()
 if a.self_test:
  d,w=inputs();print("STAGE5_SELFTEST_PASS days=%d pairs=%d"%(len(d),len(w)));return 0
 if not a.basic_dir or not a.output_dir: p.error("native requires --basic-dir and --output-dir")
 return run(a.basic_dir.resolve(),a.output_dir.resolve())
if __name__=="__main__":
 sys.exit(main())
