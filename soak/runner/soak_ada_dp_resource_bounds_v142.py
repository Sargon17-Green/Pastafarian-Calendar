#!/usr/bin/env python3
"""v142 read-only original source bounds and synthetic DP resource audit.

Does not call F(c,t), import original calendar modules, launch native processes,
compile Ada, or run a full real-domain year/DP. The full-domain numbers are
analytical *upper bounds*, NOT measured Ada memory or runtime. Only bounded
artificial month-length vectors are evaluated with pure integer combinatorics.
"""
from __future__ import annotations
import argparse
import json
from math import comb
import os
from pathlib import Path
import struct
import sys
import time
import tracemalloc

from soak_scope_coverage_v127 import canonical, digest, parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_ADA_MONTH_WEAVE_DP_RESOURCE_BOUNDS_V142/1"
REPORT="PASTAFARI_SOAK_ADA_MONTH_WEAVE_DP_RESOURCE_REPORT_V142/1"
REPO="Sargon17-Green/Pastafarian-Calendar"
PY_REF="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PY_BLOB="d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
ADA_REF="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
ADA_BLOB="923733d4f8face03586aee304640bf7540c28b4c"
V141_RUN=44815438421
V141_SHA="a121deaf3d9a5f8c43ad8e767f688176feddf3e8"
V141_ART=14667883353
V141_ART_SHA="aea406ca90324febadb4cb28d6120b6c5d533367a8e19df87192267ef25dc8d6"
LIMITS={"min_days":252,"max_days":5778,"min_months":3,
        "max_months":47,"min_month_length":4,"max_month_length":123}
FIXTURES={
 (4,)*8:(32,153,53),
 (16,)*8:(128,585,332),
 (32,)*8:(256,1161,713),
 (12,)*12:(144,949,427)
}
MAX_SYNTHETIC_DAYS=256
MAX_SYNTHETIC_MONTHS=12
MAX_SYNTHETIC_MONTH_LENGTH=32

def need(yes,why):
    if not yes:
        raise ValueError(why)

def validate(m):
    need(type(m) is dict and m.get("schema")==SCHEMA
         and m.get("scope")==
         "PURE_MATH_SYNTHETIC_RESOURCE_ANALYSIS_NOT_ORIGINAL_FCT_OR_ADA_BENCHMARK"
         and m.get("repository")==REPO,
         "v142 resource-analysis schema or scope changed")
    need(m.get("pinned_python")=={"commit":PY_REF,
         "path":"tests/normative_reference.py","blob_sha":PY_BLOB}
         and m.get("pinned_ada")=={"commit":ADA_REF,
         "path":"src/normative_oracle.adb","blob_sha":ADA_BLOB},
         "original Ada/Python source pins changed")
    need(m.get("accepted_v141")=={"run_id":V141_RUN,"head_sha":V141_SHA,
         "artifact_id":V141_ART,"artifact_digest":V141_ART_SHA,
         "completed_success":True,"synthetic_tests_passed":32,
         "golden_vectors_passed":35},
         "prior QA receipt cannot be promoted or modified")
    need(m.get("original_domain")==LIMITS,
         "original year/month bounds changed")
    need(m.get("analytical_maximum")=={
         "month_count":47,"total_days":5778,
         "month_lengths_distribution":{"123":46,"120":1},
         "total_dp_H_entries":138789,
         "integer_value_bit_upper_bound":32270,
         "biggest_unrestricted_multinomial_bit_upper_bound":31877,
         "unrank_candidate_test_upper_bound":277344,
         "active_month_scans_upper_bound":13035168},
         "analytical big integer or DP cell bounds changed")
    rows=m.get("synthetic_fixtures")
    need(type(rows) is list and len(rows)==len(FIXTURES),
         "synthetic fixture set changed")
    observed=set()
    for row in rows:
        lengths=tuple(row.get("lengths",[]))
        need(lengths in FIXTURES and lengths not in observed,
             "unknown or duplicate synthetic fixture")
        observed.add(lengths)
        days,cells,bits=FIXTURES[lengths]
        need(row=={"lengths":list(lengths),"total_days":days,
             "H_entries":cells,"full_family_count_bits":bits},
             "synthetic expected count or table entries changed")
    need(observed==set(FIXTURES),
         "one or more synthetic fixtures missing")
    need(m.get("synthetic_execution_cap")=={
         "months":MAX_SYNTHETIC_MONTHS,
         "days":MAX_SYNTHETIC_DAYS,
         "max_single_month":MAX_SYNTHETIC_MONTH_LENGTH,
         "three_rank_samples_per_fixture":True,"no_date_input":True},
         "synthetic execution budget widened")
    need(m.get("interpretation")=={
         "time_measurements_informational_only":True,
         "memory_measurements_informational_only":True,
         "CPython_runtime_not_Ada":True,
         "max_table_bytes_CPython_model_only":True,
         "full_domain_dynamic_program_not_executed":True,
         "original_Fct_not_executed":True,
         "production_Ada_implementation_not_certified":True},
         "runtime evidence mistakenly promoted to production Ada certification")
    need(m.get("scientific_state")=={
         "issue29_open":True,"first_mismatch_not_resolved":True,
         "STOP_NEW_NATIVE_SOAK_DISPATCH":True,
         "original_Fct_calls":0,
         "full_years_accepted":0,
         "independent_algorithms_certified":0},
         "original native dispatch stop or 0/10000 status violated")

