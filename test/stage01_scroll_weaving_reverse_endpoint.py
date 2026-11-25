#!/usr/bin/env python3
"""Independent Scroll seal-32 full lexicographic unrank; Stage1 QA only.

The distribution D_k[q] counts legal future-month words with the last
occurrence of the first future month at one-based position q. Prepending
a month of multiplicity n>=2 obeys the independent reverse recurrence

 D_new[n+t] = C(t+n-2,n-2) * sum(D_old[q] for q>=t+1).

If L already-open tokens have fixed internal order, the number of ways
to insert them before that first future month's final occurrence is

 G_k(L) = sum_q D_k[q] * C(L+q-1,L).

The remaining opened months have last occurrences in increasing ID order,
so their internal interleavings contribute a product of binomial factors.
No Fortran or pinned cross-branch Python unrank is used.
"""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
import math
import sys
import time
from pathlib import Path

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SOURCE_NAME = "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md"
SOURCE_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b"
FOUNDATION_LENGTHS = (114,117,99,66,103,83,96,65,80,122,77,101,113,103,118,63,
    109,119,120,118,104,100,103,43,95,58,82,113,100,88,122,113,73,112,
    100,122,122,117,106,100,115,118,99,108)
COUNT_DIGEST = "c6d66ea1cf3aa809393bcee7b3232a2f5ff8705897f1016f6d8532d7800d5ab3"

class ResourceLimit(RuntimeError):
    pass

class Budget:
    def __init__(self, seconds=180, entries=150000):
        if seconds <= 0 or entries <= 0:
            raise ValueError("limits must be positive")
        self.start = time.monotonic()
        self.seconds = seconds
        self.entries = entries
        self.peak = 0
        self.calls = 0
    def check(self, size):
        self.calls += 1
        self.peak = max(self.peak, size)
        if size > self.entries:
            raise ResourceLimit("entry budget exceeded")
        if self.calls % 64 == 0 and time.monotonic()-self.start > self.seconds:
            raise ResourceLimit("time budget exceeded")
    def finish(self):
        if time.monotonic()-self.start > self.seconds:
            raise ResourceLimit("time budget exceeded")

def reverse_distributions(lengths, budget):
    if not lengths or any(type(n) is not int or n < 1 for n in lengths):
        raise ValueError("positive month multiplicities required")
    d = [None] * (len(lengths)+1)
    d[-1] = []
    old = [0] * (lengths[-1]+1)
    old[-1] = 1
    d[-2] = old
    for k in range(len(lengths)-2,-1,-1):
        n = lengths[k]
        if n == 1:
            nxt = [0,sum(old)]
        else:
            nxt = [0] * (len(old)+n-1)
            tail = 0
            for p in range(len(old)-1,0,-1):
                tail += old[p]
                t = p-1
                nxt[n+t] = tail*math.comb(t+n-2,n-2)
        old = nxt
        d[k] = nxt
        budget.check(sum(len(x) for x in d if x is not None))
    return d

def future_factor(dist, L):
    if not dist:
        return 1
    if L == 0:
        return sum(dist)
    answer = 0
    binomial = 1
    for q in range(1,len(dist)):
        if dist[q]:
            answer += dist[q]*binomial
        binomial = binomial*(L+q)//q
    return answer

def active_factor(remaining, opened):
    alive = [n for n in remaining[:opened] if n]
    if not alive:
        return 1
    product = 1
    subtotal = alive[0]
    for n in alive[1:]:
        product *= math.comb(subtotal+n-1,n-1)
        subtotal += n
    return product

def exact_unrank(lengths, rank, budget):
    if type(rank) is not int or rank < 0:
        raise ValueError("rank must be zero-based nonnegative integer")
    distributions = reverse_distributions(lengths,budget)
    total = future_factor(distributions[0],0)
    if rank >= total:
        raise ValueError("rank outside legal weaving space")
    left = list(lengths)
    opened = 0
    word = []
    cache = {}
    permanent = sum(len(d) for d in distributions if d is not None)
    for offset in range(sum(lengths)):
        for i in range(min(opened+1,len(lengths))):
            if not left[i]:
                continue
            left[i] -= 1
            k = max(opened,i+1)
            if left[i] == 0 and any(left[:i]):
                left[i] += 1
                continue
            key = (k,sum(left[:k]))
            if key not in cache:
                cache[key] = future_factor(distributions[k],key[1])
            ways = active_factor(left,k)*cache[key]
            if rank < ways:
                word.append(i+1)
                opened = k
                break
            rank -= ways
            left[i] += 1
        else:
            raise AssertionError("no legal lexical branch at offset "+str(offset))
        budget.check(permanent+len(cache))
    if rank != 0 or any(left):
        raise AssertionError("nonzero final rank or remaining month")
    budget.finish()
    return total,tuple(word),len(cache)

