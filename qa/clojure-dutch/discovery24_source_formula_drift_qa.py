#!/usr/bin/env python3
"""DISCOVERY24: source-pinned, mutation-tested shared-billing QA; MODEL ONLY.

Run from a checkout: python qa/clojure-dutch/discovery24_source_formula_drift_qa.py
The program will not accept a different production Git blob, even if equivalent.
No Clojure interpreter, CI, Native or five-field test is invoked.
"""
import argparse
import hashlib
import json
from pathlib import Path

PROJECT_ID = 'PC-BRANCH-CLOJURE-DUTCH'
PRODUCTION_BLOB = '62f304dc013a9a9f70475bb0d34f186838b27318'
BUDGET = 5000000
FUNCTIONS = {
    'prefix-gedeelde-raming': (
        '(dec (reduce +\' 0N restvector))',
        "(+' 1N (*' (- (count restvector) geopend)",
        '(inc resterende-dagen))',
    ),
    'prefix-legale-kandidaten': (
        '(pos? aantal)',
        '(or (> aantal 1) (= maand (inc gesloten)))',
        '(range 1 (inc (min (count restvector) (inc geopend))))',
    ),
    'prefix-volgende-keuze': (
        '(prefix-legale-kandidaten restvector geopend gesloten)',
        '(filterv #(<= % geopend) kandidaten)',
        '(prefix-gedeelde-raming restvector geopend)',
        '(prefix-gedeelde-raming restvector nieuw-geopend)',
        '(when (> nieuw begroting)',
        '(when (> nieuw-kosten begroting)',
        '(if (> r (:blok blok))',
        '(if (> r (:blok blok))',
        ':bounded-prefix-budget-unproven',
        ':bounded-prefix-invalid-count',
    ),
}


