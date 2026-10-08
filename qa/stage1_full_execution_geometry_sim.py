#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Test-only Funge-space simulator for comparing two instruction pointer traces.

This IS NOT the Pastafarian production algorithm or independent oracle.
PyFunge native tests and the independent Befunge-98 reference remain required.
"""
import hashlib

OLD = "src/interleaved_work_counts.b98"
NEW = "qa/interleaved_work_counts_lexical_candidate.b98"
BOUNDS = (1531,2016)

def run(path, source):
    with open(path,"r",encoding="ascii") as f:
        rows=f.read().split("\n")
    width=max(map(len,rows));height=len(rows)
    if (width,height)!=BOUNDS:
        raise AssertionError("source bounding rectangle differs")
    code={(x,y):ord(c) for y,line in enumerate(rows)
          for x,c in enumerate(line) if c!=" "}
    data=list(map(ord,source))
    words=source.split()
    cx=wi=0
    stack=[]
    output=[]
    x=y=0
    dx,dy=1,0
    entry=None
    heading=None
    trace=hashlib.sha256()
    after_steps=0
    after_writes=0
    def pop():
        return stack.pop() if stack else 0
    def push(n):
        stack.append(int(n))
    def mark(*values):
        trace.update(("|".join(map(str,values))+"\n").encode("ascii"))
    for step in range(350000):
        if (x,y)==(5,0) and entry is None:
            entry=tuple(stack)
            heading=(dx,dy)
        v=code.get((x,y),32)
        if not (0<=v<128):
            raise AssertionError("non-ASCII instruction %s at %s" % (v,(x,y)))
        op=chr(v)
        if entry is not None:
            mark("S",x,y,dx,dy,v)
            after_steps+=1
        if 48<=v<=57: push(v-48)
        elif 97<=v<=102: push(v-87)
        elif op=="&":
            push(int(words[wi]) if wi<len(words) else 0)
            wi+=1
        elif op=="~":
            if cx<len(data):
                push(data[cx]);cx+=1
            else: dx,dy=-dx,-dy
        elif op=="#":
            x+=dx;y+=dy
        elif op=="+":
            a=pop();bb=pop();push(bb+a)
        elif op=="-":
            a=pop();bb=pop();push(bb-a)
        elif op=="*":
            a=pop();bb=pop();push(bb*a)
        elif op=="/":
            a=pop();bb=pop()
            push(0 if not a else (abs(bb)//abs(a))*(1 if bb*a>=0 else -1))
        elif op=="%":
            a=pop();bb=pop()
            push(0 if not a else bb%a)
        elif op=="!": push(int(pop()==0))
        elif v==96:
            a=pop();bb=pop();push(int(bb>a))
        elif op=="g":
            yy=pop();xx=pop();push(code.get((xx,yy),32))
        elif op=="p":
            yy=pop();xx=pop();value=pop()
            code[(xx,yy)]=value
            if entry is not None:
                mark("P",xx,yy,value)
                after_writes+=1
        elif op=="j":
            n=pop();x+=n*dx;y+=n*dy
        elif op=="x":
            dy=pop();dx=pop()
        elif op==">":dx,dy=1,0
        elif op=="<":dx,dy=-1,0
        elif op=="^":dx,dy=0,-1
        elif op=="v":dx,dy=0,1
        elif op==":":
            a=pop();push(a);push(a)
        elif op=="\\": 
            a=pop();bb=pop();push(a);push(bb)
        elif op=="$":pop()
        elif op==".":output.append(str(pop()))
        elif op=="@":
            return {"output":output,"entry":entry,"heading":heading,
                    "trace":trace.hexdigest(),"steps":after_steps,
                    "writes":after_writes}
        elif op!=" ":raise AssertionError("unexpected opcode %r at %s" %
                                            (op,(x,y)))
        x=(x+dx)%width
        y=(y+dy)%height
    raise AssertionError("instruction timeout")

def eq(label,a,b):
    if a!=b:
        raise AssertionError("%s DIFFERENCE %r != %r" % (label,a,b))
cases=[
    "0 0 0 0\n",
    "1 15055671 1 15055671\n",
    "1 15055672 1 15055670\n",
    "0 123456789 1 987654321\n",
    "1 987654321 0 123456789\n",
    "0 1 0 2\n",
    "0 2 0 1\n",
    "1 0 0 0\n",
    "2 10 0 10\n",
    "0 170141183460469231731687303715884105727 1 1\n",
    "0 10000000000000000000000000000000000000000000 1 10000000000000000000000000000000000000000001\n",
]
for i,inp in enumerate(cases):
    first=run(OLD,inp)
    second=run(NEW,inp)
    for key in ("output","entry","heading","trace","steps","writes"):
        eq("%s:%d" % (key,i),first[key],second[key])
    eq("entry direction",(1,0),second["heading"])
    print("STAGE1_FULL_2D_TRACE_PARITY_PASS",i,"steps",first["steps"],
          "writes",first["writes"])
for malformed in ("0 -1 0 1\n","-0 1 0 1\n","0 1 -0 1",
                  "0 1 0 -1","0 1 0 1 9\n","0 1 0 x\n"):
    observed=run(NEW,malformed)
    eq("lexical-rejection",observed["output"],["-1"]*7)
    eq("invalid-not-passed-to-original-arithmetic",observed["entry"],None)
print("STAGE1_FULL_EXECUTION_SIMULATOR_PASS",len(cases),
      "full trace-equivalent examples; six lexical rejects")
print("LOCAL_SIMULATOR_ONLY; Native PyFunge still required")