def tables_entries(lengths):
    """Number of stored H[i][x] Python references, including H[m][0..T]."""
    before=0
    cells=0
    for n in lengths:
        cells+=before+1
        before+=n
    return cells+before+1

def maximum_original_table_rows():
    """Exact maximum rows under original 4..123 days, 3..47 months, T<=5778."""
    best=None
    by_months=[]
    for m in range(3,48):
        T=min(5778,123*m)
        # Feasible and maximal: fill all early months to 123, put remainder
        # in last; earliest L contributes to every later prefix row.
        lengths=(123,)*(m-1)+(T-123*(m-1),)
        need(all(4<=n<=123 for n in lengths),"bad maximal feasible vector")
        cells=tables_entries(lengths)
        rec={"month_count":m,"days":T,"cells":cells,
             "first_month_length":123,"last_month_length":lengths[-1]}
        by_months.append(rec)
        if best is None or cells>best["cells"]:
            best=rec
    return best,by_months

def theoretical_bounds():
    b,by_months=maximum_original_table_rows()
    need(b=={"month_count":47,"days":5778,"cells":138789,
            "first_month_length":123,"last_month_length":120},
         "maximum feasible original-domain H-table row count changed")
    # H_i(x) can be encoded using ≤T symbols over ≤m+1 categories
    # (future months + aggregate active-prefix symbol), so this is
    # deliberately conservative, not a measured actual H cell bit length.
    bit_upper=((48**5778).bit_length())
    need(bit_upper==32270,"conservative 48^5778 integer bit bound changed")
    # All unconstrained permutations (ignoring opening and closing order)
    # upper-bound legal complete sequences. Maximum over this T and m is
    # balanced under 47 labels: 44 lengths 123, 3 lengths 122.
    labels=(123,)*44+(122,)*3
    need(sum(labels)==5778,"balanced count denominator not feasible")
    unconstrained=1
    running=0
    for size in labels:
        unconstrained*=comb(running+size,size)
        running+=size
    need(unconstrained.bit_length()==31877,
         "upper bound for complete-family rank changed")
    # Absolute upper number of candidate transitions at each position is
    # m already-open months plus possibly one new-month opening.
    tests_bound=5778*(47+1)
    scans_bound=tests_bound*47
    need((tests_bound,scans_bound)==(277344,13035168),
         "source family worst-case lexicographic unrank state cost bound changed")
    pointer=struct.calcsize("P")
    one_big_value=(48**5778)
    # 64-bit CPython model only, NOT actual allocated H data or Ada.
    model_bytes=138789*(sys.getsizeof(one_big_value)+pointer)
    return {"domain_limits":LIMITS,
        "max_stored_H_cells":138789,
        "attaining_H_cell_shape":{"month_count":47,"days":5778,
                "lengths":{"first_46":123,"last":120}},
        "max_symbol_count_in_conservative_H_encoding":48,
        "max_H_cell_bits_in_conservative_encoding":bit_upper,
        "full_legal_family_global_rank_bits_unconstrained_upper":unconstrained.bit_length(),
        "rank_selection_possible_exceeds_original_stream_modulus_2_pow_127_minus_1":True,
        "ranked_candidate_tests_coarse_upper":tests_bound,
        "active_month_scans_coarse_upper":scans_bound,
        "H_initialization_bigint_operations_order":"O(m*T) big-integer arithmetic",
        "lexicographic_global_unrank_bigint_operations_order":"O(T*m^2) coarse upper",
        "python_storage_reference_size_bytes":pointer,
        "python_max_width_single_int_getsizeof_bytes":sys.getsizeof(one_big_value),
        "python_all_max_width_cells_plus_references_model_MiB":round(model_bytes/2**20,3),
        "python_storage_model_upper_is_not_real_allocation_or_Ada_memory":True,
        "full_domain_dp_not_evaluated":True,
        "monthly_boundary_maxima":by_months}

