#!/usr/bin/env python3
"""QA31U independent exact-input, full-physical-trace and adversarial shard audit."""
import argparse
import copy
import hashlib
import json
from pathlib import Path

from stage1_qa31t_independent_frontier_audit import audit_trace, gitblob, need

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
PREFIX = b'1 0 0 0'
CAP = 25000
SHARDS = 8
SIZE = 32
FRONTIER = {(286, 5), (235, 23), (235, 32)}

def cases(shard):
    return [
        ('byte_%02x' % b, PREFIX + bytes([b]))
        for b in range(shard * SIZE, (shard + 1) * SIZE)
    ]

def checksum(raw):
    return hashlib.sha256(raw).hexdigest()

def verify_receipt(doc, shard):
    need(type(doc) is dict, 'receipt object')
    need(doc.get('schema') == 'qa31u-original-native-one-byte-suffix-v1'
         and doc.get('source_blob') == PIN
         and doc.get('source_modified') is False
         and doc.get('ip_relocated') is False
         and doc.get('suffix_prefix_hex') == PREFIX.hex()
         and type(doc.get('shard')) is int and doc['shard'] == shard
         and doc.get('shard_size') == SIZE
         and doc.get('total_shards') == SHARDS
         and doc.get('case_cap_steps') == CAP
         and doc.get('all_shards_step_cap') == CAP * SIZE * SHARDS
         and doc.get('completed_native_cases') == SIZE
         and doc.get('stage1_pass') is False
         and doc.get('global_reachability_proven') is False,
         'receipt schema, scope, or source identity')
    received = doc.get('cases')
    need(type(received) is list and len(received) == SIZE, 'case count')
    for (label, raw), rec in zip(cases(shard), received):
        need(type(rec) is dict
             and rec.get('label') == label
             and rec.get('raw_hex') == raw.hex()
             and rec.get('raw_sha256') == checksum(raw)
             and rec.get('trace') == 'qa31g_' + label + '.jsonl.gz'
             and type(rec.get('trace_sha256')) is str
             and len(rec['trace_sha256']) == 64
             and type(rec.get('steps')) is int
             and 0 < rec['steps'] <= CAP
             and type(rec.get('reads')) is int and rec['reads'] >= 0
             and rec.get('status') == 'HALT'
             and rec.get('error') is None
             and type(rec.get('output')) is list,
             'case differs from exact fixed-input Native HALT corpus')

