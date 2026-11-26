#!/usr/bin/env python3
"""Bind the accepted baseline proofs to the active seven-field Befunge entry point."""
import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path

PROJECT = "PC-BRANCH-BEFUNGE98-KYRGYZ"
BRANCH = "qa-befunge98-stage1-order-isolation-20261008"
BASELINE = "560d6aa5807a7f766213a33835cce85eab0fa40c"
ACTIVE = "7418e1ec5fe88fe5c14b75710dea2d5607527f28"
PATCH = "96690deb1360ec35ba64e997957b6b1a6cea64f2"
COUNT_REF = "f941efc793c9eee4accf5d03873f8ed029b16725"
SAVE_REF = "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44"
CP_RUN = 45635056768
CP_HEAD = "e124409b2e5d8b34f08af3f7914ede29b3741054"
CP_JOB = 139278155210
CP_ARTIFACT = 15030924408
CP_ARTIFACT_SHA = "8e3a1572686e5fd9dcbd2f7717c9590bcdd119be6c0053745e6df4b7fe157696"
CT_RUN = 45699183636
CT_HEAD = "31c6f2950483dd66b940dd053cb505002ec69343"
CT_JOB = 139504468512
CT_ARTIFACT = 15062438663
CT_ARTIFACT_SHA = "9bfb863c51e2eab6efac64a39fbf82eb84ce535a2c97583eb52ebbc0d2eb6a2b"
REGRESSION_RUN = 45699183338
REGRESSION_HEAD = "31c6f2950483dd66b940dd053cb505002ec69343"
GATE = (1020, 1046)


def need(condition, message):
    if not condition:
        raise AssertionError(message)


def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def char_at(lines, x, y):
    row = lines[y]
    return ord(row[x]) if x < len(row) else 32


def verify_patch(baseline, active, patch):
    with tempfile.TemporaryDirectory(prefix="qa31cu-") as tmp:
        root = Path(tmp)
        (root / "src").mkdir()
        (root / "src" / "interleaved_work_counts.b98").write_bytes(baseline)
        patch_path = root / "signed_increment_gate.patch"
        patch_path.write_bytes(patch)
        subprocess.run(["git", "init", "-q"], cwd=root, check=True)
        subprocess.run(["git", "apply", "--check", str(patch_path)], cwd=root, check=True)
        subprocess.run(["git", "apply", str(patch_path)], cwd=root, check=True)
        applied = (root / "src" / "interleaved_work_counts.b98").read_bytes()
        need(applied == active, "the pinned patch does not reproduce the active source byte-for-byte")


def verify_source_delta(baseline, active):
    old_lines = baseline.decode("utf-8").splitlines()
    new_lines = active.decode("utf-8").splitlines()
    need(len(old_lines) == len(new_lines) == 2016, "unexpected source grid height")
    changes = []
    for y, (old, new) in enumerate(zip(old_lines, new_lines)):
        for x in range(max(len(old), len(new))):
            before = ord(old[x]) if x < len(old) else 32
            after = ord(new[x]) if x < len(new) else 32
            if before != after:
                changes.append((x, y, before, after))
    rows = sorted({y for _, y, _, _ in changes})
    cells = {(x, y) for x, y, _, _ in changes}
    cells.add(GATE)
    need(rows == [1046, 1047, 1048, 1050], "unexpected changed source rows")
    need(len(changes) == 61 and len(cells) == 62, "unexpected patch cell inventory")
    need(all(959 <= x <= 1022 and 1046 <= y <= 1050 for x, y in cells),
         "source change escaped the signed-increment chamber")
    delta = {(x, y): (before, after) for x, y, before, after in changes}
    need(delta.get((959, 1050)) == (ord("+"), ord("^")), "entry direction patch differs")
    need(delta.get((960, 1050)) == (ord("5"), ord(">")), "literal-five successor patch differs")
    need(char_at(old_lines, 1030, 1050) == char_at(new_lines, 1030, 1050) == 32,
         "the claimed x-to-j edit at (1030,1050) is not absent")
    need(char_at(new_lines, 1021, 1046) == ord("+") and
         char_at(new_lines, 1022, 1046) == ord("v") and
         char_at(new_lines, 1020, 1047) == ord("-"),
         "signed add/subtract arms differ")
    need(char_at(new_lines, 960, 1048) == ord("v") and
         char_at(new_lines, 961, 1048) == ord("5") and
         char_at(new_lines, 1020, 1048) == ord("<") and
         char_at(new_lines, 1022, 1048) == ord("<"),
         "signed gate return geometry differs")
    return {
        "changed_rows_zero_based": rows,
        "changed_glyphs": len(changes),
        "changed_or_runtime_writable_cells": len(cells),
        "chamber_bounds": [959, 1022, 1046, 1050],
        "entry": {"coordinate": [959, 1050], "old": "+", "new": "^"},
        "successor": {"coordinate": [960, 1050], "old": "5", "new": ">"},
        "runtime_gate": list(GATE),
        "add_arm": [1021, 1046],
        "subtract_arm": [1020, 1047],
        "claimed_x_to_j_coordinate": {
            "coordinate": [1030, 1050], "baseline": " ", "active": " ", "present": False
        }
    }


