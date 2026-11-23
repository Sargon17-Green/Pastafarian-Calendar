#!/usr/bin/env python3
"""QA-only independent Python witness for 47x5294 exact lexicographic prefixes.
PROJECT_ID PC-BRANCH-LUA-HAITIAN. Never invokes production Lua or date APIs.
Calculates suffix cardinalities directly for each trial candidate.
"""
import hashlib, itertools, json, math, pathlib, sys, time
from collections import Counter
if hasattr(sys, 'set_int_max_str_digits'): sys.set_int_max_str_digits(30000)
MONTHS=(123,92,119,123,121,120,116,116,95,114,120,121,115,116,104,113,121,120,119,117,123,86,123,117,115,108,81,116,120,112,120,116,115,120,123,114,123,89,122,116,115,79,117,123,92,122,82)

def table(months):
    assert 1<=len(months)<=47 and sum(months)<=6000 and all(type(v)==int and v>=2 for v in months)
    prefix=[0]
    for n in months: prefix.append(prefix[-1]+n)
    rows=[None]*(len(months)+1)
    rows[-1]=[1]*(prefix[-1]+1)
    for a in range(len(months)-1,-1,-1):
        n=months[a]
        old=rows[a+1]
        cur=[old[n-1]]
        # update binomial by recurrence independently, using Python integer division
        choose=1
        for q in range(1,prefix[a]+1):
            choose=(choose*(q+n-2))//q
            cur.append(cur[-1]+choose*old[q+n-1])
        rows[a]=cur
    return rows

def validate_step(rem,opened,exhausted,choice,months):
    if choice<0 or choice>=len(months) or rem[choice]<=0: return None
    if choice==opened:
        if opened==len(months): return None
        return opened+1,exhausted
    if choice<exhausted or choice>=opened: return None
    if rem[choice]==1 and choice!=exhausted: return None
    return opened,exhausted+(1 if choice==exhausted and rem[choice]==1 else 0)

def tail_cardinality(rem,opened,exhausted,rows):
    q=0;ways=1
    for j in range(exhausted,opened):
        count=rem[j]
        assert count>0
        q+=count
        ways*=math.comb(q-1,count-1)
    return ways*rows[opened][q]

def prefix_unrank(months,rows,rank,num=96):
    rem=list(months);opened=exhausted=0
    word=[]
    for k in range(num):
        old_total=tail_cardinality(rem,opened,exhausted,rows)
        blocks=[]
        for label in range(exhausted,min(opened+1,len(months))):
            state=validate_step(rem,opened,exhausted,label,months)
            if state is None:continue
            rem[label]-=1
            count=tail_cardinality(rem,*state,rows)
            rem[label]+=1
            blocks.append((label,count,state))
        assert sum(count for _,count,_ in blocks)==old_total,(k,opened,exhausted)
        assert 1<=rank<=old_total
        for label,size,state in blocks:
            if rank>size:
                rank-=size
            else:
                rem[label]-=1; opened,exhausted=state
                word.append(label)
                break
        else: raise AssertionError('block selection failed')
    suffix=tail_cardinality(rem,opened,exhausted,rows)
    assert 1<=rank<=suffix
    return word,rank,suffix

def tiny_bruteforce(months):
    out=[];remain=list(months);seq=[]
    def visit():
        if not any(remain):
            pos=[[i for i,x in enumerate(seq) if x==j] for j in range(len(months))]
            if all(pos[j][0]<pos[j+1][0] and pos[j][-1]<pos[j+1][-1] for j in range(len(months)-1)):
                out.append(tuple(seq))
            return
        for j,x in enumerate(remain):
            if x:
                remain[j]-=1;seq.append(j);visit();seq.pop();remain[j]+=1
    visit();return out

def selftest():
    tested=0
    for months in [(2,2),(3,2),(2,2,2),(2,3,2),(3,3),(2,2,2,2)]:
        t=table(months);expect=tiny_bruteforce(months)
        assert t[0][0]==len(expect)
        for rank in range(1,len(expect)+1):
            got,left,_=prefix_unrank(months,t,rank,num=sum(months))
            assert tuple(got)==expect[rank-1] and left==1
        tested+=1
    print('TINY_EXHAUSTIVE=',tested,flush=True)

def main():
    t0=time.perf_counter();selftest()
    rows=table(MONTHS);n=rows[0][0];s=str(n)
    assert len(MONTHS)==47 and sum(MONTHS)==5294
    assert len(s)==8654
    assert hashlib.sha256(s.encode()).hexdigest()=='e3d498d39d6b4dfc401a85b8d9135ff1089a81ace85565ac5dcb123870c09f34'
    entries=[]
    for tag,rank in [('FIRST',1),('MIDDLE',(n+1)//2),('LAST',n)]:
        prefix,left,total=prefix_unrank(MONTHS,rows,rank)
        csv=','.join(map(str,prefix))
        entries.append({'rank':tag,'prefix_len':len(prefix),'prefix_csv':csv,
                        'prefix_sha256':hashlib.sha256(csv.encode()).hexdigest(),
                        'residual_rank_digits':len(str(left)),
                        'residual_rank_sha256':hashlib.sha256(str(left).encode()).hexdigest(),
                        'residual_rank_first32':str(left)[:32],
                        'residual_rank_last32':str(left)[-32:],
                        'suffix_count_digits':len(str(total)),
                        'suffix_count_sha256':hashlib.sha256(str(total).encode()).hexdigest()})
        print(tag, 'PREFIX=',csv,'RANK_DIGITS=',len(str(left)),'RANK_SHA256=',entries[-1]['residual_rank_sha256'],flush=True)
    payload={'project_id':'PC-BRANCH-LUA-HAITIAN','source_sha':'7bac3d896c332976cde5e97f6527b84084ce95b2','source_blob_lua_count':'df7a6d31714d111a93aced5ccb74a55c09fd78b1','vector_csv_sha256':hashlib.sha256(','.join(map(str,MONTHS)).encode()).hexdigest(),'total_digits':len(s),'total_sha256':hashlib.sha256(s.encode()).hexdigest(),'oracle':'python_direct_suffix_lex_branch_cardinalities_independent_of_lua','tiny_exhaustive_pass':6,'entries':entries}
    fixture=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else 'test/fixtures/lua_haitian_real96_frozen_oracle.json')
    if '--write' in sys.argv:
        fixture.parent.mkdir(parents=True,exist_ok=True)
        fixture.write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print('FROZEN_REAL96=WRITTEN',flush=True)
    else:
        assert json.loads(fixture.read_text(encoding='utf-8'))==payload, 'FROZEN_REAL96_MISMATCH'
        print('FROZEN_REAL96=PASS 3/3',flush=True)
    print('ELAPSED_SECONDS=',round(time.perf_counter()-t0,3),flush=True)
if __name__=='__main__':main()
