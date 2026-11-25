#!/usr/bin/env python3
"""DISCOVERY24 in-place insertion-prefix feasibility audit.

TEST/QA ONLY. No Clojure import, production edit, CI dispatch or date claim.
The alternative algorithm counts one DP cell for each computed distribution
entry. That metric is deliberately kept separate from production's shared
prefix-cell accounting; matching the numeric ceiling does not make the units
interchangeable.
"""
import argparse
from functools import lru_cache
from hashlib import sha1, sha256
from itertools import permutations
from math import comb
import json
import sys
import zipfile

PROJECT_ID = "PC-BRANCH-CLOJURE-DUTCH"
CANONICAL_SOURCE_SHA = "ec0051ec6335fe178c03bcf3583b3dbfec1ffa84"
CANONICAL_ARTIFACT_SHA256 = "eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5"
P520_WITNESS_SHA256 = "13a4d2855eb71dae4a3d2f526e68b6301bf41880cab9388c495226ca2202ccd4"
P520_WITNESS_COMMIT = "faa37816ae4e1384e019d406c62415af7ab028b6"
CURRENT_PRODUCTION_BLOB = "62f304dc013a9a9f70475bb0d34f186838b27318"
SEARCH_BUDGET = 128
BUDGET = 5_000_000
P81_SHA256 = "2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a"

CELL_WRITES = 0
CELL_LIMIT = BUDGET


def _write_cell():
    global CELL_WRITES
    CELL_WRITES += 1
    if CELL_WRITES > CELL_LIMIT:
        raise RuntimeError("ALTERNATIVE_DP_CELL_WRITE_BUDGET_EXCEEDED")


@lru_cache(maxsize=2048)
def tail_factor_inplace(active_days, unopened_counts, first_constrained=False):
    """Exact insertion distribution, updated in place from right to left."""
    if not unopened_counts:
        return 1
    n = active_days
    dp = None
    total = 1
    for step, k in enumerate(unopened_counts):
        constrained = bool(step > 0 or first_constrained)
        if dp is None:
            dp = [0] * (n + k + 1)
            weight = 1
            for a in range(n, -1, -1):
                t = n - a
                if k >= 2:
                    if t:
                        weight = weight * (t + k - 2) // t
                    ways = weight
                else:
                    ways = 1 if t == 0 else 0
                factor = (1 if a >= 1 else 0) if constrained else total
                dp[a + 1] = factor * ways
                _write_cell()
            total = sum(dp)
        else:
            # dp[a] is read before dp[a+1] overwrites it; descending order
            # preserves every old value needed by the prefix-sum recurrence.
            dp.extend([0] * k)
            prefix = total
            new_total = 0
            weight = 1
            for a in range(n, -1, -1):
                t = n - a
                if k >= 2:
                    if t:
                        weight = weight * (t + k - 2) // t
                    ways = weight
                else:
                    ways = 1 if t == 0 else 0
                old = dp[a]
                factor = prefix if constrained else total
                value = factor * ways
                dp[a + 1] = value
                new_total += value
                _write_cell()
                if constrained:
                    prefix -= old
            dp[0] = 0
            total = new_total
        n += k
    return total


@lru_cache(maxsize=2048)
def suffix_count_inplace(state):
    counts, opened, closed = state
    m = len(counts)
    if not (0 <= closed <= opened <= m):
        raise ValueError("invalid grammar indices")
    if any(counts[:closed]) or any(k < 1 for k in counts[closed:]):
        raise ValueError("unreachable live counts")
    if closed == m:
        return 1
    base = 1
    active_days = counts[closed]
    if opened == closed:
        return tail_factor_inplace(active_days, tuple(counts[closed + 1:]), True)
    for i in range(closed + 1, opened):
        amount = counts[i]
        active_days += amount
        base *= comb(active_days - 1, amount - 1)
    return base * tail_factor_inplace(active_days, tuple(counts[opened:]))


