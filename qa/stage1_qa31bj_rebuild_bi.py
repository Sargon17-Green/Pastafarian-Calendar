#!/usr/bin/env python3
"""Independently reconstruct pinned QA31BI window receipts from original signed traces.
This does NOT perform any native execution. Fails if final JSONL SHA differs from pinned BI.
"""
import argparse, gzip, hashlib, io, json, zipfile
from pathlib import Path

ap=argparse.ArgumentParser(description=__doc__)
for name in ('ai','bc','bg','bh','out'):
    ap.add_argument('--'+name,required=True,type=Path)
args=ap.parse_args()
AI,BC,BG,BH=args.ai,args.bc,args.bg,args.bh
MOD=(1<<127)-1
SHA={'AI':'9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49',
'BC':'2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77',
'BG':'55ffd0b31d26c14b55b26666ec6705f9db6686ca80028cac71329b70899052d7',
'BH':'5db9170c1c856fd6fe440a1a32155eceebf2db44a3812678445baac844d9a933',
'AH':'4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271',
'Y':'1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a',
'BI':'7660413b191784de8ec4f54ee51aea66c509a6726ea30f19401432a2816733d2'}
def dig(b):return hashlib.sha256(b).hexdigest()
def zip_pin(b,key):
 assert dig(b)==SHA[key],key
 z=zipfile.ZipFile(io.BytesIO(b)); assert z.testzip() is None,key
 return z
ai=zip_pin(AI.read_bytes(),'AI');bc=zip_pin(BC.read_bytes(),'BC');bg=zip_pin(BG.read_bytes(),'BG');bh=zip_pin(BH.read_bytes(),'BH')
ah=zip_pin(ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'),'AH')
y=zip_pin(ah.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'),'Y')
ci=json.loads(bh.read('summary.json'))
source=json.loads(bc.read('qa31bc_full_original_selector_routes.json'))
assert source['source_git_blob']=='560d6aa5807a7f766213a33835cce85eab0fa40c'
provenance={(r['shard'],r['trace_sha256']) for r in source['per_case']}
windows=[]; steps=0; cases=0
for shard_index in range(8):
 pin=ci['shard_ids_and_hashes'][shard_index][1]
 raw=y.read(f'QA31V_SHARD{shard_index}.zip');assert dig(raw)==pin
 with zipfile.ZipFile(io.BytesIO(raw)) as shard:
  assert shard.testzip() is None
  receipt=json.loads(shard.read('qa31v_receipt.json'))
  assert receipt['shard']==shard_index and len(receipt['cases'])==25
  for case in receipt['cases']:
   blob=shard.read(case['trace']); trace_hash=dig(blob)
   assert trace_hash==case['trace_sha256'] and (shard_index,trace_hash) in provenance
   provenance.remove((shard_index,trace_hash))
   assert case['status']=='HALT' and case['error'] is None and case['steps']<=25000
   cases+=1; steps+=case['steps']
   derivative=json.loads(bh.read(case['label']+'.json'))
   assert derivative['trace_sha256']==trace_hash
   if not derivative['windows']:continue
   rows=[json.loads(line) for line in gzip.decompress(blob).splitlines()]
   assert len(rows)==case['steps'] and rows[-1]['op']==64 and rows[-1]['next'] is None
   for win in derivative['windows']:
    t=win['second_x_t'];origin=t+1309
    assert win['first_dependent_gate']['t']==origin
    old=rows[t+882-1]['post'][-1]
    root=rows[t+901-1]['post'][-1]
    put=rows[origin-1]
    assert put['op']==112 and put['ip']==[1440,575] and put['pre'][-2:]==[61,1706]
    assert put['pre'][-3]==(old+root)%MOD
    reads=[];fetches=[];next_put=None;value=put['pre'][-3]
    for ev in rows[origin:]:
     if ev['ip']==[61,1706]:fetches.append([ev['t'],ev['ip'],ev['op']])
     if ev['string'] or ev['pre'][-2:] != [61,1706]:continue
     if ev['op']==103:
      assert ev['post']==ev['pre'][:-2]+[value]
      reads.append([ev['t'],ev['ip'],value])
     elif ev['op']==112:
      next_put=[ev['t'],ev['ip'],ev['pre'][-3]]
      break
    end=next_put[0] if next_put else rows[-1]['t']
    windows.append({'case':case['label'],'trace_sha256':trace_hash,'second_x_t':t,'old61':old,'root43':root,
    'p61_tick':origin,'p61_value':value,'hold_0':old%MOD,'hold_1':(old+1)%MOD,
    'reads':reads,'fetches':fetches,'next_put':next_put,'halt_t':rows[-1]['t'],'lifetime_steps':end-origin})
assert cases==200 and steps==3628390 and len(windows)==225 and not provenance,(cases,steps,len(windows),len(provenance))
out=b''.join(json.dumps(w,sort_keys=True,separators=(',',':')).encode()+b'\n' for w in windows)
path=args.out;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(out)
print(json.dumps({'cases':cases,'steps':steps,'windows':len(windows),'sha256':dig(out),'expected_sha256':SHA['BI'],
'file':str(path)},sort_keys=True))
assert dig(out)==SHA['BI'],'reconstructed BI does not match pinned original receipt'
