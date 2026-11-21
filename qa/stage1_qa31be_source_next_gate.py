#!/usr/bin/env python3
"""QA31BE immutable original source next-gate oracle; no Native replay."""
import hashlib,json
from pathlib import Path
SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'
PATHS={
 62: {'origin':(1145,1620),'direction':(-1,0),'code':'<g5a*9+1a*7+a*0+a*5+g04a*4+a*2+-0x','initial':[53,1704],'gate':(1112,1620),'landing':(670,1620)},
 118:{'origin':(575,670),'direction':(0,-1),'code':'^%d1a*6+a*9+a8a*5+a*5+5a*0+a*6+x','initial':[0,10],'gate':(575,639),'landing':(1430,1145)}
}
def evaluate(code,initial,memory):
 st=list(initial);reads=[]
 for ch in code[1:-1]:
  if ch in '0123456789abcdef':st.append(int(ch,16))
  elif ch in '+-*%':
   assert len(st)>=2
   b=st.pop();a=st.pop()
   st.append(a+b if ch=='+' else a-b if ch=='-' else a*b if ch=='*' else a%b if b else 0)
  elif ch=='g':
   assert len(st)>=2
   y=st.pop();x=st.pop();reads.append((x,y));st.append(memory.get((x,y),0))
  else:raise AssertionError(('UNSUPPORTED',ch))
 assert code[-1]=='x' and len(st)>=2
 return {'stack':st,'g_reads':reads,'delta':st[-2:]}
def verify():
 data=Path('src/interleaved_work_counts.b98').read_bytes()
 sha=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 assert sha==SOURCE,('WRONG_ORIGINAL_SOURCE',sha)
 lines=data.decode('utf8').split('\n')
 assert len(lines)==2016 and max(map(len,lines))==1531
 def at(x,y):return lines[y][x] if x<len(lines[y]) else ' '
 results={};mutants=0
 for sel,sp in PATHS.items():
  x,y=sp['origin'];dx,dy=sp['direction'];code=sp['code']
  actual=''.join(at(x+dx*i,y+dy*i) for i in range(len(code)))
  assert actual==code,('ORIGINAL_ROUTE_MISMATCH',sel,actual)
  assert (x+dx*(len(code)-1),y+dy*(len(code)-1))==sp['gate']
  good=evaluate(code,sp['initial'],{(53,1704):0,(59,1705):0})
  assert good['g_reads']==([(53,1704),(59,1705)] if sel==62 else [])
  assert good['stack']==([0,0,-442,0] if sel==62 else [0,13,169,10,855,506])
  assert tuple(sp['gate'][i]+good['delta'][i] for i in range(2))==sp['landing']
  rejected=0
  for i,c in enumerate(code):
   if c not in '0123456789abcdef':continue
   changed=code[:i]+('1' if c!='1' else '2')+code[i+1:]
   if evaluate(changed,sp['initial'],{(53,1704):0,(59,1705):0})!=good:rejected+=1
   if rejected==12:break
  assert rejected==12,(sel,rejected)
  mutants+=rejected
  results[str(sel)]={'original_source_corridor':True,'third_x_ip':list(sp['gate']),'third_x_landing':list(sp['landing']),'conditional_stack':good['stack'],'observed_input_not_verified_now':True}
 return {'project':'PC-BRANCH-BEFUNGE98-KYRGYZ','original_blob':sha,'routes':results,'source_nonnoop_mutants':mutants,'new_native':0,'original_signed_replayed_in_CI':False,'stage1_pass':False}
if __name__=='__main__':print(json.dumps(verify(),indent=2))
