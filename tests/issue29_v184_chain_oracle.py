#!/usr/bin/env python3
"""v184 legal-domain Count -> Choose_Rank -> Unrank comparison, NEVER Calendar_Date.
Independent Python finite-word and memoized prefix-state oracle, two-month binomial oracle.
"""
from __future__ import annotations
from functools import lru_cache
from pathlib import Path
import hashlib,itertools,json,math,os,re,resource,signal,subprocess,sys,time
sys.set_int_max_str_digits(20000)
BASE='1160096aa847c54cbef27c232771ce1549d7ba8f'
ORIGINAL='e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN='56bc4173aae4975ded019ef5ab5a36249f1424df'
BRANCH='qa/issue29-ada-gmp-chain-legal-lengths-v184'
ACTIVATION='ci(issue29-v184): exact GMP Count-Rank-Unrank chain on legal month lengths; no calendar F'
SOURCE_BLOBS={
 'src/canonical_full_weave_gmp_v164.adb':'845bd8905943a54e63d6aba0334404a5051fe666',
 'src/canonical_full_weave_gmp_v164.ads':'0b68edf7eddbc33869358bcfcc21e32465fc591e',
 'src/canonical_wide_rank_gmp_v164.adb':'52b8814c2ab1924cdebafe893a65d97cd3ccfa61',
 'src/canonical_wide_rank_gmp_v164.ads':'14b94e81534e98cfdb07be3824076bd7082385ea',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
PATHS={
 '.github/workflows/issue29-v184-gmp-legal-chain.yml',
 'issue29_v184_chain.gpr',
 'tests/issue29_v184_chain_tests.adb',
 'tests/issue29_v184_chain_oracle.py',
}
FAMILIES=((4,4),(4,5,4),(8,6,9,5),(4,5,4,6,5,4),
          (6,6,6,6,6,6),(123,123),(4,123),(123,4),
          (5,6,5,7,6),(30,30,30),(50,50,50),
          (18,18,18,18),(15,15,15,15,15))
MODULUS=(1<<127)-1
EV=Path('evidence')
REF=EV/'v184-exact-chain-reference.dat'
EXEC=Path('bin_v184/issue29_v184_chain_tests')
SCHEMA='ISSUE29_V184_EXACT_LEGAL_MONTH_COUNT_RANK_UNRANK_NO_F/1'
def require(ok,reason):
 if not ok:raise RuntimeError(reason)
def sha(data):return hashlib.sha256(data).hexdigest()
def blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],stderr=subprocess.DEVNULL).decode().strip()
def save(path,data):
 with path.open('xb') as f:
  f.write(data);f.flush();os.fsync(f.fileno())
def save_json(path,value):save(path,(json.dumps(value,sort_keys=True,indent=2)+'\n').encode())
def guard():
 require(os.environ.get('GITHUB_EVENT_NAME')=='push','push event only')
 require(os.environ.get('GITHUB_RUN_ATTEMPT')=='1','one-shot without retry')
 require(os.environ.get('GITHUB_REF')=='refs/heads/'+BRANCH,'incorrect branch')
 head=git('rev-parse','HEAD')
 require(os.environ.get('GITHUB_SHA')==head,'HEAD inconsistent')
 event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_bytes())
 require(event.get('head_commit',{}).get('message')==ACTIVATION,'activation message mismatch')
 require(subprocess.run(['git','merge-base','--is-ancestor',BASE,head],capture_output=True).returncode==0,'source commit mismatch')
 changed=git('diff','--name-only',BASE+'...HEAD').splitlines()
 require(len(changed)==4 and set(changed)==PATHS,'production changes or missing QA file')
 require(blob(subprocess.check_output(['git','show',MAIN+':README.md']))=='74c424b44eadd4ece3f29072ddbf873236557604','normative specification drift')
 pins={}
 for path,expected in SOURCE_BLOBS.items():
  content=Path(path).read_bytes()
  require(blob(content)==expected and git('rev-parse',ORIGINAL+':'+path)==expected,
          'production blob changed '+path)
  pins[path]={'git_blob':expected,'sha256':sha(content)}
 locks=Path('.github/workflows/canonical-names-lock.yml').read_text()
 require(locks.count('    if: '+'$'+'{{ false }}')==42 and locks.count('  verify:\n')==1,'legacy native date jobs not disabled')
 ada=Path('tests/issue29_v184_chain_tests.adb').read_text().lower()
 require('with canonical_full_weave_gmp_v164;' in ada and
         'with canonical_wide_rank_gmp_v164;' in ada and
         'with normative_oracle;' not in ada,'forbidden original calendar symbol')
 require('with "gnatcoll_gmp.gpr";' in Path('issue29_v184_chain.gpr').read_text(),'GMP GPR missing')
 return {'head':head,'base':BASE,'branch':BRANCH,'attempt':1,
         'run_id':os.environ['GITHUB_RUN_ID']},pins

