#!/usr/bin/env python3
"""Independent mathematical oracle and source-locked QA Native fixture generator."""
import argparse
from pathlib import Path
M=2**127-1

def repr_bi(n):
    if n==0: return "(bi.zero)"
    sign=1 if n>0 else -1
    n=abs(n); digits=[]
    while n:
        n, r=divmod(n,10000); digits.append(str(r))
    return "(bi.make "+str(sign)+" [\n "+" ".join(digits)+"\n])"

def oracle(a,step,n,b=M):
    k=1; space=b
    while space<n:
        space*=b; k+=1
    sample=1
    for i in range(k):
        sample+=((a-1+step*i)%b)*b**i
    cutoff=(space//n)*n
    return (1 if step==1 else n) if sample>cutoff else (sample-1)%n+1

def enumerator(a,step,n,b):
    k=1; space=b
    while space<n:
        space*=b; k+=1
    sample=1; digit=a; weight=1
    for i in range(k):
        sample+=(digit-1)*weight
        weight*=b
        digit+=step
        if digit<1: digit=b
        if digit>b: digit=1
    cutoff=(space//n)*n
    for _ in range(space):
        if sample<=cutoff: return (sample-1)%n+1
        sample+=step
        if sample<1: sample=space
        if sample>space: sample=1
    raise AssertionError("No accepted rank")

def host_selftest():
    checks=0
    for b in range(2,7):
        for n in list(range(1,b**3+2))+[b**4]:
            for a in range(1,b+1):
                for step in (-1,1):
                    assert oracle(a,step,n,b)==enumerator(a,step,n,b)
                    checks+=1
    return checks

def cases(shard):
    mid=M//2+256
    if shard=="small":
        return [
         ("n1",1,1,1),("m_wrap_negative",1,-1,M),
         ("m_wrap_positive",M,1,M),("m_plus_one",1,1,M+1),
         ("m_plus_one_reverse",M,-1,M+1),("m2_reverse",1,-1,M*M),
         ("m2_forward",M,1,M*M),("m2_plus_one",1,1,M*M+1),
         ("m2_plus_one_reverse",M,-1,M*M+1),
         ("k2_reject_plus",mid,1,(M*M+1)//2),
         ("k2_reject_minus",mid,-1,(M*M+1)//2),
         ("m3_exact",M,1,M**3)]
    if shard=="deep31":
        return [
         ("k31_entry",1,-1,M**30+1),("k31_minus_one",M,1,M**31-1),
         ("k31_exact",M,-1,M**31),("k32_entry",1,1,M**31+1),
         ("k32_exact",M,-1,M**32),("k33_entry",1,-1,M**32+1),
         ("k33_exact",M,1,M**33),
         ("k33_reject",mid,1,(M**33+1)//2)]
    if shard=="deep64":
        return [
         ("k64_entry",1,-1,M**63+1),("k64_minus_one",M,1,M**64-1),
         ("k64_exact",M,-1,M**64),("k65_entry",1,1,M**64+1),
         ("k65_exact",M,-1,M**65)]
    raise ValueError(shard)

HEADER='''load "src/exact_integer.logo
load "src/stage02_context.logo
load "src/stage02_answer_at.logo
load "src/stage02_choose_short.logo
load "src/stage02_choose_wide.logo
load "src/stage02_choose_wide_general.logo
load "src/stage02_choose_rank.logo
make "Q.CASES 0
make "Q.CHECKS 0
make "Q.FAILED "false
print [DISPATCH_NATIVE_BOOT]
to q.require :ok :tag
 make "Q.CHECKS (:Q.CHECKS + 1)
 if not :ok [
  make "Q.FAILED "true
  print sentence [DISPATCH_TESTO_FALIIS] :tag
 ]
end
to q.valid :stream :n :expect :tag
 make "Q.CASES (:Q.CASES + 1)
 print sentence [DISPATCH_NATIVE_CASE_START] :tag
 localmake "got monster.stage02.choose.rank :stream :n
 q.require (monster.stage02.bi.canonical :got) (list :tag [canonical])
 q.require (equalp :got :expect) (list :tag [python_oracle])
 q.require (equalp :got (monster.stage02.choose.rank :stream :n)) (list :tag [repeatable])
end
to q.bad :stream :n :tag
 make "Q.CASES (:Q.CASES + 1)
 print sentence [DISPATCH_NATIVE_CASE_START] :tag
 q.require (equalp (monster.stage02.choose.rank :stream :n) []) :tag
end
'''

def generate(shard,path):
    selftests=host_selftest()
    vectors=cases(shard)
    one=repr_bi(1); goodn=repr_bi(M*M+1)
    bad=[]
    if shard=="small":
        bad=[
          ("stream_word",'"bad',goodn),
          ("first_zero","(list (bi.zero) 1)",goodn),
          ("first_over_m","(list "+repr_bi(M+1)+" 1)",goodn),
          ("first_bad_sign","(list (list 2 [1]) 1)",goodn),
          ("step_zero","(list "+one+" 0)",goodn),
          ("step_two","(list "+one+" 2)",goodn),
          ("step_word",'(list '+one+' "bad)',goodn),
          ("n_zero","(list "+one+" 1)","(bi.zero)"),
          ("n_word","(list "+one+' 1)','"bad'),
          ("n_bad_digits","(list "+one+" 1)","(list 1 [10000])")]
    expected={"small":(22,46),"deep31":(8,24),"deep64":(5,15)}
    total=len(vectors)+len(bad); checks=3*len(vectors)+len(bad)
    assert (total,checks)==expected[shard]
    lines=[HEADER]
    for number,(tag,a,step,n) in enumerate(vectors,1):
        rank=oracle(a,step,n)
        assert 1<=rank<=n
        lines.append("(q.valid\n (list "+repr_bi(a)+" "+str(step)+")\n "+
            repr_bi(n)+"\n "+repr_bi(rank)+"\n [v"+str(number)+"_"+tag+"]\n)\n")
    for tag,stream,n in bad:
        lines.append("(q.bad\n "+stream+"\n "+n+"\n ["+tag+"]\n)\n")
    lines.append(f'''
if :Q.FAILED [print [DISPATCH_NATIVE_FALIIS] stop]
if :Q.CASES <> {total} [print [DISPATCH_NATIVE_COUNT_FALIIS] stop]
if :Q.CHECKS <> {checks} [print [DISPATCH_NATIVE_CHECKS_FALIIS] stop]
print sentence [DISPATCH_NATIVE_CASES_PASIS] :Q.CASES
print sentence [DISPATCH_NATIVE_CHECKS_PASIS] :Q.CHECKS
print [DISPATCH_NATIVE_PASIS]
''')
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text("".join(lines),encoding="utf-8")
    print(f"HOST_ENUMERATIVE_CASES={selftests}")
    print(f"HOST_VALID={len(vectors)} HOST_INVALID={len(bad)}")
    print(f"HOST_CASES={total}")
    print(f"HOST_CHECKS={checks}")
    print("INDEPENDENT_HOST_ORACLE=PASS")
    print("NATIVE=NOT_RUN")

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--shard",required=True,choices=("small","deep31","deep64"))
    p.add_argument("--output",required=True,type=Path)
    a=p.parse_args()
    generate(a.shard,a.output)
