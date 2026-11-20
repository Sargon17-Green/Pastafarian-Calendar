#!/usr/bin/env python3
"""v141 finite, pure-math, source-grounded month weaving DP port specification.

IMPORTANT: This is a calendar-engine-INDEPENDENT *combinatorial specification*
for tiny legal sequences, NOT a converted original calendar date, not an Ada
production patch and not an independent real F(c,t) algorithm. No processes,
network code execution or original source import. GitHub read-only source/CI
metadata is allowed. Full-year source/native soak dispatch remains halted.
"""
from __future__ import annotations

import argparse
from itertools import combinations
from math import comb
import json
import os
from pathlib import Path

from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_ORIGINAL_MONTH_WEAVE_DP_PORT_SPEC_V141/1"
REPORT="PASTAFARI_SOAK_ORIGINAL_MONTH_WEAVE_DP_PORT_REPORT_V141/1"
REPO="Sargon17-Green/Pastafarian-Calendar"
PY_SHA="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PY_BLOB="d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
ADA_SHA="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
ADA_BLOB="9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef"
V140_RUN=44812535351
V140_SHA="8498d3a465dcef93cc41f043a4fbba0bc1f1f96e"
V140_ART=14667641480
V140_ZIP_SHA="9ee8aef1a43c6a8ca24a319d0e1714bb6c4d7aa1dda25c6144e890c4f65051ba"
FIXTURES={
(4,4):20,(4,5):35,(4,4,4):1301,(4,5,4):3499,
(4,4,4,4):177260,(2,2,2):5}
MAX_TOTAL=30
MAX_MONTHS=6

def require(condition,message):
    if not condition:raise ValueError(message)

def check_lengths(lengths):
    require(isinstance(lengths,tuple) and 1<=len(lengths)<=MAX_MONTHS
       and all(type(n) is int and n>=1 for n in lengths)
       and sum(lengths)<=MAX_TOTAL,
       "v141 is finite toy combinatorics ONLY, not an original calendar year")

def moves(remaining,opened,closed):
    """Exact *transition order* described in pinned normative_reference.py."""
    m=len(remaining)
    if not (0<=closed<=opened<=m):
        raise ValueError("invalid open/close frontier")
    for index in range(closed,opened):
        n=remaining[index]
        if n<=0 or (n==1 and index!=closed):continue
        nxt=list(remaining);nxt[index]-=1
        yield (index+1,tuple(nxt),opened,closed+(nxt[index]==0))
    if opened<m:
        index=opened
        nxt=list(remaining);nxt[index]-=1
        new_closed=closed
        if nxt[index]==0:
            require(index==closed,"opening single-day month would close out of order")
            new_closed+=1
        yield(index+1,tuple(nxt),opened+1,new_closed)

def exhaustive(lengths):
    """Independent brute-force enumerator; intentionally tiny fixtures only."""
    check_lengths(lengths)
    require(sum(lengths)<=16,
       "brute enumeration forbidden for larger inputs")
    m=len(lengths)
    out=[]
    def walk(remaining,opened,closed,prefix):
        if len(prefix)==sum(lengths):
            require(opened==closed==m and not any(remaining),
                    "illegal terminal weaving state")
            out.append(tuple(prefix));return
        for label,nxt,no,nc in moves(remaining,opened,closed):
            walk(nxt,no,nc,prefix+[label])
    walk(lengths,0,0,[])
    require(len(out)==len(set(out)) and out==sorted(out),
            "brute fixture enumeration is not canonical lexicographic order")
    return out

