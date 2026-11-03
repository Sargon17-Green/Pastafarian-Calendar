#!/usr/bin/env python3
"""Independent exact legal-month-weaving oracle, Kotlin+Cymraeg research.

Both first occurrences and last occurrences of month labels are ordered.
The suffix count is obtained from a closed binomial insertion sum, NOT from
the production Kotlin transition-ratio/unranking engine. We independently
verify the count using exhaustive word enumeration on small instances.

This is a COMPONENT oracle. It neither computes the 5000-year anchor nor
certifies the full five-field TABLETS date. Fail closed on input/work budgets.
"""
from __future__ import annotations
from dataclasses import dataclass
from math import comb

class MonthWeavingOracleError(ValueError):
    pass

@dataclass(frozen=True)
class MonthDay:
    ordinal: int
    day_in_month: int

class IndependentMonthWeavingOracle:
    def __init__(self, lengths: tuple[int, ...], *,
                 max_states: int = 250000, max_branches: int = 4000000):
        if (type(lengths) is not tuple or not 1 <= len(lengths) <= 47
                or any(type(v) is not int or not 1 <= v <= 123 for v in lengths)
                or not 1 <= sum(lengths) <= 5778
                or type(max_states) is not int or not 1 <= max_states <= 250000
                or type(max_branches) is not int or not 1 <= max_branches <= 4000000):
            raise MonthWeavingOracleError("E_WEAVE_INPUT")
        self.lengths = lengths
        self.total_days = sum(lengths)
        self.max_states = max_states
        self.max_branches = max_branches
        self.branch_ops = 0
        # For each unopened suffix j, H[j][s] counts ways of inserting j..
        # after any fixed legal active-word prefix of length s.
        # Its value depends ONLY on s, not the active-word shape.
        prefix = [0]
        for size in lengths:
            prefix.append(prefix[-1] + size)
        rows: list[tuple[int, ...]] = [()] * (len(lengths) + 1)
        rows[len(lengths)] = (1,) * (self.total_days + 1)
        states = len(rows[-1])
        if states > max_states:
            raise MonthWeavingOracleError("E_WEAVE_STATE_BUDGET")
        for j in range(len(lengths) - 1, -1, -1):
            L = lengths[j]
            smax = prefix[j]
            states += smax + 1
            if states > max_states:
                raise MonthWeavingOracleError("E_WEAVE_STATE_BUDGET")
            next_row = rows[j + 1]
            if L == 1:
                row = (next_row[0],) * (smax + 1)
            else:
                # Direct combinatorial insertion sum:
                # H_j(s) = sum_{t=0}^s C(t+L-2, L-2) H_(j+1)(t+L-1).
                # Derived by choosing the positions of L-1 surviving tokens
                # before the final close, while old open months close first.
                running = 0
                items = []
                for s in range(smax + 1):
                    running += comb(s + L - 2, L - 2) * next_row[s + L - 1]
                    items.append(running)
                row = tuple(items)
            rows[j] = row
        self._suffix = tuple(rows)
        if self._suffix[0][0] < 1:
            raise MonthWeavingOracleError("E_WEAVE_EMPTY")

    def count_all(self) -> int:
        return self._suffix[0][0]

    def _state_count(self, remaining: tuple[int, ...], opened: int, closed: int) -> int:
        if not 0 <= closed <= opened <= len(remaining):
            raise MonthWeavingOracleError("E_WEAVE_STATE")
        if any(remaining[i] != 0 for i in range(closed)):
            raise MonthWeavingOracleError("E_WEAVE_STATE")
        if any(not 1 <= remaining[i] <= self.lengths[i] for i in range(closed, opened)):
            raise MonthWeavingOracleError("E_WEAVE_STATE")
        if any(remaining[i] != self.lengths[i] for i in range(opened, len(remaining))):
            raise MonthWeavingOracleError("E_WEAVE_STATE")
        # Ordered last occurrences: all active interleavings are counted by
        # a product of interleaving binomial coefficients.
        active = 0
        interleavings = 1
        for i in range(closed, opened):
            size = remaining[i]
            if active:
                interleavings *= comb(active + size - 1, size - 1)
            active += size
        row = self._suffix[opened]
        if active >= len(row):
            raise MonthWeavingOracleError("E_WEAVE_SUFFIX_RANGE")
        return interleavings * row[active]

    def _children(self, remaining: tuple[int, ...], opened: int, closed: int):
        # A month must open in order; its last token must close in order.
        # Every legal choice is yielded lexicographically.
        for i in range(closed, opened):
            if remaining[i] == 1 and i != closed:
                continue
            child = list(remaining)
            child[i] -= 1
            yield (i, tuple(child), opened,
                   closed + 1 if child[i] == 0 else closed)
        if opened < len(remaining):
            i = opened
            if remaining[i] > 1 or opened == closed:
                child = list(remaining)
                child[i] -= 1
                yield (i, tuple(child), opened + 1,
                       closed + 1 if child[i] == 0 else closed)

    def day_at(self, rank1: int, offset0: int) -> MonthDay:
        total = self.count_all()
        if (type(rank1) is not int or not 1 <= rank1 <= total
                or type(offset0) is not int or not 0 <= offset0 < self.total_days):
            raise MonthWeavingOracleError("E_WEAVE_SELECTION_RANGE")
        remaining = self.lengths
        opened = closed = 0
        rank = rank1
        parent = total
        chosen = -1
        for _ in range(offset0 + 1):
            found = False
            observed = 0
            for label, child, j, k in self._children(remaining, opened, closed):
                self.branch_ops += 1
                if self.branch_ops > self.max_branches:
                    raise MonthWeavingOracleError("E_WEAVE_BRANCH_BUDGET")
                ways = self._state_count(child, j, k)
                if not 0 < ways <= parent:
                    raise MonthWeavingOracleError("E_WEAVE_BRANCH_COUNT")
                observed += ways
                if rank > ways:
                    rank -= ways
                    continue
                remaining, opened, closed, parent, chosen = child, j, k, ways, label
                found = True
                break
            if not found:
                raise MonthWeavingOracleError("E_WEAVE_UNRANK")
        return MonthDay(chosen + 1, self.lengths[chosen] - remaining[chosen])

    def full_word(self, rank1: int) -> tuple[int, ...]:
        if self.total_days > 128:
            raise MonthWeavingOracleError("E_WEAVE_FULL_WORD_BUDGET")
        if type(rank1) is not int or not 1 <= rank1 <= self.count_all():
            raise MonthWeavingOracleError("E_WEAVE_SELECTION_RANGE")
        # Independent prefix walk, rather than calling day_at for each offset.
        remaining = self.lengths
        opened = closed = 0
        rank = rank1
        words = []
        for _ in range(self.total_days):
            for i, child, j, k in self._children(remaining, opened, closed):
                self.branch_ops += 1
                if self.branch_ops > self.max_branches:
                    raise MonthWeavingOracleError("E_WEAVE_BRANCH_BUDGET")
                block = self._state_count(child, j, k)
                if rank > block:
                    rank -= block
                else:
                    remaining, opened, closed = child, j, k
                    words.append(i + 1)
                    break
            else:
                raise MonthWeavingOracleError("E_WEAVE_UNRANK")
        if any(remaining) or opened != len(self.lengths) or closed != opened:
            raise MonthWeavingOracleError("E_WEAVE_POSTCONDITION")
        return tuple(words)
