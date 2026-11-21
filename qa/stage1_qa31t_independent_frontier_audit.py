#!/usr/bin/env python3
"""Independent source-pinned QA31T physical Native trace auditor."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CAP = 25000
CASES = (
    ('sep000_no_lf', b'1 0 0 0'),
    ('sep001_no_lf', b'1 0 0\t0'),
    ('sep010_no_lf', b'1 0\t0 0'),
    ('sep011_no_lf', b'1 0\t0\t0'),
    ('sep100_no_lf', b'1\t0 0 0'),
    ('sep101_no_lf', b'1\t0 0\t0'),
    ('sep110_no_lf', b'1\t0\t0 0'),
    ('sep111_no_lf', b'1\t0\t0\t0'),
    ('space_lf', b'1 0 0 0\n'),
    ('space_crlf', b'1 0 0 0\r\n'),
    ('space_trailing_space', b'1 0 0 0 '),
    ('space_trailing_tab', b'1 0 0 0\t'),
)
FRONTIER = ((286, 5), (235, 23), (235, 32))
GATES = {(57, 29): 'm29', (57, 32): 'q32', (57, 38): 'q38'}
JUMPS = {(89, 29): 'j29', (113, 32): 'j32', (114, 38): 'j38'}
EXITS = {(211, 29): 'x29', (174, 32): 'x32', (309, 35): 'x35'}

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def gitblob(raw):
    return hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()

def cell(rows, x, y):
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return rows[y][x]
    return 32

def check_receipt(report):
    need(report['schema'] == 'qa31t-original-native-delimiter-frontier-v1'
         and report['source_blob'] == PIN
         and report['source_modified'] is False
         and report['ip_relocated'] is False
         and report['fresh_native_cases'] == len(CASES)
         and report['cap_per_case'] == CAP
         and report['total_step_cap'] == CAP * len(CASES)
         and report['global_reachability_proven'] is False
         and report['stage1_pass'] is False,
         'QA31T receipt identity, provenance, or scope')
    items = report['cases']
    need(len(items) == len(CASES), 'QA31T case count')
    for (label, raw), rec in zip(CASES, items):
        need(rec['label'] == label
             and rec['raw_hex'] == raw.hex()
             and rec['raw_sha256'] == sha(raw)
             and rec['trace'] == 'qa31g_' + label + '.jsonl.gz',
             'QA31T input identity or order')
        need(type(rec['steps']) is int and 0 < rec['steps'] <= CAP
             and type(rec['reads']) is int and rec['reads'] >= 0,
             'QA31T event bounds')
        need(rec['status'] in ('HALT', 'STEP_LIMIT', 'RUNTIME_ERROR')
             and ((rec['error'] is not None) ==
                  (rec['status'] == 'RUNTIME_ERROR')),
             'QA31T status/error pairing')
        need(type(rec['output']) is list, 'QA31T output shape')

def audit_trace(rec, raw, rows, folder, mutate=None):
    path = folder / rec['trace']
    compressed = path.read_bytes()
    need(sha(compressed) == rec['trace_sha256'] and rec['trace_sha256'] != '',
         'trace compressed SHA256')
    overlay = {}
    last_writer = {}
    prior_next = prior_delta = None
    seen = {}
    gates, jumps, exits = [], [], []
    p_count = g_count = read_count = eof_count = ticks = 0
    picked = {}
    with gzip.open(path, 'rb') as stream:
        for line in stream:
            event = json.loads(line)
            ticks += 1
            if mutate is not None:
                mutate(event)
            need(event['t'] == ticks and ticks <= CAP, 'physical STEP tick')
            ip = event['ip']
            delta = event['delta']
            need(type(ip) is list and len(ip) == 2
                 and all(type(v) is int for v in ip), 'physical IP shape')
            need(type(delta) is list and len(delta) == 2
                 and all(type(v) is int for v in delta), 'physical delta shape')
            x, y = ip
            need(event['op'] == overlay.get((x, y), cell(rows, x, y)),
                 'opcode differs from original source plus prior p writes')
            need(type(event['string']) is bool, 'stringmode type')
            if ticks > 1:
                need(prior_next == ip and prior_delta == delta,
                     'IP/delta discontinuity between physical STEPs')
            prior_next = event.get('next')
            prior_delta = event.get('next_delta')
            pre, post = event['pre'], event['post']
            need(type(pre) is list and type(post) is list
                 and len(pre) < 5000 and len(post) < 5000
                 and all(type(v) is int for v in pre + post),
                 'pre/post stack receipt')
            if ticks == 1:
                picked['first'] = ticks
            if (x, y) in FRONTIER and (x, y) not in seen:
                seen[(x, y)] = ticks

            if not event['string']:
                op = event['op']
                if op == ord('p'):
                    need(len(pre) >= 3 and post == pre[:-3],
                         'p must consume exactly value,x,y')
                    value, px, py = pre[-3:]
                    overlay[(px, py)] = value
                    last_writer[(px, py)] = {
                        'tick': ticks, 'ip': ip, 'value': value
                    }
                    p_count += 1
                    picked.setdefault('p', ticks)
                elif op == ord('g'):
                    need(len(pre) >= 2, 'g stack underflow')
                    gx, gy = pre[-2:]
                    value = overlay.get((gx, gy), cell(rows, gx, gy))
                    need(post == pre[:-2] + [value],
                         'g value differs from original-source/p-overlay oracle')
                    g_count += 1
                    picked.setdefault('g', ticks)
                    if (x, y) in GATES:
                        gates.append({
                            'kind': GATES[(x, y)], 'tick': ticks,
                            'target': [gx, gy], 'read': value,
                            'last_writer': last_writer.get((gx, gy))
                        })
                elif op == ord('j') and (x, y) in JUMPS:
                    need(len(pre) >= 1 and post == pre[:-1],
                         'j must consume exactly one operand')
                    jumps.append({
                        'kind': JUMPS[(x, y)], 'tick': ticks,
                        'operand': pre[-1], 'next': event.get('next')
                    })
                elif op == ord('x') and (x, y) in EXITS:
                    exits.append({
                        'kind': EXITS[(x, y)], 'tick': ticks,
                        'vector': pre[-2:], 'next': event.get('next'),
                        'next_delta': event.get('next_delta')
                    })

            for rd in event.get('reads', []):
                start, end = rd['start'], rd['end']
                need(rd['t'] == ticks and rd['ip'] == ip
                     and rd['method'] in ('read', 'readline')
                     and type(start) is int and type(end) is int
                     and 0 <= start <= end <= len(raw)
                     and rd['hex'] == raw[start:end].hex()
                     and type(rd['stack']) is list,
                     'stdin bytes/EOF provenance')
                read_count += 1
                picked.setdefault('read', ticks)
                if start == end:
                    eof_count += 1

            if ticks == rec['steps']:
                if rec['status'] == 'HALT':
                    need(event.get('next') is None, 'HALT final IP')
                elif rec['status'] == 'STEP_LIMIT':
                    need(event.get('next') is not None, 'STEP_LIMIT final IP')
                elif rec['status'] == 'RUNTIME_ERROR':
                    need(event.get('error') == rec['error'],
                         'runtime exception provenance')
            need(ticks <= rec['steps'], 'unclaimed physical STEP')
    need(ticks == rec['steps'] and read_count == rec['reads'],
         'trace count differs from receipt')
    return {
        'label': rec['label'], 'raw_hex': raw.hex(),
        'status': rec['status'], 'steps': ticks,
        'stdin_reads': read_count, 'eof_reads': eof_count,
        'physical_p': p_count, 'physical_g': g_count,
        'gates': gates, 'jumps': jumps, 'exits': exits,
        'frontier_first_ticks': {
            str(x) + ',' + str(y): seen.get((x, y)) for x, y in FRONTIER
        },
        '_picked': picked
    }

def hostile_controls(report, first, raw, rows, folder):
    attacks = (
        lambda r: r.__setitem__('schema', 'forged'),
        lambda r: r.__setitem__('source_blob', '0' * 40),
        lambda r: r.__setitem__('source_modified', True),
        lambda r: r.__setitem__('ip_relocated', True),
        lambda r: r.__setitem__('fresh_native_cases', 11),
        lambda r: r.__setitem__('cap_per_case', CAP + 1),
        lambda r: r.__setitem__('total_step_cap', 1),
        lambda r: r.__setitem__('global_reachability_proven', True),
        lambda r: r.__setitem__('stage1_pass', True),
        lambda r: r['cases'][0].__setitem__('label', 'wrong'),
        lambda r: r['cases'][0].__setitem__('raw_hex', '00'),
    )
    rejected = 0
    for attack in attacks:
        bad = copy.deepcopy(report)
        attack(bad)
        try:
            check_receipt(bad)
        except (AssertionError, KeyError, TypeError, ValueError):
            rejected += 1
        else:
            raise AssertionError('forged QA31T receipt accepted')

    base = audit_trace(first, raw, rows, folder)
    picked = base['_picked']
    need(all(k in picked for k in ('first', 'p', 'g', 'read')),
         'first trace lacks hostile-control witnesses')
    for kind, target in (
        ('tick', picked['first']), ('ip', picked['first']),
        ('opcode', picked['first']), ('delta', picked['first']),
        ('p_stack', picked['p']), ('g_stack', picked['g']),
        ('stdin', picked['read'])
    ):
        changed = [False]
        def tamper(event):
            if event['t'] != target:
                return
            if kind == 'tick':
                event['t'] = 0
            elif kind == 'ip':
                event['ip'] = [999999, 999999]
            elif kind == 'opcode':
                event['op'] = -123456
            elif kind == 'delta':
                event['next_delta'] = [999999, 999999]
            elif kind in ('p_stack', 'g_stack'):
                event['post'] = event['pre']
            elif kind == 'stdin':
                need(event.get('reads'), 'stdin hostile target missing')
                event['reads'][0]['hex'] = 'ffff'
            changed[0] = True
        try:
            audit_trace(first, raw, rows, folder, mutate=tamper)
        except (AssertionError, KeyError, TypeError, ValueError):
            need(changed[0], 'hostile event mutation was not applied')
            rejected += 1
        else:
            raise AssertionError('forged physical trace accepted: ' + kind)
    need(rejected == 18, 'QA31T must reject all 18 hostile controls')
    return rejected

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('source')
    ap.add_argument('folder')
    args = ap.parse_args()
    source = Path(args.source).read_bytes()
    need(gitblob(source) == PIN, 'original source Git blob identity')
    rows = source.splitlines()
    need(len(rows) == 2015 and rows[49] == b'',
         'original source geometry/blank row 49')
    folder = Path(args.folder)
    receipt = json.loads((folder / 'qa31t_receipt.json').read_text())
    check_receipt(receipt)
    audits = []
    for (label, raw), rec in zip(CASES, receipt['cases']):
        result = audit_trace(rec, raw, rows, folder)
        result.pop('_picked')
        audits.append(result)
        print('QA31T_VERIFIED', label, result['steps'], result['status'])
    rejected = hostile_controls(receipt, receipt['cases'][0], CASES[0][1],
                                rows, folder)
    hits = {key for case in audits
            for key, tick in case['frontier_first_ticks'].items()
            if tick is not None}
    combos = []
    for case in audits:
        ms = [g for g in case['gates']
              if g['kind'] == 'm29' and g['target'] == [3, 49]]
        qs = [g for g in case['gates']
              if g['kind'] in ('q32', 'q38') and g['target'] == [1, 49]]
        if ms and qs:
            combos.append({
                'label': case['label'], 'm': ms[0]['read'],
                'observed_q': [[g['kind'], g['read']] for g in qs],
                'm1_q3_or_more_observed':
                    ms[0]['read'] == 1 and any(g['read'] >= 3 for g in qs)
            })
    result = {
        'schema': 'qa31t-independent-native-delimiter-frontier-v1',
        'source_blob': PIN, 'cases_verified': len(audits),
        'physical_steps_verified': sum(c['steps'] for c in audits),
        'hostile_controls_rejected': rejected,
        'frontier_targets': [[x, y] for x, y in FRONTIER],
        'frontier_hit_in_finite_matrix': sorted(hits),
        'frontier_unwitnessed_in_finite_matrix':
            sorted({str(x) + ',' + str(y) for x, y in FRONTIER} - hits),
        'gate_combinations': combos,
        'm1_and_q_ge3_observed_in_finite_matrix':
            any(c['m1_q3_or_more_observed'] for c in combos),
        'cases': audits, 'global_reachability_proven': False,
        'global_input_ownership_proven': False, 'stage1_pass': False
    }
    (folder / 'qa31t_independent.json').write_text(
        json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('QA31T_12_TRACE_CASES_AUDITED', result['physical_steps_verified'])
    print('QA31T_HOSTILE_CONTROLS', rejected, 'OF_18_REJECTED')
    print('QA31T_FINITE_FRONTIER_HITS', sorted(hits))
    print('QA31T_STAGE1_REMAINS_OPEN')

if __name__ == '__main__':
    main()