class FullFamilyDP:
    """Finite math version of original source's H-table plus lexicographic unrank.

    H[m][x]=1. For n>=2 and opened index i:
      H[i][x] = Σ_{y=n-1}^{x+n-1} C(y-1,n-2) * H[i+1][y].
    For n==1:
      H[i][x] = H[i+1][0].
    State_count multiplies H[opened][sum(active_remains)] by the number
    of interleavings of active (currently opened, not yet closed) months.
    This model uses unbounded Python integers and deliberately caps days.
    """
    def __init__(self,lengths):
        check_lengths(lengths)
        self.lengths=lengths
        self.months=len(lengths)
        self.days=sum(lengths)
        prefix=[0]
        for n in lengths:prefix.append(prefix[-1]+n)
        rows=[None]*(self.months+1)
        rows[self.months]=[1]*(self.days+1)
        for i in range(self.months-1,-1,-1):
            n=lengths[i]
            x_max=prefix[i]
            if n==1:
                rows[i]=[rows[i+1][0]]*(x_max+1)
                continue
            # Incremental binomial coefficient: C(y-1,n-2).
            max_y=prefix[i+1]-1
            pref=[0]*(max_y+1)
            running=0
            choose=1
            for y in range(n-1,max_y+1):
                if y>n-1:
                    # C(y-1,n-2) / C(y-2,n-2) = (y-1)/(y-n+1).
                    choose=choose*(y-1)//(y-n+1)
                running+=choose*rows[i+1][y]
                pref[y]=running
            rows[i]=[pref[x+n-1] for x in range(x_max+1)]
        self.H=rows
    def count(self):
        return self.H[0][0]
    def state_count(self,remaining,opened,closed):
        require(0<=closed<=opened<=self.months,
                "invalid DP state frontier")
        total=0
        interleavings=1
        for i in range(closed,opened):
            n=remaining[i]
            if n<=0:return 0
            if total:
                interleavings*=comb(n+total-1,total)
            total+=n
        require(total<len(self.H[opened]),
                "DP table too short for requested state")
        return interleavings*self.H[opened][total]
    def unrank(self,one_based_rank):
        total=self.count()
        require(type(one_based_rank) is int and 1<=one_based_rank<=total,
                "global rank must be one-based and <= full legal-family count")
        rank=one_based_rank
        remaining=self.lengths
        opened=closed=0
        out=[]
        for _ in range(self.days):
            for label,nxt,no,nc in moves(remaining,opened,closed):
                ways=self.state_count(nxt,no,nc)
                if rank>ways:
                    rank-=ways
                else:
                    out.append(label)
                    remaining,opened,closed=nxt,no,nc
                    break
            else:raise ValueError("DP unranking exhausted all candidates")
        require(not any(remaining) and opened==closed==self.months
                and rank==1,"DP failed to consume unique legal sequence")
        return tuple(out)
    def rank(self,sequence):
        """Inverse one-based global rank, useful for independent port checks."""
        require(isinstance(sequence,tuple) and len(sequence)==self.days,
                "rank input must be a full month-ID tuple")
        remaining=self.lengths
        opened=closed=0
        rank=1
        for wanted in sequence:
            found=False
            for label,nxt,no,nc in moves(remaining,opened,closed):
                if label==wanted:
                    remaining,opened,closed=nxt,no,nc
                    found=True
                    break
                rank+=self.state_count(nxt,no,nc)
            require(found,"rank sequence is not in original legal family")
        require(not any(remaining) and opened==closed==self.months
                and 1<=rank<=self.count(),
                "rank did not finish in the legal terminal state")
        return rank

def fixed_two_rail_count(lengths):
    """Ada's toy family count: (Σ(n-2))! / Π(n-2)!."""
    from math import factorial
    check_lengths(lengths)
    inside=sum(n-2 for n in lengths)
    require(all(n>=2 for n in lengths),
            "Ada two-rail count requires at least two days per month")
    numerator=factorial(inside)
    for n in lengths:numerator//=factorial(n-2)
    return numerator

