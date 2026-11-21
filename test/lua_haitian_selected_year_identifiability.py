#!/usr/bin/env python3
"""Independent, bounded selected-year identifiability QA for PC-BRANCH-LUA-HAITIAN.

Run: python3 test/lua_haitian_selected_year_identifiability.py
Only integer arithmetic, no Lua or network. Inputs are *attested excerpts* from the
accepted 2026-11-21 radius96/4-target evidence, NOT a freshly authenticated ZIP.
This is a logical countermodel test, not a year5000 selection implementation.
"""
from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json

PROJECT = "PC-BRANCH-LUA-HAITIAN"
GEOMETRY_SHA = "6e5aeec25cae0201e3181d652e63da0642196e39b414150a748c1fe80291cbca"
FOUR_TARGET_SHA = "adda0054dbaf4b897eb13adca0df131b75a04e4a7f93fa52ee27f9a748a824fd"
GEOMETRY_ARTIFACT = 14670954537
FOUR_TARGET_ARTIFACT = 14698888975

# Directly attested radius96 gate positions: G[70], G[76].
# Four-target Native probe #1 selected 66..76, length 3630, day -15017677.
# The selected opening is derived independently: G[66] = G[76] - 3630.
G70, G76 = -15018240, -15016551
SELECTED_LENGTH = 3630
G66 = G76 - SELECTED_LENGTH
WITNESS_DAY = -15017677
FRESH_DAY = WITNESS_DAY + 1
NEGATIVE_DAYS = (
    -15033432, -15032867, -15034166, -15033568, -15034351,
    -15033701, -15017677, -15017114, -15017465, -15016813,
)

@dataclass(frozen=True)
class YearInterval:
    start_index: int
    end_index: int
    open_day: int
    close_day: int

    @property
    def length(self) -> int:
        return self.close_day - self.open_day

    @property
    def gaps(self) -> int:
        return self.end_index - self.start_index

    def includes(self, day: int) -> bool:
        return self.open_day < day <= self.close_day

    def valid(self) -> bool:
        return (isinstance(self.open_day, int)
                and isinstance(self.close_day, int)
                and self.gaps >= 6 and 252 <= self.length <= 5778)

SHORT = YearInterval(70, 76, G70, G76)
LONG = YearInterval(66, 76, G66, G76)


