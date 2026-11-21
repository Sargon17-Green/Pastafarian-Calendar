#!/usr/bin/env python3
"""QA-only, exact-Git-blob-locked Slice25 sauce phase instrumentation.

Outputs reversible QA aliases; production SQL files are never modified. The
phase trace is observational, NOT an independent calendar oracle nor a pass.
"""
from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from pathlib import Path

CASE = "prev_3_prev_middle"
CALC, TARGET = -15055671, -15072356
LOCKS = {
    "sql/08_stage02_bowl_round.sql": "68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6",
    "sql/10_stage02_sauce.sql": "c5c6be7c02c255382ae7c317bfbf17138a12788c",
    "sql/18_stage02_target_year_navigation.sql": "c204a314972b22a4a38f06a02c2fe1bd5bde7acf",
    "sql/26_stage02_year_structure.sql": "faac634a06aee59354de207eb088e4e9996034fa",
    "sql/27_stage02_calendar_date.sql": "748d4bc1f7754f003c29a42a1756f26e08c1669b",
    "sql/test/164_stage25_calendar_date_matrix.py": "89e28c013e635446c4bf7db2fafe82e095e10f9d",
    "sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl":
        "21f38cd280498070b08b6c3074780f1742c36957",
}


def blob(path: str) -> str:
    b = Path(path).read_bytes()
    return hashlib.sha1(b"blob " + str(len(b)).encode("ascii") + b"\0" + b).hexdigest()


def locked() -> dict[str, str]:
    for path, expected in LOCKS.items():
        actual = blob(path)
        assert actual == expected, f"Git source lock failed: {path}: {actual}"
    return {p: Path(p).read_text(encoding="utf-8") for p in LOCKS}


def segment(source: str, prefix: str, stop: str = "") -> str:
    assert source.count(prefix) == 1, f"function anchor: {prefix}"
    result = source[source.index(prefix):]
    if stop:
        assert result.count(stop) == 1, f"function stop: {stop}"
        result = result[:result.index(stop)]
    return result


def changes(original: str, modifications: list[tuple[str, str]]) -> str:
    candidate = original
    for before, after in modifications:
        assert before != after and candidate.count(before) == 1, f"unlocked transform: {before}"
        candidate = candidate.replace(before, after, 1)
    reverse = candidate
    for before, after in reversed(modifications):
        assert reverse.count(after) == 1, f"ambiguous inverse: {after}"
        reverse = reverse.replace(after, before, 1)
    assert reverse == original, "instrumentation is not reversible"
    return candidate


def trace(name: str, signature: str, typ: str, call: str, tag: str) -> str:
    return f"""CREATE OR REPLACE FUNCTION pastafari_sql_tamil.qa_trace_{name}({signature})
RETURNS {typ} LANGUAGE plpgsql VOLATILE STRICT AS $qa_profile$
DECLARE
  v_result {typ};
  v_started timestamptz := clock_timestamp();
BEGIN
  RAISE NOTICE 'SQL_TAMIL_PROFILE_ENTER={name}:%:%', ({tag})::text, v_started;
  v_result := {call};
  RAISE NOTICE 'SQL_TAMIL_PROFILE_EXIT={name}:%:%', ({tag})::text,
    round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);
  RETURN v_result;
END;
$qa_profile$;
"""


