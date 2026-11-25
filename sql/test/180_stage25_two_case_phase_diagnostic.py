#!/usr/bin/env python3
"""SQL+தமிழ் Slice25: source-locked, one-case-per-database phase diagnostics."""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

P = "pastafari_sql_tamil."
FIXTURE = "sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl"
FIXTURE_BLOB = "21f38cd280498070b08b6c3074780f1742c36957"
FIXTURE_SOURCE = "1ddaef9a315f83402ececaf4dc31f96dbdd051bd"
FIELDS = ("year_number", "cutlet_name", "day_in_cutlet", "month_name", "day_in_month")
PHASE_CASES = {"prev_3_prev_last", "next_3_next_middle"}
DIRECT_CASES = {"prev_3_middle"}
LOCKS = {
"sql/00_schema.sql":"9ca6f6ea5b3932facbe92aee6a2b38f6557cedd5",
"sql/01_source_language_catalog.sql":"b28730931e26ee65eaf9108621320d73f458ba07",
"sql/02_monster_bootstrap.sql":"3367fe9c34e830b0bd99049ebef64398d150cd79",
"sql/03_stage02_production_core.sql":"72ae68d3ec009f65f081a099c8bf06e0dd3ed9d6",
"sql/04_stage02_stone_states.sql":"caed82dc41d7a259953dc817d5e0722038821310",
"sql/05_stage02_hidden_drop.sql":"f465b466d4a00e24baa689561725a12e5478bf55",
"sql/06_stage02_visible_drops.sql":"2cc67c27b1f5e0c2f22537e479e42956a5711b9e",
"sql/07_stage02_bowls.sql":"0ad25cc4054f46fba66c10dfeffcd81d49f32399",
"sql/08_stage02_bowl_round.sql":"68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6",
"sql/09_stage02_post_stir_round.sql":"2f2f2e19e8851b3130f3c3d5edafd5dfbc6923f9",
"sql/10_stage02_sauce.sql":"c5c6be7c02c255382ae7c317bfbf17138a12788c",
"sql/11_stage02_answer_stream.sql":"b9339560c58cd7a6ab13871ad144257e01c26b84",
"sql/12_stage02_choose_rank.sql":"bde130055cead8d3e5677acac516af7329819748",
"sql/13_stage02_gate_gaps.sql":"d4044e6a4f2f2ae94795233dd3aa14a7d7edaf9e",
"sql/14_stage02_gate_day_selector.sql":"be1d5450f37e3448f7683aea2a0cabdd4620a6c0",
"sql/15_stage02_year5000_gate_candidates.sql":"4d0ad4326b2488e8d2260ffff37f0a93ce49e4f9",
"sql/16_stage02_year5000.sql":"b2fd62c17b133c639f8751fe2eaa03e93ae167f5",
"sql/17_stage02_adjacent_year_navigation.sql":"116e330d0215f58e23e94b4b573071ad24d44664",
"sql/18_stage02_target_year_navigation.sql":"c204a314972b22a4a38f06a02c2fe1bd5bde7acf",
"sql/19_stage02_cutlet_count.sql":"d9e11559c4b3a3a2497dc5cf903c66aba007af40",
"sql/20_stage02_cutlet_partition.sql":"42acfb80e9eabfd9d091176643763ee7d7bca9ee",
"sql/21_stage02_cutlet_names.sql":"5d32a391e1b5609ef790d6a6731ae6713db85a28",
"sql/22_stage02_month_count.sql":"3a23c9a1b5ccae667e3e8990005f4b37480df7e4",
"sql/23_stage02_month_lengths.sql":"0fdcaaa03121692ea9762f79cd08e9aedb0ca24c",
"sql/24_stage02_month_weaving.sql":"a48f611d205763ee5dc7c21da7ddf1c9cfa20e8c",
"sql/25_stage02_month_names.sql":"43c2a6f1071f3e2c9b3ca0225154e42dd2a0de53",
"sql/26_stage02_year_structure.sql":"faac634a06aee59354de207eb088e4e9996034fa",
"sql/27_stage02_calendar_date.sql":"748d4bc1f7754f003c29a42a1756f26e08c1669b",
FIXTURE:FIXTURE_BLOB,
}

