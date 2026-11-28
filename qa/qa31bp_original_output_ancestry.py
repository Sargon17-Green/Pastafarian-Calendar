#!/usr/bin/env python3
"""QA31BP: fixed-path provenance of an original signed Befunge-98 suffix.

Only pre-existing SHA-pinned original Native traces are read. Nothing here
executes the original interpreter or establishes an altered-run path/causality.
Standard Python 3.11+, no third-party packages.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
import copy
import gzip
import hashlib
import io
import json
from pathlib import Path
import zipfile

P = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
PIN = {'AI': '9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49',
       'AH': '4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271',
       'Y': '1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a',
       'BN': '6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79',
       'BO': 'b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de'}
SOURCE = '560d6aa5807a7f766213a33835cce85eab0fa40c'


def demand(cond, why):
    if not cond:
        raise ValueError(why)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def nested(data, label):
    demand(digest(data) == PIN[label], label + ' input SHA256 mismatch')
    z = zipfile.ZipFile(io.BytesIO(data))
    demand(z.testzip() is None, label + ' CRC mismatch')
    return z


def jsonlines(raw):
    return [json.loads(line) for line in raw.splitlines() if line.strip()]


def check_manifest(z, path):
    m = json.loads(z.read(path))
    demand(m['project_id'] == P, 'manifest PROJECT_ID')
    for name, sha in m['files'].items():
        demand(digest(z.read(name)) == sha, 'manifest payload ' + name)
    return m


def original_cases(ai_bytes, bn_bytes, bo_bytes):
    with nested(bn_bytes, 'BN') as bn, nested(bo_bytes, 'BO') as bo:
        bm = check_manifest(bn, 'MANIFEST.json')
        om = check_manifest(bo, 'MANIFEST.json')
        demand(bm['stage1_pass'] is False and om['stage1_pass'] is False, 'unexpected Stage1 status')
        bs = json.loads(bn.read('evidence/qa31bn_summary.json'))
        os = json.loads(bo.read('evidence/qa31bo_summary.json'))
        demand(bs['source_blob'] == os['source_blob'] == SOURCE, 'source pin mismatch')
        demand(os['changed_predictions'] == 446 and os['selected_original_cases'] == 135, 'BO cohort mismatch')
        cases = defaultdict(list)
        for group in ('interventions', 'boundaries'):
            for r in jsonlines(bn.read(f'evidence/qa31bn_{group}.jsonl')):
                if r['classification'] == 'SINK_CHANGED':
                    demand(r['forward_sinks'] == r['symbolic_sinks'], 'unreconciled model')
                    cases[r['case']].append(r)
        noops = jsonlines(bn.read('evidence/qa31bn_noops.jsonl'))
        demand(len(cases) == 135 and sum(map(len,cases.values())) == 446, 'BN selection mismatch')
        demand(len(noops) == 24, 'no-op cohort mismatch')
        for r in noops:
            demand(r['original_g'] == r['intervention_g'] and r['baseline_sinks'] == r['forward_sinks'], 'not a genuine no-op')
            cases[r['case']].append(r)
        demand(len(cases) == 135, 'no-op outside selected original selection')
    with nested(ai_bytes, 'AI') as ai:
        with nested(ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'), 'AH') as ah:
            ybytes = ah.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip')
    with nested(ybytes, 'Y') as y:
        ym = check_manifest(y, 'QA31Y_MANIFEST.json')
        signed = Counter()
        for shard in range(8):
            name = f'QA31V_SHARD{shard}.zip'
            zipped = y.read(name)
            demand(digest(zipped) == ym['files'][name], 'original shard SHA ' + name)
            with zipfile.ZipFile(io.BytesIO(zipped)) as s:
                demand(s.testzip() is None, 'original shard CRC ' + name)
                receipt = json.loads(s.read('qa31v_receipt.json'))
                demand(receipt['source_blob'] == SOURCE and receipt['shard'] == shard and len(receipt['cases']) == 25, 'shard source or cardinality')
                for case in receipt['cases']:
                    demand(case['status'] == 'HALT' and case['error'] is None and case['steps'] <= 25000, 'original not HALT')
                    compressed = s.read(case['trace'])
                    demand(digest(compressed) == case['trace_sha256'], 'signed trace SHA ' + case['label'])
                    signed['original'] += 1
                    signed['steps'] += case['steps']
                    if case['label'] not in cases:
                        continue
                    ev = jsonlines(gzip.decompress(compressed))
                    demand(len(ev) == case['steps'] and all(e['t'] == i for i,e in enumerate(ev,1)), 'non-contiguous STEP ' + case['label'])
                    yield case, ev, cases[case['label']], signed
        demand(signed['original'] == 200 and signed['steps'] == 3628390, 'signed original corpus mismatch')


def op(event):
    demand(event['string'] is False and 0 <= event['op'] < 128, 'unknown instruction encoding')
    return chr(event['op'])


def inspect(case, events, predictions):
    """Chronological last-writer index; concrete suffix stack with taint propagation."""
    label = case['label']
    demand(all(r['case'] == label and r['trace_sha256'] == case['trace_sha256'] for r in predictions), 'case/prediction association')
    first, second = predictions[0]['sink_ticks']
    demand(all(r['sink_ticks'] == [first, second] for r in predictions), 'sink disagreement')
    demand(0 < first < second < len(events), 'sink bounds')
    for tick, addr in [(first,(103,1715)),(second,(107,1716))]:
        e = events[tick-1]
        demand(op(e) == 'p' and tuple(e['pre'][-2:]) == addr and e['post'] == [], 'original sink shape')
        demand(all(e['pre'][-3] == r['baseline_sinks'][0 if tick == first else 1] for r in predictions), 'signed sink baseline mismatch')
    last = {}
    for e in events:
        if op(e) == 'p':
            demand(len(e['pre']) >= 3, 'missing p operands')
            address = tuple(e['pre'][-2:])
            last[address] = (e['t'], e['pre'][-3])
        if e['t'] == second:
            # A saved snapshot of the entire physical history at sink2, separate from
            # suffix writes, so that a later g can resolve its last pre-read owner.
            before = dict(last)
            break
    suffix = events[second:]
    g_events = [e for e in suffix if op(e) == 'g']
    demand(len(g_events) == 1 and tuple(g_events[0]['pre'][-2:]) == (19,1696), 'post-second-sink g site')
    g = g_events[0]
    # Complete chronological p writes up to this particular g (not the last p at HALT).
    for e in events[second:g['t']-1]:
        if op(e) == 'p':
            before[tuple(e['pre'][-2:])] = (e['t'],e['pre'][-3])
    owner = before.get((19,1696))
    demand(owner is not None and owner[0] < first, 'writer does not precede first sink')
    demand(g['post'] == [owner[1]], 'signed p->g value mismatch')
    demand(g['pre'] == [19,1696], 'g address stack not isolated')

    # Concrete stack and conservative taint simulation on original signed suffix:
    # ROOT may propagate even through arithmetic with zero (no false disconnection).
    stack = []  # (value, set of provenance labels)
    output = []
    output_taints = []
    p_after_g = []
    for e in suffix:
        name = op(e)
        demand([v for v,_ in stack] == e['pre'], 'suffix pre stack mismatch tick ' + str(e['t']))
        if name in '0123456789':
            stack.append((int(name),frozenset()))
        elif name == 'a':
            stack.append((10,frozenset()))
        elif name in '+-*':
            demand(len(stack) >= 2, 'arithmetic stack underflow')
            b,bt = stack.pop()
            a,at = stack.pop()
            value = a+b if name == '+' else a-b if name == '-' else a*b
            stack.append((value,at|bt))
        elif name == 'g':
            y,yt = stack.pop()
            x,xt = stack.pop()
            demand((x,y) == (19,1696), 'changed g coordinate in signed suffix')
            demand(not xt and not yt, 'source-dependent g address')
            stack.append((owner[1],frozenset({'PRE_FIRST_SINK_WRITER'})))
        elif name == 'p':
            y,yt = stack.pop()
            x,xt = stack.pop()
            v,vt = stack.pop()
            demand(e['pre'][-3:] == [v,x,y], 'p consumed different value')
            if e['t'] > g['t']:
                p_after_g.append({'tick':e['t'],'address':[x,y],'value':v,'taints':sorted(vt|xt|yt)})
        elif name == 'x':
            demand(len(stack) >= 2, 'x vector underflow')
            stack.pop(); stack.pop()
        elif name == '.':
            v,t = stack.pop()
            output.append(v)
            output_taints.append(t)
        elif name in '><v@':
            pass
        else:
            raise ValueError('unsupported suffix instruction '+repr(name))
        demand([v for v,_ in stack] == e['post'], 'suffix post stack mismatch tick ' + str(e['t']))
    demand(op(suffix[-1]) == '@' and suffix[-1]['t'] == len(events), 'original HALT inconsistency')
    demand(len(output) == 7 and output == [-1]*7, 'unexpected terminal outputs')
    demand(all(not t for t in output_taints), 'pre-first-sink writer data reaches terminal output')
    demand(case['output'] == ['-1']*7, 'receipt/output mismatch')
    demand(len(p_after_g) == 1, 'unexpected p count after g')
    code_p = p_after_g[0]
    demand(code_p['address'] == [1500,1860] and code_p['value'] == ord('>')
           and code_p['taints'] == ['PRE_FIRST_SINK_WRITER'], 'untracked source-dependent code write')
    code_fetches = [e for e in suffix if e['t'] > code_p['tick']
                    and tuple(e['ip']) == (1500,1860)]
    # The code fetch must occur after the p write but before the first terminal output.
    first_dot_tick = next(e['t'] for e in suffix if op(e) == '.')
    demand(len(code_fetches) == 1 and op(code_fetches[0]) == '>'
           and code_p['tick'] < code_fetches[0]['t'] < first_dot_tick,
           'original data-to-code fetch boundary missing')
    # Reverse-only owner oracle for the executable byte: find the nearest p that
    # wrote the fetched cell before this physical instruction fetch.
    fetched = code_fetches[0]
    code_writer = next((e for e in reversed(events[:fetched['t']-1])
                        if op(e) == 'p' and tuple(e['pre'][-2:]) == tuple(fetched['ip'])), None)
    demand(code_writer is not None and code_writer['t'] == code_p['tick']
           and code_writer['pre'][-3] == fetched['op'], 'independent code-owner oracle disagreement')

    # Independently verify output with backward local literal slicing rather than
    # taint propagation. For each signed ".", fixed opcode window 0 1 - .
    # must start with empty stack and the previous instruction must reset it.
    dots = [i for i,e in enumerate(events) if e['t'] > second and op(e) == '.']
    demand(len(dots) == 7, 'independent output count')
    for i in dots:
        demand(''.join(op(x) for x in events[i-3:i+1]) == '01-.', 'no literal-only output window')
        demand(events[i-3]['pre'] == [] and events[i-3]['post'] == [0], 'literal window no reset')
        demand(events[i-2]['post'] == [0,1] and events[i-1]['post'] == [-1], 'literal window value')
        demand(events[i]['pre'] == [-1] and events[i]['post'] == [], 'literal output value')
    demand(all(op(events[i-4]) == '.' for i in dots[1:]), 'no local output reset anchor')

    # Reverse physical writer search: no chronological live-memory index reused.
    backwards = next((e for e in reversed(events[:g['t']-1])
                      if op(e) == 'p' and tuple(e['pre'][-2:]) == (19,1696)), None)
    demand(backwards is not None and (backwards['t'], backwards['pre'][-3]) == owner, 'reverse writer disagrees')
    return {'case':label,'trace_sha256':case['trace_sha256'],'first_sink':first,'second_sink':second,
            'g_tick':g['t'],'g_address':[19,1696],'g_value':g['post'][-1],
            'writer_tick':owner[0],'writer_value':owner[1],
            'terminal_output':output,'terminal_stack_tainted':False,'last_p_after_g':code_p,
            'code_fetch_tick':fetched['t'],'tainted_code_fetch_before_output':True,
            'independent_literal_windows':len(dots),'predictions':len(predictions)}


def hostile_checks(case, ev, predictions, baseline):
    """Detached signed event mutations must not be mistaken for original evidence."""
    first,second=predictions[0]['sink_ticks']
    g_tick=baseline['g_tick']
    writer_tick=baseline['writer_tick']
    dot_tick=next(e['t'] for e in ev[second:] if op(e)=='.')
    p_tick=baseline['last_p_after_g']['tick']
    changes = [
        ('false_writer_value',writer_tick,'pre',0,1),
        ('wrong_writer_coordinate_x',writer_tick,'pre',1,1),
        ('wrong_writer_coordinate_y',writer_tick,'pre',2,1),
        ('wrong_writer_opcode',writer_tick,'op',None,ord('g')),
        ('false_read_x',g_tick,'pre',0,1),
        ('false_read_y',g_tick,'pre',1,1),
        ('false_read_value',g_tick,'post',0,1),
        ('false_read_opcode',g_tick,'op',None,ord('p')),
        ('second_sink_value',second,'pre',0,1),
        ('nonempty_reset',p_tick,'post',None,[1]),
        ('false_output',dot_tick,'pre',0,1),
        ('wrong_output_opcode',dot_tick,'op',None,ord('g')),
        ('wrong_code_fetch_opcode',baseline['code_fetch_tick'],'op',None,ord('?')),
        ('wrong_code_fetch_address',baseline['code_fetch_tick'],'ip',0,1),
        ('wrong_code_writer_value',p_tick,'pre',0,1),
        ('wrong_code_writer_address',p_tick,'pre',1,1),
    ]
    passed=[]
    for label,tick,field,pos,new in changes:
        clone=list(ev)
        old=copy.deepcopy(ev[tick-1])
        clone[tick-1]=old
        if pos is None:old[field]=new
        else:old[field][pos] = old[field][pos]+new
        try:
            inspect(case,clone,predictions)
        except (ValueError,IndexError,AssertionError) as exc:
            passed.append({'mutation':label,'rejected':True,'reason':str(exc)[:160]})
        else:
            raise AssertionError('forged signed STEP was accepted: '+label)
    return passed


def main():
    a=argparse.ArgumentParser()
    a.add_argument('--ai',type=Path,required=True)
    a.add_argument('--bn',type=Path,required=True)
    a.add_argument('--bo',type=Path,required=True)
    a.add_argument('--out',type=Path,required=True)
    arg=a.parse_args()
    demand(not arg.out.exists(), 'output directory exists')
    report=[]; hostiles=[]; noops=0; signed = None
    for case,events,rows,counters in original_cases(arg.ai.read_bytes(),arg.bn.read_bytes(),arg.bo.read_bytes()):
        result=inspect(case,events,rows)
        report.append(result)
        if len(hostiles) == 0:
            hostiles=hostile_checks(case,events,rows,result)
        noops += sum(r['original_g'] == r['intervention_g'] for r in rows)
        signed=dict(counters)
    demand(len(report) == 135 and len(hostiles) == 16 and noops == 24, 'final cohorts invalid')
    demand(all(r['writer_value'] == r['g_value'] == 0 and r['writer_tick'] < r['first_sink'] for r in report),'owner class varies')
    demand(Counter(r['writer_tick'] for r in report) == {11135:99,11287:36},'last-writer tick distribution')
    demand(all(r['terminal_output'] == [-1]*7 and r['independent_literal_windows'] == 7
               and r['tainted_code_fetch_before_output'] for r in report), 'terminal output/code provenance changes')
    counts = {'signed_original_cases':200,'signed_original_steps':3628390,'selected_cases':135,
              'g_reads':135,'owner_before_first_sink':135,'writer_ticks':{'11135':99,'11287':36},
              'terminal_outputs':945,'terminal_values':'-1 x 945','direct_stack_output_dependencies':0,'original_data_to_code_fetch_before_output':135,
              'independent_literal_windows':945,'genuine_noop_controls':noops,
              'hostile_signed_step_mutations_rejected':len(hostiles),
              'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False,
              'scope':'original signed path: pre-first writer -> g -> p executable instruction -> code fetch -> output block. Altered-run route, code bytes, numeric causality UNKNOWN'}
    arg.out.mkdir(parents=True)
    def save(name,content):
        (arg.out/name).write_bytes(content)
    def dump_rows(rs):
        return ''.join(json.dumps(r,ensure_ascii=False,sort_keys=True)+'\n' for r in rs).encode()
    save('qa31bp_cases.jsonl',dump_rows(sorted(report,key=lambda r:r['case'])))
    save('qa31bp_hostile_controls.jsonl',dump_rows(hostiles))
    save('qa31bp_summary.json',(json.dumps(counts,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode())
    print(json.dumps(counts,ensure_ascii=False,sort_keys=True))

if __name__ == '__main__':
    main()