def generate(source: dict[str, str]) -> str:
    p = "CREATE OR REPLACE FUNCTION pastafari_sql_tamil."
    bowl = segment(source["sql/08_stage02_bowl_round.sql"], p+"bowl_round(")
    post = segment(source["sql/10_stage02_sauce.sql"], p+"post_stir_chain(", p+"sauce(")
    sauce = segment(source["sql/10_stage02_sauce.sql"], p+"sauce(")
    year = segment(source["sql/26_stage02_year_structure.sql"], p+"build_year_structure(")
    cal = segment(source["sql/27_stage02_calendar_date.sql"], p+"calendar_date(")
    bowl = changes(bowl, [
        (p+"bowl_round(", p+"qa_phase_bowl_round("),
        ("RETURNS numeric[] LANGUAGE SQL STABLE STRICT AS $$",
         "RETURNS numeric[] LANGUAGE SQL VOLATILE STRICT AS $$"),
        ("pastafari_sql_tamil.bowl_order_from_drop(", "pastafari_sql_tamil.qa_trace_order("),
    ])
    assert bowl.count("pastafari_sql_tamil.stone_value(") == 4
    bowl = bowl.replace("pastafari_sql_tamil.stone_value(", "pastafari_sql_tamil.qa_trace_stone(")
    assert bowl.count("pastafari_sql_tamil.qa_trace_stone(") == 4
    assert bowl.count("pastafari_sql_tamil.save_value(") == 4
    bowl = bowl.replace("pastafari_sql_tamil.save_value(", "pastafari_sql_tamil.qa_trace_save(")
    assert bowl.count("pastafari_sql_tamil.qa_trace_save(") == 4
    assert bowl.replace("pastafari_sql_tamil.qa_trace_save(", "pastafari_sql_tamil.save_value(").count("pastafari_sql_tamil.save_value(") == 4
    post = changes(post, [
        (p+"post_stir_chain(", p+"qa_phase_post_stir_chain("),
        ("RETURNS numeric[] LANGUAGE SQL IMMUTABLE STRICT AS $$",
         "RETURNS numeric[] LANGUAGE SQL VOLATILE STRICT AS $$"),
        ("pastafari_sql_tamil.post_stir_round(", "pastafari_sql_tamil.qa_trace_post_stir_round("),
    ])
    sauce = changes(sauce, [
        (p+"sauce(", p+"qa_phase_sauce("),
        ("LANGUAGE SQL STABLE STRICT AS $$", "LANGUAGE SQL VOLATILE STRICT AS $$"),
        ("pastafari_sql_tamil.bowl_round(", "pastafari_sql_tamil.qa_trace_bowl_round("),
        ("pastafari_sql_tamil.post_stir_chain(", "pastafari_sql_tamil.qa_trace_post_chain("),
    ])
    year = changes(year, [
        (p+"build_year_structure(", p+"qa_phase_build_year_structure("),
        ("pastafari_sql_tamil.sauce(", "pastafari_sql_tamil.qa_trace_sauce("),
    ])
    cal = changes(cal, [
        (p+"calendar_date(", p+"qa_phase_calendar_date("),
        ("pastafari_sql_tamil.find_target_year(", "pastafari_sql_tamil.qa_trace_target_year("),
        ("pastafari_sql_tamil.build_year_structure(",
         "pastafari_sql_tamil.qa_phase_build_year_structure("),
    ])
    helpers = [
        trace("order", "p_drop numeric", "integer[]",
              "pastafari_sql_tamil.bowl_order_from_drop(p_drop)", "'order'"),
        trace("stone", "p_index integer, p_kind integer", "numeric",
              "pastafari_sql_tamil.stone_value(p_index,p_kind)",
              "p_index::text||':'||p_kind::text"),
        trace("save", "p_x numeric", "numeric",
              "pastafari_sql_tamil.save_value(p_x)", "'save'"),
        trace("bowl_round", "p_bowls numeric[], p_drop numeric, p_i integer",
              "numeric[]", "pastafari_sql_tamil.qa_phase_bowl_round(p_bowls,p_drop,p_i)",
              "p_i"),
        trace("post_stir_round", "p_bowls numeric[], p_stir integer", "numeric[]",
              "pastafari_sql_tamil.post_stir_round(p_bowls,p_stir)", "p_stir"),
        trace("post_chain", "p_bowls numeric[]", "numeric[]",
              "pastafari_sql_tamil.qa_phase_post_stir_chain(p_bowls)", "'chain'"),
        trace("sauce", "p_calculation_day numeric, p_target_day numeric",
              "pastafari_sql_tamil.sauce_result",
              "pastafari_sql_tamil.qa_phase_sauce(p_calculation_day,p_target_day)",
              "p_target_day"),
        trace("target_year", "p_calculation_day numeric, p_target_day numeric",
              "pastafari_sql_tamil.year_rec",
              "pastafari_sql_tamil.find_target_year(p_calculation_day,p_target_day)",
              "p_target_day"),
    ]
    result = "-- QA aliases: original production functions and types remain unchanged.\n"
    result += "\n".join([*helpers[:3], bowl, helpers[3], helpers[4], post,
                         helpers[5], sauce, helpers[6], helpers[7], year, cal])
    for forbidden in ("CREATE TYPE ", p+"calendar_date(", p+"sauce(", p+"bowl_round("):
        assert forbidden not in result, f"unexpected production override: {forbidden}"
    for required in ("qa_phase_calendar_date(", "qa_trace_target_year(",
                     "qa_trace_sauce(", "qa_trace_bowl_round(",
                     "qa_trace_stone(", "qa_trace_save(", "qa_trace_post_stir_round("):
        assert required in result
    return result