def independent_model(lengths):
 m=len(lengths)
 require(2<=m<=47 and all(4<=n<=123 for n in lengths) and sum(lengths)<=5778,
         'not a legal synthetic month family')
 if m==2:
  a,b=lengths;total=math.comb(a+b-2,a-1)
  def unrank(rank):
   require(1<=rank<=total,'binomial rank bounds')
   p,q=a-1,b-1;out=[1]
   while p+q:
    ones_block=math.comb(p+q-1,p-1) if p else 0
    if rank<=ones_block:out.append(1);p-=1
    else:out.append(2);q-=1;rank-=ones_block
   out.append(2)
   require(rank==1,'binomial unrank rank consumed')
   return tuple(out)
  def rank_word(word):
   require(word[0]==1 and word[-1]==2,'binomial endpoints')
   p,q=a-1,b-1;rank=1
   for token in word[1:-1]:
    block=math.comb(p+q-1,p-1) if p else 0
    if token==2:rank+=block;q-=1
    else:require(token==1,'bad word token');p-=1
   require(p==q==0 and rank<=total,'binomial inverse state')
   return rank
  return total,unrank,rank_word,0
 @lru_cache(None)
 def ways(rem,opened,closed):
  if not any(rem):return int(opened==closed==m)
  total=0
  for j in range(closed,min(opened+1,m)):
   if rem[j] and (j==opened or rem[j]>1 or j==closed):
    nxt=list(rem);nxt[j]-=1
    total+=ways(tuple(nxt),opened+(j==opened),closed+(rem[j]==1))
  return total
 total=ways(lengths,0,0)
 require(total>0 and ways.cache_info().currsize<900000,'DP state budget exceeded')
 def transitions(rem,opened,closed):
  for j in range(closed,min(opened+1,m)):
   if rem[j] and (j==opened or rem[j]>1 or j==closed):
    nxt=list(rem);nxt[j]-=1;nxt=tuple(nxt)
    yield j+1,nxt,opened+(j==opened),closed+(rem[j]==1)
 def unrank(rank):
  require(1<=rank<=total,'prefix DP rank bounds')
  rem=lengths;opened=closed=0;out=[]
  for _ in range(sum(lengths)):
   for token,nxt,no,nc in transitions(rem,opened,closed):
    block=ways(nxt,no,nc)
    if rank>block:rank-=block
    else:out.append(token);rem=nxt;opened=no;closed=nc;break
   else:raise RuntimeError('prefix DP missing legal next token')
  require(rank==1 and opened==closed==m and not any(rem),'prefix DP terminal')
  return tuple(out)
 def rank_word(word):
  rem=lengths;opened=closed=0;rank=1
  for label in word:
   for token,nxt,no,nc in transitions(rem,opened,closed):
    if token<label:rank+=ways(nxt,no,nc)
    elif token==label:rem=nxt;opened=no;closed=nc;break
   else:raise RuntimeError('prefix DP reverse rank invalid label')
  require(opened==closed==m and not any(rem) and 1<=rank<=total,'reverse rank terminal')
  return rank
 return total,unrank,rank_word,ways.cache_info().currsize

