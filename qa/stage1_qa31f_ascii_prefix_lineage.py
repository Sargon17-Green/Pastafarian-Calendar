#!/usr/bin/env python3
"""QA31F finite natural-byte prefixes in the pinned original source; NOT Native."""
import hashlib, json
from pathlib import Path
SRC=Path(__file__).resolve().parents[1]/"src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def source():
 b=SRC.read_bytes()
 assert hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()==PIN
 return b.decode("ascii").splitlines()
def run(rows,data):
 x=y=0; dx=1;dy=0; stack=[];mem={};last={};got=[];read=0
 def pop(): return stack.pop() if stack else 0
 def at(a,b):
  return mem.get((a,b),ord(rows[b][a]) if 0<=b<len(rows) and 0<=a<len(rows[b]) else 32)
 for tick in range(16000):
  assert 0<=x<600 and 0<=y<50,(x,y)
  c=chr(at(x,y))
  if x==10 and y in (2,5,8,11,14,17,20,23,26):
   assert not stack,("stack at entrance",x,y,stack)
  if "0"<=c<="9":stack.append(ord(c)-48)
  elif "a"<=c<="f":stack.append(ord(c)-87)
  elif c in "+-*"+chr(96):
   b,a=pop(),pop()
   stack.append(a+b if c=="+" else a-b if c=="-" else a*b if c=="*" else int(a>b))
  elif c=="!":stack.append(int(pop()==0))
  elif c=="g":
   b,a=pop(),pop();stack.append(at(a,b))
  elif c=="p":
   b,a,v=pop(),pop(),pop()
   assert b==49,(x,y,a,b)
   mem[a,b]=v;last[a,b]=(x,y)
  elif c=="j":
   v=pop()
   if (x,y) in ((113,11),(89,20),(113,23)):
    q,m=at(1,49),at(3,49)
    got.append((y,q,m,v,last.get((1,49)),last.get((3,49))))
   x+=dx*v;y+=dy*v
  elif c=="x":dy,dx=pop(),pop()
  elif c=="#":x+=dx;y+=dy
  elif c=="~":
   if read==len(data):
    return ("input",read,at(1,49),at(3,49),got,len(stack),tick)
   stack.append(data[read]);read+=1
  elif c==">":dx,dy=1,0
  elif c=="v":dx,dy=0,1
  elif c==".":pop()
  elif c=="@":return ("halt",read,at(1,49),at(3,49),got,len(stack),tick)
  elif c!=" ":raise AssertionError(("opcode",c,x,y))
  x+=dx;y+=dy
 raise AssertionError("bound 16000")
def case(rows,digit,space,n):
 outcome=run(rows,bytes([v for _ in range(n) for v in (digit,space)]))
 status,used,q,m,gates,depth,ticks=outcome
 assert status==("input" if n<=4 else "halt"),outcome
 assert used==(2*n if n<=4 else 9),(used,n)
 assert (q,m,depth)==(min(n,4),0,0),outcome
 for y in (11,20,23):
  found=[g for g in gates if g[0]==y]
  expect=list(range(n)) if y==11 and n<=4 else list(range(5)) if y==11 else list(range(min(n,4)))
  assert [g[1] for g in found]==expect,(y,n,found)
  for _,q0,m0,j,qw,mw in found:
   assert m0==(0 if y==11 else 1)
   assert j==(61 if y==11 and q0>3 else 61 if y==20 else 0),(y,q0,j)
   if y==23:
    assert mw==(248,14) and qw==((106,2) if q0==0 else (248,26)),(mw,qw)
 return ticks
def audit(rows):
 count=0;highest=0
 for digit in (48,49,57):
  for sep in (32,9,10,13):
   for n in range(1,6):
    highest=max(highest,case(rows,digit,sep,n));count+=1
 assert count==60
 rejected=0
 for y,x in ((11,113),(14,248),(26,248)):
  assert rows[y][x] in "jp"
  modified=list(rows);modified[y]=rows[y][:x]+" "+rows[y][x+1:]
  try:case(modified,49,32,5)
  except AssertionError:rejected+=1
  else:raise AssertionError(("mutation survived",x,y))
 assert rejected==3
 return {"kind":"original_source_full_prefix_model_NOT_NATIVE","source_blob":PIN,
         "prefix_cases":count,"rejected_mutations":rejected,"max_steps":highest,
         "q_at_row11_five_pairs":[0,1,2,3,4],"q_at_row23":[0,1,2,3],
         "natural_byte_prefixes_only":True,"EOF_tested":False,
         "new_native_runs":0,"stage1_complete":False}
if __name__=="__main__":print(json.dumps(audit(source()),indent=2))