def brute(lengths):
    remaining = list(lengths)
    word = []
    result = []
    def visit():
        if not any(remaining):
            w = tuple(word)
            first = [w.index(i) for i in range(1,len(lengths)+1)]
            last = [len(w)-1-w[::-1].index(i) for i in range(1,len(lengths)+1)]
            if first == sorted(first) and last == sorted(last):
                result.append(w)
            return
        for i,n in enumerate(remaining):
            if n:
                remaining[i] -= 1
                word.append(i+1)
                visit()
                word.pop()
                remaining[i] += 1
    visit()
    return result

def self_test():
    shapes = ranks = 0
    for colors in range(1,5):
        for lengths in itertools.product((1,2,3),repeat=colors):
            if sum(lengths) > 10:
                continue
            words = brute(lengths)
            shapes += 1
            for r,w in enumerate(words):
                n,got,_ = exact_unrank(lengths,r,Budget(seconds=30))
                assert n == len(words) and got == w,(lengths,r)
                ranks += 1
    assert (shapes,ranks) == (115,1408)
    return shapes,ranks

def word_invariants(lengths,word):
    if len(word) != sum(lengths):
        raise AssertionError("wrong weaving length")
    if [word.count(i) for i in range(1,len(lengths)+1)] != list(lengths):
        raise AssertionError("incorrect month frequencies")
    first = [word.index(i) for i in range(1,len(lengths)+1)]
    last = [len(word)-1-word[::-1].index(i) for i in range(1,len(lengths)+1)]
    if first != sorted(first) or last != sorted(last):
        raise AssertionError("first or last month ordering failed")

def sha(text):
    return hashlib.sha256(text.encode("ascii")).hexdigest()

