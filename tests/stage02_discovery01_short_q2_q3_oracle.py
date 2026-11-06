#!/usr/bin/env python3
"""Independent q=3/q=2 short-ring boundary oracle, not Native."""
import json
M=(1<<127)-1
def math_case(m,n,first,step):
    limit=(m//n)*n
    if first<=limit: x,count=first,0
    elif step==1: x,count=1,m-first+1
    else: x,count=limit,first-limit
    return (x-1)%n+1,x,count
def loop_case(m,n,first,step,cap):
    limit=(m//n)*n
    x=first
    for count in range(cap+1):
        if x<=limit: return (x-1)%n+1,x,count
        if count==cap: break
        x=(1 if x==m else x+1) if step==1 else (m if x==1 else x-1)
    raise AssertionError("cap exceeded")
def main():
    cases=steps=moduli=0
    for m in range(7,122,6):
        moduli+=1
        for n in ((m-1)//3,(m+2)//3):
            for first in range(1,m+1):
                for step in (-1,1):
                    expected=math_case(m,n,first,step)
                    actual=loop_case(m,n,first,step,m)
                    assert expected==actual,(m,n,first,step)
                    cases+=1
                    steps+=actual[2]
    assert (moduli,cases,steps)==(20,5120,11100)
    a=(M-1)//3
    n3,n2=a,a+1
    l3,l2=3*n3,2*n2
    specs=[
        ("test_discovery01_short_q23_m_forward_q3",n3,M,1,1),
        ("test_discovery01_short_q23_m_backward_q3",n3,M,-1,n3),
        ("test_discovery01_short_q23_limit_forward_q3",n3,l3,1,n3),
        ("test_discovery01_short_q23_m_forward_q2",n2,M,1,1),
        ("test_discovery01_short_q23_limit_plus_one_backward_q2",n2,l2+1,-1,n2),
        ("test_discovery01_short_q23_limit_backward_q2",n2,l2,-1,n2)]
    assert M-l3==1 and M-l2==a-1
    prod=[]
    for name,n,first,step,rank in specs:
        q=M//n
        assert q==(3 if n==n3 else 2)
        value=math_case(M,n,first,step)
        assert value==loop_case(M,n,first,step,2)
        assert value[0]==rank and value[2]<=1
        prod.append(dict(name=name,n=str(n),q=q,first=str(first),
                         step=step,limit=str(q*n),rank=str(rank),rejections=value[2]))
    print(json.dumps(dict(project_id="PC-BRANCH-WAT-SPANISH",
         mode="independent_integer_oracle_not_native",
         moduli=moduli,exhaustive_pairs=cases,exhaustive_rejection_steps=steps,
         production_passed=6,production_cases=prod,
         excluded="q2 first=M backward requires (M-1)/3-1 rejection steps",
         failed=0,passed=True),indent=2,sort_keys=True))
if __name__=="__main__": main()
