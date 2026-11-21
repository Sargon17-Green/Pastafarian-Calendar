#!/usr/bin/env python3
"""QA31BW: bounded original-signed Befunge-98 effective-address and last-p audit.

Python 3.11+ standard library only. Does not run the interpreter, infer modified
routes, or certify Stage1. Requires five previously signed Library ZIP files.
Usage: python qa31bw_original_effective_address_audit.py --inputs DIR --output DIR
"""
from __future__ import annotations
import argparse
import bisect
import collections
import copy
import gzip
import hashlib
import io
import json
import math
try:
 import orjson as _fast_json  # optional accelerator; semantics are unchanged
except ImportError:
 _fast_json=None
from pathlib import Path
import zipfile
import time

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_GIT_BLOB_SHA1 = '560d6aa5807a7f766213a33835cce85eab0fa40c'
PINS = {
 'AI': ('QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip','9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49'),
 'BN': ('QA31BN_BEFUNGE98_KYRGYZ_SIGNED_MINUS_ONE_20261120.zip','6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79'),
 'BO': ('QA31BO_BEFUNGE98_KYRGYZ_POST_SECOND_SINK_20261120.zip','b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de'),
 'BT': ('QA31BT_BEFUNGE98_KYRGYZ_REMAINING_DOWNWARD_ORIGINAL_20261121.zip','faacb845cadc7554766ccff76d52a970aea10b775ed97ff20a306cb9c3dbabf6'),
 'BP': ('QA31BP_BEFUNGE98_KYRGYZ_ORIGINAL_EXECUTABLE_OWNER_20261120.zip','d0b7487eb3bb257fb0a89adcb3f8157c8f41caffd0c35e1f80f4a13340ddeb24'),
 'AH': (None, '4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271'),
 'Y': (None, '1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a'),
}

def check(ok, why):
 if not ok: raise AssertionError(why)

def digest(data): return hashlib.sha256(data).hexdigest()

def open_locked(data, pin):
 check(digest(data) == PINS[pin][1], pin + ': archive SHA-256 mismatch')
 z = zipfile.ZipFile(io.BytesIO(data))
 check(z.testzip() is None, pin + ': ZIP CRC failure')
 return z

def manifest(z, path):
 m=json.loads(z.read(path))
 check(m['project_id']==PROJECT, path+': project mismatch')
 for name,sha in m['files'].items():
  check(digest(z.read(name))==sha,path+': member SHA mismatch '+name)
 return m

def scalar(v): return type(v) is int
def finite_number(v): return type(v) is int or (type(v) is float and math.isfinite(v))

def validate_trace(case, packed, events):
 check(case['status']=='HALT' and case['error'] is None, 'not an original HALT receipt')
 check(case['steps']==len(events) and 0 < len(events)<=25000, 'wrong physical STEP length')
 check(digest(packed)==case['trace_sha256'], 'compressed original trace SHA drift')
 check(digest(bytes.fromhex(case['raw_hex']))==case['raw_sha256'], 'signed stdin SHA drift')
 for tick,e in enumerate(events,1):
  check(e['t']==tick, 'non-contiguous physical tick')
  check(e['string'] is False, 'unsupported string-mode trace')
  check(scalar(e['op']) and 0<=e['op']<128, 'invalid opcode scalar')
  check(isinstance(e['pre'],list) and isinstance(e['post'],list) and all(finite_number(v) for v in e['pre']+e['post']), 'invalid physical stack')
  check(isinstance(e['ip'],list) and len(e['ip'])==2 and all(scalar(v) for v in e['ip']), 'invalid physical IP')
  if tick<len(events):check(e['next']==events[tick]['ip'],'broken physical IP successor')
  else:check(e['next'] is None or (isinstance(e['next'],list) and len(e['next'])==2),'invalid terminal next IP')

