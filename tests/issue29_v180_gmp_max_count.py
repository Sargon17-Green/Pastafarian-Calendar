#!/usr/bin/env python3
"""Issue29 v180: max-domain exact combinatorial Count reference; no native date converter."""
from __future__ import annotations
import hashlib,json,math,os,re,resource,signal,subprocess,sys,time
from pathlib import Path
sys.set_int_max_str_digits(20000)
BASE='1160096aa847c54cbef27c232771ce1549d7ba8f'
ORIGINAL='e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN='56bc4173aae4975ded019ef5ab5a36249f1424df'
BRANCH='qa/issue29-ada-gmp-max-count-v180'
ACTIVATION='ci(issue29-v180): source-locked GMP maximum legal year Count only; no F'
SOURCES={
 'src/canonical_full_weave_gmp_v164.adb':'845bd8905943a54e63d6aba0334404a5051fe666',
 'src/canonical_full_weave_gmp_v164.ads':'0b68edf7eddbc33869358bcfcc21e32465fc591e',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
PATHS={
 '.github/workflows/issue29-v180-gmp-max-count.yml',
 'issue29_v180_gmp_max_count.gpr',
 'tests/issue29_v180_gmp_max_count_tests.adb',
 'tests/issue29_v180_gmp_max_count.py',
}
EV=Path('evidence')
REF=EV/'v180-max-count-reference.dat'
BIN=Path('bin_v180/issue29_v180_gmp_max_count_tests')
SHAPES=(
 ('max_tail_120',tuple([123]*46+[120])),
 ('max_head_120',tuple([120]+[123]*46)),
 ('uniform_122',tuple([122]*47)),
 ('uniform_123_46',tuple([123]*46)),
 ('uniform_4',tuple([4]*47)),
)
def require(cond,msg):
 if not cond: raise RuntimeError(msg)
def git(*args):
 return subprocess.check_output(['git',*args],stderr=subprocess.DEVNULL).decode().strip()
def sha(data):
 return hashlib.sha256(data).hexdigest()
def blob(data):
 return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def write_once(path,data):
 with path.open('xb') as stream:
  stream.write(data);stream.flush();os.fsync(stream.fileno())
def receipt(path,value):
 write_once(path,(json.dumps(value,sort_keys=True,indent=2)+'\n').encode())
def source_gates():
 require(os.environ.get('GITHUB_RUN_ATTEMPT')=='1','rerun not allowed')
 require(os.environ.get('GITHUB_EVENT_NAME')=='push','push event only')
 require(os.environ.get('GITHUB_REF')=='refs/heads/'+BRANCH,'branch mismatch')
 head=git('rev-parse','HEAD')
 require(os.environ.get('GITHUB_SHA')==head,'HEAD mismatch')
 event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_bytes())
 require(event.get('head_commit',{}).get('message')==ACTIVATION,'one-shot commit mismatch')
 require(subprocess.run(['git','merge-base','--is-ancestor',BASE,head],capture_output=True).returncode==0,'wrong baseline')
 changed=git('diff','--name-only',BASE+'...HEAD').splitlines()
 require(len(changed)==4 and set(changed)==PATHS,'unexpected file changes')
 require(blob(subprocess.check_output(['git','show',MAIN+':README.md']))=='74c424b44eadd4ece3f29072ddbf873236557604','canonical specification drift')
 source_info={}
 for path,expected in SOURCES.items():
  data=Path(path).read_bytes()
  require(blob(data)==expected and git('rev-parse',ORIGINAL+':'+path)==expected,'pinned source mismatch: '+path)
  source_info[path]={'git_blob':expected,'sha256':sha(data)}
 lock=Path('.github/workflows/canonical-names-lock.yml').read_text()
 require(lock.count('    if: '+'$'+'{{ false }}')==42 and lock.count('  verify:\n')==1,'42 native dispatch guards not confirmed')
 ada=Path('tests/issue29_v180_gmp_max_count_tests.adb').read_text().lower()
 require('with canonical_full_weave_gmp_v164;' in ada and 'with normative_oracle;' not in ada,'forbidden calendar linkage')
 return {'head':head,'base':BASE,'branch':BRANCH,'run_id':os.environ['GITHUB_RUN_ID'],'attempt':1},source_info
def reference_count(lengths):
 # A stand-alone Python exact-integer reference from the finite weighted-sum identity.
 # Uses math.comb, no production GMP and no native F(c,t) imports.
 prefix=[0]
 for n in lengths: prefix.append(prefix[-1]+n)
 assert len(lengths)<=47 and prefix[-1]<=5778 and all(2<=n<=123 for n in lengths)
 old=[1]*(prefix[-1]+1)
 for i in range(len(lengths)-1,-1,-1):
  n=lengths[i]
  weighted=0
  row=[]
  for x in range(prefix[i]+1):
   y=x+n-1
   weighted += math.comb(y-1,n-2)*old[y]
   row.append(weighted)
  old=row
 return old[0]
