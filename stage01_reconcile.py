#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

import difflib
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path
from typing import Dict, Iterable, Tuple

OWNER = "Sargon17-Green"
REPO = "Pastafarian-Calendar"
BRANCH = "MATLAB+Polski"
EXPECTED_HEAD = "b8be028d24b0a2aedd2d6a7a17f1fac2db3d23de"

BASE = Path.home() / "Pastafarian_MATLAB_Polski_STAGE01_RECONCILE"
REPO_DIR = BASE / "repo"
ARCHIVE = BASE / "repo.zip"
RESULT = BASE / "RESULT.txt"
LOG = BASE / "ROLLING_LOG.txt"
DIFF = BASE / "FINAL_DIFF.patch"

TARGET_FILES = [
    "src/+pastafari/BigInt.m",
    "src/+pastafari/ValidationManager.m",
    "tests/run_stage01_tests.m",
]


def stamp() -> str:
    return time.strftime("%Y-%m-%d %H:%M:%S")


def log(msg: str) -> None:
    BASE.mkdir(parents=True, exist_ok=True)
    line = f"[{stamp()}] {msg}"
    print(line, flush=True)
    with LOG.open("a", encoding="utf-8", newline="\n") as f:
        f.write(line + "\n")
        f.flush()


def write_result(lines: Iterable[str]) -> None:
    BASE.mkdir(parents=True, exist_ok=True)
    RESULT.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def fail(message: str, extra: Iterable[str] = (), rc: int = 1) -> None:
    log("FAIL: " + message)
    lines = [
        "STATUS=FAIL",
        f"EXPECTED_HEAD={EXPECTED_HEAD}",
        f"ERROR={message}",
    ]
    lines.extend(extra)
    write_result(lines)
    print_diagnostics()
    raise SystemExit(rc)


def api_json(url: str):
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Pastafarian-MATLAB-Stage01-Reconcile/1.0",
            "Accept": "application/vnd.github+json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def download(url: str, dst: Path) -> None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Pastafarian-MATLAB-Stage01-Reconcile/1.0"},
    )
    with urllib.request.urlopen(req, timeout=180) as r, dst.open("wb") as f:
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)


def fetch_current_head() -> str:
    url = (
        f"https://api.github.com/repos/{OWNER}/{REPO}/branches/"
        + urllib.parse.quote(BRANCH, safe="")
    )
    data = api_json(url)
    return str(data["commit"]["sha"])


def fresh_snapshot() -> None:
    if BASE.exists():
        for p in [REPO_DIR, ARCHIVE, RESULT, LOG, DIFF]:
            if p.is_dir():
                shutil.rmtree(p, ignore_errors=True)
            elif p.exists():
                p.unlink()
    BASE.mkdir(parents=True, exist_ok=True)

    actual = fetch_current_head()
    log(f"EXPECTED_HEAD={EXPECTED_HEAD}")
    log(f"ACTUAL_HEAD={actual}")
    if actual != EXPECTED_HEAD:
        fail(
            "Branch HEAD changed; this package is intentionally pinned and will not patch an unknown tree.",
            [f"ACTUAL_HEAD={actual}"],
        )

    archive_url = f"https://api.github.com/repos/{OWNER}/{REPO}/zipball/{EXPECTED_HEAD}"
    log("Downloading exact commit archive.")
    download(archive_url, ARCHIVE)

    extract_dir = BASE / "_extract"
    shutil.rmtree(extract_dir, ignore_errors=True)
    extract_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ARCHIVE, "r") as zf:
        zf.extractall(extract_dir)

    roots = [p for p in extract_dir.iterdir() if p.is_dir()]
    if len(roots) != 1:
        fail(f"Unexpected archive layout: found {len(roots)} top-level directories.")
    shutil.move(str(roots[0]), str(REPO_DIR))
    shutil.rmtree(extract_dir, ignore_errors=True)
    log(f"Fresh snapshot ready: {REPO_DIR}")