def blob_sha(raw: bytes) -> str:
    return hashlib.sha1(b"blob "+str(len(raw)).encode("ascii")+b"\0"+raw).hexdigest()

def load(root=Path(".")):
    assert len(LOCKS)==29
    src={}
    for path,expected in LOCKS.items():
        raw=(root/path).read_bytes()
        actual=blob_sha(raw)
        assert actual==expected, f"source lock mismatch {path}: {actual}"
        if path!=FIXTURE: src[path]=raw.decode("utf-8")
    rows=[json.loads(x) for x in (root/FIXTURE).read_text(encoding="utf-8").splitlines() if x.strip()]
    by={x["case_id"]:x for x in rows}
    assert len(rows)==len(by)==29 and len({x["year_id"] for x in rows})==8
    assert len({x["target_day"] for x in rows})==29 and sum(len(x["expected"]) for x in rows)==145
    for r in rows:
        assert r["source_sha"]==FIXTURE_SOURCE and set(r["expected"])==set(FIELDS)
        assert type(r["calculation_day"]) is int and type(r["target_day"]) is int
        assert abs(r["calculation_day"]-r["target_day"])<=60000
        assert type(r["expected"]["year_number"]) is int
        assert type(r["expected"]["day_in_cutlet"]) is int and type(r["expected"]["day_in_month"]) is int
        assert isinstance(r["expected"]["cutlet_name"],str) and isinstance(r["expected"]["month_name"],str)
        assert type(r["original_zip_artifact_id"]) is int
    return src,by

def definition(src,name):
    anchor=f"CREATE OR REPLACE FUNCTION {P}{name}("
    assert src.count(anchor)==1, f"function anchor changed: {name}"
    i=src.index(anchor); j=src.find("\nCREATE OR REPLACE FUNCTION ",i+len(anchor))
    return src[i:j if j>=0 else len(src)].strip()+"\n"

def clone(src,name,repls=()):
    original=definition(src,name)
    ops=[(f"CREATE OR REPLACE FUNCTION {P}{name}(",f"CREATE OR REPLACE FUNCTION {P}qa_{name}(",1)]
    markers=("LANGUAGE SQL IMMUTABLE STRICT","LANGUAGE SQL STABLE STRICT",
             "LANGUAGE plpgsql STABLE STRICT","LANGUAGE plpgsql VOLATILE STRICT")
    found=[m for m in markers if original.count(m)==1]
    assert len(found)==1, f"volatility declaration changed: {name}"
    if "VOLATILE" not in found[0]:
        ops.append((found[0],found[0].replace("IMMUTABLE","VOLATILE").replace("STABLE","VOLATILE"),1))
    ops.extend(repls)
    out=original
    for a,b,n in ops:
        assert a!=b and out.count(a)==n, f"{name}: transform count mismatch for {a!r}"
        out=out.replace(a,b,n)
    rev=out
    for a,b,n in reversed(ops):
        assert rev.count(b)==n, f"{name}: inverse ambiguous for {b!r}"
        rev=rev.replace(b,a,n)
    assert rev==original, f"{name}: non-reversible QA clone"
    return out

def tracer(name,sig,ret,call,tag):
    return f"""CREATE OR REPLACE FUNCTION {P}qa_trace_{name}({sig})
RETURNS {ret} LANGUAGE plpgsql VOLATILE STRICT AS $qa_phase$
DECLARE v_result {ret}; v_started timestamptz := clock_timestamp();
BEGIN
 RAISE NOTICE 'SQL_TAMIL_PHASE_ENTER={name}:%:%', ({tag})::text, v_started;
 v_result := {call};
 RAISE NOTICE 'SQL_TAMIL_PHASE_EXIT={name}:%:%', ({tag})::text,
   round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);
 RETURN v_result;
END;
$qa_phase$;
"""