# Oracle F: independent forward-address arithmetic directly on immutable stacks.
# pre is bottom-to-top. p consumes y,x,v; g consumes y,x. Empty pops are zero.
def forward_operand(e):
 s=e['pre']; k=e['op']
 x=s[-2] if len(s)>=2 else 0
 y=s[-1] if len(s)>=1 else 0
 if k==112:
  v=s[-3] if len(s)>=3 else 0
  return (x,y),v,len(s)<3
 if k==103:return (x,y),None,len(s)<2
 raise ValueError('p/g only')

# Oracle R: separately replay stack-copy pops; never use oracle F's output.
def reverse_operand(e):
 st=list(e['pre'])
 def pop(): return st.pop() if st else 0
 y=pop(); x=pop()
 if e['op']==112:
  value=pop(); return (x,y),value,len(e['pre'])<3
 if e['op']==103:return (x,y),None,len(e['pre'])<2
 raise ValueError('p/g only')

def original_sites(events):
 """Forward chronologically: snapshot last strictly earlier physically observed p."""
 last={}; out=[]; all_writes=[]; stats=collections.Counter()
 for e in events:
  opcode=e['op']; site=tuple(e['ip']); t=e['t']
  if opcode in (112,103):
   address,v,under=forward_operand(e)
   addr2,v2,under2=reverse_operand(e)
   check((address,v,under)==(addr2,v2,under2), 'independent operand oracle mismatch')
   check(scalar(address[0]) and scalar(address[1]),'non-integral effective p/g coordinates: classify separately')
   if opcode==112 and type(v) is float:stats['p_with_observed_float_value']+=1
   stats['p' if opcode==112 else 'g']+=1
   stats['operand_oracle_agreements']+=1
   if under:stats['operand_underflow']+=1
   if opcode==112:
    writer=(t,address,v,site)
    last[address]=writer; all_writes.append(writer)
   else:
    writer=last.get(address)
    observed=e['post'][-1] if e['post'] else None
    out.append((t,site,'g',address,writer,observed))
    if writer is not None:
     stats['g_with_prior_physical_p']+=1
     if observed is not None and observed!=writer[2]: stats['g_last_p_value_mismatch']+=1
    else:stats['g_without_prior_physical_p']+=1
  if site==(1500,1860) or site==(1500,1881):
   writer=last.get(site)
   out.append((t,site,'fetch',site,writer,opcode))
   stats['fetch_1860' if site[1]==1860 else 'fetch_1881']+=1
 return out,all_writes,stats

def reverse_sites(events, forward_sites):
 """Separate oracle: extract descending physical p ledger from reversed STEPs.

 The index is populated only from p events, never from the chronological
 last-writer map or a forward oracle's reconstructed addresses. Lookups choose
 the nearest *strictly earlier* p with bisect in the descending-writer ledger.
 """
 ledger=collections.defaultdict(list)
 for e in reversed(events):
  if e['op']==112:
   addr,value,_=reverse_operand(e)
   ledger[addr].append((e['t'],addr,value,tuple(e['ip'])))
 for addr,entries in ledger.items():
  entries.reverse()  # ascending tick for predecessor lookup
  check(all(entries[j][0]<entries[j+1][0] for j in range(len(entries)-1)),'non-increasing reverse-writer index')
 indexed={addr:([e[0] for e in entries],entries) for addr,entries in ledger.items()}
 agreements=0
 for t,site,kind,addr,expected,_ in forward_sites:
  if kind=='g':
   original=events[t-1]
   alt,_,_=reverse_operand(original)
   check(alt==addr,'independent original g effective-address mismatch')
  ticks,writers=indexed.get(addr,([],[]))
  ix=bisect.bisect_left(ticks,t)-1
  found=writers[ix] if ix>=0 else None
  check(expected==found,f'{kind} last-p writer mismatch at physical tick {t}')
  agreements+=1
 return agreements

