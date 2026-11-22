#!/usr/bin/env python3
"""v182 closed-form geometric series vs GMP global rank at 248 radix-M places; NO F."""
from __future__ import annotations
from pathlib import Path
import hashlib,json,math,os,re,resource,signal,subprocess,sys,time
sys.set_int_max_str_digits(20000)
BASE='1160096aa847c54cbef27c232771ce1549d7ba8f'
ORIGINAL='e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN='56bc4173aae4975ded019ef5ab5a36249f1424df'
BRANCH='qa/issue29-ada-gmp-rank-p248-v182'
ACTIVATION='ci(issue29-v182): GMP global rank 248-place closed-form golden vectors; zero F'
SOURCES={
 'src/canonical_wide_rank_gmp_v164.adb':'52b8814c2ab1924cdebafe893a65d97cd3ccfa61',
 'src/canonical_wide_rank_gmp_v164.ads':'14b94e81534e98cfdb07be3824076bd7082385ea',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
PATHS={
 '.github/workflows/issue29-v182-gmp-rank-p248.yml',
 'issue29_v182_rank_p248.gpr',
 'tests/issue29_v182_rank_p248_tests.adb',
 'tests/issue29_v182_rank_p248.py',
}
EV=Path('evidence');REF=EV/'v182-rank-p248-reference.dat'
BIN=Path('bin_v182/issue29_v182_rank_p248_tests')
M=(1<<127)-1
EXPECTED_COUNT_SHA='01ef297e0d3a91a445a9087fc83238ad678eab644a0a6f89a013af918217a80a'
def require(ok,reason):
 if not ok:raise RuntimeError(reason)
def sha(data):return hashlib.sha256(data).hexdigest()
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],stderr=subprocess.DEVNULL).decode().strip()
def write_once(path,data):
 with path.open('xb') as f:
  f.write(data);f.flush();os.fsync(f.fileno())
def json_once(path,value):
 write_once(path,(json.dumps(value,sort_keys=True,indent=2)+'\n').encode())
def gates():
 require(os.environ.get('GITHUB_RUN_ATTEMPT')=='1' and os.environ.get('GITHUB_EVENT_NAME')=='push','one-shot push only')
 require(os.environ.get('GITHUB_REF')=='refs/heads/'+BRANCH,'branch mismatch')
 head=git('rev-parse','HEAD')
 require(os.environ.get('GITHUB_SHA')==head,'SHA mismatch')
 event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_bytes())
 require(event.get('head_commit',{}).get('message')==ACTIVATION,'activation mismatch')
 require(subprocess.run(['git','merge-base','--is-ancestor',BASE,head],capture_output=True).returncode==0,'wrong base')
 changed=git('diff','--name-only',BASE+'...HEAD').splitlines()
 require(set(changed)==PATHS and len(changed)==4,'unexpected production files')
 require(blob(subprocess.check_output(['git','show',MAIN+':README.md']))=='74c424b44eadd4ece3f29072ddbf873236557604','canonical spec drift')
 pins={}
 for path,expected in SOURCES.items():
  data=Path(path).read_bytes()
  require(blob(data)==expected and git('rev-parse',ORIGINAL+':'+path)==expected,'Git source lock '+path)
  pins[path]={'git_blob':expected,'sha256':sha(data)}
 lock=Path('.github/workflows/canonical-names-lock.yml').read_text()
 require(lock.count('    if: '+'$'+'{{ false }}')==42 and lock.count('  verify:\n')==1,'42 native dispatch gates not proven')
 ada=Path('tests/issue29_v182_rank_p248_tests.adb').read_text().lower()
 require('with canonical_wide_rank_gmp_v164;' in ada and 'with normative_oracle;' not in ada,'forbidden original F import')
 return {'head':head,'base':BASE,'branch':BRANCH,'attempt':1,'run_id':os.environ['GITHUB_RUN_ID']},pins
def exact_count(lengths):
 prefix=[0]
 for n in lengths:prefix.append(prefix[-1]+n)
 row=[1]*(prefix[-1]+1)
 for i in range(len(lengths)-1,-1,-1):
  n=lengths[i];s=0;new=[]
  for x in range(prefix[i]+1):
   y=x+n-1
   s+=math.comb(y-1,n-2)*row[y]
   new.append(s)
  row=new
 return row[0]