def moves(state):
    counts, opened, closed = state
    m = len(counts)
    for i in range(min(m, opened + 1)):
        before = counts[i]
        if before == 0 or (before == 1 and i != closed):
            continue
        child = list(counts)
        child[i] -= 1
        yield i + 1, (tuple(child), max(opened, i + 1), closed + int(before == 1))


def git_blob_sha(data):
    return sha1(b"blob " + str(len(data)).encode("ascii") + b"\\0" + data).hexdigest()


def production_charge(counts, opened):
    # Algebraically identical to source:
    # 1 + (m-opened) * (1 + (sum(rest)-1)).
    return 1 + (len(counts) - opened) * sum(counts)


def rank_trace_inplace(profile, ordinal, target, *, production_budget=None):
    global CELL_WRITES
    if len(profile) < 2 or any(k < 2 for k in profile):
        raise ValueError("invalid initial profile")
    if not (1 <= target <= sum(profile)):
        raise ValueError("invalid target position")
    root = (tuple(profile), 0, 0)
    total = suffix_count_inplace(root)
    if not (1 <= ordinal <= total):
        raise ValueError("rank outside legal language")
    state = dict(moves(root))[1]  # mandatory first month 1 is free
    rank = ordinal
    prefix = [1]
    billed = tested = skipped = active_groups = new_groups = 0
    snapshots = {}
    while len(prefix) < target:
        counts, opened, closed = state
        legal = list(moves(state))
        active = [(letter, child) for letter, child in legal if letter <= opened]
        new = [(letter, child) for letter, child in legal if letter == opened + 1]
        found = False
        if active:
            charge = production_charge(counts, opened)
            if production_budget is not None and billed + charge > production_budget:
                return dict(status="PRODUCTION_BUDGET_REFUSAL", prefix=prefix,
                            prefix_length=len(prefix), billed_before=billed,
                            required_next=billed + charge, next_charge=charge,
                            refusal_position=len(prefix) + 1, group="ACTIVE",
                            tested=tested, skipped=skipped)
            billed += charge
            active_groups += 1
            for letter, child in active:
                block = suffix_count_inplace(child)
                tested += 1
                if rank > block:
                    rank -= block
                    skipped += 1
                else:
                    prefix.append(letter)
                    state = child
                    found = True
                    break
        if not found and new:
            charge = 1 + (len(profile) - opened - 1) * sum(counts)
            if production_budget is not None and billed + charge > production_budget:
                return dict(status="PRODUCTION_BUDGET_REFUSAL", prefix=prefix,
                            prefix_length=len(prefix), billed_before=billed,
                            required_next=billed + charge, next_charge=charge,
                            refusal_position=len(prefix) + 1, group="NEW",
                            tested=tested, skipped=skipped)
            billed += charge
            new_groups += 1
            letter, child = new[0]
            block = suffix_count_inplace(child)
            tested += 1
            if rank > block:
                raise AssertionError("new candidate block is too small")
            prefix.append(letter)
            state = child
            found = True
        if not found:
            raise AssertionError(("no legal candidate", len(prefix), rank))
        if len(prefix) in (81, 82, 520):
            snapshots[len(prefix)] = dict(
                prefix=prefix.copy(),
                prefix_sha256=sha256(",".join(map(str, prefix)).encode("ascii")).hexdigest(),
                month_id=prefix[-1],
                day_in_month=prefix.count(prefix[-1]),
                production_shared_cost=billed,
                dp_cell_writes=CELL_WRITES,
                tested=tested,
                skipped=skipped,
                opened=state[1],
                closed=state[2],
            )
    return dict(status="PREFIX_CERTIFIED", total=total, snapshots=snapshots,
                prefix=prefix.copy(), billed=billed, tested=tested, skipped=skipped,
                active_groups=active_groups, new_groups=new_groups,
                dp_cell_writes=CELL_WRITES, residual_rank_digits=len(str(rank)))


