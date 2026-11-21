#!/usr/bin/env python3
"""v164 source-free replay prep from immutable v161 QA trace, NEVER calls F.

Downloads prior sealed GitHub artifact only to extract already recorded
month lengths, exact selector rank and expected weave. Every byte and field
is validated against known provenance before producing a disposable fixture.
"""
from __future__ import annotations

from hashlib import sha256
from io import BytesIO
import json
import os
from pathlib import Path
import sys
from urllib.request import Request, urlopen
from zipfile import ZipFile

OWNER_REPO = "Sargon17-Green/Pastafarian-Calendar"
ARTIFACT_ID = 14707599556
ARTIFACT_SHA256 = "0d1722164fc4c460c0691fe372a1e4530a2f0d2f4339dc8351626745a2f51f50"
RANK_HEX_SHA256 = "e5291e359bb51c67d80ac89e1752c05d209fe13a597dfccc8740f5e402c91989"
WEAVE_JSON_SHA256 = "4d3320d1feef2af21542c9461cc2ac730b230f341462c61197666dfa68f81b66"


def sha(raw: bytes) -> str:
    return sha256(raw).hexdigest()


def main() -> int:
    if len(sys.argv) != 2:
        raise RuntimeError("usage: prepare_v161_replay.py DISPOSABLE_DIRECTORY")
    dest = Path(sys.argv[1])
    if dest.exists():
        raise RuntimeError("refuse to overwrite prior v161 replay fixture")
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise RuntimeError("GitHub token missing, cannot lock archived source")
    address = f"https://api.github.com/repos/{OWNER_REPO}/actions/artifacts/{ARTIFACT_ID}/zip"
    request = Request(address, headers={
        "Authorization": "Bearer " + token,
        "Accept": "application/vnd.github+json",
        "User-Agent": "issue29-v164-captured-intermediate-replay-no-calendar-execution",
    })
    with urlopen(request, timeout=30) as response:
        data = response.read(128 * 1024 + 1)
    if len(data) > 128 * 1024 or sha(data) != ARTIFACT_SHA256:
        raise RuntimeError("v161 sealed artifact missing/mutated; refuse to replay")

    with ZipFile(BytesIO(data)) as z:
        p_stderr = z.read("run-python.stderr").decode("utf-8")
        p_stdout = z.read("run-python.stdout").decode("utf-8")
        prep = json.loads(z.read("preparation.json"))
        receipt = json.loads(z.read("run-python.receipt.json"))
    if receipt["exit_code"] != 0 or receipt["status"] != "completed":
        raise RuntimeError("the v161 Python QA process did not complete")
    if prep["source_dispatch_count"] != 0 or prep["soak_years"] != 0:
        raise RuntimeError("v161 source receipt does not preserve Soak halt")
    selector_lines = [
        line.removeprefix("V159_PY_DIAG|selector|")
        for line in p_stderr.splitlines()
        if line.startswith("V159_PY_DIAG|selector|")
    ]
    result_lines = [
        line.removeprefix("V159_PY_DIAG|result|")
        for line in p_stderr.splitlines()
        if line.startswith("V159_PY_DIAG|result|")
    ]
    if len(selector_lines) != 1 or len(result_lines) != 1:
        raise RuntimeError("v161 intermediate QA capture missing or ambiguous")
    selector, observed = json.loads(selector_lines[0]), json.loads(result_lines[0])
    lengths = selector["month_lengths"]
    names = observed["month_name_indices"]
    weave = observed["month_weaving"]
    rank_hex = selector["global_rank_hex"]
    family_hex = selector["family_count_hex"]
    if (
        selector["source_mode"] != "QA_INSTRUMENTED_COPY_NOT_ORIGINAL"
        or observed["source_mode"] != "QA_INSTRUMENTED_COPY_NOT_ORIGINAL"
        or sha(rank_hex.encode("ascii")) != RANK_HEX_SHA256
        or sha(json.dumps(weave, separators=(",", ":")).encode("ascii")) != WEAVE_JSON_SHA256
        or lengths != observed["month_lengths"]
        or len(lengths) != len(names) != 45
        or len(weave) != sum(lengths) != 4244
        or observed["month_count"] != 45
        or observed["target_offset0"] != 2031
        or observed["month_id"] != 8
        or observed["month_index"] != 20
        or observed["day_in_month"] != 56
        or [x.strip() for x in p_stdout.splitlines() if x.startswith("V160_PY_RESULT|")]
           != ["V160_PY_RESULT|5000|10|503|20|56"]
    ):
        raise RuntimeError("v161 sealed intermediate contents are inconsistent")
    if any(not isinstance(v, int) or v < 4 or v > 123 for v in lengths):
        raise RuntimeError("invalid normative month length in archived trace")
    if any(v < 1 or v > 45 for v in weave):
        raise RuntimeError("invalid weave month identifier")
    if names[7] != 20 or sum(1 for v in weave[:2032] if v == 8) != 56:
        raise RuntimeError("archived v161 projection does not match source QA result")

    dest.mkdir(parents=True)
    file_lines = ",".join(map(str, lengths)) + "\n" + rank_hex + "\n"
    (dest / "v164-captured-selector.txt").write_text(file_lines, encoding="ascii")
    source = {
        "schema": "ISSUE29_V164_ARCHIVED_FOUNDATION_QA_INTERMEDIATE_REPLAY_INPUT/1",
        "artifact_id": ARTIFACT_ID,
        "artifact_sha256": ARTIFACT_SHA256,
        "instrumented_source_only": True,
        "calendar_invocations_this_run": 0,
        "previous_v161_fct_invocations": {"python_qa": 1, "ada_qa": 1},
        "case_from_prior_evidence": "original foundation c=t=-15055671",
        "selector_rank_hex_sha256": RANK_HEX_SHA256,
        "selector_rank_hex": rank_hex,
        "selector_family_count_hex": family_hex,
        "month_lengths": lengths,
        "month_name_indices": names,
        "expected_python_QA_month_weave": weave,
        "weave_json_sha256": WEAVE_JSON_SHA256,
        "offset0": 2031,
        "expected_projection": {"month_id": 8, "month_index": 20, "day_in_month": 56},
    }
    (dest / "v164-captured-v161-expected.json").write_text(
        json.dumps(source, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8"
    )
    print("V164_V161_SOURCE_LOCKED_REPLAY_PREPARED_NO_NEW_F")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