def choose_rank(first,step,n):
 require(1<=first<=MODULUS and step in (-1,1) and n>=1,'stream domain')
 if n<=MODULUS:
  x=first
  limit=(MODULUS//n)*n
  if x>limit:x=limit if step==-1 else 1
  places=1
 else:
  space=MODULUS;places=1
  while space<n:space*=MODULUS;places+=1
  # Independent arbitrary-precision Python digit list, NOT the Ada GMP implementation.
  candidate=1+sum(((first-1+step*k)%MODULUS)*(MODULUS**k)
                  for k in range(places))
  limit=(space//n)*n
  x=candidate if candidate<=limit else (limit if step==-1 else 1)
 return (x-1)%n+1,places

def finite_controls():
 checked=0
 for lengths in ((4,4),(4,5),(4,4,4)):
  n,unrank,rank_word,_=independent_model(lengths)
  m=len(lengths)
  words=set(itertools.permutations(j for j,q in enumerate(lengths,1) for _ in range(q)))
  legal=sorted(w for w in words if
   sorted(range(1,m+1),key=lambda j:w.index(j))==list(range(1,m+1)) and
   sorted(range(1,m+1),key=lambda j:len(w)-1-w[::-1].index(j))==list(range(1,m+1)))
  require(n==len(legal),'finite family independent count disagreement')
  for i,word in enumerate(legal,1):
   require(unrank(i)==word and rank_word(word)==i,'finite family exact rank disagreement')
  checked+=len(legal)
 return checked

def validate_sequence(lengths,word):
 require(len(word)==sum(lengths),'sequence length')
 m=len(lengths)
 require(all(word.count(j)==lengths[j-1] for j in range(1,m+1)),'multiplicity')
 require(tuple(dict.fromkeys(word))==tuple(range(1,m+1)),'first occurrence order')
 last={}
 for idx,label in enumerate(word):last[label]=idx
 require(tuple(sorted(last,key=last.get))==tuple(range(1,m+1)),'last occurrence order')
def reference():
 finite=finite_controls()
 require(len(FAMILIES)==13,'legal family count')
 lines=[str(len(FAMILIES))];cases=[];streams=0;tokens=0;wide=0
 for lengths in FAMILIES:
  n,u,r,states=independent_model(lengths)
  require(n>=1,'zero family')
  wide+=int(n>MODULUS)
  lines.extend([str(len(lengths)),*(str(k) for k in lengths),str(n),'6'])
  stats=[]
  for first_code,first in ((1,1),(2,MODULUS//2),(3,MODULUS)):
   for step in (-1,1):
    rank,places=choose_rank(first,step,n)
    seq=u(rank)
    require(r(seq)==rank,'independent reverse rank mismatch')
    validate_sequence(lengths,seq)
    lines.extend([str(first_code),str(step),str(rank),*(str(x) for x in seq)])
    streams+=1;tokens+=len(seq)
    stats.append({'first_code':first_code,'step':step,'rank':str(rank),
                  'radix_places':places,'sequence_sha256':sha(bytes(seq))})
  cases.append({'lengths':list(lengths),'months':len(lengths),'days':sum(lengths),
                'count':str(n),'bits':n.bit_length(),'state_count':states,'samples':stats})
 require(streams==78 and tokens==6174 and wide>=4,'coverage insufficient')
 data=('\n'.join(lines)+'\n').encode('ascii')
 return data,cases,{'families':len(cases),'streams':streams,'tokens':tokens,
                    'wide_families':wide,'finite_exhaustive_legal_words':finite,
                    'max_count_bits':max(x['bits'] for x in cases)}

def preflight():
 identity,pins=guard()
 EV.mkdir(exist_ok=True)
 raw,cases,stats=reference()
 save(REF,raw)
 save_json(EV/'preflight.json',{'schema':SCHEMA,'status':'REFERENCE_READY_NO_F',
    'identity':identity,'source_blobs':pins,'cases':cases,'statistics':stats,
    'fixture_bytes':len(raw),'fixture_sha256':sha(raw),
    'calendar_calls':0,'soak_years':0,'dispatch_halt_remains':True})
 print('V184_INDEPENDENT_LEGAL_COUNT_RANK_UNRANK_REFERENCE_READY_ZERO_F')
 print('V184_REFERENCE_STREAMS='+str(stats['streams']))
def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(150,150))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def kill(proc):
 try:os.killpg(proc.pid,signal.SIGKILL)
 except ProcessLookupError:pass
def run_once():
 identity,_=guard()
 pre=json.loads((EV/'preflight.json').read_bytes())
 require(pre['identity']==identity and sha(REF.read_bytes())==pre['fixture_sha256'],'reference changed')
 require(EXEC.is_file(),'native GMP-only test not built')
 sym=subprocess.run(['nm',str(EXEC)],capture_output=True,check=True)
 require(b'normative_oracle' not in sym.stdout.lower(),'original calendar F linked')
 require(not (EV/'RUN_STARTED_ONCE').exists(),'second native run forbidden')
 binary_sha=sha(EXEC.read_bytes())
 save_json(EV/'RUN_STARTED_ONCE',{'head':identity['head'],'binary_sha256':binary_sha,
                                'native_invocations':1,'calendar_calls':0})
 stdout=EV/'native.stdout';stderr=EV/'native.stderr'
 result={'schema':SCHEMA,'status':'FAIL_CLOSED','identity':identity,
         'binary_sha256':binary_sha,'reference_sha256':pre['fixture_sha256'],
         'native_invocations':1,'calendar_calls':0,'soak_years':0}
 started=time.monotonic();proc=None
 try:
  with stdout.open('xb') as fo,stderr.open('xb') as fe:
   proc=subprocess.Popen([str(EXEC.resolve())],stdin=subprocess.DEVNULL,
     stdout=fo,stderr=fe,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    code=proc.poll()
    if stdout.stat().st_size+stderr.stat().st_size>131072:
     violation='OUTPUT_LIMIT';kill(proc);break
    if time.monotonic()-started>150:
     violation='WALL_LIMIT';kill(proc);break
    if code is not None:break
    time.sleep(.05)
   proc.wait(timeout=5)
  raw=stdout.read_bytes().decode('ascii');errors=stderr.read_bytes()
  result.update({'exit_code':proc.returncode,'stderr_bytes':len(errors),
    'elapsed_seconds':round(time.monotonic()-started,4),
    'peak_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
    'resource_violation':violation})
  require(proc.returncode==0 and not errors and violation is None,'native failure, stderr or limit')
  def field(k):
   data=re.findall('^'+re.escape(k)+r'=\s*([0-9]+)\s*$',raw,re.M)
   require(len(data)==1,'missing native marker '+k)
   return int(data[0])
  got={k:field('V184_'+k.upper()) for k in
       ('families','streams','tokens','wide_count_families','assertions')}
  s=pre['statistics']
  require((got['families'],got['streams'],got['tokens'],got['wide_count_families'])==
          (s['families'],s['streams'],s['tokens'],s['wide_families']),
          'native fixture coverage incomplete')
  require(got['assertions']>18000 and
          'V184_EXACT_COUNT_CHOOSE_RANK_UNRANK_LEGAL_LENGTHS_PASS_ZERO_F' in raw,
          'native assertion threshold or pass marker missing')
  result.update({'status':'PASS_LEGAL_LENGTH_GMP_CHAIN_COUNT_RANK_UNRANK_ZERO_F',
                 **got})
 except Exception as exc:
  result['failure']=str(exc)
  if proc is not None and proc.poll() is None:kill(proc);proc.wait(timeout=5)
 finally:
  for label,path in [('stdout',stdout),('stderr',stderr)]:
   if path.exists():
    result[label+'_sha256']=sha(path.read_bytes())
    result[label+'_bytes']=path.stat().st_size
  save_json(EV/'result.json',result)
 require(result['status']=='PASS_LEGAL_LENGTH_GMP_CHAIN_COUNT_RANK_UNRANK_ZERO_F',
         'v184 did not pass; no automatic rerun')
 print('V184_NATIVE_LEGAL_GMP_COUNT_RANK_UNRANK_CHAIN_PASS_ZERO_F')
if __name__=='__main__':
 require(len(sys.argv)==2 and sys.argv[1] in ('self-check','preflight','run-once'),
         'bad QA invocation')
 if sys.argv[1]=='self-check':
  data,cases,stats=reference()
  print(json.dumps({'fixture_sha256':sha(data),'fixture_bytes':len(data),
    'statistics':stats,'count_bits':[x['bits'] for x in cases]},indent=2))
 elif sys.argv[1]=='preflight':preflight()
 else:run_once()