def minimum_months(length: int) -> int:
    if not isinstance(length, int) or length <= 0:
        raise ValueError("positive integer length required")
    return max(3, (length + 122) // 123)


def state_upper(length: int, months: int) -> int:
    if not isinstance(months, int) or months < 1:
        raise ValueError("positive integer month count required")
    return sum(max(0, min(length, 123 * k) - 4 * k + 1)
               for k in range(1, months + 1))


def ensure_sample_exclusion(samples: tuple[int, ...], day: int) -> None:
    if len(samples) != 10 or len(set(samples)) != len(samples):
        raise ValueError("ten distinct accepted negative days required")
    if day in samples:
        raise ValueError("candidate reuses an accepted Native sample")


def validate_countermodel(short: YearInterval, long: YearInterval,
                          witness_day: int, fresh_day: int,
                          samples: tuple[int, ...]) -> None:
    ensure_sample_exclusion(samples, fresh_day)
    if not short.valid() or not long.valid():
        raise ValueError("invalid year interval")
    if (short.start_index, short.end_index) != (70, 76):
        raise ValueError("short candidate must be attested 70..76")
    if (long.start_index, long.end_index) != (66, 76):
        raise ValueError("long selection must be attested 66..76")
    if short.open_day != G70 or short.close_day != G76:
        raise ValueError("short boundaries differ from accepted transcript")
    if long.close_day != G76 or long.length != SELECTED_LENGTH:
        raise ValueError("long boundaries differ from Native witness")
    if witness_day != WITNESS_DAY or witness_day not in samples:
        raise ValueError("attested selected-year witness mismatch")
    if not (short.includes(witness_day) and long.includes(witness_day)):
        raise ValueError("witness is not inside both geometric intervals")
    if not (short.includes(fresh_day) and long.includes(fresh_day)):
        raise ValueError("proposed independent day not in both intervals")
    if short.length > 16 * 123 or long.length <= 16 * 123:
        raise ValueError("intervals do not discriminate month-cap possibility")
    if not (minimum_months(short.length) <= 16
            and minimum_months(long.length) > 16):
        raise ValueError("minimum-month discriminant failed")
    # Structural feasibility only. The actual SEAL_MONTH_COUNT is NOT computed.
    if state_upper(short.length, 14) > 20000:
        raise ValueError("short interval fails arithmetic state cap")


def tests() -> int:
    checks = []
    def check(name, condition):
        if not condition:
            raise AssertionError(name)
        checks.append(name)
    def rejected(thunk):
        try:
            thunk()
        except ValueError:
            return True
        return False

    validate_countermodel(SHORT, LONG, WITNESS_DAY, FRESH_DAY, NEGATIVE_DAYS)
    check("attested gate subtraction", G66 == -15020181)
    check("attested interval lengths", (SHORT.length, LONG.length) == (1689, 3630))
    check("exact minimum month arithmetic", (minimum_months(1689), minimum_months(3630)) == (14, 30))
    check("attested selected day and fresh neighbor", SHORT.includes(WITNESS_DAY) and LONG.includes(FRESH_DAY))
    check("short opening is exclusive", not SHORT.includes(G70) and SHORT.includes(G70 + 1))
    check("short closing is inclusive", SHORT.includes(G76) and not SHORT.includes(G76 + 1))
    check("fourteen-month arithmetic state cap", state_upper(SHORT.length, 14) <= 20000)
    check("explicit 14-month partition exists", 13 * 123 + 90 == SHORT.length and 4 <= 90 <= 123)
    check("ten accepted negatives unique and excluded", len(set(NEGATIVE_DAYS)) == 10 and FRESH_DAY not in NEGATIVE_DAYS)
    check("reject old-day probe", rejected(lambda: ensure_sample_exclusion(NEGATIVE_DAYS, WITNESS_DAY)))
    check("reject duplicate accepted input", rejected(lambda: ensure_sample_exclusion(NEGATIVE_DAYS[:-1] + (NEGATIVE_DAYS[0],), FRESH_DAY)))
    check("reject false long interval", rejected(lambda: validate_countermodel(SHORT, YearInterval(66, 76, G66 + 1, G76), WITNESS_DAY, FRESH_DAY, NEGATIVE_DAYS)))
    check("reject changed short transcript boundary", rejected(lambda: validate_countermodel(YearInterval(70, 76, G70 + 1, G76), LONG, WITNESS_DAY, FRESH_DAY, NEGATIVE_DAYS)))
    check("reject non-discriminating or repeated probe", rejected(lambda: validate_countermodel(SHORT, LONG, WITNESS_DAY, G76 + 1, NEGATIVE_DAYS)))
    return len(checks)


def main() -> None:
    n = tests()
    # Countermodels agree at the ten *observed* points by definition: neither
    # alters any stored Native result. At FRESH_DAY, model A assigns the short
    # structurally possible interval, model B assigns the long observed interval.
    # This proves underdetermination by the finite evidence, not that either is
    # realizable by normative stochastic selection at that day.
    record = {
        "projectId": PROJECT,
        "inputProvenance": {
            "geometryArtifact": GEOMETRY_ARTIFACT,
            "geometryZipSha256Attested": GEOMETRY_SHA,
            "fourTargetArtifact": FOUR_TARGET_ARTIFACT,
            "fourTargetZipSha256Attested": FOUR_TARGET_SHA,
            "zipBytesReauthenticatedHere": False,
        },
        "observed": {"day": WITNESS_DAY, "selectedIndices": [66, 76],
                     "length": LONG.length, "minimumMonths": minimum_months(LONG.length)},
        "freshDay": FRESH_DAY,
        "countermodels": [
            {"selector": "A", "intervalIndices": [70, 76], "length": SHORT.length,
             "minimumMonths": minimum_months(SHORT.length),
             "hypotheticalMonths": 14, "arithmeticStateUpper": state_upper(SHORT.length, 14)},
            {"selector": "B", "intervalIndices": [66, 76], "length": LONG.length,
             "minimumMonths": minimum_months(LONG.length)},
        ],
        "sharedObservedOutcomesUnmodified": len(NEGATIVE_DAYS),
        "decision": "GEOMETRY_AND_FINITE_NEGATIVES_DO_NOT_IDENTIFY_SELECTED_YEAR",
        "scope": {"staticArithmetic": "PASS", "nativeNewTarget": "NOT_RUN",
                  "selectedYearDifferential": "NOT_VERIFIED",
                  "composition": "NOT_INVOKED", "fullDate": "NOT_RUN"},
        "testsPassed": n,
    }
    canonical = json.dumps(record, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"
    print(canonical, end="")
    print("INDEPENDENT_SELECTION_IDENTIFIABILITY_SELFTEST: %d/%d PASS" % (n, n))
    print("REPORT_SHA256: " + sha256(canonical.encode("utf-8")).hexdigest())

if __name__ == "__main__":
    main()