def synthetic_controls():
 """Mathematical controls only; no Native execution, no signed input alteration."""
 fixtures=[
  ([],103,(0,0),None,True),
  ([17],103,(0,17),None,True),
  ([9,5],103,(9,5),None,False),
  ([],112,(0,0),0,True),
  ([37],112,(0,37),0,True),
  ([3,9],112,(3,9),0,True),
  ([7,11,13],112,(11,13),7,False),
  ([-1,-2,-3],112,(-2,-3),-1,False),
 ]
 for pre,op,addr,v,under in fixtures:
  e={'pre':pre,'op':op}
  check(forward_operand(e)==(addr,v,under),'forward synthetic address contract')
  check(reverse_operand(e)==(addr,v,under),'reverse synthetic address contract')
 return len(fixtures)

def detached_hostiles(case, packed, source):
 """Detached malicious copies, never signed originals or Native red tests."""
 baseline={'source':source,'receipt':copy.deepcopy(case),'trace':packed}
 def accept(x):
  r=x['receipt']
  check(x['source']==SOURCE_GIT_BLOB_SHA1,'source-pin corruption')
  check(r['label']==case['label'],'label corruption')
  check(r['status']=='HALT' and r['error'] is None,'status/error corruption')
  check(r['steps']==case['steps'],'step-count corruption')
  check(r['output']==case['output'],'output corruption')
  check(r['reads']==case['reads'],'read-count corruption')
  check(r['trace_sha256']==case['trace_sha256'],'trace-pin corruption')
  check(digest(x['trace'])==case['trace_sha256'],'compressed STEP corruption')
  check(r['raw_sha256']==case['raw_sha256'],'stdin-digest corruption')
  check(r['raw_hex']==case['raw_hex'],'stdin-bytes corruption')
  check(digest(bytes.fromhex(r['raw_hex']))==r['raw_sha256'],'internal stdin mismatch')
  return True
 mutations=[
  ('bad_source',lambda x:x.update(source='0'*40)),
  ('wrong_label',lambda x:x['receipt'].update(label='forged')),
  ('wrong_status',lambda x:x['receipt'].update(status='TIMEOUT')),
  ('non_null_error',lambda x:x['receipt'].update(error='fake')),
  ('wrong_steps',lambda x:x['receipt'].update(steps=-1)),
  ('wrong_output',lambda x:x['receipt'].update(output=['fake'])),
  ('wrong_reads',lambda x:x['receipt'].update(reads=-1)),
  ('wrong_trace_sha',lambda x:x['receipt'].update(trace_sha256='0'*64)),
  ('wrong_raw_sha',lambda x:x['receipt'].update(raw_sha256='0'*64)),
  ('wrong_raw_hex',lambda x:x['receipt'].update(raw_hex='00')),
  ('first_trace_byte',lambda x:x.update(trace=bytes([x['trace'][0]^1])+x['trace'][1:])),
  ('middle_trace_byte',lambda x:x.update(trace=x['trace'][:len(x['trace'])//2]+bytes([x['trace'][len(x['trace'])//2]^1])+x['trace'][len(x['trace'])//2+1:])),
  ('drop_trace_byte',lambda x:x.update(trace=x['trace'][:-1])),
  ('append_trace_byte',lambda x:x.update(trace=x['trace']+b'X')),
  ('remove_status',lambda x:x['receipt'].pop('status')),
  ('remove_sha',lambda x:x['receipt'].pop('trace_sha256')),
 ]
 check(accept(baseline),'original unchanged signed control not accepted')
 rejected=[]
 for label,mutate in mutations:
  item=copy.deepcopy(baseline);mutate(item)
  try:accept(item)
  except (AssertionError,KeyError,ValueError):rejected.append(label)
  else:raise AssertionError('detached hostile accepted: '+label)
 return rejected

def run(inp:Path,out:Path):
 out.mkdir(parents=True,exist_ok=False)
 raw={tag:(inp/PINS[tag][0]).read_bytes() for tag in ('AI','BN','BO','BT','BP')}
 for tag in raw:check(digest(raw[tag])==PINS[tag][1],tag+' SHA mismatch')
 noops=[]
 for tag in ('BN','BO','BT','BP'):
  with open_locked(raw[tag],tag) as z:
   manifest(z,'MANIFEST.json')
   if tag=='BN':
    noops=[json.loads(x) for x in z.read('evidence/qa31bn_noops.jsonl').splitlines() if x.strip()]
 check(len(noops)==24 and all(x['classification']=='NO_NUMERIC_EFFECT' and x['original_g']==x['intervention_g'] and x['forward_sinks']==x['baseline_sinks'] for x in noops),'genuine original no-effect row lock')
 with open_locked(raw['AI'],'AI') as ai:
  ah=ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip')
 with open_locked(ah,'AH') as z:
  y=z.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip')
 summary=collections.Counter();rows=[]; witnesses=[]; controls=[]; receipts={}; hostile=[]; other_mutators=collections.Counter()
 with open_locked(y,'Y') as z:
  ym=manifest(z,'QA31Y_MANIFEST.json')
  for shard in range(8):
   _start=time.monotonic()
   print('Processing original signed shard',shard,flush=True)
   name=f'QA31V_SHARD{shard}.zip';bb=z.read(name)
   check(digest(bb)==ym['files'][name],'QA31Y original shard SHA mismatch')
   with zipfile.ZipFile(io.BytesIO(bb)) as signed:
    check(signed.testzip() is None, f'QA31V shard{shard} ZIP CRC')
    receipt=json.loads(signed.read('qa31v_receipt.json'))
    check(receipt['source_blob']==SOURCE_GIT_BLOB_SHA1 and receipt['shard']==shard and len(receipt['cases'])==25,'signed native source/shard identity')
    for case in receipt['cases']:
     label=case['label'];check(label not in receipts,'duplicate signed case ID')
     packed=signed.read(case['trace']);ev=[(_fast_json.loads(line) if _fast_json is not None else json.loads(line)) for line in gzip.decompress(packed).splitlines() if line.strip()]
     validate_trace(case,packed,ev)
     for e in ev:
      if e['op'] in (ord('{'),ord('}'),ord('s'),ord('i')):other_mutators[chr(e['op'])]+=1
     sites,writes,stats=original_sites(ev)
     agree=reverse_sites(ev,sites)
     check(agree==len(sites),'independent signed predecessor index agreement')
     summary.update(stats)
     summary.update({'original_halt_receipts':1,'original_steps':len(ev),'last_p_oracle_site_agreements':agree})
     receipts[label]=case['trace_sha256']
     rows.append({'case':label,'trace_sha256':case['trace_sha256'],'physical_steps':len(ev),'p_events':stats['p'],'g_events':stats['g'],'fetch_1500_1860':stats['fetch_1860'],'effective_address_oracle_agreements':stats['operand_oracle_agreements'],'last_p_oracle_agreements':agree,'original_unseen_addresses':'UNKNOWN'})
     for t,site,kind,addr,writer,observed in sites:
      if kind=='fetch' or (kind=='g' and (addr==(1500,1860) or addr==(1500,1881) or addr==(79,1710))):
       witnesses.append({'case':label,'t':t,'kind':kind,'ip':list(site),'effective_address':list(addr),'physical_prior_p_writer':None if writer is None else {'tick':writer[0],'ip':list(writer[3]),'stored_value':writer[2]},'observed_value_or_opcode':observed, 'initial_or_non_p_origin_if_no_writer':'UNKNOWN' if writer is None else 'NOT_APPLICABLE'})
     if len(controls)<12:
      controls.append({'type':'untouched_original_signed_native','case':label,'steps':len(ev),'trace_sha256':case['trace_sha256'],'p_events':stats['p'],'g_events':stats['g']})
     if not hostile: hostile=detached_hostiles(case,packed,SOURCE_GIT_BLOB_SHA1)
    print('Finished shard',shard,'in seconds',round(time.monotonic()-_start,2),flush=True)
 check(summary['original_halt_receipts']==200 and summary['original_steps']==3628390,'signed 200 original identity drift')
 check(summary['p']==14820 and summary['g']==27395,'signed p/g count drift')
 check(summary['fetch_1860']==140 and summary['fetch_1881']==0,'observed original fetch-site drift')
 check(summary['operand_oracle_agreements']==42215,'p/g operand agreement count drift')
 check(summary['last_p_oracle_site_agreements']==27535,'last-p/reader agreement count drift')
 check(not other_mutators,'unexpected SO or alternative FungeSpace mutator on signed originals; manual semantic review required: '+str(other_mutators))
 check(len(controls)>=12 and len(hostile)>=12,'insufficient signed/hostile controls')
 noop_cases=set()
 for x in noops:
  check(receipts.get(x['case'])==x['trace_sha256'],'BN no-effect case not an original signed trace')
  noop_cases.add(x['case'])
 check(len(noop_cases)==6,'genuine no-effect case count changed')
 syn=synthetic_controls()
 result={
  'project_id':PROJECT,'qa':'QA31BW','scope':'QA_ONLY_SIGNED_ORIGINAL_PHYSICAL_TRACES',
  'source_git_blob_sha1_from_original_signed_receipts':SOURCE_GIT_BLOB_SHA1,
  'full_source_blob_rehashed_in_this_pass':False,
  'archive_sha256':{k:PINS[k][1] for k in PINS},
  'original_signed_halt_receipts':summary['original_halt_receipts'],
  'original_signed_physical_steps':summary['original_steps'],
  'p_events':summary['p'],'g_events':summary['g'],
  'original_fetch_1500_1860':summary['fetch_1860'],'original_fetch_1500_1881':summary['fetch_1881'],
  'effective_address_forward_reverse_agreements':summary['operand_oracle_agreements'],
  'last_p_writer_forward_reverse_agreements':summary['last_p_oracle_site_agreements'],
  'g_with_prior_physically_observed_p':summary['g_with_prior_physical_p'],
  'g_without_prior_physically_observed_p':summary['g_without_prior_physical_p'],
  'g_prior_p_value_vs_observed_post_stack_mismatch':summary['g_last_p_value_mismatch'],
  'operand_underflow_sites':summary['operand_underflow'],
  'p_observed_float_values_in_signed_native_pre_stack':summary['p_with_observed_float_value'],
  'other_original_fungespace_mutator_opcodes':dict(other_mutators),
  'unmodified_original_case_controls':len(controls),
  'genuine_bn_no_numeric_effect_rows':len(noops),'distinct_bn_original_cases':len(noop_cases),
  'detached_hostile_rejections':len(hostile),'synthetic_underflow_contract_controls':syn,
  'no_prior_p_owner_meaning':'INITIAL_OR_UNOBSERVED_UNKNOWN_NOT_PROOF_OF_SOURCE_BYTE',
  'unobserved_or_changed_run_route_source_offset_stack_output':'UNKNOWN',
  'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False,
 }
 def jsonout(name,thing): (out/name).write_text(json.dumps(thing,ensure_ascii=False,indent=2,sort_keys=True)+'\n',encoding='utf-8')
 def jsonlines(name,items): (out/name).write_text(''.join(json.dumps(x,ensure_ascii=False,sort_keys=True)+'\n' for x in items),encoding='utf-8')
 jsonout('qa31bw_summary.json',result)
 jsonlines('qa31bw_case_evidence.jsonl',rows)
 jsonlines('qa31bw_selected_original_sites.jsonl',witnesses)
 jsonlines('qa31bw_untouched_controls.jsonl',controls)
 jsonlines('qa31bw_detached_hostiles.jsonl',[{'test':x,'rejected':True} for x in hostile])
 print(json.dumps(result,ensure_ascii=False,indent=2))

if __name__=='__main__':
 p=argparse.ArgumentParser()
 p.add_argument('--inputs',type=Path,required=True)
 p.add_argument('--output',type=Path,required=True)
 args=p.parse_args()
 run(args.inputs,args.output)