OLD_BIGINT_BLOCK = """            if isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value\n                if abs(double(value)) > flintmax\n                    error('Pastafari:BigInt:UnsafeNumericInput', ...\n                        'Wartość numeryczna przekracza zakres dokładnych liczb całkowitych MATLAB-a; użyj napisu dziesiętnego.');\n                end\n                [sgn, lm] = pastafari.BigInt.parseDecimal(sprintf('%.0f', double(value)));\n                obj.signValue = sgn;\n                obj.limbs = lm;\n                obj = obj.normalize();\n                return\n            end\n"""

NEW_BIGINT_BLOCK = """            if isinteger(value) && isscalar(value)\n                if strncmp(class(value), 'uint', 4)\n                    s = sprintf('%u', value);\n                else\n                    s = sprintf('%d', value);\n                end\n                [sgn, lm] = pastafari.BigInt.parseDecimal(s);\n                obj.signValue = sgn;\n                obj.limbs = lm;\n                obj = obj.normalize();\n                return\n            end\n            if isfloat(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value\n                if abs(double(value)) > flintmax\n                    error('Pastafari:BigInt:UnsafeNumericInput', ...\n                        'Wartość zmiennoprzecinkowa przekracza bezpieczny zakres dokładnych liczb całkowitych MATLAB-a; użyj natywnego typu całkowitego albo napisu dziesiętnego.');\n                end\n                [sgn, lm] = pastafari.BigInt.parseDecimal(sprintf('%.0f', double(value)));\n                obj.signValue = sgn;\n                obj.limbs = lm;\n                obj = obj.normalize();\n                return\n            end\n"""

OLD_VALIDATION_METHOD = """        function requireExactIntegerInput(value)\n            if isa(value, 'pastafari.BigInt')\n                return\n            end\n            if ~(isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value && abs(double(value)) <= flintmax)\n                error('Pastafari:Validation:IntegerInput', ...\n                    'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');\n            end\n        end\n"""

NEW_VALIDATION_METHOD = """        function requireExactIntegerInput(value)\n            if isa(value, 'pastafari.BigInt')\n                return\n            end\n            if ~(isnumeric(value) && isscalar(value) && isreal(value))\n                error('Pastafari:Validation:IntegerInput', ...\n                    'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');\n            end\n            if isinteger(value)\n                return\n            end\n            if isfloat(value) && isfinite(value) && fix(value) == value && abs(double(value)) <= flintmax\n                return\n            end\n            error('Pastafari:Validation:IntegerInput', ...\n                'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');\n        end\n"""

TEST_INSERT_MARKER = """assert((pastafari.BigInt('999999999999999999') * pastafari.BigInt('888888888888888888')) == ...\n    pastafari.BigInt('888888888888888887111111111111111112'), ...\n    'Mnożenie dowolnej precyzji jest niepoprawne.');\n\n"""

