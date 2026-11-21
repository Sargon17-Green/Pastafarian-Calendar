#!/usr/bin/env python3
"""Separate hostile mutation harness for QA31I paired differential claims."""
import argparse
import copy
import json
from pathlib import Path
import stage1_qa31i_paired_native_differential as pair


def audit(traces):
    a, b = traces['digit'], traces['digit_space']
    pair.pair_assert(a, b)
    attacks = [
        ('forge first read digit', 'digit', lambda s: s[291]['reads'][0].__setitem__('hex', '30')),
        ('forge first read space', 'digit_space', lambda s: s[291]['reads'][0].__setitem__('hex', '31')),
        ('forge early digit stack', 'digit', lambda s: s[100].__setitem__('post', [919])),
        ('forge early spaced stack', 'digit_space', lambda s: s[200].__setitem__('post', [919])),
        ('forge EOF reflection', 'digit', lambda s: s[1131].__setitem__('next', [14, 5])),
        ('forge buffered-space value', 'digit_space', lambda s: s[1131].__setitem__('post', [49])),
        ('remove physical STEP', 'digit', lambda s: s.pop(1131)),
        ('forge digit gate', 'digit', lambda s: s[1253]['pre'].__setitem__(-1, 0)),
        ('forge spaced gate', 'digit_space', lambda s: s[2675]['pre'].__setitem__(-1, 61)),
        ('forge spaced input event tick', 'digit_space', lambda s: s[291]['reads'][0].__setitem__('t', 999)),
    ]
    rejected = []
    for label, which, mutation in attacks:
        damaged = {'digit': copy.deepcopy(a), 'digit_space': copy.deepcopy(b)}
        mutation(damaged[which])
        try:
            pair.pair_assert(damaged['digit'], damaged['digit_space'])
        except (AssertionError, IndexError, ValueError, KeyError, TypeError):
            rejected.append(label)
        else:
            raise AssertionError('mutated pair accepted: ' + label)
    pair.need(len(rejected) == len(attacks) == 10, 'hostile controls')
    return {'schema': 'qa31i-negative-controls-v1', 'attacks': 10,
            'rejected': rejected, 'source_modified': False,
            'new_native_executions': 0, 'stage1_pass': False}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('original_native_zip')
    p.add_argument('--output', default='qa31i_negative_controls.json')
    args = p.parse_args()
    signed = pair.signed_pair(args.original_native_zip)
    report = audit(signed)
    Path(args.output).write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print('QA31I_HOSTILE_PAIR_MUTATIONS_REJECTED 10')
    print('QA31I_NEGATIVE_CONTROL_NO_STAGE1_PASS')


if __name__ == '__main__':
    main()