def verify_baseline_proofs(root):
    ch = read_json(root / "qa" / "qa31ch_results.json")
    cj = read_json(root / "qa" / "qa31cj_results.json")
    ck = read_json(root / "qa" / "qa31ck_results.json")
    cl = read_json(root / "qa" / "qa31cl_results.json")
    cm = read_json(root / "qa" / "qa31cm_results.json")
    for name, item in (("QA31CH", ch), ("QA31CJ", cj), ("QA31CK", ck),
                       ("QA31CL", cl), ("QA31CM", cm)):
        need(item.get("source_git_blob") == BASELINE, name + " baseline source pin")
        need(item.get("stage1_accepted") is False, name + " must not claim Stage1 acceptance")
    need(len(ch["states"]) == 9 and ch["transitions"] == 2313, "QA31CH scanner induction")
    need(ch["exits"] == {"handoff": 2, "read": 116, "reject": 2195}, "QA31CH exit partition")
    need(set(cj["classes"]) == {"a=0", "a=1", "a>=2"} and cj["native_steps"] == 5091,
         "QA31CJ first-join classes/calibration")
    need(len(ck["classes"]) == 36 and ck["corridor_steps_including_successor"] == 1039
         and ck["native_steps_including_successors"] == 17663, "QA31CK first-gate coverage")
    need(cl["period"] == 2326 and cl["archived_iterations"] == 102
         and cl["physical_iteration_steps"] == 237252
         and cl["archived_final_east_fetches"] == 17, "QA31CL loop rank/calibration")
    geometry = cm["composed_geometry"]
    need(cm["native_steps_from_first_gate"] == 341158, "QA31CM Native trace extent")
    need(cm["normative_counts"] == COUNT_REF and cm["normative_save"] == SAVE_REF,
         "QA31CM independent reference pins")
    need(geometry["scanner_transitions"] == 2313 and
         geometry["distinct_arithmetic_positions"] == 9724 and
         geometry["arithmetic_incoming_directions"] == 258 and
         geometry["fresh_visited_positions"] == 13297 and
         geometry["original_nonblank_unreachable"] == 147 and
         geometry["no_post_handoff_scanner_execution_or_access"] is True,
         "QA31CM composed scanner/arithmetic geometry")
    return {
        "QA31CH": {"states": 9, "transitions": 2313, "handoffs": 2, "rejects": 2195},
        "QA31CJ": {"first_join_classes": 3, "native_steps": 5091},
        "QA31CK": {"first_gate_classes": 36, "corridor_steps": 1039, "native_steps": 17663},
        "QA31CL": {"period": 2326, "iterations": 102, "physical_steps": 237252,
                   "final_east_fetches": 17},
        "QA31CM": {"native_steps_from_first_gate": 341158,
                   "arithmetic_positions": 9724, "incoming_directions": 258,
                   "fresh_visited_positions": 13297, "unreachable_nonblank_cells": 147}
    }


