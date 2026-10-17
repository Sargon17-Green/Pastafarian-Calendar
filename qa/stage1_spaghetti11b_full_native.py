#!/usr/bin/env python3
"""QA11B Native acceptance: frozen 3-IP 17D program, all 208 traps, causal controls.

Usage: python3 qa/stage1_spaghetti11b_full_native.py --group GROUP
GROUP: baseline | axes-low | axes-high | roles | third
A passed individual group is not a claim of full QA11B acceptance.
"""
from __future__ import annotations
import argparse, hashlib, json, re, time, traceback
from pathlib import Path
import stage1_spaghetti10_macro_native as q10
import stage1_spaghetti11b_three_shard_native as q11

SOURCE = Path('qa/spaghetti11_17d_cascade_208_generated_candidate.beq')
MANIFEST = Path('qa/SPAGHETTI11B_THIRD_RESIDUE_MACRO_MANIFEST.json')
QA11A = Path('qa/spaghetti11_17d_three_worker_cascade.beq')
EXPECTED_SOURCE = 'afa261c6eab74d69b6c3afbe6c641fc130d627c0'
MODES = ('funge', 'native')
GROUPS = ('baseline', 'axes-low', 'axes-high', 'roles', 'third')


def fingerprint(result):
    canonical = json.dumps(result['output'], separators=(',', ':')).encode('ascii')
    return {'exit': result['rc'], 'seconds': result['elapsed_s'],
            'timeout': result['timeout'], 'numeric_count': len(result['output']),
            'numeric_sha256': hashlib.sha256(canonical).hexdigest(),
            'first_values': result['output'][:8],
            'last_values': result['output'][-4:], 'stderr_tail': result['stderr']}


def verify_source(raw, meta):
    q10.check(q10.gitblob(raw) == EXPECTED_SOURCE, 'QA11B frozen source drift')
    q10.check(q10.gitblob(QA11A.read_bytes()) == meta['qa11a_parent_source_sha']
              == q11.QA11A_SHA, 'QA11A Native-signed parent changed')
    q10.check(meta['qa10_parent_source_sha'] == q11.QA10_SHA,
              'QA10 immutable parent changed in manifest')
    q10.check(len(raw) == meta['source_bytes'] == 68832,
              'QA11B physical length changed')
    q10.check(meta['dimensions'] == 17 and meta['worker_count'] == 3
              and len(meta['stages']) == 16 and meta['generated_opcode_count'] == 208,
              'QA11B geometry/worker counts changed')
    lines, panels = q10.lines_and_panels(raw)
    q10.check(len(panels) == 242, 'Wrong number of physical panels')
    traps = [(i, h, b) for i, h, b in panels if b == '@']
    q10.check(len(traps) == 208, 'Missing hostile source traps')
    def coordinate(header):
        m = re.fullmatch(r'Lines 1,Origin (-?\d+):(-?\d+),Coord ((?:-?\d+:){15})',
                         header.rstrip('\n'))
        q10.check(m is not None, 'Malformed 17-dimensional panel '+header)
        return tuple([int(m[1]), int(m[2])] + [int(x) for x in m[3].split(':')[:-1]])
    trap_coordinates = [coordinate(h) for _, h, _ in traps]
    targets = [tuple(v) for st in meta['stages'] for v in st['target_positions']]
    q10.check(len(set(trap_coordinates)) == 208 and set(trap_coordinates) == set(targets),
              '208 trap positions are not exactly the manifest target cells')
    R = meta['cross_residual_formula']
    for st in meta['stages']:
        found = [(i, s) for i, h, s in panels if h.startswith(
            'Lines 1,Origin %d:' % st['source_x']) and len(s) > 1000]
        q10.check(len(found) == 1 and found[0][1].count(R + '+') == 13,
                  'Missing causal three-worker operand in axis '+str(st['axis']))
        q10.check(len(st['target_positions']) == 13 and
                  all(len(p) == 17 for p in st['target_positions']),
                  'Stage geometry is not 17D')
    return lines, panels, traps


