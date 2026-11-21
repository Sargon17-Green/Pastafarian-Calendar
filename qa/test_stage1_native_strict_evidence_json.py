#!/usr/bin/env python3
"""QA adversarial tests of Native JSON receipt integrity; no PyFunge needed."""
import json
from stage1_native_strict_evidence_json import strict_evidence_loads


def need(ok, message):
    if not ok:
        raise AssertionError(message)


def main():
    clean = dict(schema='native-v2', records=[dict(index=0, run=dict(
        steps=2, p_history=[dict(tick=1, coordinate=[-3, 5], value='0')],
        output=['0'] * 7))], stage1_complete=False)
    raw = json.dumps(clean, sort_keys=True, separators=(',', ':'))
    need(strict_evidence_loads(raw) == clean, 'normal Native JSON changed')
    need(strict_evidence_loads(raw.encode('utf-8')) == clean,
         'normal byte-oriented Native JSON changed')
    need(strict_evidence_loads('{"\\u0061":1,"b":2}') == {'a': 1, 'b': 2},
         'escaped JSON key parsing drifted')
    need(strict_evidence_loads('{"p":1,"g":2,"p2":3}') ==
         {'p': 1, 'g': 2, 'p2': 3}, 'unique object keys rejected')

    forged = (
        ('duplicated_top_level', '{"schema":"legit","schema":"forged"}'),
        ('duplicated_nested_run', '{"record":{"run":{},"run":{"steps":1}}}'),
        ('duplicated_tick', '{"p":[{"tick":1,"tick":2}]}'),
        ('duplicated_escaped_key', '{"a":1,"\\u0061":2}'),
        ('nan', '{"steps":NaN}'),
        ('positive_inf', '{"steps":Infinity}'),
        ('negative_inf', '{"steps":-Infinity}'),
        ('float_step', '{"steps":1.5}'),
        ('exponent_step', '{"steps":1e5}'),
        ('trailing_document', '{"steps":1}{"steps":2}'),
        ('malformed_json', '{"steps":1'),
        ('bad_utf8', b'{"steps":"\xff"}'),
    )
    for label, text in forged:
        try:
            strict_evidence_loads(text)
        except (ValueError, UnicodeDecodeError):
            pass
        else:
            raise AssertionError('ambiguous Native JSON was accepted: ' + label)
    need(clean == strict_evidence_loads(raw), 'caller-owned fixture mutated')
    print('NATIVE_JSON_UNIQUE_KEYS_AND_12_FALSIFICATIONS_REJECT_PASS')


if __name__ == '__main__':
    main()