def verify_run(run, jobs, artifacts, *, run_id, head_sha, job_id=None,
               job_name=None, job_count=None, artifact_id=None, artifact_name=None,
               artifact_sha=None, artifact_count=None):
    need(run["id"] == run_id and run["head_sha"] == head_sha, "run identity/SHA")
    need(run["status"] == "completed" and run["conclusion"] == "success", "run not completed/success")
    need(run["head_branch"] == BRANCH, "run branch mismatch")
    job_rows = jobs.get("jobs", [])
    need(len(job_rows) == job_count, "job count mismatch")
    need(all(j["status"] == "completed" and j["conclusion"] == "success" for j in job_rows),
         "one or more jobs not completed/success")
    if job_id is not None:
        selected = [j for j in job_rows if j["id"] == job_id]
        need(len(selected) == 1 and selected[0]["name"] == job_name, "expected Native job missing")
        need(all(s.get("conclusion") == "success" for s in selected[0].get("steps", [])),
             "Native job contains a non-success step")
    artifact_rows = artifacts.get("artifacts", [])
    need(len(artifact_rows) == artifact_count, "artifact count mismatch")
    need(all(not a.get("expired", True) for a in artifact_rows), "an expected artifact is expired")
    if artifact_id is not None:
        selected = [a for a in artifact_rows if a["id"] == artifact_id]
        need(len(selected) == 1, "expected artifact missing")
        item = selected[0]
        need(item["name"] == artifact_name and item["digest"] == "sha256:" + artifact_sha,
             "artifact name/digest mismatch")
    return {"run_id": run_id, "head_sha": head_sha, "jobs": len(job_rows),
            "all_jobs_completed_success": True, "artifacts": len(artifact_rows)}


def verify_cp_artifact(cp_dir):
    source_path = cp_dir / "source.json"
    native_path = cp_dir / "native.json"
    need(sha256(source_path.read_bytes()) == "5d5af5daa650510d21a1e07641631de6241c6769b9e4dc768356e76a8703cc26",
         "QA31CP source receipt digest")
    need(sha256(native_path.read_bytes()) == "aaa87ece54b82b60489a1b2ac38d4a3c6cfb48b68a8fba9fe4bf4586c4c268ad",
         "QA31CP Native receipt digest")
    source = read_json(source_path)
    rows = read_json(native_path)
    need(source["original"] == BASELINE and source["candidate"] == ACTIVE, "QA31CP source pins")
    need(source["changed_or_writable_cells"] == 62 and
         source["distinct_checked_original_directed_edges"] == 9730 and
         source["untouched_external_arithmetic"] is True, "QA31CP route-composition proof")
    need(set(source["sign_classes"]) == {"-1", "0", "1"}, "QA31CP sign classes")
    need(source["sign_classes"]["-1"]["operator"] == "-" and
         source["sign_classes"]["0"]["operator"] == "+" and
         source["sign_classes"]["1"]["operator"] == "+", "QA31CP signed branch selection")
    need(len(rows) == 4, "QA31CP Native case count")
    by_fields = {tuple(row["fields"]): row for row in rows}
    expected_fields = {(0, 21, 1, 12), (0, 12, 1, 21), (0, 11, 1, 11), (0, 0, 0, 0)}
    need(set(by_fields) == expected_fields, "QA31CP Native input set")
    for fields, row in by_fields.items():
        healthy = row["healthy"]["output"]
        need(len(healthy) == 7 and row["baseline"]["output"] == healthy
             and row["native_reference"] == healthy, "baseline/candidate/reference seven-field equality")
    forced = []
    for fields, signs in (((0, 21, 1, 12), [-1, 10]), ((0, 12, 1, 21), [1, -10])):
        row = by_fields[fields]
        healthy = row["healthy"]
        need([x["inc"] for x in healthy["crossings"]] == signs, "QA31CP live signed increments")
        need([x["arm"] for x in healthy["crossings"]] ==
             (["-", "+"] if signs[0] < 0 else ["+", "-"]), "QA31CP live branch arms")
        mutation = row["opposite_first_arm"]
        need(mutation["forced"] is True and
             mutation["output"] == row["counterfactual_native_reference"], "forced-arm independent oracle")
        need(mutation["route_sha256"] != healthy["route_sha256"] and
             mutation["output"][:2] != healthy["output"][:2] and
             mutation["output"][2] == healthy["output"][2] and
             mutation["output"][3] != healthy["output"][3] and
             mutation["output"][4:] == healthy["output"][4:],
             "causal mutation affected unexpected output fields")
        need(mutation["crossings"][0].get("forced") is True, "forced mutation not physically observed")
        forced.append({"fields": list(fields), "increments": signs,
                       "healthy_output": healthy["output"], "counterfactual_output": mutation["output"]})
    zero = by_fields[(0, 11, 1, 11)]["healthy"]
    need([x["inc"] for x in zero["crossings"]] == [0, 0] and
         "opposite_first_arm" not in by_fields[(0, 11, 1, 11)], "zero-increment control")
    need(by_fields[(0, 0, 0, 0)]["healthy"]["crossings"] == [], "zero-loop control")
    return {"static_edges": 9730, "changed_or_runtime_writable_cells": 62,
            "Native_inputs": 4, "forced_counterfactuals": forced, "zero_controls": 2}


