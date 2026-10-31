#!/usr/bin/env python3
"""QA13: actual earlier Native 2D BF98 memory events, finite evidence only."""
import hashlib,json,sys
from pathlib import Path
from stage1_native_diverse_manifest_contract import (
  NATIVE_CASES,check_manifest_cases,check_saved_outputs,check_native_replay_report)
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
HASH=dict(x.split() for x in """
epoch_forward_one 8d9bec19a0ec9440da62d53488932b129b61141e0f1d24bafcb073a5619d1878
epoch_reverse_one 74ff33c78476139b7586db04e520f8e540ba3e61f8aa20afbc2b4250ed27ede0
forward_short dde1a0af66c8423898c2aa3fcaba43f5f7e5c45fb91f6fd0b96647830405d05b
foundation_cross ba6bf33cc42d99cde2583325af6eff9e0a9e0bfa77b2602ecba247d667b2e6d1
foundation_neighbor_forward 91cff350e7282b9660f2e876d7cf9edd646159dcf1c421fce7d3d30ff02465e8
foundation_neighbor_reverse 97df5f1fcce96164bc8a7136404cd9b261bce2b8e417e635e09ac3945824aefc
invalid_big_sign 5c01cadb201fbbca60292699f3f90d1c14bdbc41fed80bdf4bfb06b7adadffc6
invalid_target_zero_sign ea25f84f774fab1dc0bda95b947e0657e5286ec18b01c4229b171fbc1bddcec0
invalid_zero_sign 3d239bf7b46f71be028eb26df9f02e1e62bf8798c64867e940493c372fd805d3
large_values 05859f69da27a60fdcb130e92f5214d7e58ecafcd8396911d78c4ca5dd489675
mixed_small 84d7d69730362c2a096b5025eee26f5304bf22eaee6db6202dde27dc36ec4738
negative_positive 1897dbbe448dd586634696ff0a6b8dfd110c59039c4f260d3f09aaffb0a0ef6e
positive_negative bb763ba76ccf4062e460180e65badb0489c4511696a5e94e411f3bb7205cbef7
recent_anchor_equal 0c0ff4ab0ac6fd35c07fdaa9734b0baf235839dac4652eec8f062b10797e55cf
recent_anchor_next d88e2894ad4d709856e7328be1c037dbcc448e0dfe9e0f983c51a5f121964d63
reverse_short 28c963d4d1a7efdd35595a5d3b8edb260192bacc3369b09a4770e3b53f5a3273
zero_equal 93af18ded9d9d640f606cd5b6946f9e57cfb6a4d2d6aeddb44ea39b04532d4ca
""".strip().splitlines())
def check(ok,msg):
 if not ok:raise AssertionError(msg)
