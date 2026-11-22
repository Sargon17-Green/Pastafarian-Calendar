#!/usr/bin/env python3
"""Independent compact (opens, closes, extras-left) DP for one exceptional month.
47-month heterogeneous synthetic GMP component QA, no Calendar_Date/F(c,t).
"""
from __future__ import annotations
from functools import lru_cache
from pathlib import Path
import hashlib, itertools, json, os, re, resource, signal, subprocess, sys, time

BASE='1160096aa847c54cbef27c232771ce1549d7ba8f'
ORIGINAL='e17ab44aa3fd1d08eb14644164735a7c5c87721d'
MAIN='56bc4173aae4975ded019ef5ab5a36249f1424df'
BRANCH='qa/issue29-ada-gmp-one-exception-dp-v183'
ACTIVATION='ci(issue29-v183): independent 47-month one-exception DP vs GMP inner Unrank; no F'
SOURCES={
 'src/canonical_full_weave_gmp_v164.adb':'845bd8905943a54e63d6aba0334404a5051fe666',
 'src/canonical_full_weave_gmp_v164.ads':'0b68edf7eddbc33869358bcfcc21e32465fc591e',
 'src/normative_oracle.adb':'0be8f8ab4ddef26d34963d5567707a511ebda50b',
}
PATHS={
 '.github/workflows/issue29-v183-gmp-one-exception-dp.yml',
 'issue29_v183_one_exception_dp.gpr',
 'tests/issue29_v183_one_exception_oracle.py',
 'tests/issue29_v183_one_exception_tests.adb',
}
SHAPES=((47,1,123),(47,24,123),(47,47,123),(47,24,7),(47,24,3))
EV=Path('evidence')
REF=EV/'v183-one-exception-reference.dat'
BIN=Path('bin_v183/issue29_v183_one_exception_tests')

def check(ok,message):
 if not ok:raise RuntimeError(message)
def sha(blob):return hashlib.sha256(blob).hexdigest()
def git_blob(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],stderr=subprocess.DEVNULL).decode().strip()
def write_once(path,data):
 with path.open('xb') as f:
  f.write(data);f.flush();os.fsync(f.fileno())
def json_once(path,value):write_once(path,(json.dumps(value,sort_keys=True,indent=2)+'\n').encode())

def independent_model(m,x,ell):
 check(2<=m<=47 and 1<=x<=m and 3<=ell<=123,'invalid oracle domain')
 extras=ell-2
 def steps(opened,closed,left):
  options=[]
  if opened<m:
   options.append((opened+1,opened+1,closed,left)) # open next
  if closed<opened and (closed+1!=x or left==0):
   options.append((closed+1,opened,closed+1,left)) # close oldest
  if closed<x<=opened and left>0:
   options.append((x,opened,closed,left-1)) # interior copy
  options.sort(key=lambda v:v[0])
  check(len({a[0] for a in options})==len(options),'duplicate transition label')
  return options
 @lru_cache(None)
 def ways(opened,closed,left):
  if opened==closed==m:return int(left==0)
  return sum(ways(no,nc,nl) for _,no,nc,nl in steps(opened,closed,left))
 total=ways(0,0,extras)
 check(total>0 and ways.cache_info().currsize<250000,'DP budget / invalid zero family')
 def unrank(rank):
  check(1<=rank<=total,'unrank domain')
  o=c=0;l=extras;out=[]
  for _ in range(2*m+extras):
   chosen=False
   for label,no,nc,nl in steps(o,c,l):
    block=ways(no,nc,nl)
    if rank>block:rank-=block
    else:
     out.append(label);o,c,l=no,nc,nl;chosen=True;break
   check(chosen,'no oracle transition')
  check(o==c==m and l==0 and rank==1,'invalid oracle end state')
  return tuple(out)
 def rank_word(seq):
  o=c=0;l=extras;rank=1
  for token in seq:
   chosen=False
   for label,no,nc,nl in steps(o,c,l):
    if label<token:rank+=ways(no,nc,nl)
    elif label==token:o,c,l=no,nc,nl;chosen=True;break
   check(chosen,'no reverse-rank transition')
  check(o==c==m and l==0 and 1<=rank<=total,'reverse-rank end state')
  return rank
 return total,unrank,rank_word,ways.cache_info().currsize

def finite_controls():
 shapes=((2,1,3),(2,2,4),(3,2,3),(3,1,4),(4,3,3))
 for m,x,ell in shapes:
  lengths=[2]*m;lengths[x-1]=ell
  n,u,r,states=independent_model(m,x,ell)
  words=set(itertools.permutations(j for j,k in enumerate(lengths,1) for _ in range(k)))
  legal=sorted(w for w in words if
   sorted(range(1,m+1),key=lambda j:w.index(j))==list(range(1,m+1)) and
   sorted(range(1,m+1),key=lambda j:len(w)-1-w[::-1].index(j))==list(range(1,m+1)))
  check(n==len(legal),'independent DP vs multiset exhaustive disagreement')
  for i,w in enumerate(legal,1):
   check(u(i)==w and r(w)==i,'independent lex rank/unrank mismatch')
 return len(shapes)

