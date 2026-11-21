#!/usr/bin/env python3
"""QA31BK: finite, source-pinned put→get ownership audit; no Native execution.

Owner oracle A is a forward mutable-memory sweep. Oracle B independently
searches backward from every observed g to the latest preceding p.
QA31BJ's already tested pair of independent stack-ancestry projections is
reused ONLY for downstream g→sink classification, not for memory ownership.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
import copy
import gzip
import hashlib
import io
import json
from pathlib import Path
import zipfile
from stage1_qa31bj_read_fates import forward, backward

PROJECT='PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'
PINS={
 'AI':'9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49',
 'AH':'4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271',
 'Y':'1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a',
 'BI':'7660413b191784de8ec4f54ee51aea66c509a6726ea30f19401432a2816733d2',
 'BJ':'cba7da292cf8d595a5a680743ea29ca3642299bd9aecd62094fb8f42652251c3'
}
SITES={(1057,290),(195,1036),(1430,1540),(1328,860)}
ROOTS={(195,1508),(960,1620)}

def require(ok,why):
 if not ok:raise ValueError(why)
def sha(b):return hashlib.sha256(b).hexdigest()
def archive(b, expected):
 require(sha(b)==PINS[expected],expected+' checksum')
 z=zipfile.ZipFile(io.BytesIO(b))
 require(z.testzip() is None and len(z.namelist())==len(set(z.namelist())),expected+' ZIP CRC/name collision')
 return z

def coordinate(ev):
 return tuple(ev['pre'][-2:])
def physical(rows):
 require(0<len(rows)<=25000 and rows[-1]['op']==64 and rows[-1]['next'] is None,'trace bounded HALT')
 for i,e in enumerate(rows):
  require(e['t']==i+1 and isinstance(e['pre'],list) and isinstance(e['post'],list),'tick/stack shape')
  if i:
   prev=rows[i-1]
   require((prev['next'],prev['next_delta'],prev['post'])==(e['ip'],e['delta'],e['pre']),'physical STEP linkage')

def oracle_forward(rows, sites):
 """Owner map updated at each p, then queried at every matching g."""
 last={}; reads=[];fetch=[];writes=[]
 for e in rows:
  op=e['op'];tick=e['t']
  if op==112 and not e['string']:
   require(len(e['pre'])>=3,'put stack')
   coord=coordinate(e);last[coord]=(tick,e['pre'][-3]);
   if tick in sites:
    require(tuple(e['ip']) in SITES,'put location')
    writes.append((tick,coord,e['pre'][-3]))
  if op==103 and not e['string'] and len(e['pre'])>=2:
   coord=coordinate(e)
   if coord in sites.values() and coord in last:
    require(e['post'] and e['post'][-1]==last[coord][1],'physical g returns last written value')
    reads.append((tick,coord,last[coord][0],last[coord][1],tuple(e['ip'])))
  if tuple(e['ip']) in sites.values() and last.get(tuple(e['ip'])):
   fetch.append((tick,tuple(e['ip']),last[tuple(e['ip'])][0]))
 return reads,fetch,writes

def oracle_reverse(rows, reads):
 """Independent owner oracle: reversed event scan for each original read."""
 out=[]
 for tick,coord,_,value,ip in reads:
  candidates=(e for e in reversed(rows[:tick-1]) if e['op']==112 and not e['string']
              and len(e['pre'])>=3 and coordinate(e)==coord)
  owner=next(candidates,None)
  require(owner is not None,'reverse owner absent')
  require(owner['pre'][-3]==value,'reverse owner numerical mismatch')
  out.append((tick,coord,owner['t'],owner['pre'][-3],ip))
 return out

def verify(rows,witnesses):
 physical(rows)
 require(len(witnesses)==2 and len({w['read_tick'] for w in witnesses})==2,'signed two roots')
 require({tuple(w['read_ip']) for w in witnesses}==ROOTS,'signed g sites')
 require({w['trace_sha256'] for w in witnesses}.__len__()==1,'witness trace identity')
 ds={d['t']:d for w in witnesses for d in w['destinations']}
 require(len(ds)==4 and {tuple(d['ip']) for d in ds.values()}==SITES,'four signed put sites')
 require(all(d['kind']=='write_value' and d['op']=='p' for d in ds.values()),'signed value sinks')
 for t,d in ds.items():
  require(1<=t<=len(rows),'put tick bounds')
  e=rows[t-1]
  require(e['op']==112 and not e['string'] and e['ip']==d['ip'] and len(e['pre'])>=3,'put identity')
 for w in witnesses:
  t=w['read_tick'];e=rows[t-1]
  require(e['op']==103 and not e['string'] and e['ip']==w['read_ip'] and
          e['pre'][-2:]==[61,1706] and e['post'] and e['post'][-1]==w['read_value'],'BJ root g')
  require(not w['uncertain'] and w['halt_tick']==len(rows),'witness finite')
 addrs={t:coordinate(rows[t-1]) for t in ds}
 require(len(set(addrs.values()))==2,'two observed put destinations')
 a,fetch,writes=oracle_forward(rows,addrs)
 b=oracle_reverse(rows,a)
 require(a==b,'forward/backward owner divergence')
 target={t for t in ds}
 # Every signed put must remain the last writer until the next put to that cell or HALT.
 p_rows=[]
 for t,d in sorted(ds.items()):
  e=rows[t-1];addr=coordinate(e);value=e['pre'][-3]
  next_write=next((x['t'] for x in rows[t:] if x['op']==112 and not x['string'] and
                   len(x['pre'])>=3 and coordinate(x)==addr),None)
  observed=[r for r in a if r[2]==t]
  require(all(t<r[0] and (next_write is None or r[0]<next_write) and r[3]==value for r in observed),'write/read lifetime')
  p_rows.append({'tick':t,'ip':e['ip'],'address':list(addr),'value':value,
                 'next_overwrite':next_write,'g_reads':[{'tick':r[0],'ip':list(r[4]),'value':r[3]} for r in observed],
                 'instruction_fetches':[r[0] for r in fetch if r[2]==t]})
 require(len(a)==4,'two reads of each of two first puts')
 require(sum(len(p['g_reads']) for p in p_rows)==4,'four physical g owner reads')
 # Trace-only g→sink ancestry, cross-checked by two QA31BJ stack algorithms.
 read_roots={r[0] for r in a}
 suffix=rows[min(read_roots)-1:]
 f=forward(suffix,read_roots);g=backward(suffix,read_roots)
 require(f==g,'downstream two stack analyses disagree')
 uses={r[0]:{'first_use':f[0].get(r[0]),'sinks':f[1][r[0]],'uncertain':r[0] in f[2]} for r in a}
 require(not any(x['uncertain'] for x in uses.values()),'downstream uncertainty')
 return {'case':witnesses[0]['case'],'trace_sha256':witnesses[0]['trace_sha256'],
         'steps':len(rows),'puts':p_rows,'g_downstream':uses,'new_native_runs':0}

def signed_mutations(rows,ws):
 """14 non-noop edits of *real* signed physical STEP records, fail closed."""
 puts=sorted({d['t'] for w in ws for d in w['destinations']})
 reads=sorted(w['read_tick'] for w in ws)
 tests=[
  ('p0-op',puts[0],lambda e:e.update(op=103)),
  ('p1-op',puts[1],lambda e:e.update(op=103)),
  ('p2-ip',puts[2],lambda e:e['ip'].__setitem__(0,e['ip'][0]+1)),
  ('p3-ip',puts[3],lambda e:e['ip'].__setitem__(1,e['ip'][1]+1)),
  ('p0-coordinate',puts[0],lambda e:e['pre'].__setitem__(-2,e['pre'][-2]+1)),
  ('p2-coordinate',puts[2],lambda e:e['pre'].__setitem__(-1,e['pre'][-1]+1)),
  ('g0-op',reads[0],lambda e:e.update(op=112)),
  ('g1-op',reads[1],lambda e:e.update(op=112)),
  ('g0-value',reads[0],lambda e:e['post'].__setitem__(-1,e['post'][-1]+1)),
  ('g1-value',reads[1],lambda e:e['post'].__setitem__(-1,e['post'][-1]+1)),
  ('g0-coordinate',reads[0],lambda e:e['pre'].__setitem__(-2,e['pre'][-2]+1)),
  ('g1-coordinate',reads[1],lambda e:e['pre'].__setitem__(-1,e['pre'][-1]+1)),
  ('g0-tick',reads[0],lambda e:e.update(t=e['t']+1)),
  ('halt-op',len(rows),lambda e:e.update(op=32)),
 ]
 passed=[]
 for name,t,mut in tests:
  forged=rows[:];event=copy.deepcopy(rows[t-1]);mut(event)
  require(event!=rows[t-1],'empty mutation '+name);forged[t-1]=event
  try:verify(forged,ws)
  except (ValueError,IndexError) as exc:
   require(str(exc),'unexplained rejection '+name)
   passed.append(name)
  else:raise ValueError('forged real STEP accepted: '+name)
 require(len(passed)==14,'mutation count')
 return passed

def test_toy():
 """Independent owner algorithms on a tiny physical memory history."""
 def ev(t,op,pre,post,ip):return {'t':t,'op':ord(op),'pre':pre,'post':post,'ip':ip,'string':False}
 r=[ev(1,'p',[3,10,20],[],[1057,290]),ev(2,'g',[10,20],[3],[1,0]),
    ev(3,'p',[7,10,20],[],[1430,1540]),ev(4,'g',[10,20],[7],[3,0])]
 # Deliberately an isolated owner-oracle unit, not a physically continuous trace.
 a,_,_=oracle_forward(r,{1:(10,20),3:(10,20)})
 require(a==oracle_reverse(r,a) and [x[2] for x in a]==[1,3],'independent toy owners')
 bad=copy.deepcopy(r);bad[3]['post'][-1]=3
 try:oracle_forward(bad,{1:(10,20),3:(10,20)})
 except ValueError:pass
 else:raise ValueError('toy stale read undetected')
 return 2

def run(args):
 require(sha(args.bi.read_bytes())==PINS['BI'],'BI original byte SHA')
 require(sha(args.bj.read_bytes())==PINS['BJ'],'BJ original byte SHA')
 bi=[json.loads(x) for x in args.bi.read_text().splitlines()]
 bj=[json.loads(x) for x in args.bj.read_text().splitlines()]
 selected={w['trace_sha256']:w for w in bi if w['next_put'] is None}
 grouped=defaultdict(list)
 for r in bj:grouped[r['trace_sha256']].append(r)
 require(len(bi)==225 and len(selected)==135 and len(bj)==270 and set(selected)==set(grouped),'signed receipt coverage')
 ai=archive(args.ai.read_bytes(),'AI')
 ah=archive(ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'),'AH')
 y=archive(ah.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'),'Y')
 records=[];seen=set();total_cases=0;total_steps=0;checks=Counter();mutation_names=None
 for sn in range(8):
  z=zipfile.ZipFile(io.BytesIO(y.read(f'QA31V_SHARD{sn}.zip')))
  require(z.testzip() is None,'original shard CRC')
  receipt=json.loads(z.read('qa31v_receipt.json'))
  require(receipt['shard']==sn and receipt['source_blob']==SOURCE and len(receipt['cases'])==25,'Native shard provenance')
  for c in receipt['cases']:
   require(c['status']=='HALT' and c['error'] is None and c['steps']<=25000,'Native case bound')
   blob=z.read(c['trace']);digest=sha(blob)
   require(digest==c['trace_sha256'] and digest not in seen,'source trace receipt SHA/unique')
   seen.add(digest);total_cases+=1;total_steps+=c['steps']
   if digest not in selected:continue
   rows=[json.loads(line) for line in gzip.decompress(blob).splitlines()]
   require(len(rows)==c['steps'] and selected[digest]['case']==c['label'],'source case equality')
   res=verify(rows,grouped[digest]);records.append(res)
   for p in res['puts']:
    checks['p']+=1;checks['g']+=len(p['g_reads']);checks['fetch']+=len(p['instruction_fetches'])
    checks['overwrites']+=int(p['next_overwrite'] is not None)
   for u in res['g_downstream'].values():
    for sink in u['sinks']:checks['sink_'+sink['kind']]+=1
   if mutation_names is None:mutation_names=signed_mutations(rows,grouped[digest])
 require(len(records)==135 and total_cases==200 and total_steps==3628390,'original corpus count')
 require(checks['p']==540 and checks['g']==540,'original ownership count')
 require(len(mutation_names)==14,'real mutations')
 rows_out=b''.join(json.dumps(r,sort_keys=True,separators=(',',':')).encode()+b'\n' for r in records)
 args.out.mkdir(parents=True,exist_ok=True)
 (args.out/'qa31bk_witnesses.jsonl').write_bytes(rows_out)
 summary={'project_id':PROJECT,'scope':'finite signed originals; no new Native; Stage1 open',
          'original_source_blob':SOURCE,'original_corpus_cases':total_cases,'original_steps':total_steps,
          'selected_cases':len(records),'counts':dict(sorted(checks.items())),
          'independent_owner_oracles':['forward last-writer map','reverse prior-p search'],
          'downstream_projection':'QA31BJ forward stack tags vs independent inverse-slot graph',
          'negative_real_mutations':mutation_names,'toy_tests':test_toy(),
          'ai_sha256':PINS['AI'],'bi_sha256':PINS['BI'],'bj_sha256':PINS['BJ'],
          'witnesses_sha256':sha(rows_out),'new_native_runs':0,'stage1_pass':False}
 (args.out/'qa31bk_summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False,sort_keys=True)+'\n')
 print(json.dumps(summary,ensure_ascii=False,sort_keys=True))

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--self-test',action='store_true')
 for name in ('ai','bi','bj','out'):ap.add_argument('--'+name,type=Path)
 a=ap.parse_args()
 if a.self_test:print('toy tests:',test_toy());return
 require(all((getattr(a,x) is not None) for x in ('ai','bi','bj','out')),'missing required file argument')
 run(a)
if __name__=='__main__':main()
