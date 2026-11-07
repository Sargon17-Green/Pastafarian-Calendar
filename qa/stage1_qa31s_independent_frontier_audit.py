#!/usr/bin/env python3
"""QA31S independent source-pinned, bounded, physical Native trace auditor."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CAP = 25000
CASES = (
    ('one_lf', b'1\n'), ('one_0_lf', b'1 0\n'),
    ('one_00_lf', b'1 0 0\n'), ('one_000_lf', b'1 0 0 0\n'),
    ('one_0000_lf', b'1 0 0 0 0\n'),
    ('one_tab_0_lf', b'1\t0\t0\n'),
    ('one_tab_00_lf', b'1\t0\t0\t0\n'),
    ('one_hundred_lf', b'100\n'), ('one_thousand_lf', b'1000\n'),
    ('one_eleven_lf', b'111\n'), ('one_eleven_eleven_lf', b'1111\n'),
    ('one_000_no_lf', b'1 0 0 0'),
)
TARGETS = ((286, 5), (235, 23), (235, 32))
GATES = {(57, 29): 'm29', (57, 32): 'q32', (57, 38): 'q38'}
JUMPS = {(89, 29): 'j29', (113, 32): 'j32', (114, 38): 'j38'}
EXITS = {(211, 29): 'x29', (174, 32): 'x32', (309, 35): 'x35'}

def need(ok, reason):
    if not ok:
        raise AssertionError(reason)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def gitblob(raw):
    return hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()

def cell(rows, x, y):
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return rows[y][x]
    return 32

def metadata(report):
    need(report['schema'] == 'qa31s-original-native-frontier-v1'
         and report['source_blob'] == PIN
         and report['source_modified'] is False
         and report['ip_relocated'] is False
         and report['fresh_native_cases'] == 12
         and report['cap_per_case'] == CAP
         and report['global_reachability_proven'] is False
         and report['stage1_pass'] is False,
         'report identity, provenance, or scope')
    items = report['cases']
    need(len(items) == len(CASES), 'case count')
    for (label, raw), record in zip(CASES, items):
        need(record['label'] == label and
             record['raw_hex'] == raw.hex() and
             record['raw_sha256'] == sha(raw) and
             record['trace'] == 'qa31g_' + label + '.jsonl.gz',
             'raw stdin identity or receipt order')
        need(type(record['steps']) is int and 0 < record['steps'] <= CAP
             and type(record['reads']) is int and record['reads'] >= 0,
             'physical event count bounds')
        need(record['status'] in ('HALT','STEP_LIMIT','RUNTIME_ERROR')
             and ((record['error'] is not None) ==
                  (record['status'] == 'RUNTIME_ERROR')),
             'status/error pairing')
        need(type(record['output']) is list, 'recorded output shape')

def audit_one(case, raw, rows, folder, mutate=None):
    compressed = (folder / case['trace']).read_bytes()
    need(sha(compressed) == case['trace_sha256'], 'compressed trace SHA')
    need(case['trace_sha256'] != '', 'empty compressed trace digest')
    overlay = {}
    last_write = {}
    prev_next = prev_delta = None
    hits = {}
    gates = []
    jumps = []
    exits = []
    p_events = 0
    g_events = 0
    eof_reads = 0
    read_count = 0
    count = 0
    picked = {}
    with gzip.open(folder / case['trace'], 'rb') as stream:
        for line in stream:
            e = json.loads(line)
            count += 1
            if mutate is not None:
                mutate(e)
            need(e['t'] == count and count <= CAP, 'monotonic signed Native STEP tick')
            x,y = e['ip']
            dx,dy = e['delta']
            need(type(x) is int and type(y) is int
                 and type(dx) is int and type(dy) is int, 'integer IP/delta')
            need(e['op'] == overlay.get((x,y), cell(rows,x,y)),
                 'physical opcode vs original source + prior p')
            need(type(e['string']) is bool, 'stringmode receipt type')
            if count > 1:
                need(prev_next == e['ip'] and prev_delta == e['delta'],
                     'consecutive original IP path/direction')
            prev_next, prev_delta = e.get('next'), e.get('next_delta')
            pre,post = e['pre'],e['post']
            need(type(pre) is list and type(post) is list
                 and len(pre) < 5000 and len(post) < 5000
                 and all(type(v) is int for v in pre+post),
                 'Native stack data')
            if count == 1:
                picked['first'] = count
            if (x,y) in TARGETS and (x,y) not in hits:
                hits[(x,y)] = count
            if not e['string']:
                if e['op'] == ord('p'):
                    need(len(pre) >= 3 and post == pre[:-3],
                         'physical p last-three stack transition')
                    v,px,py = pre[-3:]
                    overlay[(px,py)] = v
                    last_write[(px,py)] = {'t':count,'ip':[x,y],'value':v}
                    p_events += 1
                    picked.setdefault('p',count)
                if e['op'] == ord('g'):
                    need(len(pre) >= 2, 'physical g stack underflow')
                    gx,gy = pre[-2:]
                    observed = overlay.get((gx,gy),cell(rows,gx,gy))
                    need(post == pre[:-2] + [observed], 'g independent source/p overlay oracle')
                    g_events += 1
                    picked.setdefault('g',count)
                    if (x,y) in GATES:
                        gates.append({'kind':GATES[x,y], 'tick':count,
                                      'target':[gx,gy], 'read':observed,
                                      'last_writer':last_write.get((gx,gy))})
                if e['op'] == ord('j') and (x,y) in JUMPS:
                    need(len(pre) >= 1 and post == pre[:-1], 'j pop semantics')
                    jumps.append({'kind':JUMPS[x,y], 'tick':count,
                                  'operand':pre[-1], 'next':e.get('next')})
                if e['op'] == ord('x') and (x,y) in EXITS:
                    exits.append({'kind':EXITS[x,y], 'tick':count,
                                  'vector':pre[-2:], 'next':e.get('next'),
                                  'next_delta':e.get('next_delta')})
            for rd in e['reads']:
                start,end=rd['start'],rd['end']
                need(rd['t'] == count and rd['ip'] == e['ip']
                     and rd['method'] in ('read','readline')
                     and type(start) is int and type(end) is int
                     and 0 <= start <= end <= len(raw)
                     and rd['hex'] == raw[start:end].hex()
                     and type(rd['stack']) is list,
                     'stdin actual byte provenance or EOF boundary')
                read_count += 1
                picked.setdefault('read',count)
                if start == end:
                    eof_reads += 1
            if count == case['steps']:
                if case['status'] == 'HALT':
                    need(e['next'] is None, 'HALT must remove original IP')
                elif case['status'] == 'STEP_LIMIT':
                    need(e['next'] is not None, 'STEP_LIMIT must retain original IP')
                elif case['status'] == 'RUNTIME_ERROR':
                    need('error' in e and e['error'] == case['error'],
                         'Native runtime exception provenance')
            need(count <= case['steps'], 'extra unclaimed STEP')
    need(count == case['steps'] and read_count == case['reads'],
         'physical STEP/read count does not match signed receipt')
    return {'label':case['label'], 'input_hex':raw.hex(), 'status':case['status'],
            'steps':count, 'stdin_reads':read_count, 'eof_reads':eof_reads,
            'physical_p':p_events, 'physical_g':g_events, 'gates':gates,
            'jumps':jumps, 'exits':exits,
            'frontier_first_ticks':{str(x)+','+str(y):hits.get((x,y))
                                    for x,y in TARGETS},
            '_picked':picked}

def hostile_controls(report, rows, folder):
    # 11 immutable-input/receipt mutations: none is a discovered program bug.
    attackers = (
        lambda x: x.__setitem__('schema','qa31s-false'),
        lambda x: x.__setitem__('source_blob','0'*40),
        lambda x: x.__setitem__('source_modified',True),
        lambda x: x.__setitem__('ip_relocated',True),
        lambda x: x.__setitem__('fresh_native_cases',11),
        lambda x: x.__setitem__('cap_per_case',25001),
        lambda x: x.__setitem__('global_reachability_proven',True),
        lambda x: x.__setitem__('stage1_pass',True),
        lambda x: x['cases'][0].__setitem__('label','duplicate'),
        lambda x: x['cases'][0].__setitem__('raw_hex','00'),
        lambda x: x['cases'][0].__setitem__('steps',25001),
    )
    rejected = 0
    for attack in attackers:
        bad = copy.deepcopy(report)
        attack(bad)
        try:
            metadata(bad)
        except (AssertionError, KeyError, TypeError, ValueError):
            rejected += 1
        else:
            raise AssertionError('forged QA31S receipt was accepted')
    # Seven in-memory STEP/byte/stack/motion attacks. No signed file is rewritten.
    first = report['cases'][0]
    raw = CASES[0][1]
    baseline = audit_one(first,raw,rows,folder)
    p = baseline['_picked']
    need(all(z in p for z in ('first','p','g','read')),
         'first original Native case lacks targeted hostile-control witness')
    for kind,target in (('tick',p['first']),('ip',p['first']),
                        ('op',p['first']),('delta',p['first']),
                        ('p_post',p['p']),('g_post',p['g']),
                        ('stdin',p['read'])):
        changed = [False]
        def tamper(e):
            if e['t'] != target:
                return
            if kind == 'tick':
                e['t'] = 0
            elif kind == 'ip':
                e['ip'] = [999999,999999]
            elif kind == 'op':
                e['op'] = -123456
            elif kind == 'delta':
                e['next_delta'] = [999999,999999]
            elif kind in ('p_post','g_post'):
                e['post'] = e['pre']
            elif kind == 'stdin':
                need(e['reads'], 'read mutation target missing')
                e['reads'][0]['hex'] = 'ffff'
            changed[0] = True
        try:
            audit_one(first,raw,rows,folder,mutate=tamper)
        except (AssertionError, KeyError, TypeError, ValueError):
            need(changed[0], 'hostile mutation did not execute')
            rejected += 1
        else:
            raise AssertionError('forged Native event accepted: '+kind)
    need(rejected == 18, 'must reject all 18 hostile controls')
    return rejected

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('source')
    ap.add_argument('folder')
    args=ap.parse_args()
    source=Path(args.source).read_bytes()
    need(gitblob(source)==PIN, 'original source Git blob identity')
    rows=source.splitlines()
    need(len(rows)==2015 and rows[49]==b'', 'original source geometry/row49')
    folder=Path(args.folder)
    receipt=json.loads((folder/'qa31s_receipt.json').read_text())
    metadata(receipt)
    audits=[]
    for (label,raw),item in zip(CASES,receipt['cases']):
        result=audit_one(item,raw,rows,folder)
        result.pop('_picked')
        audits.append(result)
        print('QA31S_VERIFIED',label,result['steps'],result['status'])
    rejected=hostile_controls(receipt,rows,folder)
    seen={key for a in audits for key,value in a['frontier_first_ticks'].items()
          if value is not None}
    combos=[]
    for a in audits:
        ms=[g for g in a['gates'] if g['kind']=='m29' and g['target']==[3,49]]
        qs=[g for g in a['gates'] if g['kind'] in ('q32','q38')
            and g['target']==[1,49]]
        if ms and qs:
            combos.append({'label':a['label'],'m':ms[0]['read'],
                           'observed_q':[(g['kind'],g['read']) for g in qs],
                           'm1_q3_or_more_observed':
                           ms[0]['read']==1 and any(g['read']>=3 for g in qs)})
    output={'schema':'qa31s-independent-native-frontier-v1',
            'source_blob':PIN,'cases_verified':len(audits),
            'physical_steps_verified':sum(a['steps'] for a in audits),
            'hostile_controls_rejected':rejected,
            'frontier_targets':[[x,y] for x,y in TARGETS],
            'frontier_hit_in_finite_matrix':sorted(seen),
            'frontier_unwitnessed_in_finite_matrix':
            sorted({str(x)+','+str(y) for x,y in TARGETS}-seen),
            'gate_combinations':combos,
            'm1_and_q_ge3_observed_in_finite_matrix':
            any(a['m1_q3_or_more_observed'] for a in combos),
            'cases':audits,'global_reachability_proven':False,
            'global_input_ownership_proven':False,'stage1_pass':False}
    (folder/'qa31s_independent.json').write_text(
        json.dumps(output,sort_keys=True,indent=2)+'\n')
    print('QA31S_12_TRACE_CASES_AUDITED',output['physical_steps_verified'])
    print('QA31S_HOSTILE_CONTROLS',rejected,'OF_18_REJECTED')
    print('QA31S_FINITE_FRONTIER_HITS',sorted(seen))
    print('QA31S_STAGE1_REMAINS_OPEN')

if __name__=='__main__':
    main()
