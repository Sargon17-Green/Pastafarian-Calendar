#!/usr/bin/env python3
"""QA31M: narrow independent route audit of one signed QA31L original-Native trace.

Inputs: GitHub Actions artifact ZIP 13057227833, not a new Native replay.
This is evidence of one dynamic route only, never a Stage 1 acceptance test.
"""
import copy
import gzip
import hashlib
import io
import json
import sys
import zipfile

OUTER_SHA = '7de4556fda1b3d0b746c5b08e1600e029abb8d3a3565b976ddff804b9d4043b7'
TRACE_SHA = '779a58cc01255828dc76831566c31acf48395133a123611b35351aa18dff0a59'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
INPUT_SHA = '5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9'
GATE = (1254, (89,29), (151,29), 61)
ROUTE = (
    (1301, (211,29), (10,32)),
    (1445, (174,32), (10,35)),
    (1731, (309,35), (10,38)),
    (1876, (175,38), (10,44)),
)

def need(condition, msg):
    if not condition:
        raise AssertionError(msg)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def load_signed(data):
    need(digest(data) == OUTER_SHA, 'original Actions ZIP digest')
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        need(z.testzip() is None, 'outer archive CRC')
        expected = {'qa31l_receipt.json', 'qa31g_single_zero.jsonl.gz',
                    'qa31l-native-evidence.zip', 'qa31l_independent.json',
                    'audit.log', 'native.log'}
        need(set(z.namelist()) == expected, 'outer archive entry set')
        raw_trace = z.read('qa31g_single_zero.jsonl.gz')
        receipt_bytes = z.read('qa31l_receipt.json')
        with zipfile.ZipFile(io.BytesIO(z.read('qa31l-native-evidence.zip'))) as inner:
            need(inner.testzip() is None, 'nested archive CRC')
            need(set(inner.namelist()) == {'qa31l_receipt.json',
                                            'qa31g_single_zero.jsonl.gz'},
                 'nested archive contents')
            need(inner.read('qa31l_receipt.json') == receipt_bytes and
                 inner.read('qa31g_single_zero.jsonl.gz') == raw_trace,
                 'outer/nested bytes inconsistent')
        independent = json.loads(z.read('qa31l_independent.json'))
    need(digest(raw_trace) == TRACE_SHA, 'original compressed trace SHA256')
    receipt = json.loads(receipt_bytes)
    need(receipt.get('source_blob') == SOURCE_BLOB and
         receipt.get('schema') == 'qa31l-single-zero-original-native-v1' and
         receipt.get('stage1_pass') is False and
         receipt.get('source_modified') is False and
         receipt.get('old_cases_rerun') == 0, 'source and scope receipt')
    need(len(receipt['cases']) == 1, 'one case')
    case = receipt['cases'][0]
    need(case['raw_hex'] == '30' and case['raw_sha256'] == INPUT_SHA and
         case['trace_sha256'] == TRACE_SHA and case['steps'] == 2046 and
         case['status'] == 'HALT' and case['reads'] == 2, 'native run receipt')
    need(independent['oracle_coverage_complete'] is True and
         independent['bounded_evidence_verified'] is True and
         independent['hostile_minimum_8_met'] is True and
         independent['stage1_pass'] is False, 'predecessor QA31L audit')
    steps = [json.loads(x) for x in gzip.decompress(raw_trace).splitlines()]
    return steps

def audit(steps):
    need(len(steps) == 2046, 'length')
    for i, step in enumerate(steps):
        need(step['t'] == i + 1, 'physical STEP continuity')
        need(len(step['ip']) == 2 and len(step['delta']) == 2 and
             (step['next'] is None or len(step['next']) == 2),
             'coordinate schema')
        if i < len(steps)-1:
            need(step['next'] == steps[i+1]['ip'], 'physical next/IP linkage')
    need(steps[-1]['op'] == ord('@') and steps[-1]['next'] is None,
         'original HALT')
    gate_tick, gate_ip, gate_next, operand = GATE
    gate = steps[gate_tick-1]
    need(gate['ip'] == list(gate_ip) and gate['op'] == ord('j') and
         gate['pre'] and gate['pre'][-1] == operand and
         gate['next'] == list(gate_next), 'row29 j and operand')
    need(not any(s['ip'] == [150,29] for s in steps), 'x150 was unexpectedly executed')
    observed = []
    for tick, ip, nxt in ROUTE:
        e = steps[tick-1]
        need(e['op'] == ord('x') and e['ip'] == list(ip) and
             e['next'] == list(nxt), 'row cross-lane route')
        need(sum(s['ip'] == list(ip) for s in steps) == 1,
             'cross-lane location is not single-hit')
        observed.append({'tick': tick, 'from': list(ip), 'to': list(nxt)})
    j32, j38 = steps[1397], steps[1828]
    need(j32['ip'] == [113,32] and j32['op'] == 106 and
         j32['pre'][-1] == 0 and j32['next'] == [114,32], 'row32 j')
    need(j38['ip'] == [114,38] and j38['op'] == 106 and
         j38['pre'][-1] == 0 and j38['next'] == [115,38], 'row38 j')
    need(any(s['ip'][1] == 44 for s in steps), 'row44 visit')
    return observed

def sabotage(steps):
    attacks = [
        (1254, 'next', [150,29]),
        (1254, 'pre', [0]),
        (1301, 'op', ord('0')),
        (1301, 'next', [10,29]),
        (1445, 'next', [10,38]),
        (1731, 'ip', [309,32]),
        (1876, 'next', [10,38]),
        (2046, 'op', ord(' ')),
    ]
    rejected = 0
    for tick, key, value in attacks:
        test = copy.deepcopy(steps)
        test[tick-1][key] = value
        try:
            audit(test)
        except AssertionError:
            rejected += 1
        else:
            raise AssertionError('hostile mutation escaped: %s at %s' % (key,tick))
    test = copy.deepcopy(steps)
    del test[1300]
    try:
        audit(test)
    except AssertionError:
        rejected += 1
    else:
        raise AssertionError('missing physical STEP escaped')
    return rejected

def main(path):
    data = open(path, 'rb').read()
    steps = load_signed(data)
    observed = audit(steps)
    rejected = sabotage(steps)
    need(rejected == 9, 'hostile control count')
    print(json.dumps({'schema':'qa31m-signed-route-v1',
                      'source_blob':SOURCE_BLOB,
                      'actions_outer_sha256':OUTER_SHA,
                      'step_count':len(steps), 'raw_hex':'30',
                      'gate':{'tick':1254,'operand':61,'next':[151,29]},
                      'x15029_visits':0,
                      'cross_lane_route':observed,
                      'hostile_rejected':rejected,
                      'native_new_cases':0,'stage1_pass':False},
                     indent=2, sort_keys=True))
    print('QA31M_SIGNED_CROSS_LANE_ROUTE_PASS')
    print('QA31M_NO_STAGE1_PASS')

if __name__ == '__main__':
    need(len(sys.argv) == 2, 'usage: script.py QA31L_ACTIONS_ARTIFACT.zip')
    main(sys.argv[1])