def trace_specs(mode):
    s=[
    ("sauce","p_calculation_day numeric,p_target_day numeric",P+"sauce_result",P+"qa_sauce(p_calculation_day,p_target_day)","p_target_day"),
    ("bowl_round","p_bowls numeric[],p_drop numeric,p_i integer","numeric[]",P+"qa_bowl_round(p_bowls,p_drop,p_i)","p_i"),
    ("post_stir_chain","p_bowls numeric[]","numeric[]",P+"qa_post_stir_chain(p_bowls)","array_length(p_bowls,1)"),
    ("gate_gap_signed","p_offset numeric","numeric",P+"qa_gate_gap_signed(p_offset)","p_offset"),
    ("positive_gate_gap","p_n numeric","numeric",P+"qa_positive_gate_gap(p_n)","p_n"),
    ("negative_gate_gap","p_n numeric","numeric",P+"qa_negative_gate_gap(p_n)","p_n"),
    ("year5000","p_calculation_day numeric",P+"year_rec",P+"qa_year5000(p_calculation_day)","p_calculation_day"),
    ("next_year","p_calculation_day numeric,p_known "+P+"year_rec",P+"year_rec",P+"qa_next_year(p_calculation_day,p_known)","(p_known).year_number"),
    ("previous_year","p_calculation_day numeric,p_known "+P+"year_rec",P+"year_rec",P+"qa_previous_year(p_calculation_day,p_known)","(p_known).year_number"),
    ("find_target_year","p_calculation_day numeric,p_target_day numeric",P+"year_rec",P+"qa_find_target_year(p_calculation_day,p_target_day)","p_target_day"),
    ("build_year_structure","p_calculation_day numeric,p_year "+P+"year_rec",P+"year_structure",P+"qa_build_year_structure(p_calculation_day,p_year)","(p_year).year_number"),
    ("calendar_date","p_calculation_day numeric,p_target_day numeric",P+"calendar_result_text",P+"qa_calendar_date(p_calculation_day,p_target_day)","p_target_day")]
    if mode=="next_3_next_middle":
        s += [
        ("bowl_factorial","p_n integer","integer",P+"qa_bowl_factorial(p_n)","p_n"),
        ("bowl_order_from_number","p_rank1 integer","integer[]",P+"qa_bowl_order_from_number(p_rank1)","p_rank1"),
        ("bowl_order_from_drop","p_drop numeric","integer[]",P+"qa_bowl_order_from_drop(p_drop)","p_drop"),
        ("post_stir_round","p_bowls numeric[],p_stir integer","numeric[]",P+"qa_post_stir_round(p_bowls,p_stir)","p_stir")]
    if mode=="prev_3_prev_last":
        s += [
        ("stone_state","p_index integer",P+"stone5",P+"stone_state(p_index)","p_index"),
        ("stone_value","p_index integer,p_kind integer","numeric",P+"qa_stone_value(p_index,p_kind)","p_index::text||':'||p_kind::text"),
        ("gate_index_at_or_before","p_day numeric","numeric",P+"qa_gate_index_at_or_before(p_day)","p_day"),
        ("gate_day","p_index numeric","numeric",P+"qa_gate_day(p_index)","p_index"),
        ("exact_gate_index","p_day numeric","numeric",P+"qa_exact_gate_index(p_day)","p_day"),
        ("choose_cutlet_partition","p_calculation_day numeric,p_sauce "+P+"sauce_result,p_year "+P+"year_rec,p_k integer","integer[]",P+"qa_choose_cutlet_partition(p_calculation_day,p_sauce,p_year,p_k)","p_k")]
    return s

