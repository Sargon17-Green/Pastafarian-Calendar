#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

import json
import shutil
import sys
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

OWNER = "Sargon17-Green"
REPO = "Pastafarian-Calendar"
BRANCH = "MATLAB+Polski"
EXPECTED_HEAD = "3bed1c949cd18c7271109fef7d9c737bcf68596d"

BASE = Path.home() / "Pastafarian_MATLAB_Polski_STAGE01_STATIC"
REPO_DIR = BASE / "repo"
ARCHIVE = BASE / "repo.zip"
RESULT = BASE / "RESULT.txt"
LOG = BASE / "ROLLING_LOG.txt"
UPLOAD_ZIP = BASE / "UPLOAD_STAGE01_RECONCILE_DRAFT.zip"
DELETE_LIST = BASE / "DELETE_FROM_GITHUB.txt"

TARGET_FILES = [
    "src/+pastafari/BigInt.m",
    "src/+pastafari/ValidationManager.m",
    "tests/run_stage01_tests.m",
]

ACCIDENTAL_HELPERS = [
    "README_HE.txt",
    "RUN_STAGE01_RECONCILE.cmd",
    "stage01_reconcile.py",
]


def stamp() -> str:
    return time.strftime("%Y-%m-%d %H:%M:%S")


def log(message: str) -> None:
    BASE.mkdir(parents=True, exist_ok=True)
    line = f"[{stamp()}] {message}"
    print(line, flush=True)
    with LOG.open("a", encoding="utf-8", newline="\n") as f:
        f.write(line + "\n")


def write_result(lines: list[str]) -> None:
    RESULT.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def fail(message: str, rc: int = 1) -> None:
    log("FAIL: " + message)
    write_result([
        "STATUS=FAIL",
        f"EXPECTED_HEAD={EXPECTED_HEAD}",
        f"ERROR={message}",
    ])
    raise SystemExit(rc)


def api_json(url: str):
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Pastafarian-MATLAB-Stage01-Static/1.0",
            "Accept": "application/vnd.github+json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def download(url: str, destination: Path) -> None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Pastafarian-MATLAB-Stage01-Static/1.0"},
    )
    with urllib.request.urlopen(req, timeout=180) as response, destination.open("wb") as f:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)


def fetch_head() -> str:
    url = (
        f"https://api.github.com/repos/{OWNER}/{REPO}/branches/"
        + urllib.parse.quote(BRANCH, safe="")
    )
    return str(api_json(url)["commit"]["sha"])


def reset_workspace() -> None:
    if BASE.exists():
        shutil.rmtree(BASE)
    BASE.mkdir(parents=True)


def fetch_snapshot() -> None:
    actual = fetch_head()
    log(f"EXPECTED_HEAD={EXPECTED_HEAD}")
    log(f"ACTUAL_HEAD={actual}")
    if actual != EXPECTED_HEAD:
        fail("Branch HEAD changed; refusing to build a package from an unknown tree.")

    download(
        f"https://api.github.com/repos/{OWNER}/{REPO}/zipball/{EXPECTED_HEAD}",
        ARCHIVE,
    )

    extract_dir = BASE / "_extract"
    extract_dir.mkdir()
    with zipfile.ZipFile(ARCHIVE, "r") as zf:
        zf.extractall(extract_dir)

    roots = [p for p in extract_dir.iterdir() if p.is_dir()]
    if len(roots) != 1:
        fail(f"Unexpected archive layout: {len(roots)} top-level directories.")

    shutil.move(str(roots[0]), str(REPO_DIR))
    shutil.rmtree(extract_dir)
    log(f"Snapshot ready: {REPO_DIR}")


OLD_BIGINT = """            if isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value
                if abs(double(value)) > flintmax
                    error('Pastafari:BigInt:UnsafeNumericInput', ...
                        'Wartość numeryczna przekracza zakres dokładnych liczb całkowitych MATLAB-a; użyj napisu dziesiętnego.');
                end
                [sgn, lm] = pastafari.BigInt.parseDecimal(sprintf('%.0f', double(value)));
                obj.signValue = sgn;
                obj.limbs = lm;
                obj = obj.normalize();
                return
            end
"""