def verify_ct_artifact(ct_dir):
    sums = ct_dir / "SHA256SUMS.txt"
    checked = 0
    for line in sums.read_text(encoding="utf-8").splitlines():
        digest, name = line.split("  ", 1)
        path = ct_dir / name.removeprefix("./")
        need(path.is_file() and sha256(path.read_bytes()) == digest, "QA31CT internal SHA256: " + name)
        checked += 1
    need(checked == 6, "QA31CT checksum member count")
    need((ct_dir / "exit-code.txt").read_text().strip() == "0", "QA31CT Native exit code")
    identity = (ct_dir / "identity.txt").read_text(encoding="utf-8")
    tarball_sha = sha256((ct_dir / "PyFunge-0.5-rc2.tar.gz").read_bytes())
    need("PYFUNGE_TARBALL_SHA256=" + tarball_sha in identity, "QA31CT PyFunge identity")
    log = (ct_dir / "native.log").read_text(encoding="utf-8")
    need("QA31CT_NATIVE_SEMANTIC_DOMAIN_PASS invalid=6 valid=8 above-modulus-valid=2 native_invocations=38" in log,
         "QA31CT Native log summary")
    data = read_json(ct_dir / "qa31ct_semantic_domain.json")
    need(data["project_id"] == PROJECT and data["status"] == "PASS" and
         data["native_invocations"] == 38 and data["error"] is None, "QA31CT Native receipt")
    ids = data["source_ids"]
    active = ids["src/work_counts.b98"]
    need(active["git_blob"] == ACTIVE and
         active["sha256"] == "a59c1066843abfde9b059e9ec62b2c9daf0483f116095bbd78c19cf28ab59137",
         "QA31CT active source identity")
    need(ids["reference/work_counts.b98"]["git_blob"] == COUNT_REF and
         ids["reference/save.b98"]["git_blob"] == SAVE_REF,
         "QA31CT independent reference identities")
    cases = data["cases"]
    invalid = [c for c in cases if c["class"] == "invalid-semantic"]
    valid = [c for c in cases if c["class"] == "valid-semantic"]
    need(len(cases) == 14 and len(invalid) == 6 and len(valid) == 8, "QA31CT case partition")
    need(all(c["output"] == ["-1"] * 7 for c in invalid), "QA31CT invalid sentinel outputs")
    need(all(c.get("matches_independent_native_oracle") is True for c in valid),
         "QA31CT valid Native oracle matches")
    need(data["invalid_semantic_probes_passed"] == 6 and
         data["valid_native_oracle_controls_passed"] == 8 and
         data["above_modulus_valid_controls_passed"] == 2, "QA31CT counters")
    return {"cases": 14, "invalid": 6, "valid": 8, "above_modulus_valid": 2,
            "Native_invocations": 38, "internal_checksums": checked}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(".")
    baseline = (root / "src/interleaved_work_counts.b98").read_bytes()
    active = (root / "src/work_counts.b98").read_bytes()
    patch = (root / "qa/signed_increment_gate.patch").read_bytes()
    need(git_blob(baseline) == BASELINE, "baseline Git blob pin")
    need(git_blob(active) == ACTIVE, "active Git blob pin")
    need(git_blob(patch) == PATCH, "patch Git blob pin")
    count_ref = (root / "reference/work_counts.b98").read_bytes()
    save_ref = (root / "reference/save.b98").read_bytes()
    need(git_blob(count_ref) == COUNT_REF, "work_counts reference pin")
    need(git_blob(save_ref) == SAVE_REF, "save reference pin")
    verify_patch(baseline, active, patch)
    delta = verify_source_delta(baseline, active)
    baseline_proofs = verify_baseline_proofs(root)

    meta = args.evidence_root / "meta"
    cp_run = verify_run(read_json(meta / "cp_run.json"), read_json(meta / "cp_jobs.json"),
                        read_json(meta / "cp_artifacts.json"), run_id=CP_RUN, head_sha=CP_HEAD,
                        job_id=CP_JOB, job_name="native-signed-increment", job_count=1,
                        artifact_id=CP_ARTIFACT, artifact_name="befunge-digit-dependent-gate",
                        artifact_sha=CP_ARTIFACT_SHA, artifact_count=1)
    ct_run = verify_run(read_json(meta / "ct_run.json"), read_json(meta / "ct_jobs.json"),
                        read_json(meta / "ct_artifacts.json"), run_id=CT_RUN, head_sha=CT_HEAD,
                        job_id=CT_JOB, job_name="native-work-counts-semantic-domain", job_count=1,
                        artifact_id=CT_ARTIFACT, artifact_name="befunge-qa31ct-semantic-domain-native",
                        artifact_sha=CT_ARTIFACT_SHA, artifact_count=1)
    regression = verify_run(read_json(meta / "regression_run.json"),
                            read_json(meta / "regression_jobs.json"),
                            read_json(meta / "regression_artifacts.json"),
                            run_id=REGRESSION_RUN, head_sha=REGRESSION_HEAD,
                            job_count=30, artifact_count=69)
    cp = verify_cp_artifact(args.evidence_root / "qa31cp")
    ct = verify_ct_artifact(args.evidence_root / "qa31ct")

    result = {
        "schema": "qa31cu-current-entry-composition-v1",
        "project_id": PROJECT,
        "audit_commit": os.environ.get("GITHUB_SHA"),
        "source": {"baseline_git_blob": BASELINE, "active_git_blob": ACTIVE,
                   "active_sha256": sha256(active), "patch_git_blob": PATCH,
                   "patch_reproduces_active_byte_for_byte": True, "delta": delta},
        "baseline_proofs": baseline_proofs,
        "QA31CP": {"run": cp_run, "static_and_native": cp},
        "QA31CT": {"run": ct_run, "semantic_domain": ct},
        "Stage1_regression": regression,
        "composition": {
            "digit_increment": "z=P(e+f); if z<0 then S'=S-|z|, else S'=S+|z|; in both cases S'=S+z",
            "scanner_and_first_join": "the baseline proofs are pinned to 560d6aa; the exact active patch is confined to the signed gate chamber and the composed route audit checks all 9,730 original directed arithmetic edges",
            "kernel_and_outputs": "the shared loop/kernel and independent Befunge references remain pinned; QA31CP verifies live signed arms and counterfactual outputs; QA31CT verifies the active source's valid/invalid semantic domain",
            "stage1_acceptance": "NOT_ACCEPTED"
        },
        "stage1_accepted": False
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
                           encoding="utf-8")
    print("QA31CU_COMPOSITION_PASS | exact patch | 9,730 directed edges | "
          "4 QA31CP Native inputs / 2 forced counterfactuals | "
          "14 QA31CT Native cases | Stage1 remains NOT_ACCEPTED")


if __name__ == "__main__":
    main()