TEST_INSERT = """assert((pastafari.BigInt('999999999999999999') * pastafari.BigInt('888888888888888888')) == ...\n    pastafari.BigInt('888888888888888887111111111111111112'), ...\n    'Mnożenie dowolnej precyzji jest niepoprawne.');\n\n% Regresje dokładnych wejść natywnych powyżej flintmax.\nuBeyond = bitshift(uint64(1), 53) + uint64(1);\niBeyond = -int64(bitshift(uint64(1), 53)) - int64(1);\nuMax = intmax('uint64');\niMin = intmin('int64');\nassert(strcmp(char(pastafari.BigInt(uBeyond)), '9007199254740993'), ...\n    'uint64(2^53+1) utracił dokładność podczas konwersji do BigInt.');\nassert(strcmp(char(pastafari.BigInt(iBeyond)), '-9007199254740993'), ...\n    'int64(-(2^53+1)) utracił dokładność podczas konwersji do BigInt.');\nassert(strcmp(char(pastafari.BigInt(uMax)), '18446744073709551615'), ...\n    'intmax(uint64) utracił dokładność podczas konwersji do BigInt.');\nassert(strcmp(char(pastafari.BigInt(iMin)), '-9223372036854775808'), ...\n    'intmin(int64) utracił dokładność podczas konwersji do BigInt.');\npastafari.ValidationManager.requireExactIntegerInput(uBeyond);\npastafari.ValidationManager.requireExactIntegerInput(iBeyond);\npastafari.ValidationManager.requireExactIntegerInput(uMax);\npastafari.ValidationManager.requireExactIntegerInput(iMin);\n\ncaught = false;\ntry\n    pastafari.BigInt(flintmax + 1);\ncatch err\n    caught = strcmp(err.identifier, 'Pastafari:BigInt:UnsafeNumericInput');\nend\nassert(caught, 'BigInt zaakceptował zmiennoprzecinkowe wejście większe niż flintmax.');\n\ncaught = false;\ntry\n    pastafari.ValidationManager.requireExactIntegerInput(flintmax + 1);\ncatch err\n    caught = strcmp(err.identifier, 'Pastafari:Validation:IntegerInput');\nend\nassert(caught, 'Walidator zaakceptował zmiennoprzecinkowe wejście większe niż flintmax.');\n\ncaught = false;\ntry\n    calendarDateSpaghetti(uBeyond, uBeyond);\ncatch err\n    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');\nend\nassert(caught, 'Pełna ścieżka wejścia odrzuciła dokładny uint64 powyżej flintmax.');\n\n"""