def build_aliases(s,mode):
    assert mode in PHASE_CASES
    out=["-- QA-only aliases; production definitions and types remain unchanged."]
    out += [tracer(*spec) for spec in trace_specs(mode)]
    bowl=s["sql/07_stage02_bowls.sql"]; br=s["sql/08_stage02_bowl_round.sql"]
    post=s["sql/09_stage02_post_stir_round.sql"]; sauce=s["sql/10_stage02_sauce.sql"]
    stone=s["sql/04_stage02_stone_states.sql"]; gaps=s["sql/13_stage02_gate_gaps.sql"]
    selector=s["sql/14_stage02_gate_day_selector.sql"]; y5000=s["sql/16_stage02_year5000.sql"]
    adjacent=s["sql/17_stage02_adjacent_year_navigation.sql"]; target=s["sql/18_stage02_target_year_navigation.sql"]
    partition=s["sql/20_stage02_cutlet_partition.sql"]; structure=s["sql/26_stage02_year_structure.sql"]
    calendar=s["sql/27_stage02_calendar_date.sql"]
    a=[]
    if mode=="next_3_next_middle":
        a += [
        clone(bowl,"bowl_factorial"),
        clone(bowl,"bowl_order_from_number",[(P+"bowl_factorial(",P+"qa_trace_bowl_factorial(",3)]),
        clone(bowl,"bowl_order_from_drop",[(P+"bowl_order_from_number(",P+"qa_trace_bowl_order_from_number(",1)]),
        clone(post,"post_stir_round",[(P+"bowl_order_from_number(",P+"qa_trace_bowl_order_from_number(",1)])]
    if mode=="prev_3_prev_last":
        a.append(clone(stone,"stone_value",[(P+"stone_state(",P+"qa_trace_stone_state(",1)]))
    a.append(clone(sauce,"post_stir_chain",
        [(P+"post_stir_round(",P+"qa_trace_post_stir_round(",1)] if mode=="next_3_next_middle" else []))
    br_repls=[]
    if mode=="next_3_next_middle": br_repls.append((P+"bowl_order_from_drop(",P+"qa_trace_bowl_order_from_drop(",1))
    if mode=="prev_3_prev_last": br_repls.append((P+"stone_value(",P+"qa_trace_stone_value(",4))
    a.append(clone(br,"bowl_round",br_repls))
    sauce_repls=[(P+"bowl_round(",P+"qa_trace_bowl_round(",1),(P+"post_stir_chain(",P+"qa_trace_post_stir_chain(",1)]
    if mode=="next_3_next_middle": sauce_repls.append((P+"bowl_order_from_drop(",P+"qa_trace_bowl_order_from_drop(",1))
    a.append(clone(sauce,"sauce",sauce_repls))
    a += [
    clone(gaps,"gate_gap_signed",[(P+"sauce(",P+"qa_trace_sauce(",1)]),
    clone(gaps,"positive_gate_gap",[(P+"gate_gap_signed(",P+"qa_trace_gate_gap_signed(",1)]),
    clone(gaps,"negative_gate_gap",[(P+"gate_gap_signed(",P+"qa_trace_gate_gap_signed(",1)]),
    clone(y5000,"year5000_gate_window",[(P+"positive_gate_gap(",P+"qa_trace_positive_gate_gap(",1),(P+"negative_gate_gap(",P+"qa_trace_negative_gate_gap(",1)]),
    clone(y5000,"year5000",[(P+"year5000_gate_window(",P+"qa_year5000_gate_window(",1),(P+"sauce(",P+"qa_trace_sauce(",1)]),
    clone(adjacent,"next_year",[(P+"negative_gate_gap(",P+"qa_trace_negative_gate_gap(",1),(P+"positive_gate_gap(",P+"qa_trace_positive_gate_gap(",1),(P+"sauce(",P+"qa_trace_sauce(",1)]),
    clone(adjacent,"previous_year",[(P+"positive_gate_gap(",P+"qa_trace_positive_gate_gap(",1),(P+"negative_gate_gap(",P+"qa_trace_negative_gate_gap(",1),(P+"sauce(",P+"qa_trace_sauce(",1)]),
    clone(target,"find_target_year",[(P+"year5000(",P+"qa_trace_year5000(",1),(P+"next_year(",P+"qa_trace_next_year(",1),(P+"previous_year(",P+"qa_trace_previous_year(",1)])]
    if mode=="prev_3_prev_last":
        a += [
        clone(selector,"gate_index_at_or_before",[(P+"positive_gate_gap(",P+"qa_trace_positive_gate_gap(",1),(P+"negative_gate_gap(",P+"qa_trace_negative_gate_gap(",1)]),
        clone(selector,"gate_day",[(P+"positive_gate_gap(",P+"qa_trace_positive_gate_gap(",1),(P+"negative_gate_gap(",P+"qa_trace_negative_gate_gap(",1)]),
        clone(selector,"exact_gate_index",[(P+"gate_index_at_or_before(",P+"qa_trace_gate_index_at_or_before(",1),(P+"gate_day(",P+"qa_trace_gate_day(",1)]),
        clone(partition,"choose_cutlet_partition",[(P+"exact_gate_index(",P+"qa_trace_exact_gate_index(",1)])]
    build_repls=[(P+"sauce(",P+"qa_trace_sauce(",1)]
    if mode=="prev_3_prev_last": build_repls.append((P+"choose_cutlet_partition(",P+"qa_trace_choose_cutlet_partition(",1))
    a.append(clone(structure,"build_year_structure",build_repls))
    a.append(clone(calendar,"calendar_date",[(P+"find_target_year(",P+"qa_trace_find_target_year(",1),(P+"build_year_structure(",P+"qa_trace_build_year_structure(",1)]))
    result="\n".join(out+a)
    for line in result.splitlines():
        if line.startswith("CREATE OR REPLACE FUNCTION "): assert ".qa_" in line
    assert "CREATE TYPE " not in result
    assert "CREATE OR REPLACE FUNCTION "+P+"calendar_date(" not in result
    assert "CREATE OR REPLACE FUNCTION "+P+"sauce(" not in result
    return result+"\n"