def axis_mutation(original, st):
    ls, panels = q10.lines_and_panels(original)
    targets = [(i, body) for i, header, body in panels if
               header.startswith('Lines 1,Origin %d:' % st['source_x']) and len(body) > 1000]
    q10.check(len(targets) == 1, 'Axis panel not unique')
    i, body = targets[0]
    offset = 0
    if st['axis'] == 1:
        offset = len(q10.addr(10001)+'g.'+q10.addr(10003)+'g.'+
                     q10.addr(10007)+'g.'+'&:'+'0'*17+'p0')
    old = q10.integer_literal(st['axis'])
    new = q10.integer_literal(st['axis'] + (1 if st['axis'] <= 13 or st['axis'] == 16 else -1))
    q10.check(len(old) == len(new) and body[offset:offset+len(old)+1] == old+'+',
              'Axis contribution source location changed: '+str(st['axis']))
    ls[i+1] = body[:offset] + new + body[offset+len(old):] + '\n'
    return ''.join(ls).encode('ascii')


def role_mutation(original, st, R, from_c, to_c, occurrence=1):
    ls, panels = q10.lines_and_panels(original)
    x = st['source_x']
    matching = [(i, s) for i, h, s in panels if h.startswith(
        'Lines 1,Origin %d:' % x) and len(s) > 1000]
    q10.check(len(matching) == 1, 'Role stage missing')
    i, body = matching[0]
    tri = st['axis']*(st['axis']+1)//2
    old = ':'+q10.integer_literal(tri)+'-'+R+'+:*'+q10.integer_literal(from_c)+'+'
    new = ':'+q10.integer_literal(tri)+'-'+R+'+:*'+q10.integer_literal(to_c)+'+'
    matches = list(re.finditer(re.escape(old), body))
    q10.check(len(old) == len(new) and len(matches) >= occurrence,
              'Requested opcode role absent')
    start = matches[occurrence-1].start()
    ls[i+1] = body[:start]+new+body[start+len(old):]+'\n'
    return ''.join(ls).encode('ascii')


