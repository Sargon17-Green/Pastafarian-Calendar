#!/usr/bin/env python3
"""v181 maximal-domain GMP Unrank first/last; exact external lex extrema, zero F."""
from __future__ import annotations
from itertools import permutations
from pathlib import Path
import hashlib,json,math,os,re,resource,signal,subprocess,sys,time
sys.set_int_max_str_digits(20000)
BASE='1160096aa847c54cbef27c232771ce1549d7ba8f'
ORIGINAL='e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN='56bc4173aae4975ded019ef5ab5a36249f1424df'
BRANCH='qa/issue29-ada-gmp-max-unrank-extrema-v181'
ACTIVATION='ci(issue29-v181): exact GMP Unrank extrema at 5778 days, zero F'
SOURCES={
 'src/canonical_full_weave_gmp_v164.adb':'845bd8905943a54e63d6aba0334404a5051fe666',
 'src/canonical_full_weave_gmp_v164.ads':'0b68edf7eddbc33869358bcfcc21e32465fc591e',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
PATHS={
 '.github/workflows/issue29-v181-gmp-max-unrank-extrema.yml',
 'issue29_v181_unrank_extrema.gpr',
 'tests/issue29_v181_unrank_extrema_tests.adb',
 'tests/issue29_v181_unrank_extrema.py',
}
EV=Path('evidence')
REF=EV/'v181-unrank-extrema-reference.dat'
BIN=Path('bin_v181/issue29_v181_unrank_extrema_tests')
SHAPES=(
 ('max_tail_120',tuple([123]*46+[120])),
 ('max_head_120',tuple([120]+[123]*46)),
 ('uniform_122',tuple([122]*47)),
)
def require(ok,context):
 if not ok:raise RuntimeError(context)
def sha(data):return hashlib.sha256(data).hexdigest()
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],stderr=subprocess.DEVNULL).decode().strip()
def write_once(p,data):
 with p.open('xb') as f:
  f.write(data);f.flush();os.fsync(f.fileno())
def json_once(p,value):
 write_once(p,(json.dumps(value,sort_keys=True,indent=2)+'\n').encode())
def identity():
 require(os.environ.get('GITHUB_RUN_ATTEMPT')=='1' and os.environ.get('GITHUB_EVENT_NAME')=='push','one-shot push only')
 require(os.environ.get('GITHUB_REF')=='refs/heads/'+BRANCH,'branch not authorized')
 head=git('rev-parse','HEAD')
 require(os.environ.get('GITHUB_SHA')==head,'HEAD mismatch')
 event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_bytes())
 require(event.get('head_commit',{}).get('message')==ACTIVATION,'activation commit mismatch')
 require(subprocess.run(['git','merge-base','--is-ancestor',BASE,head],capture_output=True).returncode==0,'wrong source base')
 changed=git('diff','--name-only',BASE+'...HEAD').splitlines()
 require(set(changed)==PATHS and len(changed)==4,'unexpected production changes')
 require(blob(subprocess.check_output(['git','show',MAIN+':README.md']))=='74c424b44eadd4ece3f29072ddbf873236557604','canonical specification drift')
 locked={}
 for path,expected in SOURCES.items():
  data=Path(path).read_bytes()
  require(blob(data)==expected and git('rev-parse',ORIGINAL+':'+path)==expected,'source lock failed '+path)
  locked[path]={'git_blob':expected,'sha256':sha(data)}
 locks=Path('.github/workflows/canonical-names-lock.yml').read_text()
 require(locks.count('    if: '+'$'+'{{ false }}')==42 and locks.count('  verify:\n')==1,'42 dispatch safety gates missing')
 contents=Path('tests/issue29_v181_unrank_extrema_tests.adb').read_text().lower()
 require('with canonical_full_weave_gmp_v164;' in contents and 'with normative_oracle;' not in contents,'forbidden native F dependency')
 return {'head':head,'base':BASE,'branch':BRANCH,'attempt':1,'run_id':os.environ['GITHUB_RUN_ID']},locked
def count(lengths):
 # Independent exact-integer reference for Count (v180 recurrence).
 p=[0]
 for n in lengths:p.append(p[-1]+n)
 old=[1]*(p[-1]+1)
 for i in range(len(lengths)-1,-1,-1):
  n=lengths[i];v=0;row=[]
  for x in range(p[i]+1):
   y=x+n-1
   v+=math.comb(y-1,n-2)*old[y]
   row.append(v)
  old=row
 return old[0]
def extrema(lengths):
 m=len(lengths)
 first=tuple(j for j,n in enumerate(lengths,1) for _ in range(n))
 # Direct combinatorial construction, not state DP and not GMP.
 last=(tuple(range(1,m+1))
       +tuple(j for j in range(m,1,-1) for _ in range(lengths[j-1]-2))
       +(1,)*(lengths[0]-1)+tuple(range(2,m+1)))
 return first,last
def finite_self_check():
 for lengths in ((2,2),(3,3),(4,4),(2,2,2),(3,2,2),(2,3,2),(4,2,3)):
  m=len(lengths)
  seqs=set(permutations(j for j,n in enumerate(lengths,1) for _ in range(n)))
  valid=sorted(w for w in seqs if
    sorted(range(1,m+1),key=lambda j:w.index(j))==list(range(1,m+1)) and
    sorted(range(1,m+1),key=lambda j:len(w)-1-w[::-1].index(j))==list(range(1,m+1)))
  require(bool(valid) and (valid[0],valid[-1])==extrema(lengths),
          'independent finite lex-extreme self-check mismatch '+str(lengths))