NEW_BIGINT = """            if isinteger(value) && isscalar(value)
                if strncmp(class(value), 'uint', 4)
                    s = sprintf('%u', value);
                else
                    s = sprintf('%d', value);
                end
                [sgn, lm] = pastafari.BigInt.parseDecimal(s);
                obj.signValue = sgn;
                obj.limbs = lm;
                obj = obj.normalize();
                return
            end
            if isfloat(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value
                if abs(double(value)) > flintmax
                    error('Pastafari:BigInt:UnsafeNumericInput', ...
                        'Wartość zmiennoprzecinkowa przekracza bezpieczny zakres dokładnych liczb całkowitych MATLAB-a; użyj natywnego typu całkowitego albo napisu dziesiętnego.');
                end
                [sgn, lm] = pastafari.BigInt.parseDecimal(sprintf('%.0f', double(value)));
                obj.signValue = sgn;
                obj.limbs = lm;
                obj = obj.normalize();
                return
            end
"""

OLD_VALIDATION = """        function requireExactIntegerInput(value)
            if isa(value, 'pastafari.BigInt')
                return
            end
            if ~(isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value && abs(double(value)) <= flintmax)
                error('Pastafari:Validation:IntegerInput', ...
                    'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');
            end
        end
"""

NEW_VALIDATION = """        function requireExactIntegerInput(value)
            if isa(value, 'pastafari.BigInt')
                return
            end
            if ~(isnumeric(value) && isscalar(value) && isreal(value))
                error('Pastafari:Validation:IntegerInput', ...
                    'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');
            end
            if isinteger(value)
                return
            end
            if isfloat(value) && isfinite(value) && fix(value) == value && abs(double(value)) <= flintmax
                return
            end
            error('Pastafari:Validation:IntegerInput', ...
                'Dzień musi być dokładną liczbą całkowitą albo obiektem pastafari.BigInt.');
        end
"""

TEST_MARKER = """assert((pastafari.BigInt('999999999999999999') * pastafari.BigInt('888888888888888888')) == ...
    pastafari.BigInt('888888888888888887111111111111111112'), ...
    'Mnożenie dowolnej precyzji jest niepoprawne.');

"""

TEST_REPLACEMENT = """assert((pastafari.BigInt('999999999999999999') * pastafari.BigInt('888888888888888888')) == ...
    pastafari.BigInt('888888888888888887111111111111111112'), ...
    'Mnożenie dowolnej precyzji jest niepoprawne.');

% Regresje dokładnych wejść natywnych powyżej flintmax.
uBeyond = bitshift(uint64(1), 53) + uint64(1);
iBeyond = -int64(bitshift(uint64(1), 53)) - int64(1);
uMax = intmax('uint64');
iMin = intmin('int64');

assert(strcmp(char(pastafari.BigInt(uBeyond)), '9007199254740993'), ...
    'uint64(2^53+1) utracił dokładność podczas konwersji do BigInt.');
assert(strcmp(char(pastafari.BigInt(iBeyond)), '-9007199254740993'), ...
    'int64(-(2^53+1)) utracił dokładność podczas konwersji do BigInt.');
assert(strcmp(char(pastafari.BigInt(uMax)), '18446744073709551615'), ...
    'intmax(uint64) utracił dokładność podczas konwersji do BigInt.');
assert(strcmp(char(pastafari.BigInt(iMin)), '-9223372036854775808'), ...
    'intmin(int64) utracił dokładność podczas konwersji do BigInt.');

pastafari.ValidationManager.requireExactIntegerInput(uBeyond);
pastafari.ValidationManager.requireExactIntegerInput(iBeyond);
pastafari.ValidationManager.requireExactIntegerInput(uMax);
pastafari.ValidationManager.requireExactIntegerInput(iMin);

caught = false;
try
    pastafari.BigInt(flintmax + 1);
catch err
    caught = strcmp(err.identifier, 'Pastafari:BigInt:UnsafeNumericInput');
end
assert(caught, 'BigInt zaakceptował zmiennoprzecinkowe wejście większe niż flintmax.');

caught = false;
try
    pastafari.ValidationManager.requireExactIntegerInput(flintmax + 1);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Validation:IntegerInput');
end
assert(caught, 'Walidator zaakceptował zmiennoprzecinkowe wejście większe niż flintmax.');

caught = false;
try
    calendarDateSpaghetti(uBeyond, uBeyond);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, 'Pełna ścieżka wejścia odrzuciła dokładny uint64 powyżej flintmax.');

"""


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        fail(f"{label}: expected one target, found {count}.")
    return text.replace(old, new, 1)