def run_check(receipt, name, raw, seed, mode, timeout, should_match):
    got = q10.native(raw, seed, mode, timeout)
    item = {'case': name, 'seed': seed, 'scheduler': mode, 'input_blob': q10.gitblob(raw),
            'bound_seconds': timeout, **fingerprint(got)}
    healthy = got['rc'] == 0 and got['output'] == q11.expected(seed)
    item['matches_healthy_oracle'] = healthy
    receipt['runs'].append(item)
    print('QA11B_FULL', name, mode, seed, got['rc'], len(got['output']),
          got['elapsed_s'], 'GREEN' if healthy else 'DIFFERENT', flush=True)
    q10.check(healthy == should_match, 'Unexpected Native behavior '+name+': '+repr(item))
    return got


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--group', choices=GROUPS, required=True)
    args = parser.parse_args()
    raw = SOURCE.read_bytes()
    meta = json.loads(MANIFEST.read_text('utf-8'))
    receipt = {'schema': 'qa11b-full-17d-three-IP-208-cell-acceptance-v1',
               'group': args.group, 'source_git_blob': q10.gitblob(raw),
               'manifest_sha256': hashlib.sha256(MANIFEST.read_bytes()).hexdigest(),
               'engine_requires_disposable_scheduler_shutdown_fix': True,
               'native_only': True, 'runs': [], 'final_status': 'INCOMPLETE'}
    path = Path('spaghetti11b_full_%s_receipt.json' % args.group.replace('-', '_'))
    try:
        lines, panels, traps = verify_source(raw, meta)
        if args.group == 'baseline':
            for mode in MODES:
                for seed in (1, 2):
                    for iteration in range(2):
                        run_check(receipt, 'healthy-repeat-'+str(iteration), raw,
                                  seed, mode, 240, True)
            masked = lines[:]
            for i, _, _ in traps:
                masked[i+1] = 'q\n'
            masked = ''.join(masked).encode('ascii')
            q10.check(q10.gitblob(masked) != q10.gitblob(raw), 'Mask is inert at source')
            for seed in (1, 2):
                run_check(receipt, 'all-208-hostile-traps-masked', masked,
                          seed, 'funge', 240, True)
        else:
            # Every counterfactual group has its own matching Native baseline,
            # plus a harmless source edit under the identical calibrated deadline.
            standard = run_check(receipt, 'local-healthy-calibration', raw, 1,
                                 'funge', 240, True)
            bound = max(200, int(standard['elapsed_s']*1.7)+35)
            neutral = q10.replace_one_panel(raw,
                lambda h, b: h.startswith('Lines 1,Origin 10005:0,') and b == 'z',
                'z', 'q')
            run_check(receipt, 'neutral-sentinel-equal-timing', neutral,
                      1, 'funge', bound, True)
            receipt['calibration'] = {'baseline_seconds': standard['elapsed_s'],
                                      'counterfactual_timeout_seconds': bound,
                                      'neutral_control_completed': True}
            if args.group.startswith('axes-'):
                steps = meta['stages'][:8] if args.group == 'axes-low' else meta['stages'][8:]
                for step in steps:
                    altered = axis_mutation(raw, step)
                    got = run_check(receipt, 'axis-%02d-causes-difference' % step['axis'],
                                    altered, 1, 'funge', bound, False)
                    index = 3 + (step['axis']-1)*14
                    baseline_output = q11.expected(1)
                    q10.check(len(got['output']) > index and
                              got['output'][:index] == baseline_output[:index] and
                              got['output'][index] != baseline_output[index],
                              'Axis mutation lacks localized generated-code witness')
            elif args.group == 'roles':
                st = meta['stages'][7]
                R = meta['cross_residual_formula']
                for name, old, new, occurrence in (
                    ('multiply', 42, 43, 1), ('divide', 47, 37, 1),
                    ('stack-drop', 36, 35, 3), ('direction-turn', 62, 61, 1)):
                    altered = role_mutation(raw, st, R, old, new, occurrence)
                    got = run_check(receipt, 'opcode-role-'+name, altered, 1,
                                    'funge', bound, False)
                    role_index = {'multiply': 5, 'divide': 7,
                                  'stack-drop': 9, 'direction-turn': 12}[name]
                    index = 3 + (st['axis']-1)*14 + role_index
                    q10.check(len(got['output']) > index and
                              got['output'][index] == new,
                              'Generated opcode role was not physically changed: '+name)
            elif args.group == 'third':
                independent = q11.mutate_worker_divider(QA11A.read_bytes())
                c = q10.native(independent, 1, 'funge', 25)
                receipt['third_worker_independent_witness'] = fingerprint(c)
                q10.check(c['rc'] == 0 and c['output'] == [31, 33, 21],
                          'Independent third worker no longer completes')
                altered = q11.mutate_worker_divider(raw)
                for seed in (1, 2):
                    got = run_check(receipt, 'third-worker-residue-changes-code',
                                    altered, seed, 'funge', bound, False)
                    # An altered printed residue or mere timeout does NOT prove
                    # that any future opcode was changed.
                    q10.check(len(got['output']) > 3 and
                              got['output'][3] != q11.expected(seed)[3],
                              'Missing executable future-opcode causal witness')
        receipt['final_status'] = 'PASS'
        print('QA11B_FULL_NATIVE_GROUP_PASS', args.group, flush=True)
    except BaseException as exc:
        receipt['final_status'] = 'FAIL'
        receipt['failure'] = {'type': type(exc).__name__, 'message': str(exc),
                              'traceback': traceback.format_exc()[-2000:]}
        raise
    finally:
        path.write_text(json.dumps(receipt, indent=2, sort_keys=True)+'\n',
                        encoding='utf-8')


if __name__ == '__main__':
    main()
