#!/usr/bin/env python3
"""Stage8 QA-only cost attribution for the accepted Dart+עברית §V source."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PROJECT_ID = "PC-BRANCH-DART-HEBREW"
BRANCH = "Dart+עברית"
EXPECTED_HEAD = "e9c5797f75fa01dd37eb8d628acc5004260db298"

EXPECTED_SOURCE_BLOBS = {
    "lib/src/monster_base.dart": "03bc54a3972fc48afd62c3b020199cb448769778",
    "lib/src/monster_bowl_processor.dart": "e7f6ed24d354bfcd5ed51d9af1c5d06128aab08e",
    "lib/src/monster_bowl_questions.dart": "eae2de2398a15ee6c43e9b5796f4f1c6c1dd0549",
    "lib/src/monster_five_field_calendar.dart": "f29c6cd893bbe31d5ddef294a25013ca384e504d",
    "lib/src/monster_meatball_gates.dart": "072c957dca2803f6ce05fe076ff2f882dd914afa",
    "lib/src/monster_meatball_partition.dart": "2dd196357f35fbae7c4bf63995338dc43673c7b1",
    "lib/src/monster_modular_math.dart": "40bf06311a9a3edabcbdac811952cfade17d583d",
    "lib/src/monster_month_lengths.dart": "f62796e02bec7d1a052cb878b9f90b17e8003359",
    "lib/src/monster_month_names.dart": "fe10b6d53fe8e3eb1c05df058e4552e27723c234",
    "lib/src/monster_month_weave_counter.dart": "5e2321a4c9d00701f2968f2c7dbfc5d5e7c02446",
    "lib/src/monster_month_weave_planner.dart": "1824e96d82e6b0ceb12da01ba33fa75a83204d2a",
    "lib/src/monster_seed_feeder.dart": "4fa6c7b4fbf6bb348e76b7c8e860fab12ba88808",
    "lib/src/monster_visible_droplets.dart": "19a18baae110ab5962c0da84fa3d1f944b87c54a",
    "lib/src/monster_work_counts.dart": "cc6156bc81929d8f219ba7f8b85caa9437304811",
    "lib/src/monster_year_eligibility.dart": "de2df360b6d917f6117f48432714c1d9ddb2a76b",
    "lib/src/monster_year_locator.dart": "d5f3b7fe3b00d9a1b8af57a54ca580d512e1c27a",
    "lib/src/monster_year_selection.dart": "3e93cf9ae009cceef349506283d3bd97d35ad5e4",
    "lib/src/monster_year_traversal.dart": "887d7e9557f08d3dcd017596a59a610864182ec1",
    "lib/src/source_language_catalog.dart": "742c770fab24245ac9a7a7b100ba3a753ef22b2a",
}

EXPECTED_OUTPUT_SHA256 = {
    "count": "c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8",
    "first": "dc2dabc1c69f5007425c032e576577195ea6cf7b1d1054a9faca74e025aaf13c",
    "last": "71b78eb2ce0c68252f404e6c6d34b52a2f8f2b834eb6a2eff687bbc6c0bccdd8",
    "canonical": "7093c6c666dc19642d650fe7fd8a9bbe43cd12238ac4f563ebe668d370eacdda",
}



def fail(message: str) -> None:
    raise RuntimeError(message)


def command(args: list[str], cwd: Path, timeout: int = 120) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        args,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        check=False,
    )
    print("$ " + " ".join(args))
    if result.stdout:
        print(result.stdout.rstrip())
    if result.returncode != 0:
        fail(f"Command exited {result.returncode}: {' '.join(args)}")
    return result


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(f"Expected exactly one instrumentation anchor for {label}; found {count}")
    return source.replace(old, new, 1)


def verify_source_locks() -> str:
    expected_ref = "refs/heads/" + BRANCH
    actual_ref = os.environ.get("GITHUB_REF")
    if actual_ref and actual_ref != expected_ref:
        fail(f"Wrong branch: expected {expected_ref}, got {actual_ref}")

    head = command(["git", "rev-parse", "HEAD"], ROOT).stdout.strip()
    event_sha = os.environ.get("GITHUB_SHA")
    if event_sha and event_sha != head:
        fail(f"Checkout SHA mismatch: GITHUB_SHA={event_sha}, HEAD={head}")

    parent = command(["git", "rev-parse", "HEAD^"], ROOT).stdout.strip()
    if parent != EXPECTED_HEAD:
        fail(f"Stage8 must be a direct QA-only child of accepted Stage7 HEAD: {parent}")

    branch = command(["git", "branch", "--show-current"], ROOT).stdout.strip()
    if branch and branch != BRANCH:
        fail(f"Wrong checked-out branch: {branch}")

    expected_paths = {
        ".github/workflows/canonical-names-lock.yml",
        "bin/stage8_cost_attribution_profile.dart",
        "docs/DART_HEBREW_STAGE_08_DISCOVERY_06_COST_ATTRIBUTION_CONTRACT.md",
        "tool/dart_hebrew_stage8_cost_attribution.py",
        "tool/stage8_cost_attribution_metrics.dart",
    }
    changed = set(
        command(
            ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"],
            ROOT,
        ).stdout.splitlines()
    )
    if changed != expected_paths:
        fail(f"Unexpected Stage8 commit paths: {sorted(changed)}")

    for path, expected in EXPECTED_SOURCE_BLOBS.items():
        actual = command(["git", "rev-parse", f"HEAD:{path}"], ROOT).stdout.strip()
        if actual != expected:
            fail(f"Production source lock mismatch for {path}: {actual} != {expected}")

    print(
        f"STAGE8_SOURCE_LOCK_PASS; head={head}; parent={parent}; "
        f"production_files={len(EXPECTED_SOURCE_BLOBS)}; changed_paths=4"
    )
    return head


def instrument_sources(target: Path) -> None:
    planner_path = target / "lib/src/monster_month_weave_planner.dart"
    planner = planner_path.read_text(encoding="utf-8")
    planner = replace_once(
        planner,
        "import 'monster_month_lengths.dart';\n",
        "import 'monster_month_lengths.dart';\n"
        "import '../../tool/stage8_cost_attribution_metrics.dart';\n",
        "planner metrics import",
    )

    planner = replace_once(
        planner,
        "  static List<BigInt> _activeChildren(List<int> counts, BigInt base) {\n",
        """  static List<BigInt> _activeChildren(List<int> counts, BigInt base) {
    Stage8CostAttributionMetrics.beginActiveChildren(counts, base);
    final timer = Stopwatch()..start();
    final result = _activeChildrenImpl(counts, base);
    timer.stop();
    Stage8CostAttributionMetrics.endActiveChildren(
      result,
      timer.elapsedMicroseconds,
    );
    return result;
  }

  static List<BigInt> _activeChildrenImpl(List<int> counts, BigInt base) {
""",
        "active children wrapper",
    )

    planner = replace_once(
        planner,
        """  static BigInt _unopenedFactor(
    List<int> remaining,
    int opened,
    int nextActiveLength,
  ) {
""",
        """  static BigInt _unopenedFactor(
    List<int> remaining,
    int opened,
    int nextActiveLength,
  ) {
    Stage8CostAttributionMetrics.beginUnopenedFactor(
      remaining,
      opened,
      nextActiveLength,
    );
    final timer = Stopwatch()..start();
    final result = _unopenedFactorImpl(remaining, opened, nextActiveLength);
    timer.stop();
    Stage8CostAttributionMetrics.endUnopenedFactor(
      result,
      timer.elapsedMicroseconds,
    );
    return result;
  }

  static BigInt _unopenedFactorImpl(
    List<int> remaining,
    int opened,
    int nextActiveLength,
  ) {
""",
        "unopened factor wrapper",
    )
    planner_path.write_text(planner, encoding="utf-8")

    counter_path = target / "lib/src/monster_month_weave_counter.dart"
    counter = counter_path.read_text(encoding="utf-8")
    counter = replace_once(
        counter,
        "/// §V discovery: exact counts of admissible suffix weaves, not a completed\n",
        "import '../../tool/stage8_cost_attribution_metrics.dart';\n\n"
        "/// §V discovery: exact counts of admissible suffix weaves, not a completed\n",
        "counter metrics import",
    )
    counter = replace_once(
        counter,
        """  static BigInt countCompletions(
    List<int> remaining, {
    required int openedUpTo,
    required int closedUpTo,
  }) {
""",
        """  static BigInt countCompletions(
    List<int> remaining, {
    required int openedUpTo,
    required int closedUpTo,
  }) {
    Stage8CostAttributionMetrics.beginCountCompletions(
      remaining,
      openedUpTo: openedUpTo,
      closedUpTo: closedUpTo,
    );
    final timer = Stopwatch()..start();
    final result = _countCompletionsImpl(
      remaining,
      openedUpTo: openedUpTo,
      closedUpTo: closedUpTo,
    );
    timer.stop();
    Stage8CostAttributionMetrics.endCountCompletions(
      result,
      timer.elapsedMicroseconds,
    );
    return result;
  }

  static BigInt _countCompletionsImpl(
    List<int> remaining, {
    required int openedUpTo,
    required int closedUpTo,
  }) {
""",
        "count completions wrapper",
    )
    counter_path.write_text(counter, encoding="utf-8")


def copy_profile_tree(destination: Path) -> None:
    shutil.copytree(ROOT / "lib", destination / "lib")
    shutil.copy2(ROOT / "pubspec.yaml", destination / "pubspec.yaml")
    (destination / "bin").mkdir(parents=True, exist_ok=True)
    shutil.copy2(
        ROOT / "bin/stage8_cost_attribution_profile.dart",
        destination / "bin/stage8_cost_attribution_profile.dart",
    )
    (destination / "tool").mkdir(parents=True, exist_ok=True)
    shutil.copy2(
        ROOT / "tool/stage8_cost_attribution_metrics.dart",
        destination / "tool/stage8_cost_attribution_metrics.dart",
    )


def run_profile(label: str, directory: Path) -> dict[str, Any]:
    command(["dart", "pub", "get"], directory, timeout=180)
    output_path = directory / "stage8-profile.json"
    result = command(
        ["dart", "run", "bin/stage8_cost_attribution_profile.dart", str(output_path)],
        directory,
        timeout=240,
    )
    if "STAGE8_COST_ATTRIBUTION_PROFILE_PASS" not in result.stdout:
        fail(f"{label} profile did not emit its PASS marker")
    if not output_path.is_file():
        fail(f"{label} profile did not create its JSON output")
    data = json.loads(output_path.read_text(encoding="utf-8"))
    if data.get("yearNumber") != "5000" or data.get("yearLength") != 4244:
        fail(f"{label} profile has unexpected canonical year")
    if data.get("monthCount") != 45:
        fail(f"{label} profile has unexpected month count")
    if set(data.get("phases", {})) != {"COUNT", "FIRST", "LAST", "CANONICAL"}:
        fail(f"{label} profile is missing a required phase")
    return data


def payload_digest(value: Any) -> str:
    if isinstance(value, list):
        payload = ",".join(str(item) for item in value)
    else:
        payload = str(value)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def validate_metrics(label: str, phase_name: str, metrics: dict[str, Any]) -> None:
    calls = metrics["callCounts"]
    elapsed = metrics["elapsedMicroseconds"]
    states = metrics["stateHistograms"]
    bits = metrics["bigIntBitLengthHistograms"]

    if any(value < 0 for value in calls.values()):
        fail(f"{label}/{phase_name}: negative call count")
    if any(value < 0 for value in elapsed.values()):
        fail(f"{label}/{phase_name}: negative elapsed time")
    if calls["countCompletions"] != (
        calls["countCompletionsFromUnopenedFactor"]
        + calls["countCompletionsOutsideUnopenedFactor"]
    ):
        fail(f"{label}/{phase_name}: countCompletions origin accounting mismatch")

    if sum(states["activeChildren"].values()) != calls["activeChildren"]:
        fail(f"{label}/{phase_name}: activeChildren state histogram mismatch")
    if sum(states["unopenedFactor"].values()) != calls["unopenedFactor"]:
        fail(f"{label}/{phase_name}: unopenedFactor state histogram mismatch")
    if sum(states["countCompletions"].values()) != calls["countCompletions"]:
        fail(f"{label}/{phase_name}: countCompletions state histogram mismatch")
    if sum(bits["activeBase"].values()) != calls["activeChildren"]:
        fail(f"{label}/{phase_name}: active-base bit histogram mismatch")
    if sum(bits["activeChild"].values()) < calls["activeChildren"]:
        fail(f"{label}/{phase_name}: active-child bit histogram is incomplete")
    if sum(bits["unopenedFactor"].values()) != calls["unopenedFactor"]:
        fail(f"{label}/{phase_name}: factor bit histogram mismatch")
    if sum(bits["countCompletions"].values()) != calls["countCompletions"]:
        fail(f"{label}/{phase_name}: completion bit histogram mismatch")


def main() -> None:
    output_dir = ROOT / "out/dart-hebrew-stage8-cost-attribution"
    shutil.rmtree(output_dir, ignore_errors=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        head = verify_source_locks()
        if not shutil.which("dart"):
            fail("Dart SDK is not available on PATH")

        with tempfile.TemporaryDirectory(prefix="dart-hebrew-stage8-") as temp:
            temp_root = Path(temp)
            baseline_dir = temp_root / "baseline"
            instrumented_dir = temp_root / "instrumented"
            baseline_dir.mkdir()
            instrumented_dir.mkdir()
            copy_profile_tree(baseline_dir)
            copy_profile_tree(instrumented_dir)
            instrument_sources(instrumented_dir)

            baseline = run_profile("baseline", baseline_dir)
            instrumented = run_profile("instrumented", instrumented_dir)

        scalar_keys = [
            "yearNumber",
            "yearLength",
            "monthCount",
            "monthLengths",
            "count",
            "canonicalRank",
            "canonicalModulus",
        ]
        for key in scalar_keys:
            if baseline[key] != instrumented[key]:
                fail(f"Instrumented output changed {key}")
        for phase_name in ("FIRST", "LAST", "CANONICAL"):
            if baseline["phases"][phase_name]["result"] != instrumented["phases"][phase_name]["result"]:
                fail(f"Instrumented {phase_name} word differs from baseline")

        actual_digests = {
            "count": payload_digest(instrumented["count"]),
            "first": payload_digest(instrumented["phases"]["FIRST"]["result"]),
            "last": payload_digest(instrumented["phases"]["LAST"]["result"]),
            "canonical": payload_digest(instrumented["phases"]["CANONICAL"]["result"]),
        }
        if actual_digests != EXPECTED_OUTPUT_SHA256:
            fail(f"Stage7 output digest lock mismatch: {actual_digests}")

        for phase_name in ("COUNT", "FIRST", "LAST", "CANONICAL"):
            baseline_metrics = baseline["phases"][phase_name]["metrics"]
            if any(value != 0 for value in baseline_metrics["callCounts"].values()):
                fail(f"Baseline {phase_name} unexpectedly has instrumentation calls")

            metrics = instrumented["phases"][phase_name]["metrics"]
            validate_metrics("instrumented", phase_name, metrics)
            calls = metrics["callCounts"]
            if calls["countCompletionsOutsideUnopenedFactor"] != 1:
                fail(f"{phase_name}: expected exactly one top-level whole-domain count")
            if phase_name == "COUNT":
                if calls["activeChildren"] != 0 or calls["unopenedFactor"] != 0:
                    fail("COUNT phase unexpectedly entered unrank helpers")
            elif phase_name == "FIRST":
                if calls["activeChildren"] == 0 or calls["unopenedFactor"] != 0:
                    fail("FIRST rank-one path did not preserve its no-factor shortcut")
            else:
                if calls["activeChildren"] == 0 or calls["unopenedFactor"] == 0:
                    fail(f"{phase_name}: expected both active and unopened factor paths")
                if calls["countCompletionsFromUnopenedFactor"] == 0:
                    fail(f"{phase_name}: no nested suffix completion calls were attributed")

        summary = {
            "project_id": PROJECT_ID,
            "stage": "Stage8 / DISCOVERY06 — §V cost attribution",
            "branch": BRANCH,
            "head_sha": head,
            "production_source_blobs": EXPECTED_SOURCE_BLOBS,
            "output_sha256": actual_digests,
            "interpretation": (
                "Function timings are inclusive; countCompletions is nested inside "
                "unopenedFactor in some calls. Do not add nested timings together. "
                "This is attribution, not a performance comparison or algorithm change."
            ),
            "phases": {
                name: {
                    "baseline_elapsed_microseconds": baseline["phases"][name]["elapsedMicroseconds"],
                    "instrumented_elapsed_microseconds": instrumented["phases"][name]["elapsedMicroseconds"],
                    "metrics": instrumented["phases"][name]["metrics"],
                }
                for name in ("COUNT", "FIRST", "LAST", "CANONICAL")
            },
        }

        (output_dir / "baseline.json").write_text(
            json.dumps(baseline, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        (output_dir / "instrumented.json").write_text(
            json.dumps(instrumented, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        (output_dir / "summary.json").write_text(
            json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        for phase_name in ("COUNT", "FIRST", "LAST", "CANONICAL"):
            calls = instrumented["phases"][phase_name]["metrics"]["callCounts"]
            print(
                f"STAGE8_{phase_name}_CALLS; activeChildren={calls['activeChildren']}; "
                f"unopenedFactor={calls['unopenedFactor']}; "
                f"countCompletions={calls['countCompletions']}; "
                f"nested={calls['countCompletionsFromUnopenedFactor']}"
            )
        print(f"STAGE8_OUTPUT_SHA256_PASS; {actual_digests}")
        print(
            "STAGE8_COST_ATTRIBUTION_PASS; baseline_identical=true; "
            "production_unchanged=true; phases=4; instrumentation=temporary_copy"
        )
    except Exception as error:
        (output_dir / "failure.txt").write_text(str(error) + "\n", encoding="utf-8")
        print(f"STAGE8_COST_ATTRIBUTION_FAIL; {error}")
        raise


if __name__ == "__main__":
    main()
