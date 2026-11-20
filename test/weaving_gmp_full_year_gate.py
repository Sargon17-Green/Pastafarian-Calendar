#!/usr/bin/env python3
"""Bounded, branch-only 4244-symbol median rank/unrank feasibility diagnostic.

This is NOT a production implementation and not Stage 6 acceptance. Each
direction receives an independent 180-second process and 512 MiB RSS ceiling.
An independent dense recurrence checks selected exact prefix counts. A memory
safety guard stops at 496 MiB, reporting INCONCLUSIVE (never PASS).
"""
import hashlib
import resource
import signal
import subprocess
import sys
import tempfile
import time
from collections import Counter
from pathlib import Path

import weaving_gmpy2_backend_probe as g

LENGTHS = g.MONTH_LENGTHS
TARGET = sum(LENGTHS)
EXPECTED_ROOT_SHA256 = "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
TIME_LIMIT_SECONDS = 180.0
RSS_LIMIT_KIB = 512 * 1024
RSS_GUARD_KIB = 496 * 1024
CHECKPOINTS = frozenset((6, 16, 32, 64, 96, 128, 256, 512, 1024, 2048, 4096, 4244))


def rss_kib():
    return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss


def digest_root(root):
    bits = root.bit_length()
    assert bits == 22470, "unexpected exact root size"
    actual = hashlib.sha256(root.to_bytes((bits + 7) // 8, "big")).hexdigest()
    assert actual == EXPECTED_ROOT_SHA256, "unexpected exact root hash"


def check_prefix(state, prefix):
    reference = g.dual.count_prefix(LENGTHS, tuple(prefix))
    assert reference == int(state.total), ("independent dense prefix mismatch", len(prefix))
    print("WEAVING_GMP_FULL_GATE_DENSE_CHECKPOINT=" + str(len(prefix)) + ":EQUAL", flush=True)


def bounded_phase(mode, word_path):
    assert sys.platform.startswith("linux")
    assert mode in ("unrank", "rank")
    assert TARGET == 4244 and len(LENGTHS) == 45
    started = time.monotonic()
    completed = []
    dense_checks = 0
    status = "UNSET"
    saved = g.dual.sparse_transfer
    previous_handler = signal.getsignal(signal.SIGALRM)
    result_rank = 0

    def alarm(_signal, _frame):
        raise TimeoutError("full-year phase reached bounded time limit")

    print("WEAVING_GMP_FULL_GATE_MODE=" + mode, flush=True)
    print("WEAVING_GMP_FULL_GATE_TARGET=" + str(TARGET), flush=True)
    print("WEAVING_GMP_FULL_GATE_TIME_LIMIT_SECONDS=" + str(TIME_LIMIT_SECONDS), flush=True)
    print("WEAVING_GMP_FULL_GATE_RSS_LIMIT_KIB=" + str(RSS_LIMIT_KIB), flush=True)
    print("WEAVING_GMP_FULL_GATE_RSS_GUARD_KIB=" + str(RSS_GUARD_KIB), flush=True)
    signal.signal(signal.SIGALRM, alarm)
    signal.setitimer(signal.ITIMER_REAL, TIME_LIMIT_SECONDS)
    try:
        g.dual.sparse_transfer = g.gmp_transfer
        state = g.dual.SparseDualWeaving(LENGTHS)
        root = int(state.total)
        digest_root(root)
        print("WEAVING_GMP_FULL_GATE_ROOT_SHA256=PASS", flush=True)
        median = root // 2
        if mode == "rank":
            word = tuple(int(x) for x in word_path.read_text(encoding="ascii").strip().split(","))
            assert len(word) == TARGET
            assert Counter(word) == Counter({i + 1: n for i, n in enumerate(LENGTHS)})
        else:
            word = None
            residual = median

        for depth in range(1, TARGET + 1):
            blocks = state.blocks()
            assert sum(blocks) == state.total
            if mode == "unrank":
                choice = None
                for symbol in range(1, len(LENGTHS) + 1):
                    if residual >= blocks[symbol]:
                        residual -= blocks[symbol]
                    else:
                        choice = symbol
                        break
                assert choice is not None
            else:
                choice = word[depth - 1]
                assert blocks[choice] > 0
                result_rank += sum(blocks[1:choice])
            state.take(choice)
            completed.append(choice)
            if depth in CHECKPOINTS:
                check_prefix(state, completed)
                dense_checks += 1
            if rss_kib() >= RSS_GUARD_KIB:
                status = "INCONCLUSIVE_RSS_GUARD"
                break
        else:
            assert state.total == 1
            if mode == "unrank":
                assert residual == 0
                assert Counter(completed) == Counter(
                    {i + 1: n for i, n in enumerate(LENGTHS)})
                word_path.write_text(",".join(map(str, completed)) + "\n", encoding="ascii")
                status = "COMPLETE_UNRANK_ONLY"
            else:
                assert tuple(completed) == word
                assert result_rank == median, "reverse rank did not recover median"
                status = "COMPLETE_RANK_ONLY"
    except TimeoutError:
        status = "INCONCLUSIVE_TIME_BUDGET"
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        g.dual.sparse_transfer = saved

    assert len(completed) >= 6 and dense_checks >= 1, (
        "regression before minimal independent checkpoint", len(completed), dense_checks, status)
    elapsed = time.monotonic() - started
    prefix_digest = hashlib.sha256(",".join(map(str, completed)).encode("ascii")).hexdigest()
    print("WEAVING_GMP_FULL_GATE_STATUS=" + status, flush=True)
    print("WEAVING_GMP_FULL_GATE_SYMBOLS=" + str(len(completed)), flush=True)
    print("WEAVING_GMP_FULL_GATE_DENSE_CHECKS=" + str(dense_checks), flush=True)
    print("WEAVING_GMP_FULL_GATE_PREFIX_SHA256=" + prefix_digest, flush=True)
    print("WEAVING_GMP_FULL_GATE_SECONDS=" + format(elapsed, ".6f"), flush=True)
    print("WEAVING_GMP_FULL_GATE_RSS_KIB=" + str(rss_kib()), flush=True)
    print("WEAVING_GMP_FULL_GATE_STAGE6_ACCEPTANCE=NOT_CLAIMED", flush=True)


def main():
    if len(sys.argv) == 3 and sys.argv[1] in ("--unrank", "--rank"):
        bounded_phase(sys.argv[1][2:], Path(sys.argv[2]))
        return
    if len(sys.argv) != 1:
        raise SystemExit("usage: weaving_gmp_full_year_gate.py [--unrank|--rank wordpath]")

    print("WEAVING_GMP_FULL_GATE_CONTRACT=4244_EXACT_MEDIAN_TWO_ISOLATED_DIRECTIONS", flush=True)
    with tempfile.TemporaryDirectory(prefix="chapel-gmp-median-") as directory:
        word_path = Path(directory) / "median-word.txt"
        subprocess.run([sys.executable, "-u", __file__, "--unrank", str(word_path)],
                       check=True, timeout=190)
        if word_path.is_file():
            subprocess.run([sys.executable, "-u", __file__, "--rank", str(word_path)],
                           check=True, timeout=190)
            print("WEAVING_GMP_FULL_GATE_DIRECTIONS=UNRANK_AND_RANK_TESTED", flush=True)
        else:
            print("WEAVING_GMP_FULL_GATE_RANK=NOT_TESTED_NO_COMPLETE_WORD", flush=True)
    print("WEAVING_GMP_FULL_GATE_PRODUCTION_CHANGE=NONE", flush=True)
    print("WEAVING_GMP_FULL_GATE_STAGE6_ACCEPTANCE=NOT_CLAIMED", flush=True)


if __name__ == "__main__":
    main()
