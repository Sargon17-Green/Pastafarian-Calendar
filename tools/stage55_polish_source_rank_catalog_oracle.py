#!/usr/bin/env python3
"""Independent source-rank -> month-length / cutlet / Polish-catalog oracle.

No MATLAB, production sourceLanguageCatalog lookup, or production partition
unranker is used as the oracle.  Completed Native outputs are pinned as
provenance inputs; all unranking, composition enumeration, segment summing,
and catalog mapping are independently implemented here.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import re
import sys
import os
import subprocess
from functools import lru_cache
from pathlib import Path

PROJECT_ID = "PC-BRANCH-MATLAB-POLSKI"
TOTAL_DAYS = 4244
SLOTS = 45
LOW = 4
HIGH = 123
EXPECTED_RUNS = {
    "month_length_certificate": {
        "workflow_run_id": 41110586119, "job_id": 124251655051,
        "head_sha": "3be694df96418ebe5eea46423e1e9d2cc2fc188c",
        "artifact_id": 13002028397, "artifact_name": "stage55-month-length-composition-rank",
        "artifact_zip_sha256": "5f670efad2090697701b2aa03c95f3c62cf479c17b28dbeb1a79e91a417c3d39",
        "log_sha256": "4d2f1347d5d38445b6f216261d1f9254db6e14fcf67f93d8b735c98765b5f163",
        "run_url": "https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41110586119",
        "artifact_size_bytes": 560,
    },
    "source_month_rank": {
        "workflow_run_id": 41117203268, "job_id": 124274411337,
        "head_sha": "53ddfb99ef34d1f4280f9358c3ac83572d2c7095",
        "artifact_id": 13004749650, "artifact_name": "stage55-source-month-rank-native-41117203268",
        "artifact_zip_sha256": "53b952ea31f2f61ff1c6c06f22809a9122be941d021966a8c96286c181d47516",
        "log_sha256": "0cc477dc3e484a2d8fa4df7943ae2b72d30add11a71c5e0df5589b420769c759",
        "run_url": "https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41117203268",
        "artifact_size_bytes": 480,
    },
    "source_cutlet_names": {
        "workflow_run_id": 41119621651, "job_id": 124282723095,
        "head_sha": "83a83402f01992ae05810c57d1924be17fe20d94",
        "artifact_id": 13007028942, "artifact_name": "stage55-source-cutlet-names-native",
        "artifact_zip_sha256": "a329d2c3bd2fc2009c813c0a737cb8a4d48a30d5ea5185651ac268018c3e04c6",
        "log_sha256": "d58872e6a91d5fec3b8de16d19758477c6824ab4834d887b996350a34b5dad71",
        "run_url": "https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41119621651",
        "artifact_size_bytes": 444,
    },
    "source_cutlet_day_lengths": {
        "workflow_run_id": 41121273668, "job_id": 124287804533,
        "head_sha": "fa1a550520c48808bd55666b0a7c24e585031b25",
        "artifact_id": 13008523821, "artifact_name": "stage55-source-cutlet-day-lengths-native",
        "artifact_zip_sha256": "855f532a20c57b0f2427af110b41c3007fc9345adbe44527b57044abc741f256",
        "log_sha256": "52e8f692db9138cd74a84e21477885fe8c150f0c1eef2909ba8cf8a1d408e515",
        "run_url": "https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41121273668",
        "artifact_size_bytes": 411,
    },
}
EXPECTED_RUN_SOURCE_PATHS = {
    "month_length_certificate": [
        "tests/fixtures/stage55_year5000_appendix_a_metadata.json",
        "tools/stage55_polish_month_length_rank_certificate.py",
    ],
    "source_month_rank": [
        "tools/run_stage55_source_month_rank_native.m",
        "src/+pastafari/sauceWithCurrentScars.m",
        "src/+pastafari/AnswerRingStreamFactory.m",
        "src/+pastafari/GeneralSelectionCompatibilityRoute.m",
        "src/+pastafari/WideSelectionDetourPatch.m",
        "src/+pastafari/SmallPickCompatibilityRoute.m",
        "src/+pastafari/AnswerRingRejectionPatch.m",
        "src/+pastafari/LegacyBiasedPick.m",
        "src/+pastafari/LatchedSuccessorPatch.m",
    ],
    "source_cutlet_names": [
        "tools/run_stage55_source_cutlet_names_native.m",
        "tests/fixtures/stage55_year5000_appendix_a_metadata.json",
        "src/+pastafari/sourceLanguageCatalog.m",
        "docs/SOURCE_LANGUAGE_CATALOG.md",
        "src/+pastafari/sauceWithCurrentScars.m",
        "src/+pastafari/AnswerRingStreamFactory.m",
        "src/+pastafari/GeneralSelectionCompatibilityRoute.m",
        "src/+pastafari/WideSelectionDetourPatch.m",
        "src/+pastafari/SmallPickCompatibilityRoute.m",
        "src/+pastafari/AnswerRingRejectionPatch.m",
        "src/+pastafari/LegacyBiasedPick.m",
        "src/+pastafari/LatchedSuccessorPatch.m",
        "src/+pastafari/CutletPartitionCompatibilityRoute.m",
        "src/+pastafari/FilteredLegacyCutletPartitionFamily.m",
        "src/+pastafari/LegacyAllPositiveCutletPartitionFamily.m",
        "src/+pastafari/CutletNameCompatibilityRoute.m",
        "src/+pastafari/RepeatedNamePatchWrapper.m",
        "src/+pastafari/partialPermutationNameRowCount.m",
        "src/+pastafari/partialPermutationNameRowUnrank.m",
    ],
    "source_cutlet_day_lengths": [
        "tools/run_stage55_source_cutlet_day_lengths_native.m",
        "tests/fixtures/stage55_year5000_appendix_a_metadata.json",
        "src/+pastafari/GateQuestionEngine.m",
        "src/+pastafari/GateGapCompatibilityRoute.m",
        "src/+pastafari/SignedGateQuestionPatch.m",
        "src/+pastafari/LegacyPositiveOnlyGateQuestion.m",
    ],
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def parse_one(log: str, pattern: str, label: str) -> re.Match[str]:
    match = re.search(pattern, log, re.MULTILINE)
    if not match:
        raise AssertionError(f"missing {label} line in pinned Native log")
    return match


def positive_compositions(total: int, slots: int):
    if slots == 1:
        if total >= 1:
            yield (total,)
        return
    for first in range(1, total - slots + 2):
        for rest in positive_compositions(total - first, slots - 1):
            yield (first,) + rest


def falling(n: int, k: int) -> int:
    if k < 0 or k > n:
        return 0
    value = 1
    for x in range(n - k + 1, n + 1):
        value *= x
    return value


def partial_permutation_unrank(n: int, k: int, rank: int) -> tuple[int, ...]:
    total = falling(n, k)
    if not 1 <= rank <= total:
        raise AssertionError(f"partial permutation rank outside 1..{total}")
    remaining = list(range(1, n + 1))
    result = []
    r = rank
    for position in range(k):
        block = falling(len(remaining) - 1, k - position - 1)
        index = (r - 1) // block
        r = (r - 1) % block + 1
        result.append(remaining.pop(index))
    if r != 1:
        raise AssertionError("partial permutation unrank did not terminate at residual rank 1")
    return tuple(result)


def parse_markdown_catalog(text: str, heading: str) -> list[str]:
    lines = text.splitlines()
    try:
        start = lines.index(heading) + 1
    except ValueError as exc:
        raise AssertionError(f"catalog heading not found: {heading}") from exc
    names: list[str] = []
    for line in lines[start:]:
        if line.startswith("## "):
            break
        if not line.startswith("|"):
            continue
        cells = [part.strip() for part in line.strip().strip("|").split("|")]
        if len(cells) < 2 or not cells[0].isdigit():
            continue
        index = int(cells[0])
        if index != len(names) + 1:
            raise AssertionError(f"non-contiguous canonicalIndex in {heading}")
        names.append(cells[1])
    return names


def parse_matlab_cell_array(text: str, variable: str) -> list[str]:
    match = re.search(rf"\b{re.escape(variable)}\s*=\s*\{{(.*?)\}}\s*;", text, re.DOTALL)
    if not match:
        raise AssertionError(f"MATLAB catalog cell array not found: {variable}")
    return re.findall(r"'([^']*)'", match.group(1))


def count_ie(total: int, slots: int) -> int:
    """Inclusion-exclusion count for bounded compositions [LOW,HIGH]^slots."""
    if slots < 0 or total < 0:
        return 0
    if slots == 0:
        return int(total == 0)
    shifted = total - slots * LOW
    if shifted < 0:
        return 0
    width = HIGH - LOW + 1
    answer = 0
    for j in range(slots + 1):
        remainder = shifted - j * width
        if remainder < 0:
            break
        answer += (-1 if j & 1 else 1) * math.comb(slots, j) * math.comb(remainder + slots - 1, slots - 1)
    return answer


def count_dp_table(total: int, slots: int) -> list[list[int]]:
    """Independent sliding-window DP: dp[k][s] counts k bounded parts summing to s."""
    dp = [[0] * (total + 1) for _ in range(slots + 1)]
    dp[0][0] = 1
    for k in range(1, slots + 1):
        window = 0
        for subtotal in range(total + 1):
            add_at = subtotal - LOW
            remove_at = subtotal - HIGH - 1
            if add_at >= 0:
                window += dp[k - 1][add_at]
            if remove_at >= 0:
                window -= dp[k - 1][remove_at]
            dp[k][subtotal] = window
    return dp


def unrank_composition(rank: int, total: int, slots: int, count_suffix) -> tuple[int, ...]:
    if rank < 1 or rank > count_suffix(total, slots):
        raise AssertionError("composition rank outside family")
    residual_rank = rank
    residual_total = total
    result = []
    for position in range(slots):
        suffix_slots = slots - position - 1
        chosen = None
        for candidate in range(LOW, HIGH + 1):
            block = count_suffix(residual_total - candidate, suffix_slots)
            if residual_rank > block:
                residual_rank -= block
            else:
                chosen = candidate
                break
        if chosen is None:
            raise AssertionError("composition unrank exhausted candidate range")
        result.append(chosen)
        residual_total -= chosen
    if residual_total != 0 or residual_rank != 1:
        raise AssertionError("composition unrank terminal state mismatch")
    return tuple(result)


def rank_composition(vector: tuple[int, ...], total: int, slots: int, count_suffix) -> int:
    if len(vector) != slots or sum(vector) != total or any(not LOW <= x <= HIGH for x in vector):
        raise AssertionError("invalid bounded-composition vector")
    rank = 1
    residual_total = total
    for position, actual in enumerate(vector):
        suffix_slots = slots - position - 1
        for candidate in range(LOW, actual):
            rank += count_suffix(residual_total - candidate, suffix_slots)
        residual_total -= actual
    if residual_total != 0:
        raise AssertionError("composition rank residual total mismatch")
    return rank


def run(args: argparse.Namespace) -> dict:
    root = Path(args.repo_root).resolve()
    evidence_path = root / args.evidence
    fixture_path = root / args.fixture
    docs_path = root / "docs/SOURCE_LANGUAGE_CATALOG.md"
    catalog_path = root / "src/+pastafari/sourceLanguageCatalog.m"
    names_native_script_path = root / "tools/run_stage55_source_cutlet_names_native.m"
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    current_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    env_sha = os.environ.get("GITHUB_SHA")
    if env_sha and env_sha != current_head:
        raise AssertionError(f"workflow checkout SHA mismatch: HEAD={current_head} GITHUB_SHA={env_sha}")

    evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
    if evidence.get("project_id") != PROJECT_ID:
        raise AssertionError("provenance project sentinel mismatch")

    if evidence.get("current_head_at_manifest_capture") != "7b37e6a74b351e10e6e229dba5bbd0d7438c458a":
        raise AssertionError("source-manifest capture HEAD changed")
    manifest = evidence["source_manifest"]
    if evidence.get("native_run_source_paths") != EXPECTED_RUN_SOURCE_PATHS:
        raise AssertionError("Native run source path sets differ from the reviewed manifest")
    if set(manifest) != {p for paths in EXPECTED_RUN_SOURCE_PATHS.values() for p in paths}:
        raise AssertionError("source manifest is not the exact union of Native run source paths")
    history = evidence.get("historical_tree_comparison", {}).get("runs", {})
    for key, expected in EXPECTED_RUNS.items():
        h = history.get(key, {})
        if h.get("commit") != expected["head_sha"] or h.get("run_relevant_blobs_match") is not True:
            raise AssertionError(f"historical/current source tree equivalence not pinned: {key}")
        if h.get("path_count") != len(EXPECTED_RUN_SOURCE_PATHS[key]):
            raise AssertionError(f"historical/current source tree path count mismatch: {key}")
    for path, expected_blob in manifest.items():
        data = (root / path).read_bytes()
        actual_blob = git_blob_sha1(data)
        if actual_blob != expected_blob:
            raise AssertionError(f"source manifest mismatch: {path} {actual_blob} != {expected_blob}")
    for run_key, expected in EXPECTED_RUNS.items():
        run = evidence["runs"][run_key]
        for field in ("workflow_run_id", "job_id", "head_sha", "artifact_id", "artifact_name",
                      "artifact_zip_sha256", "log_sha256", "run_url", "artifact_size_bytes"):
            if run.get(field) != expected[field]:
                raise AssertionError(f"Native provenance {field} mismatch: {run_key}")
        if run.get("status") != "completed" or run.get("job_status") != "completed":
            raise AssertionError(f"Native run/job status is not completed: {run_key}")
        if run.get("conclusion") != "success" or run.get("job_conclusion") != "success":
            raise AssertionError(f"Native run/job not completed successfully: {run_key}")
        if run.get("artifact_expired") is not False or run.get("artifact_zip_bytes") != expected["artifact_size_bytes"]:
            raise AssertionError(f"Native artifact missing/expired/size mismatch: {run_key}")
        if sha256(run["log_text"].encode("utf-8")) != run["log_sha256"]:
            raise AssertionError(f"Native artifact log hash mismatch: {run_key}")

    cert_log = evidence["runs"]["month_length_certificate"]["log_text"]
    source_rank_log = evidence["runs"]["source_month_rank"]["log_text"]
    names_log = evidence["runs"]["source_cutlet_names"]["log_text"]
    days_log = evidence["runs"]["source_cutlet_day_lengths"]["log_text"]

    parse_one(cert_log, r"STAGE55_MONTH_LENGTH_SMALL_FORMULA_PASS FAMILIES=120", "small composition formula controls")
    parse_one(cert_log,
        r"STAGE55_YEAR5000_MONTH_LENGTH_COMPOSITION_RANK_PASS MONTHS=45 DAYS=4244 LO=4 HI=123 COUNT_METHODS=2 RANK_METHODS=2 ROUNDTRIPS=2",
        "month-length composition certificate PASS")
    family_total_from_cert = int(parse_one(cert_log, r"^STAGE55_MONTH_LENGTH_FAMILY_COUNT=(\d+)$", "composition family count").group(1))
    rank_from_cert = int(parse_one(cert_log, r"^STAGE55_MONTH_LENGTH_LEX_RANK=(\d+)$", "composition lex rank").group(1))
    vector_sha_from_cert = parse_one(cert_log, r"^STAGE55_MONTH_LENGTH_VECTOR_SHA256=([0-9a-f]{64})$", "composition vector hash").group(1)

    source_rank = int(parse_one(source_rank_log, r"^STAGE55_SOURCE_MONTH_RANK_ACTUAL=(\d+)$", "source month rank actual").group(1))
    source_certified_rank = int(parse_one(source_rank_log, r"^STAGE55_SOURCE_MONTH_RANK_CERTIFIED=(\d+)$", "source month rank certified").group(1))
    rejection_steps = int(parse_one(source_rank_log, r"^STAGE55_SOURCE_MONTH_RANK_REJECTION_STEPS=(\d+)$", "source month rank rejection count").group(1))
    parse_one(source_rank_log, r"STAGE55_SOURCE_MONTH_RANK_SAUCE_AND_RING_VERIFIED NEXT_BOWL=1 DIRECTION=-1", "source month rank sauce/ring verification")
    parse_one(source_rank_log, r"STAGE55_SOURCE_MONTH_RANK_PRODUCTION_PATCH14_AGREES", "source month rank production patch cross-check")
    parse_one(source_rank_log, r"STAGE55_SOURCE_MONTH_SELECTION_RANK_NATIVE_PASS YEAR=5000 MONTHS=45 DAYS=4244 BOWLS=6 PLACES=3", "source month rank Native PASS")
    if source_rank != source_certified_rank or source_rank != rank_from_cert:
        raise AssertionError("Native source rank, certified rank and composition certificate disagree")
    if rejection_steps != 0:
        raise AssertionError("unexpected rejection steps in completed source month-rank Native run")

    names_match = parse_one(names_log,
        r"STAGE55_SOURCE_NAMES_PASS CUTLETS=6 MONTHS=45 INDICES=51 CUTLET_RANK=(\d+) MONTH_RANK=(\d+)",
        "source cutlet/month name Native")
    parse_one(names_log, r"STAGE55_SOURCE_CUTLET_PARTITION_PASS GAPS=8 CUTLETS=6", "source cutlet partition Native")
    parse_one(names_log, r"STAGE55_SOURCE_CUTLET_NAMES_NATIVE_PASS YEAR=5000 CUTLETS=6 MONTHS=45 NAME_INDICES=51 SMALL_CASES=60", "source cutlet names Native PASS")
    days_match = parse_one(days_log,
        r"STAGE55_SOURCE_CUTLET_DAY_LENGTHS_NATIVE_PASS YEAR=5000 CUTLETS=6 DAYS=4244 VALUES=\[([0-9 ]+)\]",
        "source cutlet day-length Native")
    gaps_match = parse_one(days_log,
        r"STAGE55_SIGNED_GATE_NATIVE_PASS QUESTIONS=8 NEGATIVE=4 POSITIVE=4 GAPS=\[([0-9 ]+)\]",
        "signed gate Native gaps")

    month_lengths = tuple(int(x) for x in fixture["month_lengths"])
    if len(month_lengths) != SLOTS or sum(month_lengths) != TOTAL_DAYS:
        raise AssertionError("fixture month-length dimensions mismatch")
    if min(month_lengths) != 25 or max(month_lengths) != 122:
        raise AssertionError("fixture month-length min/max mismatch")

    # Re-derive the 45 lengths from the Native source rank, not from the fixture.
    family_ie = count_ie(TOTAL_DAYS, SLOTS)
    dp = count_dp_table(TOTAL_DAYS, SLOTS)
    family_dp = dp[SLOTS][TOTAL_DAYS]
    if family_ie != family_dp or family_ie != family_total_from_cert:
        raise AssertionError("independent inclusion-exclusion/DP family counts disagree")
    if not 1 <= source_rank <= family_ie:
        raise AssertionError("Native source rank outside bounded-composition family")
    def ie_suffix(rem: int, slots: int) -> int:
        return count_ie(rem, slots)
    def dp_suffix(rem: int, slots: int) -> int:
        if rem < 0 or slots < 0 or rem > TOTAL_DAYS or slots > SLOTS:
            return 0
        return dp[slots][rem]
    lengths_ie = unrank_composition(source_rank, TOTAL_DAYS, SLOTS, ie_suffix)
    lengths_dp = unrank_composition(source_rank, TOTAL_DAYS, SLOTS, dp_suffix)
    if lengths_ie != lengths_dp or lengths_ie != month_lengths:
        raise AssertionError("source-rank unrank does not independently reconstruct the pinned 45 lengths")
    if rank_composition(lengths_ie, TOTAL_DAYS, SLOTS, ie_suffix) != source_rank:
        raise AssertionError("inclusion-exclusion rank round-trip failed")
    if rank_composition(lengths_dp, TOTAL_DAYS, SLOTS, dp_suffix) != source_rank:
        raise AssertionError("sliding-window DP rank round-trip failed")
    vector_sha = sha256(",".join(map(str, lengths_ie)).encode("ascii"))
    if vector_sha != vector_sha_from_cert:
        raise AssertionError("rederived month-length vector SHA differs from prior certificate")

    # Independently enumerate all positive 8->6 partitions constrained to boundary 4.
    gaps_from_native = tuple(int(x) for x in gaps_match.group(1).split())
    values_from_native = tuple(int(x) for x in days_match.group(1).split())
    partition = tuple(int(x) for x in fixture["cutlet_gate_partition"])
    required_boundary = int(fixture["cutlet_required_boundary"])
    if len(gaps_from_native) != 8 or int(fixture["cutlet_count"]) != 6 or int(fixture["months"]) != 45:
        raise AssertionError("Native gate/cutlet dimensions differ from the pinned metadata fixture")
    if required_boundary != -int(fixture["open_gate_index"]):
        raise AssertionError("open-gate offset and required partition boundary disagree")
    all_partitions = list(positive_compositions(len(gaps_from_native), 6))
    filtered = [p for p in all_partitions if any(sum(p[:i]) == required_boundary for i in range(1, 6))]
    if all_partitions != sorted(all_partitions) or filtered != sorted(filtered):
        raise AssertionError("independent partition enumeration is not lexicographic")
    if len(all_partitions) != math.comb(7, 5) or len(filtered) != math.comb(6, 4):
        raise AssertionError("independent positive-partition family cardinality mismatch")
    if partition not in filtered or len(partition) != 6 or sum(partition) != 8:
        raise AssertionError("selected six-cutlet partition is not in the independently enumerated family")
    partition_rank = filtered.index(partition) + 1
    if partition_rank != 9:
        raise AssertionError(f"unexpected 1-based lexicographic cutlet partition rank: {partition_rank}")
    derived_cutlet_lengths = []
    cursor = 0
    for width in partition:
        derived_cutlet_lengths.append(sum(gaps_from_native[cursor:cursor + width]))
        cursor += width
    derived_cutlet_lengths = tuple(derived_cutlet_lengths)
    fixture_cutlet_lengths = tuple(int(x) for x in fixture["cutlet_day_lengths"])
    if cursor != 8 or derived_cutlet_lengths != fixture_cutlet_lengths or derived_cutlet_lengths != values_from_native:
        raise AssertionError("independent six-cutlet segment sums differ from Native and fixture values")
    if sum(derived_cutlet_lengths) != TOTAL_DAYS:
        raise AssertionError("six cutlet lengths do not sum to 4,244")
    names_native_script = names_native_script_path.read_text(encoding="utf-8")
    required_native_name_source_fragments = (
        "CutletPartitionCompatibilityRoute.call",
        "double(partition(:).')",
        "double(f.cutlet_gate_partition(:).')",
        "PATCH_21_FILTERED_PARTITION_FAMILY",
        "sourceLanguageCatalog()",
        "CutletNameCompatibilityRoute.call",
        "MonthNameCompatibilityRoute.call",
        "PATCH_22_DISTINCT_NAME_DETOUR",
        "independentUnrank(17,K,cr)",
        "independentUnrank(47,f.months,mr)",
        "f.cutlet_name_indices",
        "f.month_name_indices",
    )
    if any(fragment not in names_native_script for fragment in required_native_name_source_fragments):
        raise AssertionError("Native source names script no longer asserts its filtered partition and independent name indices")

    # The normative document is the oracle; the MATLAB catalog is checked as implementation.
    docs_text = docs_path.read_text(encoding="utf-8")
    code_text = catalog_path.read_text(encoding="utf-8")
    if "canonicalIndex" not in docs_text or "## Kotlety" not in docs_text or "## Miesiące" not in docs_text:
        raise AssertionError("normative Polish catalog document is missing its canonical-index rule/sections")
    doc_cutlets = parse_markdown_catalog(docs_text, "## Kotlety")
    doc_months = parse_markdown_catalog(docs_text, "## Miesiące")
    code_cutlets = parse_matlab_cell_array(code_text, "cutletText")
    code_months = parse_matlab_cell_array(code_text, "monthText")
    if len(doc_cutlets) != 17 or len(doc_months) != 47:
        raise AssertionError("normative Polish catalog dimensions mismatch")
    if code_cutlets != doc_cutlets or code_months != doc_months:
        raise AssertionError("sourceLanguageCatalog implementation differs from normative Markdown catalog")
    if "frozenCatalog.cutlets = makeRows(cutletText)" not in code_text or "frozenCatalog.months = makeRows(monthText)" not in code_text:
        raise AssertionError("sourceLanguageCatalog does not expose the independently checked canonical arrays")

    cutlet_rank = int(names_match.group(1))
    month_name_rank = int(names_match.group(2))
    cutlet_indices = partial_permutation_unrank(17, 6, cutlet_rank)
    month_indices = partial_permutation_unrank(47, 45, month_name_rank)
    fixture_cutlet_indices = tuple(int(x) for x in fixture["cutlet_name_indices"])
    fixture_month_indices = tuple(int(x) for x in fixture["month_name_indices"])
    if cutlet_indices != fixture_cutlet_indices or month_indices != fixture_month_indices:
        raise AssertionError("independent partial-permutation unrank differs from Native name indices/fixture")
    selected_cutlet_names = tuple(doc_cutlets[i - 1] for i in cutlet_indices)
    selected_month_names = tuple(doc_months[i - 1] for i in month_indices)
    if len(set(selected_cutlet_names)) != 6 or len(set(selected_month_names)) != 45:
        raise AssertionError("selected Polish name mapping contains duplicates")

    report = {
        "project_id": PROJECT_ID,
        "current_head": current_head,
        "current_head_at_manifest_capture": evidence["current_head_at_manifest_capture"],
        "source_manifest_verified_paths": len(manifest),
        "historical_tree_comparison": evidence["historical_tree_comparison"],
        "native_runs": {
            key: {k: v for k, v in value.items() if k != "log_text"}
            for key, value in evidence["runs"].items()
        },
        "month_length_rederivation": {
            "source_rank_from_native_stream": str(source_rank),
            "family_count_inclusion_exclusion": str(family_ie),
            "family_count_sliding_window_dp": str(family_dp),
            "rank_roundtrip_inclusion_exclusion": str(rank_composition(lengths_ie, TOTAL_DAYS, SLOTS, ie_suffix)),
            "rank_roundtrip_sliding_window_dp": str(rank_composition(lengths_dp, TOTAL_DAYS, SLOTS, dp_suffix)),
            "month_lengths": list(lengths_ie),
            "month_lengths_sha256_comma_joined": vector_sha,
            "matches_fixture": True,
            "independent_unrank_algorithms": ["inclusion-exclusion suffix count", "sliding-window DP suffix count"],
        },
        "cutlet_partition": {
            "gate_gaps": list(gaps_from_native),
            "all_positive_compositions_count": len(all_partitions),
            "filtered_boundary_compositions_count": len(filtered),
            "required_boundary": required_boundary,
            "selected_partition": list(partition),
            "selected_partition_1_based_lex_rank": partition_rank,
            "six_cutlet_day_lengths": list(derived_cutlet_lengths),
            "total_days": sum(derived_cutlet_lengths),
            "matches_native_and_fixture": True,
        },
        "polish_name_mapping": {
            "normative_source": "docs/SOURCE_LANGUAGE_CATALOG.md",
            "implementation_compared": "src/+pastafari/sourceLanguageCatalog.m",
            "catalog_sizes": {"cutlets": len(doc_cutlets), "months": len(doc_months)},
            "implementation_matches_normative_document": True,
            "cutlet_name_source_rank": str(cutlet_rank),
            "cutlet_name_indices": list(cutlet_indices),
            "selected_cutlet_names": list(selected_cutlet_names),
            "month_name_source_rank": str(month_name_rank),
            "month_name_indices": list(month_indices),
            "selected_month_names": list(selected_month_names),
            "independent_partial_permutation_unrank": True,
        },
        "native_matlab_rerun": False,
        "sourceLanguageCatalog_used_as_oracle": False,
        "stage55_accepted": False,
        "last_completed_stage": 54,
        "next": "Final audit on the exact live MATLAB+Polski HEAD; preserve Stage55 as open until its remaining Native and production gates pass.",
    }
    report_path = out / "report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (out / "source_lock.txt").write_text(
        f"PROJECT_ID={PROJECT_ID}\nCURRENT_HEAD={current_head}\nCURRENT_HEAD_AT_MANIFEST_CAPTURE={evidence['current_head_at_manifest_capture']}\n"
        f"SOURCE_MANIFEST_PATHS={len(manifest)}\nSOURCE_MONTH_RANK={source_rank}\n"
        f"CUTLET_PARTITION_RANK={partition_rank}/15\nCUTLET_NAME_RANK={cutlet_rank}\nMONTH_NAME_RANK={month_name_rank}\n",
        encoding="utf-8")
    (out / "run.log").write_text(
        "STAGE55_SOURCE_RANK_CATALOG_ORACLE_BEGIN\n"
        f"CURRENT_HEAD={current_head}\n"
        f"NATIVE_EVIDENCE_LOCK_PASS RUNS={len(EXPECTED_RUNS)} MANIFEST_PATHS={len(manifest)}\n"
        f"MONTH_LENGTHS_FROM_SOURCE_RANK_PASS RANK={source_rank} COUNT={family_ie} METHODS=2 MATCH_FIXTURE=45/45\n"
        f"CUTLET_PARTITION_ORACLE_PASS FAMILY={len(filtered)} RANK={partition_rank}/15 PARTITION={','.join(map(str, partition))}\n"
        f"CUTLET_SEGMENT_SUMS_PASS VALUES={','.join(map(str, derived_cutlet_lengths))} TOTAL={sum(derived_cutlet_lengths)}\n"
        f"POLISH_CATALOG_PARITY_PASS CUTLETS={len(doc_cutlets)} MONTHS={len(doc_months)}\n"
        f"POLISH_NAME_UNRANK_PASS CUTLET_INDICES={','.join(map(str, cutlet_indices))} MONTH_INDICES={','.join(map(str, month_indices))}\n"
        "SCOPE NATIVE_MATLAB_RERUN=NO SOURCE_LANGUAGE_CATALOG_AS_ORACLE=NO STAGE55=OPEN LAST_COMPLETED_STAGE=54\n"
        "STAGE55_SOURCE_RANK_CATALOG_ORACLE_PASS\n",
        encoding="utf-8")
    (out / "native_evidence.json").write_bytes(evidence_path.read_bytes())
    (out / "year5000_fixture.json").write_bytes(fixture_path.read_bytes())
    (out / "stage55_polish_source_rank_catalog_oracle.py").write_bytes(Path(__file__).read_bytes())
    for source_path in manifest:
        source = root / source_path
        destination = out / "source_snapshot" / source_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(source.read_bytes())
    sums = []
    for path in sorted(out.rglob("*")):
        if path.is_file() and path.name != "SHA256SUMS.txt":
            sums.append(f"{sha256(path.read_bytes())}  {path.relative_to(out).as_posix()}")
    (out / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="ascii")
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--evidence", default="tests/fixtures/stage55_polish_source_native_evidence.json")
    parser.add_argument("--fixture", default="tests/fixtures/stage55_year5000_appendix_a_metadata.json")
    parser.add_argument("--out", default="evidence/stage55-source-rank-catalog-oracle")
    args = parser.parse_args()
    try:
        report = run(args)
        print(json.dumps({
            "project_id": report["project_id"],
            "source_manifest_verified_paths": report["source_manifest_verified_paths"],
            "month_length_rederivation": report["month_length_rederivation"],
            "cutlet_partition": report["cutlet_partition"],
            "polish_name_mapping": report["polish_name_mapping"],
            "stage55_accepted": report["stage55_accepted"],
            "last_completed_stage": report["last_completed_stage"],
        }, ensure_ascii=False, indent=2))
        return 0
    except Exception as exc:
        print(f"STAGE55_SOURCE_RANK_CATALOG_ORACLE_FAIL {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
