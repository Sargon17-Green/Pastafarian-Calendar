#!/usr/bin/env python3
"""Issue29 v185 GNAT/GMP boundary contract run, strictly no calendar F."""
from pathlib import Path
import hashlib,json,os,re,resource,signal,subprocess,sys,time
BASE='1160096aa847c54cbef27c232771ce1549d7ba8f'
ORIGINAL='e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN='56bc4173aae4975ded019ef5ab5a36249f1424df'
BRANCH='qa/issue29-ada-gmp-negative-contracts-v185'
ACTIVATION='ci(issue29-v185): source-locked GMP invalid-input fail-closed contracts; no F'
PINS={
 'src/canonical_full_weave_gmp_v164.adb':'845bd8905943a54e63d6aba0334404a5051fe666',
 'src/canonical_full_weave_gmp_v164.ads':'0b68edf7eddbc33869358bcfcc21e32465fc591e',
 'src/canonical_wide_rank_gmp_v164.adb':'52b8814c2ab1924cdebafe893a65d97cd3ccfa61',
 'src/canonical_wide_rank_gmp_v164.ads':'14b94e81534e98cfdb07be3824076bd7082385ea',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
PATHS={
 '.github/workflows/issue29-v185-gmp-negative-contracts.yml',
 'issue29_v185_negative_contracts.gpr',
 'tests/issue29_v185_negative_contract_tests.adb',
 'tests/issue29_v185_contract_runner.py',
}
EV=Path('evidence')
BIN=Path('bin_v185/issue29_v185_negative_contract_tests')
def check(ok,context):
 if not ok:raise ValueError(context)
def digest(b):return hashlib.sha256(b).hexdigest()
def git_blob(b):return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],stderr=subprocess.DEVNULL).decode().strip()
def save(path,b):
 with path.open('xb') as f:
  f.write(b);f.flush();os.fsync(f.fileno())
def savejson(path,data):save(path,(json.dumps(data,sort_keys=True,indent=2)+'\n').encode())
def preflight():
 check(os.environ.get('GITHUB_EVENT_NAME')=='push' and os.environ.get('GITHUB_RUN_ATTEMPT')=='1','only first push run allowed')
 check(os.environ.get('GITHUB_REF')=='refs/heads/'+BRANCH,'wrong QA branch')
 head=git('rev-parse','HEAD')
 check(head==os.environ.get('GITHUB_SHA'),'HEAD drift')
 event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_bytes())
 check(event.get('head_commit',{}).get('message')==ACTIVATION,'activation message drift')
 check(subprocess.run(['git','merge-base','--is-ancestor',BASE,head],capture_output=True).returncode==0,'original base not preserved')
 changed=git('diff','--name-only',BASE+'...HEAD').splitlines()
 check(len(changed)==4 and set(changed)==PATHS,'unexpected source modification')
 check(git_blob(subprocess.check_output(['git','show',MAIN+':README.md']))=='74c424b44eadd4ece3f29072ddbf873236557604','main README changed')
 pins={}
 for path,expected in PINS.items():
  content=Path(path).read_bytes()
  check(git_blob(content)==expected and git('rev-parse',ORIGINAL+':'+path)==expected,'GMP or normative source drift '+path)
  pins[path]={'blob':expected,'sha256':digest(content)}
 lock=Path('.github/workflows/canonical-names-lock.yml').read_text()
 check(lock.count('    if: '+'$'+'{{ false }}')==42 and lock.count('  verify:\n')==1,'42 legacy native jobs must remain disabled')
 test=Path('tests/issue29_v185_negative_contract_tests.adb').read_text().lower()
 check('with normative_oracle;' not in test and 'with calendar_date;' not in test and
       'with canonical_full_weave_gmp_v164;' in test and
       'with canonical_wide_rank_gmp_v164;' in test,'wrong GMP-only source imports')
 check('with "gnatcoll_gmp.gpr";' in Path('issue29_v185_negative_contracts.gpr').read_text(),'GMP GPR absent')
 ident={'head':head,'base':BASE,'branch':BRANCH,
        'run_id':os.environ['GITHUB_RUN_ID'],'attempt':1}
 return ident,pins