def adversarial(doc, shard, first_rec, first_raw, rows, folder):
    mutations = (
        lambda x: x.__setitem__('schema', 'forged'),
        lambda x: x.__setitem__('source_blob', '0' * 40),
        lambda x: x.__setitem__('source_modified', True),
        lambda x: x.__setitem__('ip_relocated', True),
        lambda x: x.__setitem__('shard', (shard + 1) % SHARDS),
        lambda x: x.__setitem__('completed_native_cases', SIZE - 1),
        lambda x: x.__setitem__('case_cap_steps', CAP + 1),
        lambda x: x.__setitem__('global_reachability_proven', True),
        lambda x: x.__setitem__('stage1_pass', True),
        lambda x: x['cases'][0].__setitem__('label', 'forged'),
        lambda x: x['cases'][0].__setitem__('raw_hex', '00'),
    )
    rejected = 0
    for mutate in mutations:
        broken = copy.deepcopy(doc)
        mutate(broken)
        try:
            verify_receipt(broken, shard)
        except (AssertionError, KeyError, ValueError, TypeError):
            rejected += 1
        else:
            raise AssertionError('forged QA31U receipt accepted')
    original = audit_trace(first_rec, first_raw, rows, folder)
    witness = original['_picked']
    need(all(k in witness for k in ('first', 'p', 'g', 'read')),
         'insufficient actual Native witness for hostile control')
    specs = (
        ('tick', witness['first']),
        ('ip', witness['first']),
        ('opcode', witness['first']),
        ('delta', witness['first']),
        ('p_stack', witness['p']),
        ('g_stack', witness['g']),
        ('stdin', witness['read']),
    )
    for kind, t in specs:
        changed = [False]
        def tamper(event):
            if event['t'] != t:
                return
            if kind == 'tick':
                event['t'] = 0
            elif kind == 'ip':
                event['ip'] = [999999, 999999]
            elif kind == 'opcode':
                event['op'] = -99999
            elif kind == 'delta':
                event['next_delta'] = [999999, 999999]
            elif kind in ('p_stack', 'g_stack'):
                event['post'] = event['pre']
            elif kind == 'stdin':
                need(bool(event.get('reads')), 'missing read event')
                event['reads'][0]['hex'] = 'ffff'
            changed[0] = True
        try:
            audit_trace(first_rec, first_raw, rows, folder, mutate=tamper)
        except (AssertionError, KeyError, ValueError, TypeError):
            need(changed[0], 'hostile trace mutation never applied')
            rejected += 1
        else:
            raise AssertionError('forged QA31U physical trace accepted: ' + kind)
    need(rejected == 18, 'must reject exactly 18 hostile controls')
    return rejected

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source')
    parser.add_argument('folder')
    parser.add_argument('shard', type=int)
    args = parser.parse_args()
    need(0 <= args.shard < SHARDS, 'shard index')
    source = Path(args.source).read_bytes()
    need(gitblob(source) == PIN, 'original source Git blob identity')
    rows = source.splitlines()
    need(len(rows) == 2015 and rows[49] == b'',
         'original source geometry/blank row 49')
    folder = Path(args.folder)
    receipt = json.loads((folder / 'qa31u_receipt.json').read_bytes())
    verify_receipt(receipt, args.shard)
    audits = []
    for (label, raw), rec in zip(cases(args.shard), receipt['cases']):
        result = audit_trace(rec, raw, rows, folder)
        result.pop('_picked')
        need(result['status'] == 'HALT' and result['steps'] == rec['steps'],
             'original physical trace did not HALT')
        audits.append(result)
        print('QA31U_AUDITED', args.shard, label, result['steps'])
    rejected = adversarial(receipt, args.shard, receipt['cases'][0],
                           cases(args.shard)[0][1], rows, folder)
    totals = sum(c['steps'] for c in audits)
    need(totals <= SIZE * CAP, 'shard physical step budget')
    hits = sorted({
        name for c in audits
        for name, tick in c['frontier_first_ticks'].items()
        if tick is not None
    })
    gate_counts = {}
    for c in audits:
        observed = [
            (g['kind'], tuple(g['target']), g['read'])
            for g in c['gates']
        ]
        qualifies = (
            ('m29', (3,49), 1) in observed
            and any(k in ('q32','q38') and point == (1,49) and value >= 3
                    for k,point,value in observed)
        )
        gate_counts[c['label']] = qualifies
    report = {
        'schema': 'qa31u-independent-one-byte-shard-v1',
        'source_blob': PIN,
        'shard': args.shard,
        'cases_verified': len(audits),
        'physical_steps_verified': totals,
        'hostile_controls_rejected': rejected,
        'finite_frontier_hits': hits,
        'gate_combo_observed_by_input': gate_counts,
        'cases': audits,
        'global_reachability_proven': False,
        'stage1_pass': False,
    }
    (folder / 'qa31u_independent.json').write_text(
        json.dumps(report, sort_keys=True, indent=2) + '\n'
    )
    print('QA31U_SHARD_FULL_TRACE_AUDITED', args.shard, totals)
    print('QA31U_SHARD_HOSTILE_CONTROLS', args.shard, rejected, 'OF_18_REJECTED')
    print('QA31U_SHARD_FINITE_FRONTIER_HITS', args.shard, hits)
    print('QA31U_STAGE1_REMAINS_OPEN')

if __name__ == '__main__':
    main()