def expected():
 lines=['5'];stats=[]
 for label,lengths in SHAPES:
  n=reference_count(lengths)
  require(n>0,'zero Count: '+label)
  stats.append({'name':label,'months':len(lengths),'days':sum(lengths),
     'bits':n.bit_length(),'decimal_digits':len(str(n)),
     'count_sha256':sha(str(n).encode())})
  lines += [str(len(lengths))]+[str(x) for x in lengths]+[str(n)]
 require(stats[0]['count_sha256']==stats[1]['count_sha256'],'reverse-length exact count metamorphism failed')
 require(stats[0]['bits']>=31000 and stats[0]['days']==5778,'maximum envelope not exercised')
 raw=('\n'.join(lines)+'\n').encode('ascii')
 return raw,stats
def preflight():
 identity,sources=source_gates()
 EV.mkdir(exist_ok=True)
 raw,stats=expected()
 write_once(REF,raw)
 receipt(EV/'preflight.json',{'identity':identity,'source_blobs':sources,
    'source_case_count':5,'cases':stats,'reference_bytes':len(raw),
    'reference_sha256':sha(raw),'calendar_calls':0,'soak_years':0,
    'status':'MAX_DOMAIN_REFERENCE_READY_ZERO_F'})
 print('V180_MAXIMUM_GMP_REFERENCE_READY_ZERO_F')
 print('V180_MAX_BITS='+str(stats[0]['bits']))
def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(200,200))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def run_once():
 identity,_=source_gates()
 pre=json.loads((EV/'preflight.json').read_bytes())
 require(identity==pre['identity'] and sha(REF.read_bytes())==pre['reference_sha256'],'reference identity/hash mismatch')
 require(BIN.is_file(),'native executable missing')
 sym=subprocess.run(['nm',str(BIN)],capture_output=True,check=True)
 require(b'normative_oracle' not in sym.stdout.lower(),'forbidden source F linked')
 require(not (EV/'RUN_STARTED_ONCE').exists(),'second GMP test execution prohibited')
 binary_sha=sha(BIN.read_bytes())
 receipt(EV/'RUN_STARTED_ONCE',{'native_invocations':1,'binary_sha256':binary_sha,'calendar_calls':0})
 out=EV/'native.stdout';err=EV/'native.stderr'
 result={'identity':identity,'status':'FAIL_CLOSED','binary_sha256':binary_sha,
         'reference_sha256':pre['reference_sha256'],'native_invocations':1,
         'calendar_calls':0,'soak_years':0}
 started=time.monotonic();p=None
 try:
  with out.open('xb') as fo,err.open('xb') as fe:
   p=subprocess.Popen([str(BIN.resolve())],stdin=subprocess.DEVNULL,stdout=fo,
       stderr=fe,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    code=p.poll()
    if out.stat().st_size+err.stat().st_size>131072:
     violation='OUTPUT_LIMIT';os.killpg(p.pid,signal.SIGKILL);break
    if time.monotonic()-started>200:
     violation='WALL_LIMIT';os.killpg(p.pid,signal.SIGKILL);break
    if code is not None:break
    time.sleep(.05)
   p.wait(timeout=5)
  text=out.read_bytes().decode('ascii')
  errors=err.read_bytes()
  result.update({'exit_code':p.returncode,'stderr_bytes':len(errors),
    'elapsed_seconds':round(time.monotonic()-started,4),
    'peak_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
    'resource_violation':violation})
  require(p.returncode==0 and len(errors)==0 and violation is None,'native exit/stderr/resource failure')
  def field(key):
   values=re.findall('^'+re.escape(key)+r'=\s*([0-9]+)\s*$',text,re.M)
   require(len(values)==1,'missing marker '+key)
   return int(values[0])
  count=field('V180_GMP_COUNT_CASES');checks=field('V180_GMP_COUNT_ASSERTIONS')
  require('V180_GMP_MAX_DOMAIN_EXACT_PASS_ZERO_F' in text,'missing success marker')
  require(count==5 and checks>=240,'insufficient native Count verifications')
  result.update({'status':'PASS_GMP_MAX_5778_DAY_COUNT_ZERO_F','cases':count,
                 'assertions':checks})
 except Exception as exc:
  result['failure']=str(exc)
  if p and p.poll() is None:os.killpg(p.pid,signal.SIGKILL);p.wait(timeout=5)
 finally:
  for key,path in (('stdout',out),('stderr',err)):
   if path.exists():
    result[key+'_sha256']=sha(path.read_bytes())
    result[key+'_bytes']=path.stat().st_size
  receipt(EV/'result.json',result)
 require(result['status']=='PASS_GMP_MAX_5778_DAY_COUNT_ZERO_F','v180 failed closed, do not rerun same attempt')
 print('V180_GMP_MAXIMUM_5778_DAY_COUNT_PASS_ZERO_F')
if __name__=='__main__':
 require(len(sys.argv)==2 and sys.argv[1] in ('preflight','run-once','self-check'),'invalid subcommand')
 if sys.argv[1]=='preflight': preflight()
 elif sys.argv[1]=='run-once': run_once()
 else:
  fixture,stats=expected()
  print(json.dumps({'bytes':len(fixture),'sha256':sha(fixture),'stats':stats},indent=2))