def prepare():
 ident,pins=preflight()
 EV.mkdir(exist_ok=True)
 savejson(EV/'preflight.json',{'schema':'ISSUE29_V185_GMP_NEGATIVE_CONTRACTS_NO_F/1',
          'status':'SOURCE_LOCKED_NO_CALENDAR_F',
          'identity':ident,'source_blobs':pins,'calendar_calls':0,
          'soak_years':0,'dispatch_halt_remains':True,
          'expected_negative_cases':17,'expected_positive_controls':6})
 print('V185_NEGATIVE_INPUT_CONTRACTS_SOURCE_LOCKED_ZERO_F')
def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(45,45))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def stop(p):
 try:os.killpg(p.pid,signal.SIGKILL)
 except ProcessLookupError:pass
def run_once():
 ident,pins=preflight()
 pre=json.loads((EV/'preflight.json').read_bytes())
 check(pre['identity']==ident,'preflight identity mismatch')
 check(BIN.is_file(),'native GMP QA binary missing')
 syms=subprocess.run(['nm',str(BIN)],capture_output=True,check=True)
 check(b'normative_oracle' not in syms.stdout.lower(),'forbidden original F symbol linked')
 check(not (EV/'RUN_STARTED_ONCE').exists(),'only one native validation invocation')
 binary_sha=digest(BIN.read_bytes())
 savejson(EV/'RUN_STARTED_ONCE',{'head':ident['head'],'native_invocations':1,
                             'binary_sha256':binary_sha,'calendar_calls':0})
 result={'schema':pre['schema'],'status':'FAIL_CLOSED','identity':ident,
       'binary_sha256':binary_sha,'native_invocations':1,
       'calendar_calls':0,'soak_years':0}
 out=EV/'native.stdout';err=EV/'native.stderr';t0=time.monotonic();p=None
 try:
  with out.open('xb') as f,err.open('xb') as e:
   p=subprocess.Popen([str(BIN.resolve())],stdin=subprocess.DEVNULL,
                      stdout=f,stderr=e,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    rc=p.poll()
    if out.stat().st_size+err.stat().st_size>65536:
     violation='OUTPUT_LIMIT';stop(p);break
    if time.monotonic()-t0>45:
     violation='WALL_LIMIT';stop(p);break
    if rc is not None:break
    time.sleep(.05)
   p.wait(timeout=5)
  output=out.read_bytes().decode('ascii');errors=err.read_bytes()
  result.update({'exit_code':p.returncode,'stderr_bytes':len(errors),
       'elapsed_seconds':round(time.monotonic()-t0,4),
       'peak_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
       'resource_violation':violation})
  check(p.returncode==0 and not errors and violation is None,'native GMP input contract test failed')
  def field(name):
   values=re.findall('^'+re.escape(name)+r'=\s*([0-9]+)\s*$',output,re.M)
   check(len(values)==1,'missing native field '+name)
   return int(values[0])
  negative=field('V185_FAIL_CLOSED_CASES');positive=field('V185_ACCEPTED_CONTROLS');assertions=field('V185_ASSERTIONS')
  check(negative==17 and positive==6 and assertions>=29,'unexpected input-contract coverage')
  check('V185_GMP_NEGATIVE_CONTRACTS_EXACT_PASS_ZERO_F' in output,'missing test pass marker')
  result.update({'status':'PASS_GMP_NEGATIVE_CONTRACTS_ZERO_F',
                'negative_cases':negative,'accepted_controls':positive,
                'assertions':assertions})
 except Exception as exc:
  result['failure']=str(exc)
  if p is not None and p.poll() is None:stop(p);p.wait(timeout=5)
 finally:
  for key,path in [('stdout',out),('stderr',err)]:
   if path.exists():
    result[key+'_sha256']=digest(path.read_bytes())
    result[key+'_bytes']=path.stat().st_size
  savejson(EV/'result.json',result)
 check(result['status']=='PASS_GMP_NEGATIVE_CONTRACTS_ZERO_F','v185 failed closed; no automatic rerun')
 print('V185_GMP_INVALID_INPUT_CONTRACTS_NATIVE_PASS_ZERO_F')
if __name__=='__main__':
 check(len(sys.argv)==2 and sys.argv[1] in ('prepare','run-once'),'mode')
 if sys.argv[1]=='prepare':prepare()
 else:run_once()