def manifest_check(m):
    require(type(m) is dict and m.get("schema")==SCHEMA and
      m.get("repository")==REPO and
      m.get("scope")=="PURE_FINITE_COMBINATORIAL_MONTH_WEAVE_SPEC_AND_INDEPENDENT_SMALL_ORACLE_NO_CALENDAR_ENGINE",
      "v141 schema/QA scope changed")
    require(m.get("source_ref")=={
       "commit":PY_SHA,"path":"tests/normative_reference.py",
       "git_blob_sha1":PY_BLOB,"class_name":"MonthWeavingFamily",
       "method_name":"unrank1","count_method":"count",
       "state_count_method":"_state_count","moves_method":"_moves"},
       "pinned canonical original source changed")
    require(m.get("ada_ref")=={"commit":ADA_SHA,
       "path":"src/month_weaving.adb","git_blob_sha1":ADA_BLOB},
       "pinned divergent original Ada source changed")
    require(m.get("previous_qa")=={
       "v140_ci_run_id":V140_RUN,"v140_ci_sha":V140_SHA,
       "v140_artifact_id":V140_ART,"v140_artifact_digest":V140_ZIP_SHA},
       "prior original native witness QA acceptance changed")
    rows=m.get("family_fixtures")
    require(type(rows) is list and len(rows)==len(FIXTURES),
       "finite fixture census count changed")
    seen=set()
    for row in rows:
        tup=tuple(row.get("lengths",[]))
        require(tup in FIXTURES and tup not in seen
            and row.get("count")==FIXTURES[tup],
            "original family expected count changed")
        if tup==(4,4):require(row.get("ada_two_rail_count")==6,
                         "old Ada 2-rail reference changed")
        elif "ada_two_rail_count" in row:raise ValueError("unexpected Ada fixture claim")
        seen.add(tup)
    require(seen==set(FIXTURES),"finite fixture rows incomplete")
    need=m.get("source_ordered_transitions",{})
    require(need.get("state")==["remaining_counts","opened_prefix","closed_prefix"]
      and need.get("open_condition")=="opened < month_count"
      and need.get("opened_month_day_condition")==
        "closed <= index < opened && remaining[index] > 0"
      and need.get("close_condition")==
        "remaining[index] == 1 implies index == closed"
      and need.get("move_order")==
        "currently_open_months_in_ascending_ID_then_open_next_month"
      and need.get("rank_domain")=="1..count(all legal weaves)"
      and need.get("rank_schedule")=="one global rank, not one ticket per interior position"
      and need.get("all_month_open_prefix_required") is False
      and need.get("all_month_close_suffix_required") is False,
      "canonical ordering, legal state, or global rank contract changed")
    d=m.get("dp_contract",{})
    require(d.get("H_base")=="H[m][x]=1"
        and d.get("H_recurrence")==
          "H[i][x]=sum_{y=n_i-1}^{x+n_i-1} binom(y-1,n_i-2)*H[i+1][y] for n_i>=2"
        and d.get("H_singleton")=="H[i][x]=H[i+1][0] if n_i==1"
        and d.get("active_interleavings")==
          "product of binom(remaining_j+previous_total-1,previous_total) for active months in order"
        and d.get("big_integer_arithmetic_required") is True
        and d.get("lexicographic_one_based_rank") is True
        and d.get("production_ada_implementation_not_yet_provided") is True,
        "mathematical DP or production readiness claim changed")
    require(m.get("limits")=={
       "max_total_days_synthetic":MAX_TOTAL,
       "max_months_synthetic":MAX_MONTHS,
       "do_not_invoke_original_Fct":True,"no_source_changes_to_Ada":True},
       "finite synthetic safety limit changed")
    require(m.get("scientific_status")=={
       "issue_29_open":True,"first_original_mismatch_proven":True,
       "sole_foundation_cause_proven":False,"original_full_years_certified":0,
       "independent_algorithm_lineages_certified":0,
       "STOP_NEW_NATIVE_SOAK_DISPATCH":True,"original_native_date_executions":0},
       "original scientific stop gate incorrectly promoted")

def source_check(m,gh):
    manifest_check(m)
    py,proof=checked_blob(gh,REPO,PY_SHA,"tests/normative_reference.py")
    require(proof["git_blob_sha1"]==PY_BLOB,
       "Python original normative source Git blob changed")
    ada,proof=checked_blob(gh,REPO,ADA_SHA,"src/month_weaving.adb")
    require(proof["git_blob_sha1"]==ADA_BLOB,
       "Ada original divergent source Git blob changed")
    p=py.decode("utf-8")
    a=ada.decode("utf-8")
    required=(
       "class MonthWeavingFamily:",
       "def _state_count(", "def _moves(", "def unrank1(",
       "if n == 1 and index != closed:",
       "for index in range(closed, opened):",
       "if opened < self.month_count:",
       "next_opened = opened + 1",
       "block = self._state_count(",
       "if rank1 > block:", "rank1 -= block",
       "row[x] = weighted_prefix[x + n - 1]",
       "comb(y - 1, n - 2) * self._h[opened + 1][y]",
       "base_count *= comb(n + base_length - 1, base_length)")
    require(all(token in p for token in required),
       "source-defined original DP states/transitions/global unrank changed")
    require("function From_Choices" in a
         and "Remains (J) := Lengths (J) - 2;" in a
         and "Output (Pos) := J;" in a,
       "Ada original two-rail source lock changed")
    return {"original_source_blobs_pinned":2,
       "source_global_lexicographic_rank_verified":True,
       "source_optimized_count_recurrence_verified":True,
       "old_Ada_rail_only_divergence_preserved":True}