def source_check(m,gh):
    validate(m)
    py,proof=checked_blob(gh,REPO,PY_REF,"tests/normative_reference.py")
    need(proof["git_blob_sha1"]==PY_BLOB,
         "Python original resource/transition source Git blob mismatch")
    ada,proof=checked_blob(gh,REPO,ADA_REF,"src/normative_oracle.adb")
    need(proof["git_blob_sha1"]==ADA_BLOB,
         "Ada original resource/month-bound source Git blob mismatch")
    p=py.decode("utf-8")
    a=ada.decode("utf-8")
    need("MAX_MONTHS = 47" in p
         and "MIN_MONTH_DAYS = 4" in p and "MAX_MONTH_DAYS = 123" in p
         and "self._h[self.month_count] = [1] * (prefix[-1] + 1)" in p
         and "row[x] = weighted_prefix[x + n - 1]" in p
         and "base_count *= comb(n + base_length - 1, base_length)" in p,
         "source H-table rows/count recurrence changed")
    need("Year_Min_Days  : constant Big_Integer := B (252);" in a
         and "Year_Max_Days  : constant Big_Integer := B (5_778);" in a
         and "Low_Months : constant Natural := (Year_Length + 122) / 123;" in a
         and "High_Months : constant Natural := Natural'Min (47, Year_Length / 4);" in a
         and "for X in 4 .. 123 loop" in a
         and "Month_Weaving.From_Choices (Lengths, Tickets)" in a,
         "original Ada month/year bounds or selector call changed")
    return {"pinned_source_blobs":2,"original_year_limit_5778":True,
            "original_max_month_count_47":True,"original_month_lengths_range":[4,123],
            "original_Python_H_row_pattern_pinned":True,
            "source_technique_not_native_performance_measurement":True}

def qa_check(gh):
    r=gh.get("/repos/"+REPO+"/actions/runs/"+str(V141_RUN))
    need(r.get("id")==V141_RUN and r.get("head_sha")==V141_SHA
         and r.get("status")=="completed" and r.get("conclusion")=="success",
         "v141 source-golden CI not completed success at exact SHA")
    artifacts=gh.get("/repos/"+REPO+"/actions/runs/"+str(V141_RUN)+"/artifacts?per_page=100")
    need(isinstance(artifacts.get("total_count"),int)
         and artifacts["total_count"]<=100
         and isinstance(artifacts.get("artifacts"),list),
         "v141 artifact inventory incomplete")
    found=[x for x in artifacts["artifacts"] if x.get("id")==V141_ART]
    need(len(found)==1
         and found[0].get("digest")=="sha256:"+V141_ART_SHA
         and found[0].get("expired") is False,
         "v141 source-golden artifact digest/availability changed")
    issue=gh.get("/repos/"+REPO+"/issues/29")
    need(issue.get("number")==29 and issue.get("state")=="open"
         and "CONFIRMED_ORIGINAL_SOURCE_MISMATCH" in issue.get("body",""),
         "unresolved native mismatch Issue #29 missing/closed")
    return {"accepted_v141_run_id":V141_RUN,
        "status":"completed/success","source_golden_vectors_35_accepted":True,
        "issue29_open":True,"original_dispatch_stop":True}