def scan(blob,name):
 last=0;step=None;pending=None;memory={};active=False
 writes=[];reads=0;exec_written=0;read_written=0;arith=[];gate_w=[];gate_x=[]
 for raw in blob.decode('ascii').splitlines():
  z=raw.split('\t');op=z[0]
  if op=='STEP':
   check(pending is None and len(z)==9,name+' incomplete STEP')
   tick,ident,x,y,dx,dy,ch,depth=map(int,z[1:])
   check(tick==last+1 and ident==1 and depth>=0,name+' nonsequential tick/IP')
   last=tick;step=(tick,(x,y),ch)
   if (x,y,dx,dy)==(5,0,1,0):active=True
   if (x,y) in memory:
    check(ch==memory[(x,y)],name+' executed stale Funge-space')
    exec_written+=1
   if (x,y)==(1500,1860):gate_x.append((tick,ch))
  elif op in ('WRITE_BEFORE','READ_BEFORE'):
   kind='WRITE' if op.startswith('WRITE') else 'READ'
   check(step is not None and pending is None,name+' phantom memory event')
   check(step[2]==ord('p' if kind=='WRITE' else 'g'),name+' p/g event without real instruction')
   tick=int(z[1]);xy=tuple(map(int,z[2:4]));old=int(z[4])
   check(tick==last,name+' memory tick mismatch')
   if xy in memory:check(memory[xy]==old,name+' stale Funge-space read/write')
   check(len(z)==(6 if kind=='WRITE' else 5),name+' malformed before')
   pending=(kind,tick,xy,old,int(z[5]) if kind=='WRITE' else None)
  elif op in ('WRITE_AFTER','READ_AFTER'):
   kind='WRITE' if op.startswith('WRITE') else 'READ'
   check(pending is not None and pending[0]==kind and len(z)==5,name+' missing before event')
   tick=int(z[1]);xy=tuple(map(int,z[2:4]));value=int(z[4])
   check((tick,xy)==pending[1:3],name+' after event at wrong tick/address')
   check(value==(pending[4] if kind=='WRITE' else pending[3]),name+' before/after value change')
   if kind=='WRITE':
    memory[xy]=value;writes.append((tick,*xy,value))
    if active:arith.append((tick,*xy,value))
    if xy==(1500,1860):gate_w.append((tick,value))
   else:
    reads+=1
    if xy in memory:read_written+=1
   pending=None
  else:raise AssertionError(name+' unknown event '+op)
 check(pending is None and active and last>1000,name+' incomplete native trace')
 check(len(gate_w)==len(gate_x)==1 and gate_w[0][0]<gate_x[0][0]
       and gate_w[0][1]==gate_x[0][1],name+' missing physical write-then-execute gate')
 check(len(writes)>=30 and reads>=40 and read_written>0 and exec_written>=2,
       name+' missing live physical write/read/execute')
 return {'name':name,'ticks':last,'put':len(writes),'get':reads,
         'executed_written':exec_written,'read_after_write':read_written,
         'gate_executed_byte':gate_x[0][1],
         'history_sha256':hashlib.sha256(repr(arith).encode()).hexdigest()}
def main(folder,source,output):
 data=Path(source).read_bytes()
 blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 check(blob==PIN,'production blob changed')
 folder=Path(folder);doc=json.loads((folder/'diverse_manifest.json').read_text())
 check(doc['schema']=='befunge-stage1-diverse-native-v1','manifest schema changed')
 items=doc['cases'];check_manifest_cases(items);check_saved_outputs(folder,items)
 check_native_replay_report(folder,items)
 check(set(HASH)=={n for n,_,_ in NATIVE_CASES},'missing SHA pins')
 records=[]
 for item in items:
  name=item['case'];raw=(folder/(name+'.tsv')).read_bytes()
  check(hashlib.sha256(raw).hexdigest()==HASH[name]==item['trace_sha256'],
        name+' Native artifact SHA drift')
  record=scan(raw,name)
  check(record['gate_executed_byte']==(118 if item['valid'] else 62),
        name+' invalid executed conditional gate')
  records.append(record)
 check(len({r['history_sha256'] for r in records})==17,'repeated write histories')
 p=sum(x['put'] for x in records);g=sum(x['get'] for x in records)
 e=sum(x['executed_written'] for x in records)
 check((p,g,e)==(2919,5585,136),'Native memory metrics drift')
 receipt={'schema':'qa13-native-2d-fungespace-ownership-v1','native_run':39108506703,
          'artifact':12129457903,'source_git_blob':PIN,'physical_put':p,
          'physical_get':g,'executed_previously_written':e,
          'input_dependent_histories':17,'valid_gate_118':14,'invalid_gate_62':3,
          'stage1_final_pass':False,'records':records}
 Path(output).write_text(json.dumps(receipt,sort_keys=True,indent=2)+'\n',encoding='utf8')
 print('QA13_NATIVE_ORIGINAL_17_TRACE_MEMORY_PASS',p,g,e)
 print('STAGE1_OPEN')
if __name__=='__main__':
 check(len(sys.argv)==4,'usage: AUDITOR TRACE_DIR SOURCE OUTPUT')
 main(*sys.argv[1:])
