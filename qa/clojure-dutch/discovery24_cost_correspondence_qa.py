#!/usr/bin/env python3
"""Independent finite-family counterexample to DP/production budget-operation equivalence.

TEST/QA ONLY. Uses exhaustive legal-word enumeration, not Clojure tel-rest or
DP unrank implementation. Counts raming CHARGES, not actual allocated cells.
"""
def valid_words(profile):
    n = len(profile)
    counts = list(profile)
    found = []
    def grow(word):
        if not any(counts):
            first = [word.index(i) for i in range(1, n+1)]
            last = [len(word)-1-word[::-1].index(i) for i in range(1,n+1)]
            if first == sorted(first) and last == sorted(last):
                found.append(tuple(word))
            return
        for j in range(n):
            if counts[j]:
                counts[j] -= 1
                grow(word+[j+1])
                counts[j] += 1
    grow([])
    return sorted(found)


def legal_moves(rest, opened, closed):
    for month in range(1, min(len(rest),opened+1)+1):
        available=rest[month-1]
        if available==0 or (available==1 and month!=closed+1):
            continue
        new=list(rest)
        new[month-1]-=1
        yield month,tuple(new),max(opened,month),closed+(available==1)


def cost(rest, opened):
    return 1+(len(rest)-opened+1)*(1+sum(rest))


def production_trace(profile, rank, all_words):
    # Exact lexicographic branch selection computed by exhaustive suffix counts.
    # This does NOT call/import any project source or Python DP oracle.
    rest=tuple(profile)
    opened=closed=0
    charges=[]
    prefix=()
    r=rank
    for _ in range(sum(profile)):
        for month, new, new_open, new_closed in legal_moves(rest,opened,closed):
            candidate_prefix=prefix+(month,)
            suffix_count=sum(w[:len(candidate_prefix)]==candidate_prefix for w in all_words)
            charges.append((len(candidate_prefix),month,cost(new,new_open),suffix_count))
            if r>suffix_count:
                r-=suffix_count
            else:
                rest,opened,closed = new,new_open,new_closed
                prefix=candidate_prefix
                break
        else:
            raise AssertionError((profile,rank,prefix))
    assert prefix==all_words[rank-1] and sum(rest)==0
    return charges


def abstract_dp_graph(profile):
    # Audit of the independent memo-state/transition aggregation, after fixed 1.
    root=(tuple([profile[0]-1]+list(profile[1:])),1,0)
    seen=set()
    edges=[]
    def dfs(state):
        if state in seen:
            return
        seen.add(state)
        rest,opened,closed=state
        for month,new,no,nc in legal_moves(rest,opened,closed):
            child=(new,no,nc)
            edges.append((state,month,child,cost(new,no)))
            dfs(child)
    dfs(root)
    return len(seen),len(edges),len(seen)+sum(edge[3] for edge in edges)


def main():
    profiles=((2,2),(2,3),(3,2),(2,2,2),(3,3,2),(4,4))
    rows=[]
    for p in profiles:
        words=valid_words(p)
        assert words and all(w[0]==1 for w in words)
        states,transitions,dp_cost=abstract_dp_graph(p)
        prod_costs=[sum(x[2] for x in production_trace(p,r,words)) for r in range(1,len(words)+1)]
        rows.append((p,len(words),states,transitions,dp_cost,min(prod_costs),max(prod_costs)))
        assert all(x>0 for x in prod_costs)
        assert any(dp_cost!=x for x in prod_costs), (p,dp_cost,prod_costs)
    print('PROFILE | LEGAL_WORDS | DP_STATES | DP_TRANSITIONS | DP_AGGREGATE_COST | PRODUCTION_MIN..MAX')
    for p,words,states,transitions,dp_cost,pmin,pmax in rows:
        print(f'{p} | {words} | {states} | {transitions} | {dp_cost} | {pmin}..{pmax}')
    p=(2,2); words=valid_words(p)
    print('DETAILED_PROFILE_2_2_RANK1_WORD',words[0]);print('TRACE',production_trace(p,1,words))
    print('STATIC_QA_PASS independently enumerated families=6, each family has a concrete DP-vs-rank-path charge mismatch')

if __name__=='__main__':
    main()
