#!/usr/bin/env python3
"""DISCOVERY03: bounded, genuine 45-month median-prefix cost decomposition.

Research-only timing. A partially observed prefix is not a full rank/unrank,
a legacy counterexample, or Stage 6 acceptance.
"""
from hashlib import sha256
from resource import RUSAGE_SELF, getrusage
from time import monotonic

from weaving_reachability_oracle import MONTH_LENGTHS
from weaving_sparse_dual import SparseDualWeaving

MAX_SYMBOLS = 64
SOFT_BUDGET_SECONDS = 50.0
MAX_RSS_KIB = 512 * 1024
CHECKPOINTS = frozenset((6, 16, 32, 48, 64))
ROOT_SHA256 = "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"


def main():
    lengths = tuple(MONTH_LENGTHS)
    assert len(lengths) == 45 and sum(lengths) == 4244
    started = monotonic()
    state = SparseDualWeaving(lengths, observe_transfers=True)
    root = state.total
    assert root.bit_length() == 22470
    assert sha256(root.to_bytes((root.bit_length() + 7) // 8, "big")).hexdigest() == ROOT_SHA256
    rank = root // 2
    prefix = []
    block_seconds = take_seconds = 0.0
    max_block_seconds = max_take_seconds = 0.0
    max_rss_kib = getrusage(RUSAGE_SELF).ru_maxrss
    reason = "MAX_SYMBOLS"
    print("WEAVING_SPARSE_PROFILE_ROOT=VERIFIED", flush=True)
    print("WEAVING_SPARSE_PROFILE_BUDGET_SECONDS=50", flush=True)
    for position in range(1, MAX_SYMBOLS + 1):
        if monotonic() - started >= SOFT_BUDGET_SECONDS:
            reason = "SOFT_TIME_BUDGET"
            break
        t = monotonic()
        blocks = state.blocks()
        block_time = monotonic() - t
        assert sum(blocks) == state.total
        selected = 0
        for candidate in range(1, len(blocks)):
            if rank >= blocks[candidate]:
                rank -= blocks[candidate]
            else:
                selected = candidate
                break
        assert selected > 0, ("no median continuation", position)
        t = monotonic()
        state.take(selected)
        take_time = monotonic() - t
        assert 0 <= rank < state.total
        prefix.append(selected)
        block_seconds += block_time
        take_seconds += take_time
        max_block_seconds = max(max_block_seconds, block_time)
        max_take_seconds = max(max_take_seconds, take_time)
        max_rss_kib = max(max_rss_kib, getrusage(RUSAGE_SELF).ru_maxrss)
        if position == 6:
            assert tuple(prefix) == (1, 2, 3, 4, 5, 6)
        if position in CHECKPOINTS:
            print("WEAVING_SPARSE_PROFILE_CHECKPOINT="
                  + str(position)
                  + " BLOCKS_SECONDS=" + format(block_seconds, ".3f")
                  + " TAKE_SECONDS=" + format(take_seconds, ".3f")
                  + " ELAPSED_SECONDS=" + format(monotonic()-started, ".3f")
                  + " RSS_KIB=" + str(max_rss_kib), flush=True)
        if max_rss_kib >= MAX_RSS_KIB:
            reason = "RSS_LIMIT"
            break
    elapsed = monotonic() - started
    for phase in ("blocks", "take"):
        metric = state.transfer_metrics[phase]
        name = "WEAVING_SPARSE_PROFILE_" + phase.upper() + "_FORWARD_"
        print(name + "CALLS=" + str(metric["calls"]))
        print(name + "SECONDS=" + format(metric["seconds"], ".3f"))
        print(name + "FREE_INTERVAL_CELLS=" + str(metric["free_interval_cells"]))
        print(name + "FIXED_CALLS=" + str(metric["fixed_calls"]))
        print(name + "OUTPUT_CELLS=" + str(metric["output_cells"]))
        hot = sorted(range(2, len(lengths) + 1),
                     key=lambda month: (-metric["per_month_seconds"][month], month))[:5]
        print(name + "HOT_MONTHS=" + ",".join(
            str(month) + ":" + format(metric["per_month_seconds"][month], ".3f")
            + "s/" + str(metric["per_month_calls"][month])
            for month in hot))
        assert sum(metric["per_month_calls"]) == metric["calls"]
    print("WEAVING_SPARSE_PROFILE_REUSED_TRANSFERS="
          + str(state.reused_candidate_transfers))
    print("WEAVING_SPARSE_PROFILE_SYMBOLS=" + str(len(prefix)))
    print("WEAVING_SPARSE_PROFILE_BLOCKS_SECONDS=" + format(block_seconds, ".3f"))
    print("WEAVING_SPARSE_PROFILE_TAKE_SECONDS=" + format(take_seconds, ".3f"))
    print("WEAVING_SPARSE_PROFILE_MAX_BLOCK_SECONDS=" + format(max_block_seconds, ".3f"))
    print("WEAVING_SPARSE_PROFILE_MAX_TAKE_SECONDS=" + format(max_take_seconds, ".3f"))
    print("WEAVING_SPARSE_PROFILE_ELAPSED_SECONDS=" + format(elapsed, ".3f"))
    print("WEAVING_SPARSE_PROFILE_RSS_KIB=" + str(max_rss_kib))
    print("WEAVING_SPARSE_PROFILE_PREFIX_SHA256="
          + sha256(",".join(map(str, prefix)).encode("ascii")).hexdigest())
    print("WEAVING_SPARSE_PROFILE_STOP_REASON=" + reason)
    print("WEAVING_SPARSE_PROFILE_RESULT="
          + ("PROFILED_64_ONLY" if len(prefix) == MAX_SYMBOLS else "BOUNDED_PARTIAL"))
    print("WEAVING_SPARSE_FULL_MEDIAN_RANK_UNRANK=NOT_TESTED")


if __name__ == "__main__":
    main()