def check_synthetic(lengths):
    need(type(lengths) is tuple
         and 2<=len(lengths)<=MAX_SYNTHETIC_MONTHS
         and all(type(x) is int and 2<=x<=MAX_SYNTHETIC_MONTH_LENGTH for x in lengths)
         and sum(lengths)<=MAX_SYNTHETIC_DAYS,
         "only tiny bounded pure synthetic month lengths permitted")

class SyntheticDP:
    """Independent bounded synthetic recurrence; never computes a date."""
    def __init__(self,lengths):
        check_synthetic(lengths)
        self.lengths=lengths
        self.m=len(lengths)
        self.T=sum(lengths)
        prefix=[0]
        for n in lengths:
            prefix.append(prefix[-1]+n)
        self.H=[None]*(self.m+1)
        self.H[self.m]=[1]*(self.T+1)
        self.increments=0
        for opened in range(self.m-1,-1,-1):
            n=lengths[opened]
            if n==1:
                self.H[opened]=[self.H[opened+1][0]]*(prefix[opened]+1)
                continue
            weighted=[0]*(prefix[opened+1])
            running=0
            choose=1
            for y in range(n-1,prefix[opened+1]):
                if y>n-1:
                    choose=choose*(y-1)//(y-n+1)
                running+=choose*self.H[opened+1][y]
                self.increments+=1
                weighted[y]=running
            self.H[opened]=[weighted[x+n-1]
                       for x in range(prefix[opened]+1)]
        self.candidates=0
        self.active_month_scans=0
    def count(self):
        return self.H[0][0]
    def state_count(self,remaining,opened,closed):
        running=0
        prefix_ways=1
        for index in range(closed,opened):
            self.active_month_scans+=1
            n=remaining[index]
            if n<=0:return 0
            if running:
                prefix_ways*=comb(n+running-1,running)
            running+=n
        need(running<len(self.H[opened]),
             "synthetic state exceeds precomputed H row")
        return prefix_ways*self.H[opened][running]
    def transitions(self,rem,opened,closed):
        for index in range(closed,opened):
            n=rem[index]
            if n<=0 or (n==1 and index!=closed):continue
            nxt=list(rem);nxt[index]-=1
            yield index+1,tuple(nxt),opened,closed+(nxt[index]==0)
        if opened<self.m:
            index=opened;nxt=list(rem);nxt[index]-=1
            next_closed=closed
            if nxt[index]==0:
                need(index==closed,"synthetic opening closed out of order")
                next_closed+=1
            yield index+1,tuple(nxt),opened+1,next_closed
    def unrank(self,rank):
        need(type(rank) is int and 1<=rank<=self.count(),
             "synthetic lexicographic rank out of family")
        rem=self.lengths
        opened=closed=0
        result=[]
        for _ in range(self.T):
            for label,nxt,no,nc in self.transitions(rem,opened,closed):
                self.candidates+=1
                block=self.state_count(nxt,no,nc)
                if rank>block:
                    rank-=block
                else:
                    result.append(label)
                    rem,opened,closed=nxt,no,nc
                    break
            else:raise ValueError("synthetic global unrank exhausted choices")
        need(opened==closed==self.m and not any(rem) and rank==1,
             "synthetic legal unrank terminal invariant failed")
        return tuple(result)