def patch_file(relative: str, old: str, new: str, label: str) -> None:
    path = REPO_DIR / relative
    if not path.is_file():
        fail(f"Missing file: {relative}")
    text = path.read_text(encoding="utf-8-sig")
    path.write_text(
        replace_once(text, old, new, label),
        encoding="utf-8",
        newline="\n",
    )
    log(f"Patched: {relative}")


def remove_helpers_locally() -> list[str]:
    present = []
    for relative in ACCIDENTAL_HELPERS:
        path = REPO_DIR / relative
        if path.exists():
            present.append(relative)
            path.unlink()
    if present:
        log("Removed helper files from LOCAL snapshot: " + ", ".join(present))
    else:
        log("No accidental helper files found in local snapshot.")
    return present


def build_upload_zip() -> None:
    if UPLOAD_ZIP.exists():
        UPLOAD_ZIP.unlink()
    with zipfile.ZipFile(UPLOAD_ZIP, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for relative in TARGET_FILES:
            source = REPO_DIR / relative
            if not source.is_file():
                fail(f"Cannot package missing target: {relative}")
            zf.write(source, arcname=relative)

    with zipfile.ZipFile(UPLOAD_ZIP, "r") as zf:
        names = zf.namelist()
    if names != TARGET_FILES:
        fail(f"Unexpected ZIP contents: {names}")
    log(f"Upload ZIP ready: {UPLOAD_ZIP}")


def main() -> None:
    reset_workspace()
    fetch_snapshot()

    helpers = remove_helpers_locally()

    patch_file(
        "src/+pastafari/BigInt.m",
        OLD_BIGINT,
        NEW_BIGINT,
        "BigInt constructor",
    )
    patch_file(
        "src/+pastafari/ValidationManager.m",
        OLD_VALIDATION,
        NEW_VALIDATION,
        "ValidationManager.requireExactIntegerInput",
    )

    tests_path = REPO_DIR / "tests/run_stage01_tests.m"
    tests = tests_path.read_text(encoding="utf-8-sig")
    if "uint64(2^53+1) utracił dokładność" in tests:
        fail("Regression tests already appear to be present; refusing to double-apply.")
    tests_path.write_text(
        replace_once(
            tests,
            TEST_MARKER,
            TEST_REPLACEMENT,
            "Stage 1 regression insertion point",
        ),
        encoding="utf-8",
        newline="\n",
    )
    log("Patched: tests/run_stage01_tests.m")

    DELETE_LIST.write_text(
        "\n".join(ACCIDENTAL_HELPERS) + "\n",
        encoding="utf-8",
    )

    build_upload_zip()

    write_result([
        "STATUS=STATIC_PASS_NATIVE_DEFERRED",
        f"EXPECTED_HEAD={EXPECTED_HEAD}",
        "PATCH_APPLICATION=PASS",
        "NATIVE_MATLAB_VERIFICATION=DEFERRED",
        f"UPLOAD_ZIP={UPLOAD_ZIP}",
        f"DELETE_LIST={DELETE_LIST}",
        "UPLOAD_ZIP_CONTENTS=" + ",".join(TARGET_FILES),
        "HELPERS_PRESENT_IN_BASE=" + (",".join(helpers) if helpers else "NONE"),
        "NEXT=DELETE_HELPERS_FROM_GITHUB_THEN_UPLOAD_DRAFT_ZIP",
    ])

    log("STATIC PASS. Native MATLAB verification is deferred to the consolidated run.")
    print()
    print(RESULT.read_text(encoding="utf-8"), end="")
    print(f"\nUpload package: {UPLOAD_ZIP}")
    print(f"Delete list:    {DELETE_LIST}")
    raise SystemExit(0)


if __name__ == "__main__":
    main()