def brute_legal_words(profile):
    remaining = list(profile)
    result = []
    target_len = sum(profile)

    def visit(word):
        if len(word) == target_len:
            first = [word.index(i) for i in range(1, len(profile) + 1)]
            last = [len(word) - 1 - word[::-1].index(i)
                    for i in range(1, len(profile) + 1)]
            if first == sorted(first) and last == sorted(last):
                result.append(tuple(word))
            return
        for i, amount in enumerate(remaining):
            if amount:
                remaining[i] -= 1
                visit(word + [i + 1])
                remaining[i] += 1

    visit([])
    return sorted(result)


def small_family_tests():
    global CELL_WRITES
    profiles = ((2, 2), (2, 3), (3, 2), (2, 2, 2), (2, 3, 2),
                (3, 2, 2), (2, 2, 2, 2), (4, 4))
    words_total = rank_position_checks = exact_budget_accepts = minus_one_refusals = 0
    for profile in profiles:
        suffix_count_inplace.cache_clear()
        tail_factor_inplace.cache_clear()
        CELL_WRITES = 0
        words = brute_legal_words(profile)
        words_total += len(words)
        assert suffix_count_inplace((tuple(profile), 0, 0)) == len(words)
        for rank, word in enumerate(words, 1):
            for position in range(1, len(word) + 1):
                full = rank_trace_inplace(profile, rank, position)
                assert full["status"] == "PREFIX_CERTIFIED"
                assert full["prefix"] == list(word[:position])
                # The rank path must match every independently enumerated word.
                rank_position_checks += 1
                exact = rank_trace_inplace(profile, rank, position,
                                           production_budget=full["billed"])
                assert exact["status"] == "PREFIX_CERTIFIED"
                assert exact["prefix"] == full["prefix"]
                exact_budget_accepts += 1
                if full["billed"] > 0:
                    below = rank_trace_inplace(profile, rank, position,
                                               production_budget=full["billed"] - 1)
                    assert below["status"] == "PRODUCTION_BUDGET_REFUSAL"
                    minus_one_refusals += 1
    return dict(profiles=len(profiles), legal_words=words_total,
                rank_position_checks=rank_position_checks,
                exact_budget_accepts=exact_budget_accepts,
                budget_minus_one_refusals=minus_one_refusals)


@lru_cache(maxsize=1024)
def gap_factor(length, future, must_follow_first):
    if not future:
        return 1
    histogram = [0, 1] if must_follow_first else None
    for amount in future:
        coeff = [1] * (length + 1)
        if amount >= 2:
            for idx in range(1, length + 1):
                coeff[idx] = coeff[idx - 1] * (idx + amount - 2) // idx
        nxt = [0] * (length + amount + 1)
        running = 0
        for gap in range(length + 1):
            if histogram is None:
                possibilities = 1
            else:
                if gap < len(histogram):
                    running += histogram[gap]
                possibilities = running
            ways = 1 if gap == length else (coeff[length - gap] if amount >= 2 else 0)
            nxt[gap + 1] = possibilities * ways
        histogram = nxt
        length += amount
    return sum(histogram)


@lru_cache(maxsize=1800)
def convolution_count(state):
    rest, opened, closed = state
    if not any(rest):
        return 1
    if opened == closed:
        return gap_factor(rest[closed], rest[closed + 1:], True)
    active_days = rest[closed]
    active_factor = 1
    for label in range(closed + 1, opened):
        amount = rest[label]
        active_days += amount
        active_factor *= comb(active_days - 1, amount - 1)
    return active_factor * gap_factor(active_days, rest[opened:], False)