def replace_exact(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one replacement target, found {count}")
    return text.replace(old, new, 1)


def patch_files() -> Tuple[Dict[str, str], Dict[str, str]]:
    before: Dict[str, str] = {}
    after: Dict[str, str] = {}

    for rel in TARGET_FILES:
        p = REPO_DIR / rel
        if not p.is_file():
            raise RuntimeError(f"Missing target file: {rel}")
        before[rel] = p.read_text(encoding="utf-8-sig")

    after["src/+pastafari/BigInt.m"] = replace_exact(
        before["src/+pastafari/BigInt.m"],
        OLD_BIGINT_BLOCK,
        NEW_BIGINT_BLOCK,
        "BigInt constructor",
    )
    after["src/+pastafari/ValidationManager.m"] = replace_exact(
        before["src/+pastafari/ValidationManager.m"],
        OLD_VALIDATION_METHOD,
        NEW_VALIDATION_METHOD,
        "ValidationManager.requireExactIntegerInput",
    )
    tests_before = before["tests/run_stage01_tests.m"]
    if "uint64(2^53+1) utracił dokładność" in tests_before:
        raise RuntimeError("Regression tests appear to be already present; refusing to double-apply.")
    after["tests/run_stage01_tests.m"] = replace_exact(
        tests_before,
        TEST_INSERT_MARKER,
        TEST_INSERT,
        "Stage 1 regression insertion point",
    )

    for rel, text in after.items():
        (REPO_DIR / rel).write_text(text, encoding="utf-8", newline="\n")

    return before, after


def write_diff(before: Dict[str, str], after: Dict[str, str]) -> None:
    chunks = []
    for rel in TARGET_FILES:
        chunks.extend(
            difflib.unified_diff(
                before[rel].splitlines(keepends=True),
                after[rel].splitlines(keepends=True),
                fromfile=f"a/{rel}",
                tofile=f"b/{rel}",
            )
        )
    DIFF.write_text("".join(chunks), encoding="utf-8")


def find_matlab() -> Path | None:
    direct = shutil.which("matlab") or shutil.which("matlab.exe")
    if direct:
        return Path(direct)

    if os.name == "nt":
        roots = [
            Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "MATLAB",
            Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "MATLAB",
        ]
        candidates = []
        for root in roots:
            if root.is_dir():
                candidates.extend(root.glob("R*/bin/matlab.exe"))
        if candidates:
            candidates.sort(key=lambda p: p.as_posix().lower(), reverse=True)
            return candidates[0]
    return None


def run_process(args, cwd: Path, label: str) -> Tuple[int, str]:
    log(f"RUN {label}: {' '.join(str(a) for a in args)}")
    proc = subprocess.Popen(
        [str(a) for a in args],
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
    )
    lines = []
    assert proc.stdout is not None
    for line in proc.stdout:
        line = line.rstrip("\r\n")
        lines.append(line)
        log(f"MATLAB> {line}")
    rc = proc.wait()
    return rc, "\n".join(lines)


def print_diagnostics() -> None:
    print("\n===== OUTPUT LOCATION =====")
    print(BASE)
    print("\n===== RESULT.txt =====")
    if RESULT.is_file():
        print(RESULT.read_text(encoding="utf-8-sig", errors="replace"), end="")
    else:
        print("NOT FOUND")
    print("\n===== FINAL_DIFF.patch =====")
    if DIFF.is_file():
        text = DIFF.read_text(encoding="utf-8-sig", errors="replace")
        print(text if text else "(empty)")
    else:
        print("NOT FOUND")
    print("\n===== ROLLING_LOG.txt (last 200 lines) =====")
    if LOG.is_file():
        lines = LOG.read_text(encoding="utf-8-sig", errors="replace").splitlines()
        for line in lines[-200:]:
            print(line)
    else:
        print("NOT FOUND")


def main() -> None:
    fresh_snapshot()

    try:
        before, after = patch_files()
    except Exception as e:
        fail("Patch application failed.", [f"DETAIL={type(e).__name__}: {e}"])
    write_diff(before, after)
    log("Static patch application PASS.")

    matlab = find_matlab()
    if matlab is None:
        write_result(
            [
                "STATUS=NEEDS_MATLAB",
                f"EXPECTED_HEAD={EXPECTED_HEAD}",
                f"PATCHED_REPO={REPO_DIR}",
                f"DIFF={DIFF}",
                "PATCH_APPLICATION=PASS",
                "MATLAB=NOT_FOUND",
                "NEXT=RUN_THE_SAME_PACKAGE_ON_A_WINDOWS_MACHINE_WITH_MATLAB",
            ]
        )
        print_diagnostics()
        raise SystemExit(2)

    log(f"MATLAB={matlab}")
    tests_dir = REPO_DIR / "tests"
    batch = "try, run_stage01_tests; catch e, disp(getReport(e,'extended')); exit(1); end; exit(0);"
    rc, out = run_process([matlab, "-batch", batch], tests_dir, "run_stage01_tests")

    pass_marker = "STAGE_01_TESTS_PASS" in out
    if rc != 0 or not pass_marker:
        fail(
            "Stage 1 fast suite did not pass after the reconciliation patch.",
            [
                f"MATLAB={matlab}",
                f"MATLAB_EXIT_CODE={rc}",
                f"PASS_MARKER={pass_marker}",
                f"PATCHED_REPO={REPO_DIR}",
                f"DIFF={DIFF}",
            ],
        )

    write_result(
        [
            "STATUS=PASS",
            f"EXPECTED_HEAD={EXPECTED_HEAD}",
            f"MATLAB={matlab}",
            f"MATLAB_EXIT_CODE={rc}",
            "PATCH_APPLICATION=PASS",
            "STAGE01_FAST_SUITE=PASS",
            "EXACT_UINT64_INT64_REGRESSIONS=PASS",
            f"PATCHED_REPO={REPO_DIR}",
            f"DIFF={DIFF}",
            "MODIFIED_FILES=" + ",".join(TARGET_FILES),
            "GITHUB_PUSH=NO",
            "STAGE01_FORMALLY_CLOSED=NO",
            "NEXT=FULL_STAGE01_HEAVY_REVERIFICATION_AND_DOCUMENTATION_RECONCILIATION",
        ]
    )
    log("Stage 1 focused reconciliation PASS. No GitHub changes were made.")
    print_diagnostics()


if __name__ == "__main__":
    main()