def previous_qa_check(gh):
    r=gh.get("/repos/"+REPO+"/actions/runs/"+str(V140_RUN))
    require(r.get("id")==V140_RUN and r.get("head_sha")==V140_SHA
       and r.get("status")=="completed" and r.get("conclusion")=="success",
       "v140 source QA acceptance not completed/success at exact SHA")
    a=gh.get("/repos/"+REPO+"/actions/runs/"+str(V140_RUN)+"/artifacts?per_page=100")
    require(isinstance(a.get("total_count"),int)
       and a["total_count"]<=100 and isinstance(a.get("artifacts"),list),
       "prior QA artifact inventory incomplete")
    have=[x for x in a["artifacts"] if x.get("id")==V140_ART]
    require(len(have)==1
       and have[0].get("digest")=="sha256:"+V140_ZIP_SHA
       and have[0].get("expired") is False,
       "v140 original witness QA artifact digest/availability changed")
    issue=gh.get("/repos/"+REPO+"/issues/29")
    require(issue.get("number")==29 and issue.get("state")=="open"
       and "CONFIRMED_ORIGINAL_SOURCE_MISMATCH" in issue.get("body",""),
       "original mismatch Issue #29 no longer verifiably open")
    return {"v140_ci_verified_completed_success":True,
            "issue_29_open":True,"native_dispatch_authorized":False}

def mathematical_fixture_checks(m):
    manifest_check(m)
    results=[]
    for lengths,expected in FIXTURES.items():
        dp=FullFamilyDP(lengths)
        require(dp.count()==expected,
           "full legal family count does not match locked source fixture")
        checked=0
        if sum(lengths)<=14:
            brute=exhaustive(lengths)
            require(len(brute)==expected,"brute count differs from DP")
            for rank,seq in enumerate(brute,1):
                require(dp.unrank(rank)==seq and dp.rank(seq)==rank,
                    "lexicographic DP rank/unrank not inverse of independent brute oracle")
                checked+=1
        else:
            for rank in sorted({1,expected,max(1,expected//2),
                                min(expected,expected//2+1)}):
                seq=dp.unrank(rank)
                require(dp.rank(seq)==rank,
                    "large toy rank/unrank roundtrip mismatch")
                checked+=1
        results.append({"lengths":list(lengths),
              "full_original_legal_family":expected,
              "global_ranks_verified":checked,
              "exhaustively_verified":sum(lengths)<=14})
    return {"fixtures":results,
       "source_full_family_count_4_4":20,
       "Ada_two_rail_family_count_4_4":fixed_two_rail_count((4,4)),
       "all_expected_legal_counts_and_rank_bijections_verified":True,
       "original_Fct_covered":False,
       "original_full_years_certified":0,
       "production_Ada_implementation_complete":False}

def audit(m,gh):
    manifest_check(m)
    return {"schema":REPORT,"manifest_sha256":digest(m),
       "exact_source":source_check(m,gh),
       "prior_qa":previous_qa_check(gh),
       "finite_mathematical_evidence":mathematical_fixture_checks(m),
       "new_native_or_calendar_Fct_executions":0,
       "scientific_original_full_years_certified":0,
       "independent_original_algorithms_certified":0,
       "Ada_production_patch_made":False,
       "sole_cause_of_foundation_mismatch_proven":False,
       "STOP_NEW_NATIVE_SOAK_DISPATCH":True}

def main():
    a=argparse.ArgumentParser()
    a.add_argument("--manifest",type=Path,required=True)
    a.add_argument("--output",type=Path,required=True)
    args=a.parse_args()
    result=audit(parse_json(args.manifest.read_bytes()),
                 GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with args.output.open("xb") as f:f.write(canonical(result)+b"\n")
    print(json.dumps({"fixtures":len(result["finite_mathematical_evidence"]["fixtures"]),
      "source_blobs":result["exact_source"]["original_source_blobs_pinned"],
      "new_original_Fct_calls":0,
      "Ada_production_patch_made":False,
      "original_soak_full_years_certified":0},sort_keys=True))

if __name__=="__main__":main()