def literal(v):
    if type(v) is int: return str(v)+"::numeric"
    if isinstance(v,str): return "'"+v.replace("'","''")+"'::text"
    raise TypeError(v)

def sql_for(row,mode):
    case=row["case_id"]; phase=mode=="phase"
    call=P+("qa_trace_calendar_date" if phase else "calendar_date")
    label="PHASE" if phase else "DIRECT"
    fm="SLICE25_PHASE_FIELD_PASS" if phase else "SLICE25_DIRECT_FIELD_PASS"
    lines=["\\set ON_ERROR_STOP on","SET statement_timeout = '720s';",
           f"-- case={case}; fixture_blob={FIXTURE_BLOB}",
           "DO $one_case$","DECLARE"," v_result pastafari_sql_tamil.calendar_result_text;",
           " v_started timestamptz;","BEGIN"," v_started := clock_timestamp();",
           f" RAISE NOTICE 'SQL_TAMIL_{label}_CASE={case}';",
           f" v_result := {call}({row['calculation_day']}::numeric,{row['target_day']}::numeric);",
           f" IF v_result IS NULL THEN RAISE EXCEPTION 'calendar_date returned NULL: {case}'; END IF;"]
    for f in FIELDS:
        lines += [f" IF (v_result).{f} IS DISTINCT FROM {literal(row['expected'][f])} THEN",
                  f"   RAISE EXCEPTION 'archived oracle mismatch: {case}.{f}';"," END IF;",
                  f" RAISE NOTICE '{fm}={case}.{f}';"]
    lines += [f" RAISE NOTICE 'SQL_TAMIL_{label}_ELAPSED_MS={case}:%',",
              "   round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);",
              f" RAISE NOTICE 'SQL_TAMIL_{label}_ORACLE=PASS; CASE={case}; FIELDS=5/5';",
              " RAISE NOTICE 'SQL_TAMIL_FULL_SLICE=NOT_ACCEPTED';","END;","$one_case$;",""]
    return "\n".join(lines)