def reference():
 checks=finite_controls()
 lines=[str(len(SHAPES))];cases=[];sample_count=0;tokens=0
 for m,x,ell in SHAPES:
  n,unrank,rank_word,states=independent_model(m,x,ell)
  ranks=sorted({1,2,max(1,n//3),max(1,n//2),max(1,(2*n)//3),n-1,n})
  check(len(ranks)==7,'expect seven distinct nontrivial ranks')
  prev=None
  lines.extend((str(m),str(x),str(ell),str(n),str(len(ranks))))
  lengths=[2]*m;lengths[x-1]=ell
  for rank in ranks:
   seq=unrank(rank)
   check(rank_word(seq)==rank,'independent reverse-rank property')
   check(seq.count(x)==ell and all(seq.count(j)==2 for j in range(1,m+1) if j!=x),'multiplicities')
   check(tuple(dict.fromkeys(seq))==tuple(range(1,m+1)),'first occurrences order')
   last={}
   for i,j in enumerate(seq):last[j]=i
   check(tuple(sorted(last,key=last.get))==tuple(range(1,m+1)),'last occurrences order')
   if prev:check(prev<seq,'lex rank monotonic')
   prev=seq
   lines.append(str(rank));lines.extend(map(str,seq));tokens+=len(seq);sample_count+=1
  cases.append({'month_count':m,'exception_month':x,'exception_length':ell,'days':sum(lengths),
     'count':str(n),'count_bits':n.bit_length(),'states':states,'sample_count':len(ranks),
     'ranks':[str(r) for r in ranks]})
 check(sample_count==35 and tokens==5873,'coverage tokens/ranks')
 check(max(c['count_bits'] for c in cases)>=190,'large heterogeneous count not exercised')
 data=('\n'.join(lines)+'\n').encode('ascii')
 return data,cases,{'families':len(cases),'samples':sample_count,'tokens':tokens,
    'finite_bruteforce_controls':checks,'max_count_bits':max(c['count_bits'] for c in cases)}

def identity():
 check(os.environ.get('GITHUB_EVENT_NAME')=='push' and os.environ.get('GITHUB_RUN_ATTEMPT')=='1','first push attempt only')
 check(os.environ.get('GITHUB_REF')=='refs/heads/'+BRANCH,'unapproved QA branch')
 head=git('rev-parse','HEAD');check(head==os.environ.get('GITHUB_SHA'),'HEAD mismatch')
 event=json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_bytes())
 check(event.get('head_commit',{}).get('message')==ACTIVATION,'activation commit mismatch')
 check(subprocess.run(['git','merge-base','--is-ancestor',BASE,head],capture_output=True).returncode==0,'bad source baseline')
 changed=git('diff','--name-only',BASE+'...HEAD').splitlines()
 check(len(changed)==4 and set(changed)==PATHS,'unreviewed repo modifications')
 check(git_blob(subprocess.check_output(['git','show',MAIN+':README.md']))=='74c424b44eadd4ece3f29072ddbf873236557604','spec drift')
 pins={}
 for path,expected in SOURCES.items():
  raw=Path(path).read_bytes()
  check(git_blob(raw)==expected and git('rev-parse',ORIGINAL+':'+path)==expected,'source changed '+path)
  pins[path]={'git_blob':expected,'sha256':sha(raw)}
 lock=Path('.github/workflows/canonical-names-lock.yml').read_text()
 check(lock.count('    if: '+'$'+'{{ false }}')==42 and lock.count('  verify:\n')==1,'legacy date jobs not disabled')
 contents=Path('tests/issue29_v183_one_exception_tests.adb').read_text().lower()
 check('with canonical_full_weave_gmp_v164;' in contents and 'with normative_oracle;' not in contents,'calendar source imported')
 return {'head':head,'branch':BRANCH,'base':BASE,'attempt':1,'run_id':os.environ['GITHUB_RUN_ID']},pins

def preflight():
 ident,pins=identity()
 EV.mkdir(exist_ok=True)
 raw,cases,stats=reference();write_once(REF,raw)
 json_once(EV/'preflight.json',{'status':'REFERENCE_GENERATED_ZERO_F','identity':ident,
   'source_blobs':pins,'cases':cases,'statistics':stats,'fixture_sha256':sha(raw),
   'fixture_bytes':len(raw),'calendar_calls':0,'soak_years':0,'dispatch_halt_remains':True})
 print('V183_ONE_EXCEPTION_INDEPENDENT_DP_REFERENCE_READY_ZERO_F')
 print('V183_SAMPLES='+str(stats['samples']))

def limits():
 resource.setrlimit(resource.RLIMIT_CPU,(100,100))
 resource.setrlimit(resource.RLIMIT_AS,(768*1024*1024,768*1024*1024))
 resource.setrlimit(resource.RLIMIT_CORE,(0,0))

def run_once():
 ident,_=identity()
 pre=json.loads((EV/'preflight.json').read_bytes())
 check(pre['identity']==ident and sha(REF.read_bytes())==pre['fixture_sha256'],'reference modified')
 check(BIN.is_file(),'isolated binary missing')
 symbols=subprocess.run(['nm',str(BIN)],check=True,capture_output=True)
 check(b'normative_oracle' not in symbols.stdout.lower(),'forbidden original F linked')
 check(not (EV/'RUN_STARTED_ONCE').exists(),'native rerun prohibited')
 bsha=sha(BIN.read_bytes())
 json_once(EV/'RUN_STARTED_ONCE',{'head':ident['head'],'binary_sha256':bsha,
                              'native_invocations':1,'calendar_calls':0})
 out=EV/'native.stdout';err=EV/'native.stderr'
 result={'identity':ident,'status':'FAIL_CLOSED','binary_sha256':bsha,
         'reference_sha256':pre['fixture_sha256'],'native_invocations':1,
         'calendar_calls':0,'soak_years':0}
 started=time.monotonic();p=None
 try:
  with out.open('xb') as fo,err.open('xb') as fe:
   p=subprocess.Popen([str(BIN.resolve())],stdin=subprocess.DEVNULL,
      stdout=fo,stderr=fe,start_new_session=True,preexec_fn=limits)
   violation=None
   while True:
    code=p.poll()
    if out.stat().st_size+err.stat().st_size>131072:
     violation='OUTPUT_CAP';os.killpg(p.pid,signal.SIGKILL);break
    if time.monotonic()-started>100:
     violation='WALL_TIMEOUT';os.killpg(p.pid,signal.SIGKILL);break
    if code is not None:break
    time.sleep(.05)
   p.wait(timeout=5)
  raw=out.read_bytes().decode('ascii');errors=err.read_bytes()
  result.update({'exit_code':p.returncode,'stderr_bytes':len(errors),
     'elapsed_seconds':round(time.monotonic()-started,4),
     'peak_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
     'resource_violation':violation})
  check(p.returncode==0 and not errors and violation is None,'GMP native exit/stderr/limit')
  def field(key):
   vals=re.findall('^'+re.escape(key)+r'=\s*([0-9]+)\s*$',raw,re.M)
   check(len(vals)==1,'native marker absent '+key)
   return int(vals[0])
  cases=field('V183_FAMILIES');samples=field('V183_SAMPLES')
  tokens=field('V183_TOKENS');checks=field('V183_ASSERTIONS')
  stats=pre['statistics']
  check((cases,samples,tokens)==(stats['families'],stats['samples'],stats['tokens']) and checks>12000,'GMP sample coverage invalid')
  check('V183_ONE_EXCEPTION_DP_GMP_PASS_ZERO_F' in raw,'GMP pass marker missing')
  result.update({'status':'PASS_47_MONTH_ONE_EXCEPTION_DP_EXACT_UNRANK_ZERO_F',
                 'cases':cases,'samples':samples,'tokens':tokens,'assertions':checks})
 except Exception as exc:
  result['failure']=str(exc)
  if p is not None and p.poll() is None:
   os.killpg(p.pid,signal.SIGKILL);p.wait(timeout=5)
 finally:
  for name,path in (('stdout',out),('stderr',err)):
   if path.exists():
    result[name+'_sha256']=sha(path.read_bytes());result[name+'_bytes']=path.stat().st_size
  json_once(EV/'result.json',result)
 check(result['status']=='PASS_47_MONTH_ONE_EXCEPTION_DP_EXACT_UNRANK_ZERO_F','v183 fail closed')
 print('V183_47MONTH_HETEROGENEOUS_DP_GMP_PASS_ZERO_F')

if __name__=='__main__':
 check(len(sys.argv)==2 and sys.argv[1] in ('self-check','preflight','run-once'),'usage')
 if sys.argv[1]=='self-check':
  d,c,s=reference();print(json.dumps({'fixture_sha256':sha(d),'bytes':len(d),
    'cases':c,'statistics':s},sort_keys=True,indent=2))
 elif sys.argv[1]=='preflight':preflight()
 else:run_once()