def git_blob_sha(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def definition(source, name):
    """Extract exactly one balanced Clojure defn, ignoring string/comment parentheses."""
    import re
    pattern = re.compile(r'(?m)^\(defn-?\s+' + re.escape(name) + r'(?=\s|\[)')
    matches = list(pattern.finditer(source))
    if len(matches) != 1:
        raise AssertionError(f'{name}: expected one definition, found {len(matches)}')
    start = matches[0].start()
    depth = 0
    quoted = escaped = comment = False
    for i in range(start, len(source)):
        c = source[i]
        if comment:
            if c == '\n':
                comment = False
            continue
        if quoted:
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == '"':
                quoted = False
            continue
        if c == ';':
            comment = True
        elif c == '"':
            quoted = True
        elif c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth < 0:
                raise AssertionError(f'{name}: unmatched close')
            if depth == 0:
                return source[start:i + 1]
    raise AssertionError(f'{name}: unterminated definition')


def source_guard(data, require_blob=True):
    if require_blob and git_blob_sha(data) != PRODUCTION_BLOB:
        raise AssertionError('FAIL-CLOSED: production Git blob changed')
    source = data.decode('utf-8', errors='strict').replace('\r\n', '\n')
    forms = {}
    for name, clauses in FUNCTIONS.items():
        form = definition(source, name)
        for clause in set(clauses):
            if clause not in form:
                raise AssertionError(f'{name}: missing/altered source clause {clause!r}')
        # Boundary guard: both the active and new group have their own strict > test.
        if name == 'prefix-volgende-keuze' and form.count('(when (> ') != 2:
            raise AssertionError('Expected exactly two strict over-budget guards')
        forms[name] = hashlib.sha256(form.encode()).hexdigest()
    return forms


def legal_candidates(residual, opened, closed):
    return [month for month in range(1, min(len(residual), opened + 1) + 1)
            if residual[month - 1] > 0 and
            (residual[month - 1] > 1 or month == closed + 1)]


def charge(residual, opened):
    # Independent arithmetic from the source text: R is the count before choice.
    return 1 + (len(residual) - opened) * sum(residual)


def billed_transition(residual, opened, closed, selected, previous, budget=BUDGET,
                      *, active_multiplier=1, new_uses_old_opened=False,
                      wrong_threshold=False, allow_illegal=False):
    candidates = legal_candidates(residual, opened, closed)
    if not allow_illegal and selected not in candidates:
        raise ValueError('illegal candidate')
    active = [c for c in candidates if c <= opened]
    spent = previous + (active_multiplier * charge(residual, opened) if active else 0)
    if wrong_threshold and spent >= budget or not wrong_threshold and spent > budget:
        raise OverflowError('active budget refused')
    if selected == opened + 1:
        spent += charge(residual, opened if new_uses_old_opened else opened + 1)
        if wrong_threshold and spent >= budget or not wrong_threshold and spent > budget:
            raise OverflowError('new month budget refused')
    return spent


def model_mutation_tests():
    checks = 0
    # A full legal prefix: [1] on (2,2,2) leaves all three months in play.
    residual, opened, closed = (1, 2, 2), 1, 0
    assert legal_candidates(residual, opened, closed) == [1, 2]; checks += 1
    base = billed_transition(residual, opened, closed, 2, 0)
    assert base == charge(residual, 1) + charge(residual, 2)
    assert base == (1 + 2 * 5) + (1 + 1 * 5); checks += 1
    assert billed_transition(residual, opened, closed, 1, 0) == 11; checks += 1
    # Per-active-candidate accounting and old-opened new-group accounting are killed.
    assert billed_transition(residual, opened, closed, 2, 0, active_multiplier=2) != base; checks += 1
    assert billed_transition(residual, opened, closed, 2, 0, new_uses_old_opened=True) != base; checks += 1
    # Close order: month 2 with a single remaining letter is not yet legal.
    assert legal_candidates((1, 1, 2), 2, 0) == [1, 3]; checks += 1
    try:
        billed_transition((1, 1, 2), 2, 0, 2, 0)
    except ValueError:
        checks += 1
    else:
        raise AssertionError('illegal close was accepted')
    # Strict >, not >=, at both budget boundaries; cost-minus-one must fail.
    for sel in (1, 2):
        exact = billed_transition(residual, opened, closed, sel, 0)
        assert billed_transition(residual, opened, closed, sel, 0, budget=exact) == exact; checks += 1
        try:
            billed_transition(residual, opened, closed, sel, 0, budget=exact - 1)
        except OverflowError:
            checks += 1
        else:
            raise AssertionError('cost-minus-one accepted')
        try:
            billed_transition(residual, opened, closed, sel, 0, budget=exact,
                              wrong_threshold=True)
        except OverflowError:
            checks += 1
        else:
            raise AssertionError('mutated >= boundary was not detected')
    # Frozen 82nd-position active-group witness; not a Native observation.
    active_cost = 1 + (33 - 31) * 3488
    assert active_cost == 6977
    assert 4995675 + active_cost == 5002652 > BUDGET; checks += 1
    assert 4995675 + (active_cost - 1) == 5002651 > BUDGET; checks += 1
    return checks


def source_mutation_tests(data):
    # Mutants must be rejected by the whole-blob guard; the semantic clauses
    # also reject changes when exercised without the blob gate.
    source = data.decode('utf-8', 'strict')
    mutants = [
        ("(+' 1N (*' (- (count restvector) geopend)", "(+' 2N (*' (- (count restvector) geopend)"),
        ('(pos? aantal)', '(>= aantal 0)'),
        ('(or (> aantal 1) (= maand (inc gesloten)))', '(or (>= aantal 1) (= maand (inc gesloten)))'),
        ('(when (> nieuw begroting)', '(when (>= nieuw begroting)'),
        ('(when (> nieuw-kosten begroting)', '(when (>= nieuw-kosten begroting)'),
    ]
    for before, after in mutants:
        if before not in source:
            raise AssertionError(f'mutation anchor not found: {before}')
        changed = source.replace(before, after, 1).encode()
        for pin in (True, False):
            try:
                source_guard(changed, require_blob=pin)
            except AssertionError:
                pass
            else:
                raise AssertionError(f'mutant escaped source guard: {before!r}, pin={pin}')
    return len(mutants) * 2


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path,
                        default=Path(__file__).resolve().parents[2] / 'src/pastafari/maandrang.clj')
    args = parser.parse_args()
    data = args.source.read_bytes()  # Missing files also fail closed.
    forms = source_guard(data)
    checks = source_mutation_tests(data)
    model = model_mutation_tests()
    print(json.dumps(dict(project_id=PROJECT_ID, result='PASS', scope='STATIC_PLUS_MODEL_ONLY',
                          source_blob=git_blob_sha(data), function_sha256=forms,
                          source_mutations_rejected=checks, model_assertions=model,
                          canonical_prefix_sha256='2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a',
                          p82_billed_before=4995675, p82_billed_after=5002652,
                          ci='NOT_RUN', native='NOT_RUN', five_field='NOT_RUN', stage2='OPEN'),
                     sort_keys=True))


if __name__ == '__main__':
    main()