def native_test(output: Path) -> str:
    subprocess.run([sys.executable, "sql/test/164_stage25_calendar_date_matrix.py",
                    "--mode", "native", "--case-id", CASE, "--output", str(output)],
                   check=True)
    original = output.read_text(encoding="utf-8")
    assert f"SLICE25_MATRIX_GREEN=native:{CASE}" in original
    assert original.count("SLICE25_NATIVE_FIELD_PASS=") == 5
    return original


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--out-dir", type=Path)
    args = parser.parse_args()
    if not args.self_test and not args.out_dir:
        parser.error("--self-test or --out-dir required")
    src = locked()
    generated = generate(src)
    if args.self_test:
        assert generate(src) == generated
        tampered = dict(src)
        tampered["sql/10_stage02_sauce.sql"] = tampered["sql/10_stage02_sauce.sql"].replace(
            "pastafari_sql_tamil.bowl_round(", "pastafari_sql_tamil.nonexistent(", 1)
        try:
            generate(tampered)
        except AssertionError:
            pass
        else:
            raise AssertionError("damaged source unexpectedly accepted")
        print("SLICE25_QA_PHASE_STATIC_LOCK=7/7 PASS")
        print("SLICE25_QA_PHASE_REVERSIBLE_TRANSFORMS=PASS")
        print("SLICE25_QA_PHASE_POSTGRESQL=NOT_EXECUTED")
    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        (args.out_dir/"phase-overrides.sql").write_text(generated, encoding="utf-8")
        original_path = args.out_dir/"original.sql"
        original = native_test(original_path)
        # The five field notices are deliberately repeated; replace all after
        # the exact-once production call is source-locked and reversible.
        candidate = changes(original, [
            ("v_prod := pastafari_sql_tamil.calendar_date(",
             "v_prod := pastafari_sql_tamil.qa_phase_calendar_date("),
        ])
        for old, new in (("SLICE25_NATIVE_FIELD_PASS=", "SLICE25_QA_PHASE_FIELD_PASS="),
                         ("SLICE25_CASE_ELAPSED_MS=", "SLICE25_QA_PHASE_ELAPSED_MS="),
                         ("SLICE25_MATRIX_GREEN=", "SLICE25_QA_PHASE_GREEN=")):
            candidate = candidate.replace(old, new)
        assert candidate.count("SLICE25_QA_PHASE_FIELD_PASS=") == 5
        assert candidate.count("SLICE25_QA_PHASE_GREEN=") == 1
        (args.out_dir/"test.sql").write_text(candidate, encoding="utf-8")
        print("SLICE25_QA_PHASE_FILES_GENERATED=3")
        print("ORACLE=PREEXISTING_29_CASE_EIGHT_YEAR_INDEPENDENT_ORDINAL_CORPUS")
        print("ORIGINAL_SOURCE_EQUALITY=NOT_YET_TESTED")


if __name__ == "__main__":
    main()
