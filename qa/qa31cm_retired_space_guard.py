"""QA31CM: finite retained-space ownership guard (Python 2.7/3).
Integration: intercept puts in ALL 16+15 replays; check prior spaces before
Program.__init__, after it, and after execute; retain new space only after
execute. Store returned snapshots and check counters in a separate artifact.
Standalone synthetic tests only; not integrated into Native replay yet.
Retain actual objects, not only ids; check ALL retired snapshots before
and after every subsequent reset/execute. Coverage is the provided address
set, not all possible Funge-space cells. No calendar oracle is implied.
"""
from __future__ import print_function
import json


class RetiredSpaces(object):
    def __init__(self, max_runs=31):
        self.max_runs = max_runs
        self.retired = []
        self.checks = []

    def _values(self, space, vector, positions):
        return tuple(int(space.get(vector(p))) for p in positions)

    def check(self, active, phase):
        if phase not in ('before-reset', 'after-reset', 'after-execute'):
            raise AssertionError('unknown phase')
        if phase == 'before-reset' and self.retired and active is not self.retired[-1][0]:
            raise AssertionError('unexpected pre-reset current space')
        for index, (space, vector, positions, expected) in enumerate(self.retired):
            if active is space and not (phase == 'before-reset' and index == len(self.retired)-1):
                raise AssertionError('retired space reused: %d' % index)
            actual = self._values(space, vector, positions)
            if actual != expected:
                raise AssertionError('retired space mutated: %d/%s' % (index, phase))
        self.checks.append({'phase': phase, 'retired': len(self.retired),
                            'cells': sum(len(row[2]) for row in self.retired)})

    def retain(self, space, vector, base, written):
        if len(self.retired) >= self.max_runs:
            raise AssertionError('run bound exceeded')
        if any(space is row[0] for row in self.retired):
            raise AssertionError('duplicate space identity')
        positions = tuple(sorted(set(tuple(p) for p in base) |
                                 set(tuple(p) for p in written)))
        if not positions or any(len(p) != 2 for p in positions):
            raise AssertionError('invalid snapshot positions')
        values = self._values(space, vector, positions)
        self.retired.append((space, vector, positions, values))
        return {'ordinal': len(self.retired)-1,
                'snapshot': [[list(p), str(v)] for p, v in zip(positions, values)]}


def selftest():
    class Space(object):
        def __init__(self, value):
            self.cells = {(0, 0): value, (1, 2): value + 1}
        def get(self, p):
            return self.cells.get(p, 32)
    def fixture():
        guard = RetiredSpaces()
        spaces = [Space(i) for i in range(31)]
        for i, s in enumerate(spaces):
            guard.check(spaces[i-1] if i else None, 'before-reset')
            guard.check(s, 'after-reset')
            guard.check(s, 'after-execute')
            row = guard.retain(s, tuple, [(0, 0)], [(1, 2), (0, 0)])
            assert row['snapshot'] == [[[0, 0], str(i)], [[1, 2], str(i+1)]]
        return guard, spaces
    g, spaces = fixture()
    assert sum(x['retired'] for x in g.checks) == 3 * 31 * 30 // 2
    assert sum(x['cells'] for x in g.checks) == 2790
    rejected = 0
    for victim in (0, 1, 15, 29, 30):
        for cell in ((0, 0), (1, 2)):
            h, ss = fixture()
            ss[victim].cells[cell] += 99
            try:
                h.check(Space(99), 'after-execute')
            except AssertionError:
                rejected += 1
            else:
                raise AssertionError('delayed corruption escaped')
    for victim in (0, 15, 30):
        try:
            g.check(spaces[victim], 'after-reset')
        except AssertionError:
            rejected += 1
        else:
            raise AssertionError('identity alias escaped')
    try:
        g.check(Space(99), 'before-reset')
    except AssertionError:
        rejected += 1
    else:
        raise AssertionError('unexpected pre-reset space escaped')
    assert rejected == 14
    return {'synthetic': True, 'runs': 31, 'phase_checks': len(g.checks),
            'retired_space_comparisons': 1395, 'cell_comparisons': 2790,
            'negative_controls_rejected': rejected, 'native': False}


if __name__ == '__main__':
    print(json.dumps(selftest(), sort_keys=True))