def foundation(budget,candidate_path):
    from stage01_scroll_months_independent import foundation_months
    from stage01_scroll_gate_independent import choose_index
    from stage01_scroll_cutlets_independent import foundation_cutlets
    from stage01_scroll_month_names_independent import foundation_names
    months = foundation_months()
    lengths = tuple(months["month_lengths"])
    if lengths != FOUNDATION_LENGTHS or len(lengths)!=44 or sum(lengths)!=4399:
        raise AssertionError("locked real Foundation 44/4399 inputs changed")
    count = future_factor(reverse_distributions(lengths,budget)[0],0)
    rank = choose_index(0,months["calendar_year_first_day_offset"],4,32,count)
    total,word,cache = exact_unrank(lengths,rank,budget)
    assert count == total
    word_invariants(lengths,word)
    count_text = str(total)
    if len(count_text)!=7021 or sha(count_text)!=COUNT_DIGEST:
        raise AssertionError("7021-digit exact count digest mismatch")
    day_index = -months["calendar_year_first_day_offset"]
    cuts = foundation_cutlets()["cutlets"]
    candidates = [c for c in cuts if c["first_day_offset"]<=0<=c["last_day_offset"]]
    assert len(candidates)==1 and 0<=day_index<len(word)
    cutlet = candidates[0]
    names = foundation_names()["month_name_indices_1based"]
    month_id = word[day_index]
    fields = (5000,cutlet["name_index_1based"],1-cutlet["first_day_offset"],
        names[month_id-1],sum(x==month_id for x in word[:day_index+1]))
    report = {
        "project_id":PROJECT_ID,
        "source_snapshot":SOURCE_NAME,
        "source_sha256":SOURCE_SHA256,
        "source_bytes_verified":False,
        "scope":"INDEPENDENT_SEAL32_FULL_UNRANK_DIFFERENTIAL_NOT_FULL_STAGE1_ACCEPTANCE",
        "full_stage1_accepted":False,
        "source_commit":None,
        "months":44,"days":4399,
        "count_decimal":count_text,"count_digits":7021,"count_sha256":sha(count_text),
        "rank_zero_based":str(rank),"rank_sha256":sha(str(rank)),
        "weaving":list(word),"weaving_sha256":sha(",".join(map(str,word))),
        "independent_foundation_fields":list(fields),"cache_entries":cache,
        "candidate_available":bool(candidate_path),"candidate_dimensions_match":None,
        "month_lengths_match":None,"matched_month_ids":None,
        "matched_foundation_fields":None,"first_mismatch_1based":None,
        "comparison_pass":False,
        "peak_state_entries":budget.peak,
    }
    if candidate_path:
        candidate = json.loads(Path(candidate_path).read_text(encoding="utf-8"))
        y = candidate.get("year",{})
        m = candidate.get("months",{})
        report["candidate_dimensions_match"] = (y.get("number")==5000 and
            y.get("month_count")==44 and y.get("day_count")==4399)
        report["month_lengths_match"] = m.get("lengths")==list(lengths)
        actual = m.get("weaving")
        if isinstance(actual,list):
            report["matched_month_ids"] = sum(x==z for x,z in zip(word,actual))
            report["candidate_weaving_length"] = len(actual)
            for index in range(max(len(actual),len(word))):
                if index>=len(word) or index>=len(actual) or word[index]!=actual[index]:
                    report["first_mismatch_1based"] = index+1
                    report["mismatch_independent"] = word[index] if index<len(word) else None
                    report["mismatch_candidate"] = actual[index] if index<len(actual) else None
                    break
        candidate_fields = candidate.get("date_fields",{})
        observed = [candidate_fields.get(key) for key in
            ("year_number","cutlet_canonical_index","day_in_cutlet",
             "month_canonical_index","day_in_month")]
        report["candidate_foundation_fields"] = observed
        report["matched_foundation_fields"] = sum(x==y for x,y in zip(fields,observed))
        report["candidate_weaving_sha256"] = m.get("weaving_sha256")
        report["comparison_pass"] = (report["candidate_dimensions_match"] and
            report["month_lengths_match"] and report["matched_month_ids"]==4399 and
            len(actual or [])==4399 and report["matched_foundation_fields"]==5 and
            report["candidate_weaving_sha256"]==report["weaving_sha256"])
    report["elapsed_seconds"] = round(time.monotonic()-budget.start,3)
    return report

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--self-test",action="store_true")
    ap.add_argument("--foundation",action="store_true")
    ap.add_argument("--candidate-json")
    ap.add_argument("--output")
    ap.add_argument("--lengths")
    ap.add_argument("--rank",type=int,default=0)
    ap.add_argument("--max-seconds",type=float,default=180)
    ap.add_argument("--max-states",type=int,default=150000)
    ap.add_argument("--scroll-file",type=Path)
    args = ap.parse_args()
    if hasattr(sys,"set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)
    source_bytes_verified = False
    if args.scroll_file is not None:
        actual_source_sha = hashlib.sha256(args.scroll_file.read_bytes()).hexdigest()
        if actual_source_sha != SOURCE_SHA256:
            raise SystemExit("Hebrew Scroll source SHA-256 mismatch: " + actual_source_sha)
        source_bytes_verified = True
        print("STAGE01_SCROLL_SOURCE_BYTES_SHA256=VERIFIED")
    budget = Budget(args.max_seconds,args.max_states)
    if args.self_test:
        shapes,ranks = self_test()
        print(f"STAGE01_REVERSE_ENDPOINT_SHAPES={shapes}")
        print(f"STAGE01_REVERSE_ENDPOINT_RANKS={ranks}")
        print("STAGE01_REVERSE_ENDPOINT_BRUTE=PASS")
    if args.foundation:
        report = foundation(budget,args.candidate_json)
        report["source_bytes_verified"] = source_bytes_verified
        if args.output:
            target = Path(args.output)
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",
                encoding="utf-8")
        print(f"STAGE01_REVERSE_ENDPOINT_MONTH_IDS={report['matched_month_ids']}/4399")
        print(f"STAGE01_REVERSE_ENDPOINT_FOUNDATION_FIELDS={report['matched_foundation_fields']}/5")
        print(f"STAGE01_REVERSE_ENDPOINT_COUNT_SHA256={report['count_sha256']}")
        print(f"STAGE01_REVERSE_ENDPOINT_WEAVING_SHA256={report['weaving_sha256']}")
        print("STAGE01_REVERSE_ENDPOINT_NOT_FULL_STAGE1_ACCEPTANCE")
        if args.candidate_json and not report["comparison_pass"]:
            raise SystemExit("independent Fortran differential mismatch")
    if args.lengths:
        lengths = tuple(int(v) for v in args.lengths.split(","))
        total,word,_ = exact_unrank(lengths,args.rank,budget)
        word_invariants(lengths,word)
        print("COUNT="+str(total))
        print("WORD="+",".join(map(str,word)))
    if not(args.self_test or args.foundation or args.lengths):
        ap.error("select a diagnostic")

if __name__ == "__main__":
    try:
        main()
    except ResourceLimit as exc:
        print("STAGE01_REVERSE_ENDPOINT_RESOURCE_LIMIT_INCONCLUSIVE="+str(exc))
        raise SystemExit(2)