def rank_trace_convolution(profile, ordinal, target):
    root = (tuple(profile), 0, 0)
    total = convolution_count(root)
    state = dict(moves(root))[1]
    rank = ordinal
    prefix = [1]
    billed = tested = skipped = active_groups = new_groups = 0
    snapshots = {}
    while len(prefix) < target:
        counts, opened, closed = state
        legal = list(moves(state))
        active = [(letter, child) for letter, child in legal if letter <= opened]
        new = [(letter, child) for letter, child in legal if letter == opened + 1]
        found = False
        if active:
            billed += production_charge(counts, opened)
            active_groups += 1
            for letter, child in active:
                block = convolution_count(child)
                tested += 1
                if rank > block:
                    rank -= block
                    skipped += 1
                else:
                    prefix.append(letter)
                    state = child
                    found = True
                    break
        if not found and new:
            billed += 1 + (len(profile) - opened - 1) * sum(counts)
            new_groups += 1
            letter, child = new[0]
            block = convolution_count(child)
            tested += 1
            if rank > block:
                raise AssertionError("new candidate block is too small")
            prefix.append(letter)
            state = child
            found = True
        if not found:
            raise AssertionError(("no legal candidate", len(prefix), rank))
        if len(prefix) in (81, 82, 520):
            snapshots[len(prefix)] = dict(
                prefix=prefix.copy(),
                prefix_sha256=sha256(",".join(map(str, prefix)).encode("ascii")).hexdigest(),
                month_id=prefix[-1],
                day_in_month=prefix.count(prefix[-1]),
                production_shared_cost=billed,
                tested=tested,
                skipped=skipped,
            )
    return total, snapshots, dict(billed=billed, tested=tested, skipped=skipped,
                                  active_groups=active_groups, new_groups=new_groups)


def verify_p520_artifact(path):
    raw = open(path, "rb").read()
    digest = sha256(raw).hexdigest()
    assert digest == P520_WITNESS_SHA256, "p520 witness ZIP digest mismatch"
    with zipfile.ZipFile(path) as archive:
        assert archive.namelist() == ["discovery24_canonical_plus17_feasibility.edn"]
        edn = archive.read(archive.namelist()[0]).decode("utf-8")
    required = (
        ":stage2-accepted? false",
        ":search-budget 128N",
        ":case :canonical-shifted-plus17",
        ":probe-status :geweigerd",
        ":selective-prefix-cell-cost :not-proven",
        ":five-fields-proven? false",
        ":code :bounded-prefix-budget-unproven",
        ":target-year 5000N",
        ":position-1-based 520N",
        ":selective-prefix-budget 5000000N",
        f':github-sha "{P520_WITNESS_COMMIT}"',
    )
    for fragment in required:
        assert fragment in edn, f"p520 artifact missing {fragment!r}"
    return dict(zip_sha256=digest, github_sha=P520_WITNESS_COMMIT,
                status="geweigerd", refusal="bounded-prefix-budget-unproven",
                requested_position=520, search_budget=SEARCH_BUDGET,
                production_cell_budget=BUDGET, five_fields_proven=False,
                stage2_accepted=False)