def write_outputs(root,out_dir,mode,case):
    src,rows=load(root)
    if mode=="phase":
        assert case in PHASE_CASES
        (out_dir/"phase-overrides.sql").write_text(build_aliases(src,case),encoding="utf-8")
    else: assert case in DIRECT_CASES
    test=sql_for(rows[case],mode)
    assert test.count("FIELDS=5/5")==1 and test.count("statement_timeout = '720s'")==1
    (out_dir/"test.sql").write_text(test,encoding="utf-8")
    (out_dir/"source-locks.txt").write_text("".join(f"{v}  {k}\n" for k,v in LOCKS.items()),encoding="utf-8")
    r=rows[case]
    manifest={"project_id":"PC-BRANCH-SQL-TAMIL","branch":"SQL+தமிழ்","mode":mode,"case_id":case,
      "calculation_day":r["calculation_day"],"target_day":r["target_day"],"expected":r["expected"],
      "original_zip_artifact_id":r["original_zip_artifact_id"],"fixture_path":FIXTURE,
      "fixture_git_blob":FIXTURE_BLOB,"fixture_source_commit":FIXTURE_SOURCE,
      "locked_source_file_count":29,"production_sql_file_count":28,
      "oracle":"archived independent five-field PG17 year-structure record; not live normative differential",
      "production_modified":False,"statement_timeout_seconds":720,"watchdog_seconds":750,"job_timeout_minutes":15}
    (out_dir/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"SLICE25_GENERATED={mode}:{case}")
    print("SLICE25_SOURCE_FIXTURE_LOCKS=29/29")
    print("SLICE25_EXPECTED_TYPED_FIELDS=5/5")
    print("PRODUCTION_SQL_MODIFIED=NO")

def self_test(root):
    src,rows=load(root); generated={}
    for case in PHASE_CASES:
        generated[case]=build_aliases(src,case)
        q=sql_for(rows[case],"phase")
        assert "qa_trace_calendar_date(" in q and q.count("SLICE25_PHASE_FIELD_PASS=")==5
        assert "statement_timeout = '720s'" in q
    d=sql_for(rows["prev_3_middle"],"direct")
    assert P+"calendar_date(" in d and d.count("SLICE25_DIRECT_FIELD_PASS=")==5
    bad=dict(src); k="sql/13_stage02_gate_gaps.sql"
    bad[k]=bad[k].replace(P+"sauce(",P+"wrong_call(",1)
    try: build_aliases(bad,"prev_3_prev_last")
    except AssertionError: pass
    else: raise AssertionError("mutated source call accepted")
    required={"prev_3_prev_last":("exact_gate_index","negative_gate_gap","sauce","stone_value","stone_state"),
              "next_3_next_middle":("bowl_factorial","post_stir_chain","sauce")}
    for case,names in required.items():
        for n in names:
            assert f"SQL_TAMIL_PHASE_ENTER={n}:" in generated[case]
            assert f"SQL_TAMIL_PHASE_EXIT={n}:" in generated[case]
    print("SLICE25_DIAGNOSTIC_SOURCE_LOCKS=29/29 PASS")
    print("SLICE25_DIAGNOSTIC_FIXTURE=29/29; YEARS=8/8; FIELDS=145/145 PASS")
    print("SLICE25_DIAGNOSTIC_REVERSIBLE_QA_ALIASES=PASS")
    print("SLICE25_DIAGNOSTIC_MUTATION_REJECTED=PASS")
    print("SLICE25_DIAGNOSTIC_POSTGRESQL=NOT_EXECUTED")
    print("SLICE25_DIRECT_MIDDLE_CASE=prev_3_middle; NATIVE=NOT_EXECUTED")

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test",action="store_true")
    ap.add_argument("--root",type=Path,default=Path("."))
    ap.add_argument("--mode",choices=("phase","direct"))
    ap.add_argument("--case-id")
    ap.add_argument("--out-dir",type=Path)
    a=ap.parse_args()
    if a.self_test: self_test(a.root)
    if a.mode:
        if not a.case_id or not a.out_dir: ap.error("--mode requires --case-id and --out-dir")
        a.out_dir.mkdir(parents=True,exist_ok=True)
        write_outputs(a.root,a.out_dir,a.mode,a.case_id)
    elif not a.self_test: ap.error("choose --self-test and/or --mode")
    elif a.case_id or a.out_dir: ap.error("--case-id/--out-dir require --mode")

if __name__=="__main__": main()