def synthetic_profiles(m):
    validate(m)
    report=[]
    for lengths,(days,cells,bits) in FIXTURES.items():
        t0=time.perf_counter_ns()
        tracemalloc.start()
        try:
            dp=SyntheticDP(lengths)
            built_ns=time.perf_counter_ns()-t0
            count=dp.count()
            need(dp.T==days
                 and sum(map(len,dp.H))==cells
                 and count.bit_length()==bits,
                 "synthetic H table shape or original count bit width changed")
            last=count
            selected=sorted({1,(count+1)//2,last})
            samples=[]
            for rank in selected:
                before=dp.candidates
                scans=dp.active_month_scans
                a=dp.unrank(rank)
                need(len(a)==days and all(a.count(i+1)==n for i,n in enumerate(lengths)),
                     "synthetic global unrank month counts invalid")
                samples.append({"rank_bit_length":rank.bit_length(),
                    "seq_length":len(a),
                    "candidate_trials":dp.candidates-before,
                    "active_month_scans":dp.active_month_scans-scans,
                    "start":list(a[:min(len(a),8)]),
                    "end":list(a[-min(len(a),8):])})
            peak=tracemalloc.get_traced_memory()[1]
        finally:
            tracemalloc.stop()
        elapsed=time.perf_counter_ns()-t0
        report.append({"month_count":len(lengths),"days":days,"lengths":list(lengths),
           "H_entries":cells,"family_count_bit_length":bits,
           "H_arithmetic_weighted_terms":dp.increments,
           "sample_global_ranks":len(samples),
           "rank_sample_receipts":samples,
           "DP_build_wall_ns_informational":built_ns,
           "whole_math_profile_wall_ns_informational":elapsed,
           "tracemalloc_peak_bytes_informational":peak,
           "timing_memory_not_Ada_and_not_pass_fail_gate":True})
    need(len(report)==4 and all(z["sample_global_ranks"]==3 for z in report),
         "missing bounded synthetic pressure profiles")
    return report

def audit(m,gh):
    validate(m)
    limits=theoretical_bounds()
    need(limits["max_stored_H_cells"]==m["analytical_maximum"]["total_dp_H_entries"]
         and limits["max_H_cell_bits_in_conservative_encoding"]==
              m["analytical_maximum"]["integer_value_bit_upper_bound"]
         and limits["full_legal_family_global_rank_bits_unconstrained_upper"]==
              m["analytical_maximum"]["biggest_unrestricted_multinomial_bit_upper_bound"]
         and limits["ranked_candidate_tests_coarse_upper"]==
              m["analytical_maximum"]["unrank_candidate_test_upper_bound"]
         and limits["active_month_scans_coarse_upper"]==
              m["analytical_maximum"]["active_month_scans_upper_bound"],
         "v142 analytical resource envelope differs from source-locked manifest")
    return {"schema":REPORT,"manifest_sha256":digest(m),
       "source":source_check(m,gh),
       "previous_CI":qa_check(gh),
       "analytical_upper_bounds_not_measured_full_year":limits,
       "only_synthetic_profiles":synthetic_profiles(m),
       "production_Ada_resource_proven":False,
       "original_calendar_Fct_executions":0,
       "original_full_years_certified":0,
       "independent_algorithms_certified":0,
       "STOP_NEW_NATIVE_SOAK_DISPATCH":True}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--manifest",required=True,type=Path)
    p.add_argument("--output",required=True,type=Path)
    a=p.parse_args()
    report=audit(parse_json(a.manifest.read_bytes()),
                 GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with a.output.open("xb") as f:
        f.write(canonical(report)+b"\n")
    b=report["analytical_upper_bounds_not_measured_full_year"]
    print(json.dumps({
      "frozen_original_source_blobs":report["source"]["pinned_source_blobs"],
      "DP_H_entries_original_upper":b["max_stored_H_cells"],
      "H_value_bit_upper":b["max_H_cell_bits_in_conservative_encoding"],
      "synthetic_math_profiles":len(report["only_synthetic_profiles"]),
      "real_Fct_calls":0,"original_years_accepted":0,
      "Ada_production_memory_measured":False
      },sort_keys=True))

if __name__=="__main__":
    main()
