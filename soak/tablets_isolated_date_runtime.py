#!/usr/bin/env python3
"""Git-backed, separate-process TABLETS 3x5 date diagnostic; NOT certified.

-I -S -B prevents PYTHONPATH/site/bytecode reuse, but not external caches
or mathematical dependence. Gate replay remains a separate acceptance gate.
"""
from __future__ import annotations
import hashlib
import os
import re
import subprocess
import sys
from time import monotonic
from tablets_date_module_provenance import DateModule, verify_date_module_identities
from tablets_five_field_contract import FOUNDATION, TARGETS, FIELDS

STATUS = "PASS_TABLETS_DATE_PROCESS_ISOLATION_DIAGNOSTIC_NOT_CERTIFIED"
DECIMAL = re.compile(r"-?(?:0|[1-9][0-9]*)\Z")
BOOT = r"""
import runpy
import sys
root, filename, function = sys.argv[1:]
sys.path.insert(0, root)
date = runpy.run_path(filename)[function]
for line in sys.stdin:
    parts = line.rstrip("\n").split("\t")
    if len(parts) != 2:
        raise ValueError("E_INPUT")
    origin, target = (int(s) for s in parts)
    values = date(origin, target)
    if type(values) not in (tuple, list) or len(values) != 5 or any(type(v) is not int for v in values):
        raise ValueError("E_DATE_FIVE_INTS")
    print("\t".join(map(str, (origin, target, *values))), flush=True)
"""


class IsolationError(ValueError):
    pass


def _run(source: DateModule, pairs, remaining):
    if remaining <= 0:
        raise IsolationError("E_RUNTIME_DEADLINE")
    root = source.repo_root.resolve(strict=True)
    file = (root / source.relative_path).resolve(strict=True)
    env = {k: os.environ[k] for k in
           ("PATH", "SYSTEMROOT", "WINDIR", "TMP", "TEMP", "TMPDIR") if k in os.environ}
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    args = [sys.executable, "-I", "-S", "-B", "-c", BOOT, str(root),
            str(file), source.date_function]
    try:
        process = subprocess.Popen(args, cwd=root, env=env, text=True,
                                   stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        try:
            output, errors = process.communicate(
                "".join(f"{a}\t{b}\n" for a, b in pairs), timeout=remaining)
        except subprocess.TimeoutExpired as exc:
            process.kill()
            process.communicate()
            raise IsolationError("E_RUNTIME_TIMEOUT") from exc
    except OSError as exc:
        raise IsolationError("E_RUNTIME_EXEC") from exc
    if process.returncode:
        raise IsolationError(f"E_RUNTIME_EXIT_{process.returncode}:{errors[-300:]}")
    lines = output.splitlines()
    if len(lines) != len(pairs):
        raise IsolationError("E_RUNTIME_ROW_COUNT")
    rows = []
    for i, (line, pair) in enumerate(zip(lines, pairs)):
        parts = line.split("\t")
        if len(parts) != 7 or any(DECIMAL.fullmatch(x) is None for x in parts):
            raise IsolationError(f"E_RUNTIME_FORMAT_{i}")
        numbers = tuple(map(int, parts))
        if numbers[:2] != pair:
            raise IsolationError(f"E_RUNTIME_PAIR_{i}")
        y, c, d, m, md = numbers[2:]
        if not (y >= 1 and 1 <= c <= 17 and d >= 1
                and 1 <= m <= 47 and md >= 1):
            raise IsolationError(f"E_RUNTIME_RANGE_{i}")
        rows.append(numbers[2:])
    return rows, process.pid, hashlib.sha256(output.encode()).hexdigest()


def compare_isolated_dates(independent: DateModule, pinned: DateModule, *,
                           origin=FOUNDATION, targets=TARGETS, deadline=None):
    if (type(origin) is not int or origin != FOUNDATION
            or type(targets) is not tuple or targets != TARGETS):
        raise IsolationError("E_RUNTIME_TARGETS")
    now = monotonic()
    if (type(deadline) not in (float, int) or not now < deadline <= now + 120):
        raise IsolationError("E_RUNTIME_DEADLINE")
    provenance = verify_date_module_identities(independent, pinned)
    if provenance["independent"]["repo_root"] == provenance["pinned"]["repo_root"]:
        raise IsolationError("E_RUNTIME_SAME_ROOT")
    pairs = tuple((origin, x) for x in targets)
    a, pid_a, sha_a = _run(independent, pairs, deadline - monotonic())
    b, pid_b, sha_b = _run(pinned, pairs, deadline - monotonic())
    if pid_a == pid_b:
        raise IsolationError("E_RUNTIME_SAME_PID")
    verify_date_module_identities(independent, pinned)
    for target, left, right in zip(targets, a, b):
        if left != right:
            fields = ",".join(field for field, x, y in zip(FIELDS, left, right)
                              if x != y)
            raise IsolationError(f"E_RUNTIME_MISMATCH_{target}:{fields}")
    return {
        "status": STATUS, "targets": list(targets), "cases": 3,
        "fields_per_case": 5,
        "rows": [{"day": t, "five_fields": dict(zip(FIELDS, row))}
                 for t, row in zip(targets, a)],
        "source_provenance": provenance,
        "python_flags": ["-I", "-S", "-B"],
        "process_pids": [pid_a, pid_b],
        "stdout_sha256": [sha_a, sha_b],
        "in_memory_module_caches_shared": False,
        "external_cache_isolation_verified": False,
        "unseeded_gate_replay_verified": False,
        "algorithmic_independence_certified": False,
        "full_date_certified": False,
        "production_gate_limit_unchanged": 8192,
        "certifiable": False,
    }