def canonical_audit(canonical_zip, p520_zip, source_path=None):
    raw = open(canonical_zip, "rb").read()
    digest = sha256(raw).hexdigest()
    assert digest == CANONICAL_ARTIFACT_SHA256, "canonical ZIP digest mismatch"
    with zipfile.ZipFile(canonical_zip) as archive:
        data = json.loads(archive.read("discovery24_canonical_dp_input.json"))
        old = json.loads(archive.read("discovery24_canonical_dp_result.json"))
    assert data["project_id"] == PROJECT_ID
    assert data["source_sha"] == CANONICAL_SOURCE_SHA
    assert old["source_sha"] == CANONICAL_SOURCE_SHA
    assert old["status"] == "DP_FEASIBILITY_UNPROVEN"
    assert data["production_year_matches_normative"] is True
    assert data["production_profile_matches_normative"] is True
    assert data["production_rank_matches_normative"] is True
    profile = tuple(data["profile"])
    rank = int(data["weaving_rank"])
    recorded_total = int(data["weaving_total"])
    assert (len(profile), sum(profile), len(data["weaving_rank"]),
            data["search_budget"]) == (33, 3569, 5288, SEARCH_BUDGET)
    assert data["production_weaving_rank"] == data["weaving_rank"]

    global CELL_WRITES, CELL_LIMIT
    suffix_count_inplace.cache_clear()
    tail_factor_inplace.cache_clear()
    CELL_WRITES = 0
    CELL_LIMIT = BUDGET
    alternative = rank_trace_inplace(profile, rank, 520)
    assert alternative["total"] == recorded_total
    assert alternative["dp_cell_writes"] <= BUDGET
    snaps = alternative["snapshots"]
    assert snaps[81]["prefix_sha256"] == P81_SHA256
    assert snaps[82]["production_shared_cost"] == 5_002_652
    assert snaps[82]["prefix_sha256"] == "3408b680fac534e4c34ef0d123b6f09e05314be31210d82f14d2a61e84d8c219"
    assert snaps[520]["prefix_sha256"] == "65c683810ee69f740e38334bbc67969d4ac429bc7d7943646a2a02aa14d8ae0b"
    assert snaps[81]["production_shared_cost"] == 4_995_675
    assert snaps[520]["production_shared_cost"] == 5_218_257

    # Second exact counter: a separate gap-convolution decomposition.
    convolution_count.cache_clear()
    other_total, other_snaps, other_work = rank_trace_convolution(profile, rank, 520)
    assert other_total == recorded_total
    for pos in (81, 82, 520):
        assert other_snaps[pos]["prefix_sha256"] == snaps[pos]["prefix_sha256"]
        assert other_snaps[pos]["production_shared_cost"] == snaps[pos]["production_shared_cost"]
        assert other_snaps[pos]["month_id"] == snaps[pos]["month_id"]
        assert other_snaps[pos]["day_in_month"] == snaps[pos]["day_in_month"]

    source_blob_verified = False
    if source_path is not None:
        source_bytes = open(source_path, "rb").read()
        assert git_blob_sha(source_bytes) == CURRENT_PRODUCTION_BLOB, "current production source blob mismatch"
        source_blob_verified = True
    p520_artifact = verify_p520_artifact(p520_zip)
    return dict(
        project_id=PROJECT_ID,
        canonical_source_sha=CANONICAL_SOURCE_SHA,
        current_production_blob=CURRENT_PRODUCTION_BLOB,
        current_production_blob_verified=source_blob_verified,
        canonical_artifact_sha256=digest,
        profile_months=len(profile),
        profile_days=sum(profile),
        rank_digits=len(data["weaving_rank"]),
        search_budget=SEARCH_BUDGET,
        production_budget=BUDGET,
        p81=dict(prefix_sha256=snaps[81]["prefix_sha256"],
                 production_shared_cost=snaps[81]["production_shared_cost"]),
        p82=dict(prefix_sha256=snaps[82]["prefix_sha256"],
                 month_id=snaps[82]["month_id"],
                 day_in_month=snaps[82]["day_in_month"],
                 alternative_dp_cell_writes=snaps[82]["dp_cell_writes"],
                 production_shared_cost=snaps[82]["production_shared_cost"],
                 production_budget_exceeded=True),
        p520=dict(prefix_sha256=snaps[520]["prefix_sha256"],
                  month_id=snaps[520]["month_id"],
                  day_in_month=snaps[520]["day_in_month"],
                  alternative_dp_cell_writes=snaps[520]["dp_cell_writes"],
                  production_shared_cost=snaps[520]["production_shared_cost"],
                  production_budget_exceeded=True),
        alternative_dp_cell_write_budget=BUDGET,
        alternative_dp_cell_writes=alternative["dp_cell_writes"],
        alternative_dp_cell_budget_remaining=BUDGET-alternative["dp_cell_writes"],
        independent_gap_convolution_match=True,
        gap_convolution_work=other_work,
        p520_historical_production_artifact=p520_artifact,
        five_field_differential="NOT_RUN",
        native_for_this_new_model="NOT_RUN",
        stage2="OPEN",
    )


def main():
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(25000)
    parser = argparse.ArgumentParser()
    parser.add_argument("--canonical-artifact-zip", required=True)
    parser.add_argument("--p520-witness-zip", required=True)
    parser.add_argument("--source", help="optional current production source path for Git-blob verification")
    args = parser.parse_args()
    small = small_family_tests()
    canonical = canonical_audit(args.canonical_artifact_zip, args.p520_witness_zip, args.source)
    print(json.dumps(dict(result="PASS_MODEL_ONLY", small_families=small,
                          canonical=canonical), sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
