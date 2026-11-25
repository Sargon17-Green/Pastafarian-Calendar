#!/usr/bin/env python3
"""DISCOVERY24: source-pinned, mutation-tested shared-billing QA; MODEL ONLY.

Run from a checkout: python qa/clojure-dutch/discovery24_source_formula_drift_qa.py
The program will not accept a different production Git blob, even if equivalent.
No Clojure interpreter, CI, Native or five-field test is invoked.
"""
import argparse
from collections import Counter
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
        "(+' kosten (prefix-gedeelde-raming restvector geopend))",
        "(+' actieve-kosten\n                    (prefix-gedeelde-raming restvector nieuw-geopend))",
        "(recur (rest over) (-' r (:blok blok)))",
        "(assoc blok :rang r :kosten actieve-kosten)",
        "(assoc blok :rang r :kosten nieuw-kosten)",
        "(if (seq actieve)\n          (let",
        "(if (seq actieve)\n                  (prefix-actieve-blokken",
        "(boolean (some #(= % (inc geopend)) kandidaten))",
        "(if nieuw-maand?\n          (let",
        "(if (seq over)\n        (let",
        "(if (> r (:blok blok))\n                (fout :bounded-prefix-invalid-count)",
        "(fout :bounded-prefix-invalid-count))))))",
        "[nieuw-geopend (inc geopend)",
        "nieuw)\n          kosten)",
        ':bounded-prefix-budget-unproven',
        ':bounded-prefix-invalid-count',
    ),
    'prefix-op-rang-begrensd': (
        "(if (> plaats positie)",
        "[plaats 2",
        "(recur (inc plaats)",
        "restvector (update begin 0 dec)",
        "geopend 1 gesloten 0",
        "huidige-rang rang kosten 0N prefix [1N]",
        "restvector geopend gesloten huidige-rang begroting kosten)",
        "(:restvector keuze)",
        "(:geopend keuze)",
        "(:gesloten keuze)",
        "(:rang keuze)",
        "(:kosten keuze)",
        "(conj prefix (bigint (:maand keuze)))",
        "(let [maand (peek prefix)]",
        ":month-id maand",
        "(filter #(= maand %) prefix)",
        ":month-prefix prefix",
        ":prefix-position (bigint positie)",
        ":prefix-cell-upper-bound kosten",
        ":date-proof-scope :bounded-prefix-only",
        ":month-weaving-computed? false",
        "(prefix-op-rang-begrensd lengtes rang positie hoogste-begroting)",
        "(when-not (and (vector? lengtes) (<= 2 (count lengtes) 47)\n                  (every? #(and (integer? %) (<= 4N % 123N)) lengtes))\n     (fout :invalid-prefix-profile))",
        "(when-not (and (integer? positie) (<= 1N positie) (< positie dagen))\n       (fout :invalid-prefix-position))",
        "(when-not (and (integer? begroting)\n                    (<= 1N begroting hoogste-begroting))\n       (fout :invalid-weaving-budget))",
        "(when-not (and (integer? rang) (<= 1N rang totaal))\n         (fout :invalid-weaving-rank))",
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
        for clause, minimum in Counter(clauses).items():
            if form.count(clause) < minimum:
                raise AssertionError(f'{name}: missing/altered source clause {clause!r}; expected at least {minimum}')
        # Boundary guard: both the active and new group have their own strict > test.
        if name == 'prefix-volgende-keuze' and form.count('(when (> ') != 2:
            raise AssertionError('Expected exactly two strict over-budget guards')
        if name == 'prefix-op-rang-begrensd':
            for clause in clauses:
                if form.count(clause) != 1:
                    raise AssertionError(f'expected exactly one validation/default clause: {clause!r}')
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


def valid_profile(profile):
    # Python list is the independent model's vector representation.
    return (isinstance(profile, list) and 2 <= len(profile) <= 47 and
            all(type(value) is int and 4 <= value <= 123 for value in profile))


def valid_position(position, days):
    return type(position) is int and 1 <= position < days


def valid_budget(budget):
    return type(budget) is int and 1 <= budget <= BUDGET


def valid_rank(rank, total):
    return type(rank) is int and 1 <= rank <= total


def prefix_refusal(profile, rank, position, total, budget=BUDGET):
    # Mirrors the ordered refusal contract independently of the Clojure source.
    if not valid_profile(profile):
        return ':invalid-prefix-profile'
    days = sum(profile)
    if not valid_position(position, days):
        return ':invalid-prefix-position'
    if not valid_budget(budget):
        return ':invalid-weaving-budget'
    if not valid_rank(rank, total):
        return ':invalid-weaving-rank'
    return None


def model_validation_tests():
    checks = 0
    # Profile: vector type, count endpoints, and per-month integer endpoints.
    assert valid_profile([4, 4]); checks += 1
    assert valid_profile([123] * 47); checks += 1
    for bad in ((4, 4), [4], [4] * 48, [3, 4], [124, 4],
                [4.0, 4], [True, 4], None):
        assert not valid_profile(bad); checks += 1

    # Position is 1-based and strictly before the end of the full weaving.
    assert valid_position(1, 8); checks += 1
    assert valid_position(7, 8); checks += 1
    for bad in (0, 8, 9, 1.0, True):
        assert not valid_position(bad, 8); checks += 1

    # Both the caller budget and rank are closed integer intervals.
    assert valid_budget(1); checks += 1
    assert valid_budget(BUDGET); checks += 1
    for bad in (0, BUDGET + 1, 1.0, True):
        assert not valid_budget(bad); checks += 1
    assert valid_rank(1, 17); checks += 1
    assert valid_rank(17, 17); checks += 1
    for bad in (0, 18, 1.0, True):
        assert not valid_rank(bad, 17); checks += 1

    # Refusal-code association and the three-arity default-budget contract.
    assert prefix_refusal([4, 4], 1, 1, 4) is None; checks += 1
    assert prefix_refusal([4], 1, 1, 1) == ':invalid-prefix-profile'; checks += 1
    assert prefix_refusal([4, 4], 1, 0, 4) == ':invalid-prefix-position'; checks += 1
    assert prefix_refusal([4, 4], 1, 1, 4, 0) == ':invalid-weaving-budget'; checks += 1
    assert prefix_refusal([4, 4], 0, 1, 4) == ':invalid-weaving-rank'; checks += 1
    assert prefix_refusal([4, 4], 1, 1, 4, BUDGET) is None; checks += 1
    return checks


def source_mutation_tests(data):
    # Mutants must be rejected by the whole-blob guard; the semantic clauses
    # also reject changes when exercised without the blob gate.
    source = data.decode('utf-8', 'strict')
    mutants = [
        ('prefix-gedeelde-raming', "(+' 1N (*' (- (count restvector) geopend)", "(+' 2N (*' (- (count restvector) geopend)"),
        ('prefix-legale-kandidaten', '(pos? aantal)', '(>= aantal 0)'),
        ('prefix-legale-kandidaten', '(or (> aantal 1) (= maand (inc gesloten)))', '(or (>= aantal 1) (= maand (inc gesloten)))'),
        ('prefix-volgende-keuze', '(when (> nieuw begroting)', '(when (>= nieuw begroting)'),
        ('prefix-volgende-keuze', '(when (> nieuw-kosten begroting)', '(when (>= nieuw-kosten begroting)'),
        ('prefix-volgende-keuze', '(if (> r (:blok blok))\n            (recur', '(if (>= r (:blok blok))\n            (recur'),
        ('prefix-volgende-keuze', '(if (> r (:blok blok))\n                (fout', '(if (>= r (:blok blok))\n                (fout'),
        ("prefix-volgende-keuze", "(+' kosten (prefix-gedeelde-raming restvector geopend))", "(-' kosten (prefix-gedeelde-raming restvector geopend))"),
        ("prefix-volgende-keuze", "(+' kosten (prefix-gedeelde-raming restvector geopend))", "(+' kosten (*' 2N (prefix-gedeelde-raming restvector geopend)))"),
        ("prefix-volgende-keuze", "(+' actieve-kosten\n                    (prefix-gedeelde-raming restvector nieuw-geopend))", "(+' kosten\n                    (prefix-gedeelde-raming restvector nieuw-geopend))"),
        ("prefix-volgende-keuze", "(+' actieve-kosten\n                    (prefix-gedeelde-raming restvector nieuw-geopend))", "(-' actieve-kosten\n                    (prefix-gedeelde-raming restvector nieuw-geopend))"),
        ("prefix-volgende-keuze", "(recur (rest over) (-' r (:blok blok)))", "(recur (rest over) (+' r (:blok blok)))"),
        ("prefix-volgende-keuze", "(assoc blok :rang r :kosten actieve-kosten)", "(assoc blok :rang huidige-rang :kosten actieve-kosten)"),
        ("prefix-volgende-keuze", "(assoc blok :rang r :kosten actieve-kosten)", "(assoc blok :rang r :kosten kosten)"),
        ("prefix-volgende-keuze", "(assoc blok :rang r :kosten nieuw-kosten)", "(assoc blok :rang huidige-rang :kosten nieuw-kosten)"),
        ("prefix-volgende-keuze", "(assoc blok :rang r :kosten nieuw-kosten)", "(assoc blok :rang r :kosten actieve-kosten)"),
        ("prefix-volgende-keuze", "(if (seq actieve)\n          (let", "(if (empty? actieve)\n          (let"),
        ("prefix-volgende-keuze", "(if (seq actieve)\n                  (prefix-actieve-blokken", "(if (empty? actieve)\n                  (prefix-actieve-blokken"),
        ("prefix-volgende-keuze", "(boolean (some #(= % (inc geopend)) kandidaten))", "(boolean (some #(not= % (inc geopend)) kandidaten))"),
        ("prefix-volgende-keuze", "(if nieuw-maand?\n          (let", "(if true\n          (let"),
        ("prefix-volgende-keuze", "(if (seq over)\n        (let", "(if (empty? over)\n        (let"),
        ("prefix-volgende-keuze", "(if (> r (:blok blok))\n                (fout :bounded-prefix-invalid-count)", "(if (> r (:blok blok))\n                (fout :bounded-prefix-budget-unproven)"),
        ("prefix-volgende-keuze", "(fout :bounded-prefix-invalid-count))))))", "(fout :bounded-prefix-budget-unproven))))))"),
        ("prefix-volgende-keuze", "[nieuw-geopend (inc geopend)", "[nieuw-geopend geopend"),
        ("prefix-volgende-keuze", "nieuw)\n          kosten)", "nieuw)\n          0N)"),
        ("prefix-op-rang-begrensd", "(if (> plaats positie)", "(if (>= plaats positie)"),
        ("prefix-op-rang-begrensd", "[plaats 2", "[plaats 1"),
        ("prefix-op-rang-begrensd", "(recur (inc plaats)", "(recur (+ plaats 2)"),
        ("prefix-op-rang-begrensd", "restvector (update begin 0 dec)", "restvector begin"),
        ("prefix-op-rang-begrensd", "geopend 1 gesloten 0", "geopend 1 gesloten 1"),
        ("prefix-op-rang-begrensd", "huidige-rang rang kosten 0N prefix [1N]", "huidige-rang 1N kosten 0N prefix [1N]"),
        ("prefix-op-rang-begrensd", "restvector geopend gesloten huidige-rang begroting kosten)", "restvector geopend gesloten huidige-rang begroting 0N)"),
        ("prefix-op-rang-begrensd", "(:restvector keuze)", "restvector"),
        ("prefix-op-rang-begrensd", "(:geopend keuze)", "geopend"),
        ("prefix-op-rang-begrensd", "(:gesloten keuze)", "gesloten"),
        ("prefix-op-rang-begrensd", "(:rang keuze)", "huidige-rang"),
        ("prefix-op-rang-begrensd", "(:kosten keuze)", "kosten"),
        ("prefix-op-rang-begrensd", "(conj prefix (bigint (:maand keuze)))", "(conj prefix (bigint (peek prefix)))"),
        ("prefix-op-rang-begrensd", "(let [maand (peek prefix)]", "(let [maand (first prefix)]"),
        ("prefix-op-rang-begrensd", ":month-id maand", ":month-id 1N"),
        ("prefix-op-rang-begrensd", "(filter #(= maand %) prefix)", "(filter #(not= maand %) prefix)"),
        ("prefix-op-rang-begrensd", ":month-prefix prefix", ":month-prefix [maand]"),
        ("prefix-op-rang-begrensd", ":prefix-position (bigint positie)", ":prefix-position (bigint plaats)"),
        ("prefix-op-rang-begrensd", ":prefix-cell-upper-bound kosten", ":prefix-cell-upper-bound 0N"),
        ("prefix-op-rang-begrensd", ":date-proof-scope :bounded-prefix-only", ":date-proof-scope :full-date"),
        ("prefix-op-rang-begrensd", ":month-weaving-computed? false", ":month-weaving-computed? true"),
        ("prefix-op-rang-begrensd", "(prefix-op-rang-begrensd lengtes rang positie hoogste-begroting)", "(prefix-op-rang-begrensd lengtes rang positie 0N)"),
        ("prefix-op-rang-begrensd", "(vector? lengtes)", "(seq? lengtes)"),
        ("prefix-op-rang-begrensd", "(<= 2 (count lengtes) 47)", "(<= 1 (count lengtes) 47)"),
        ("prefix-op-rang-begrensd", "(<= 2 (count lengtes) 47)", "(<= 2 (count lengtes) 48)"),
        ("prefix-op-rang-begrensd", "(integer? %)", "(number? %)"),
        ("prefix-op-rang-begrensd", "(<= 4N % 123N)", "(<= 3N % 123N)"),
        ("prefix-op-rang-begrensd", "(<= 4N % 123N)", "(<= 4N % 124N)"),
        ("prefix-op-rang-begrensd", ":invalid-prefix-profile", ":invalid-weaving-rank"),
        ("prefix-op-rang-begrensd", "(integer? positie)", "(number? positie)"),
        ("prefix-op-rang-begrensd", "(<= 1N positie)", "(<= 0N positie)"),
        ("prefix-op-rang-begrensd", "(< positie dagen)", "(<= positie dagen)"),
        ("prefix-op-rang-begrensd", ":invalid-prefix-position", ":invalid-prefix-profile"),
        ("prefix-op-rang-begrensd", "(integer? begroting)", "(number? begroting)"),
        ("prefix-op-rang-begrensd", "(<= 1N begroting hoogste-begroting)", "(<= 0N begroting hoogste-begroting)"),
        ("prefix-op-rang-begrensd", "(<= 1N begroting hoogste-begroting)", "(<= 1N begroting (*' 2N hoogste-begroting))"),
        ("prefix-op-rang-begrensd", ":invalid-weaving-budget", ":invalid-weaving-rank"),
        ("prefix-op-rang-begrensd", "(integer? rang)", "(number? rang)"),
        ("prefix-op-rang-begrensd", "(<= 1N rang totaal)", "(<= 0N rang totaal)"),
        ("prefix-op-rang-begrensd", "(<= 1N rang totaal)", "(<= 1N rang (+ totaal 1N))"),
        ("prefix-op-rang-begrensd", ":invalid-weaving-rank", ":invalid-prefix-position"),
    ]
    for name, before, after in mutants:
        original_form = definition(source, name)
        if before not in original_form:
            raise AssertionError(f'mutation anchor not found in {name}: {before}')
        changed_form = original_form.replace(before, after, 1)
        changed = source.replace(original_form, changed_form, 1).encode()
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
    model = model_mutation_tests() + model_validation_tests()
    print(json.dumps(dict(project_id=PROJECT_ID, result='PASS', scope='STATIC_PLUS_MODEL_ONLY',
                          source_blob=git_blob_sha(data), function_sha256=forms,
                          source_mutations_rejected=checks, model_assertions=model,
                          canonical_prefix_sha256='2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a',
                          p82_billed_before=4995675, p82_billed_after=5002652,
                          ci='NOT_RUN', native='NOT_RUN', five_field='NOT_RUN', stage2='OPEN'),
                     sort_keys=True))


if __name__ == '__main__':
    main()