def generate():
 finite_self_check()
 lines=['3'];stats=[];tokens=0
 for name,lengths in SHAPES:
  n=count(lengths)
  a,b=extrema(lengths)
  require(len(a)==len(b)==sum(lengths) and a<b,'extrema malformed')
  require(a.count(1)==b.count(1)==lengths[0],'first-month multiplicity mismatch')
  require(n.bit_length()>31000,'large count regression')
  lines.extend([str(len(lengths))]+[str(x) for x in lengths]+[str(n)])
  for seq in (a,b):
   lines.extend(map(str,seq))
   tokens+=len(seq)
  stats.append({'name':name,'months':len(lengths),'days':sum(lengths),
                'count_bits':n.bit_length(),'count_sha256':sha(str(n).encode()),
                'first_sha256':sha(bytes(a)),'last_sha256':sha(bytes(b))})
 require(tokens==2*(5778+5778+5734),'fixture token count')
 require(stats[0]['count_sha256']==stats[1]['count_sha256'],'reverse month count mismatch')
 raw=('\n'.join(lines)+'\n').encode('ascii')
 return raw,stats,tokens
def preflight():
 env,sources=identity()
 EV.mkdir(exist_ok=True)
 data,stats,tokens=generate()
 write_once(REF,data)
 json_once(EV/'preflight.json',{'status':'REFERENCE_READY_ZERO_F',
     'identity':env,'source_blobs':sources,'cases':stats,
     'samples':6,'tokens':tokens,'reference_bytes':len(data),
     'reference_sha256':sha(data),'calendar_calls':0,'soak_years':0,
     'dispatch_halt_remains':True})
 print('V181_MAX_LEX_EXTREMA_REFERENCE_READY_ZERO_F')
 print('V181_EXPECTED_TOKENS='+str(tokens))
def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(210,210))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def run_once():
 env,_=identity()
 pre=json.loads((EV/'preflight.json').read_bytes())
 require(pre['identity']==env and sha(REF.read_bytes())==pre['reference_sha256'],'fixture altered')
 require(BIN.is_file(),'native file missing')
 symbols=subprocess.run(['nm',str(BIN)],check=True,capture_output=True)
 require(b'normative_oracle' not in symbols.stdout.lower(),'forbidden calendar symbol')
 require(not (EV/'RUN_STARTED_ONCE').exists(),'already run')
 binary_sha=sha(BIN.read_bytes())
 json_once(EV/'RUN_STARTED_ONCE',{'head':env['head'],'binary_sha256':binary_sha,
                                   'native_invocations':1,'calendar_calls':0})
 out=EV/'native.stdout';err=EV/'native.stderr'
 result={'identity':env,'binary_sha256':binary_sha,'reference_sha256':pre['reference_sha256'],
         'native_invocations':1,'calendar_calls':0,'soak_years':0,'status':'FAIL_CLOSED'}
 started=time.monotonic();p=None
 try:
  with out.open('xb') as fo,err.open('xb') as fe:
   p=subprocess.Popen([str(BIN.resolve())],stdin=subprocess.DEVNULL,stdout=fo,
       stderr=fe,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    rc=p.poll()
    if out.stat().st_size+err.stat().st_size>131072:
     violation='OUTPUT_LIMIT';os.killpg(p.pid,signal.SIGKILL);break
    if time.monotonic()-started>210:
     violation='WALL_LIMIT';os.killpg(p.pid,signal.SIGKILL);break
    if rc is not None:break
    time.sleep(.075)
   p.wait(timeout=5)
  body=out.read_bytes().decode('ascii');errors=err.read_bytes()
  result.update({'exit_code':p.returncode,'stderr_bytes':len(errors),
     'elapsed_seconds':round(time.monotonic()-started,4),
     'peak_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
     'resource_violation':violation})
  require(p.returncode==0 and not errors and violation is None,'native exit/stderr/resource error')
  def field(key):
   values=re.findall('^'+re.escape(key)+r'=\s*([0-9]+)\s*$',body,re.M)
   require(len(values)==1,'missing output '+key)
   return int(values[0])
  c=field('V181_GMP_EXTREMA_CASES');s=field('V181_GMP_EXTREMA_SAMPLES')
  t=field('V181_GMP_EXTREMA_TOKENS');checks=field('V181_GMP_EXTREMA_ASSERTIONS')
  require('V181_GMP_EXTREMA_PASS_ZERO_CALENDAR_F' in body,'no pass token')
  require((c,s,t)==(3,6,pre['tokens']) and checks>69000,'native coverage disagreement')
  result.update({'status':'PASS_MAX_GMP_EXACT_UNRANK_EXTREMA_ZERO_F',
                 'cases':c,'samples':s,'tokens':t,'assertions':checks})
 except Exception as exc:
  result['failure']=str(exc)
  if p is not None and p.poll() is None:
   os.killpg(p.pid,signal.SIGKILL);p.wait(timeout=5)
 finally:
  for key,path in (('stdout',out),('stderr',err)):
   if path.exists():
    result[key+'_sha256']=sha(path.read_bytes())
    result[key+'_bytes']=path.stat().st_size
  json_once(EV/'result.json',result)
 require(result['status']=='PASS_MAX_GMP_EXACT_UNRANK_EXTREMA_ZERO_F',
         'v181 failed closed, never automatic retry')
 print('V181_MAX_5778_DAY_GMP_UNRANK_EXTREMA_PASS_ZERO_F')
if __name__=='__main__':
 require(len(sys.argv)==2 and sys.argv[1] in ('preflight','run-once','self-check'),
         'bad subcommand')
 if sys.argv[1]=='preflight':preflight()
 elif sys.argv[1]=='run-once':run_once()
 else:
  data,cases,tokens=generate()
  print(json.dumps({'reference_sha256':sha(data),'bytes':len(data),
                    'samples':6,'tokens':tokens,'cases':cases},indent=2))