def sample_rank(first,step,n):
 places=1;space=M
 while space<n:space*=M;places+=1
 require(places==248,'expected exactly 248 radix-M places')
 d0=first-1
 S0=(M**places-1)//(M-1)
 S1=((places-1)*M**(places+1)-places*M**places+M)//(M-1)**2
 # Independent closed form, not the GMP implementation's digit-by-digit arithmetic.
 candidate=1+d0*S0+step*S1
 if step==1 and d0+places-1>=M:
  k=M-d0
  candidate-=M*(M**places-M**k)//(M-1)
 if step==-1 and places-1>d0:
  k=d0+1
  candidate+=M*(M**places-M**k)//(M-1)
 # Separate naive cyclic-digit expansion, to independently check the closed form.
 naive=1+sum(((d0+step*k)%M)*M**k for k in range(places))
 require(candidate==naive,'closed form and independent digit loop disagree')
 limit=(space//n)*n
 rejected=candidate>limit
 effective=(limit if step==-1 else 1) if rejected else candidate
 rank=(effective-1)%n+1
 require(1<=rank<=n,'selected rank invalid')
 return rank,places,rejected
def fixture():
 n=exact_count(tuple([123]*46+[120]))
 require(n.bit_length()==31483 and sha(str(n).encode())==EXPECTED_COUNT_SHA,'v180 max count changed')
 lines=['6',str(n)]
 stats=[]
 for code,first in ((1,1),(2,M//2),(3,M)):
  for step in (-1,1):
   r,places,rejected=sample_rank(first,step,n)
   lines.extend((str(code),str(step),str(r)))
   stats.append({'first_code':code,'direction':step,'places':places,
                 'rejected':rejected,'rank_sha256':sha(str(r).encode()),
                 'rank_digits':len(str(r))})
 require(sum(x['rejected'] for x in stats)==2,'unexpected cyclic rejection branch count')
 require(stats[0]['rank_sha256']==EXPECTED_COUNT_SHA and stats[4]['rank_sha256']==EXPECTED_COUNT_SHA,
         'descending rejected endpoint rank changed')
 return ('\n'.join(lines)+'\n').encode('ascii'),n,stats
def preflight():
 ident,pins=gates()
 EV.mkdir(exist_ok=True)
 data,n,stats=fixture()
 write_once(REF,data)
 json_once(EV/'preflight.json',{'identity':ident,'source_blobs':pins,
    'schema':'ISSUE29_V182_P248_CLOSED_FORM_GLOBAL_RANK_ZERO_F/1',
    'reference_sha256':sha(data),'reference_bytes':len(data),
    'count_sha256':EXPECTED_COUNT_SHA,'count_bits':n.bit_length(),'radix_places':248,
    'cases':stats,'calendar_calls':0,'soak_years':0,'dispatch_halt_remains':True})
 print('V182_248_DIGIT_CLOSED_FORM_REFERENCE_READY_ZERO_F')
def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(120,120))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def run_once():
 ident,_=gates()
 pre=json.loads((EV/'preflight.json').read_bytes())
 require(pre['identity']==ident and sha(REF.read_bytes())==pre['reference_sha256'],'fixture tampered')
 require(BIN.is_file(),'native binary missing')
 names=subprocess.run(['nm',str(BIN)],capture_output=True,check=True)
 require(b'normative_oracle' not in names.stdout.lower(),'calendar F linked')
 require(not (EV/'RUN_STARTED_ONCE').exists(),'repeat GMP test blocked')
 binary_sha=sha(BIN.read_bytes())
 json_once(EV/'RUN_STARTED_ONCE',{'head':ident['head'],'native_invocations':1,
                                    'binary_sha256':binary_sha,'calendar_calls':0})
 out=EV/'native.stdout';err=EV/'native.stderr'
 result={'identity':ident,'status':'FAIL_CLOSED','binary_sha256':binary_sha,
          'reference_sha256':pre['reference_sha256'],
          'native_invocations':1,'calendar_calls':0,'soak_years':0}
 t0=time.monotonic();p=None
 try:
  with out.open('xb') as fo,err.open('xb') as fe:
   p=subprocess.Popen([str(BIN.resolve())],stdin=subprocess.DEVNULL,
      stdout=fo,stderr=fe,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    rc=p.poll()
    if out.stat().st_size+err.stat().st_size>131072:
     violation='OUTPUT_LIMIT';os.killpg(p.pid,signal.SIGKILL);break
    if time.monotonic()-t0>120:
     violation='WALL_LIMIT';os.killpg(p.pid,signal.SIGKILL);break
    if rc is not None:break
    time.sleep(.05)
   p.wait(timeout=5)
  body=out.read_bytes().decode('ascii');errors=err.read_bytes()
  result.update({'exit_code':p.returncode,'stderr_bytes':len(errors),
     'elapsed_seconds':round(time.monotonic()-t0,4),
     'peak_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
     'resource_violation':violation})
  require(p.returncode==0 and not errors and violation is None,'native exit/stderr/resource failure')
  def field(key):
   data=re.findall('^'+re.escape(key)+r'=\s*([0-9]+)\s*$',body,re.M)
   require(len(data)==1,'missing GMP marker '+key)
   return int(data[0])
  assert field('V182_GMP_WIDE_RANK_PLACES')==248
  count=field('V182_GMP_WIDE_RANK_CASES');checks=field('V182_GMP_WIDE_RANK_ASSERTIONS')
  require(count==6 and checks>=28 and 'V182_GMP_WIDE_RANK_P248_CLOSED_FORM_PASS_ZERO_F' in body,
          'GMP 248-place comparison markers invalid')
  result.update({'status':'PASS_248_PLACE_GMP_RANK_ZERO_F',
                 'cases':count,'assertions':checks,'radix_places':248})
 except Exception as exc:
  result['failure']=str(exc)
  if p is not None and p.poll() is None:
   os.killpg(p.pid,signal.SIGKILL);p.wait(timeout=5)
 finally:
  for key,path in (('stdout',out),('stderr',err)):
   if path.exists():
    result[key+'_sha256']=sha(path.read_bytes());result[key+'_bytes']=path.stat().st_size
  json_once(EV/'result.json',result)
 require(result['status']=='PASS_248_PLACE_GMP_RANK_ZERO_F','v182 failed closed')
 print('V182_GMP_P248_CLOSED_FORM_SIX_STREAMS_PASS_ZERO_F')
if __name__=='__main__':
 require(len(sys.argv)==2 and sys.argv[1] in ('preflight','run-once','self-check'),'bad mode')
 if sys.argv[1]=='preflight':preflight()
 elif sys.argv[1]=='run-once':run_once()
 else:
  data,n,s=fixture()
  print(json.dumps({'bytes':len(data),'sha256':sha(data),
                    'count_bits':n.bit_length(),'cases':s},indent=2))
