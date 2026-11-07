#!/usr/bin/env python3
"""QA31Y: finite original-Native j last-writer/read observations, not causal proof.

Reuses only QA31X's independently hash-checked ZIP/CSV loader. No Native calls.
Usage: python stage1_qa31y_source_pinned_last_writer_reader.py \
  --zip-dir DIR --qa31w-csv FILE --out OUT
"""
import argparse
import collections
import csv
import hashlib
import json
from pathlib import Path
from stage1_qa31x_pairwise_first_divergence import CaseReader, load_w_csv, selected_pairs, check

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
HEAD_BEFORE = 'b3542a3acb3d81df6ccf3fc13b0604f12322172a'
ORIGINAL_RUN = 41689861481
LOOKBACK = 384
# These original-source sites were independently inspected via the GitHub
# Git blob API at SOURCE_BLOB. This pin does not assert every opcode in source.
OPCODES = {
    (13,5): 126, (60,5): 112, (107,5): 103,
    (57,8): 103, (151,8): 103,
    (57,17): 103, (129,17): 103, (202,17): 103, (275,17): 103,
    (174,8): 49, (175,8): 43, (176,8): 43, (184,8): 42, (185,8): 106,
    (324,17): 49, (325,17): 43, (326,17): 43, (334,17): 42, (335,17): 106,
}
SITES = {(185,8): ((174,8),(175,8),(176,8),(184,8)),
         (335,17): ((324,17),(325,17),(326,17),(334,17))}


def site(e):
    return tuple(e['ip'])


def source_sites_check(events):
    checks = 0
    for e in events:
        ip = site(e)
        if ip in OPCODES:
            check(e['op'] == OPCODES[ip], 'source opcode mismatch at %s tick %d' % (ip, e['t']))
            checks += 1
    return checks


def p_address(e):
    v = e['pre']
    if len(v) < 3:
        return None
    return (v[-2], v[-1])


def g_address(e):
    v = e['pre']
    if len(v) < 2:
        return None
    return (v[-2], v[-1])


def last_write(events, before_index, addr):
    # Physical 'p' only. 's' or other memory changes are deliberately untracked.
    if addr is None:
        return None
    for i in range(before_index - 1, -1, -1):
        e = events[i]
        if e['op'] == 112 and p_address(e) == addr:
            return {'tick': e['t'], 'ip': e['ip'], 'target': list(addr),
                    'value': e['pre'][-3]}
    return None


def local_j_check(events, index):
    j = events[index]
    coord = site(j)
    check(coord in SITES and j['op'] == 106 and index >= 4, 'wrong j site')
    tail = events[index - 4:index]
    check(tuple(map(site, tail)) == SITES[coord], 'nonmatching four-step expression')
    for e in tail:
        check(e['op'] == OPCODES[site(e)], 'tail source opcode')
    before_mul = tail[-1]['pre']
    check(len(before_mul) >= 2, 'mul arity')
    flag, constant = before_mul[-2:]
    check(constant == 61 and flag in (0,1), 'literal 61 or Boolean gate missing')
    check(tail[-1]['post'] == before_mul[:-2] + [flag*61], 'incorrect physical multiplication')
    check(j['pre'] and j['pre'][-1] == flag*61 and
          j['post'] == j['pre'][:-1], 'incorrect j stack operand')
    check(j['delta'] == [1,0] and j['next_delta'] == [1,0], 'unexpected direction')
    check(j['next'] == [coord[0] + flag*61 + 1, coord[1]], 'wrong original-Native jump')
    return flag


def physical_reads(events, index):
    out = []
    for e in events[:index]:
        for r in e.get('reads', []):
            out.append({'tick': e['t'], 'ip': e['ip'],
                        'method': r.get('method'), 'hex': r.get('hex'),
                        'start': r.get('start'), 'end': r.get('end')})
    return out


def audit_jump(events, index, label):
    j = events[index]
    flag = local_j_check(events, index)
    lo = max(0, index-LOOKBACK)
    upstream = []
    for i in range(lo, index):
        g = events[i]
        if g['op'] != 103 or site(g) not in OPCODES:
            continue
        addr = g_address(g)
        writer = last_write(events, i, addr)
        value = g['post'][-1] if g['post'] else None
        upstream.append({'g_tick': g['t'], 'g_ip': g['ip'],
                         'target': None if addr is None else list(addr),
                         'read_value': value, 'last_physical_p': writer,
                         'p_to_g_value_match': None if writer is None else (writer['value']==value),
                         'proven_causal_parent_of_j': False})
    reads = physical_reads(events, index)
    return {'label': label, 'j_tick': j['t'], 'j_ip': j['ip'], 'operand': j['pre'][-1],
            'flag_before_multiply': flag, 'next_ip': j['next'],
            'local_four_step_expression': 'verified',
            'lookback_steps': min(LOOKBACK,index),
            'upstream_g': upstream,
            'prior_physical_stdin_reads': reads,
            'input_byte_owner_of_j': 'unknown',
            'global_reachability_proven': False}


def synthetic_tests():
    def e(t, ip, op, pre, post, nxt):
        return {'t':t, 'ip':list(ip), 'delta':[1,0], 'op':op,
                'pre':pre, 'post':post, 'next':list(nxt), 'next_delta':[1,0],
                'reads':[], 'string':False}
    rows = [
        e(1,(174,8),49,[1,0,60],[1,0,60,1],(175,8)),
        e(2,(175,8),43,[1,0,60,1],[1,0,61],(176,8)),
        e(3,(176,8),43,[1,0,61],[1,61],(184,8)),
        e(4,(184,8),42,[1,61],[61],(185,8)),
        e(5,(185,8),106,[61],[],(247,8)),
    ]
    tests = 0
    check(local_j_check(rows,4)==1,'positive test'); tests += 1
    check(source_sites_check(rows)==5,'source positive'); tests += 1
    tests += int(p_address({'pre':[9,0,49]}) == (0,49))
    tests += int(g_address({'pre':[9,0,49]}) == (0,49))
    tests += int(last_write([{'op':112,'t':1,'ip':[1,1],'pre':[7,0,49]}],1,(0,49))['value']==7)
    tests += int(last_write([],0,(0,49)) is None)
    # Fail-closed source/site, stack, operand, successor, direction, wrong tail.
    for idx,key,value in [(0,'op',57),(3,'op',43),(3,'post',[0]),
                          (4,'pre',[0]),(4,'next',[186,8]),
                          (4,'delta',[-1,0]),(3,'ip',[184,9])]:
        bad=[dict(x) for x in rows]
        bad[idx]=dict(bad[idx], **{key:value})
        try:
            local_j_check(bad,4)
        except AssertionError:
            tests += 1
        else:
            raise AssertionError('hostile synthetic control admitted '+key)
    bad=[dict(x) for x in rows];bad[4]=dict(bad[4],op=48)
    try: source_sites_check(bad)
    except AssertionError: tests += 1
    else: raise AssertionError('source hostile admitted')
    check(tests==14,'synthetic check count: '+str(tests))
    return tests


def run(zip_dir,csv_path,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    table=load_w_csv(csv_path)
    pairs,_=selected_pairs(table)
    selected=sorted({x['label'] for _,a,b in pairs for x in (a,b)})
    record={r['label']:r for r in table}
    check(len(selected)==29,'expected frozen 29 physical traces')
    reader=CaseReader(zip_dir)
    witnesses=[]; source_count=0; reads_count=0
    for label in selected:
        ev=reader.load(record[label])
        source_count+=source_sites_check(ev)
        reads_count+=sum(len(e.get('reads',[])) for e in ev)
        for i,e in enumerate(ev):
            if e['op']==106 and site(e) in SITES:
                witnesses.append(audit_jump(ev,i,label))
    tests=synthetic_tests()
    counts=collections.Counter((tuple(x['j_ip']),x['operand']) for x in witnesses)
    p_matches=collections.Counter(y['p_to_g_value_match'] for x in witnesses for y in x['upstream_g'])
    report={
      'schema':'qa31y-bounded-original-native-last-writer-reader-v1',
      'project_id':PROJECT,'source_blob':SOURCE_BLOB,'base_head':HEAD_BEFORE,
      'original_native_run':ORIGINAL_RUN,
      'original_artifact_zip_count':len(reader.zips),
      'original_signed_traces_verified':len(reader.processed),
      'physical_steps_verified':sum(reader.processed.values()),
      'physical_read_events_in_selected_traces':reads_count,
      'source_pinned_opcode_checks':source_count,
      'observed_j_events':len(witnesses),
      'j_by_site_and_operand':{'%d,%d:operand=%d'%(*k[0],k[1]):v for k,v in sorted(counts.items())},
      'g_writer_value_matching':{str(k):v for k,v in p_matches.items()},
      'synthetic_tests_passed':tests,'lookback_cap':LOOKBACK,
      'input_byte_owner_of_j':'unknown',
      'global_reachability_proven':False,'stage1_pass':False,
    }
    # Correct source artifact hashes come from the independently pinned loader.
    from stage1_qa31x_pairwise_first_divergence import ZIP_SHA256
    report['original_zip_sha256']=ZIP_SHA256
    matched={(w['label'],g['g_tick'],g['last_physical_p']['tick']) for w in witnesses for g in w['upstream_g'] if g['p_to_g_value_match'] is True}
    report['distinct_p_to_g_value_matches']=len(matched)
    (out/'QA31Y_EVIDENCE.json').write_text(json.dumps({'summary':report,'j_witnesses':witnesses},ensure_ascii=False,sort_keys=True,indent=2)+'\n')
    (out/'QA31Y_SUMMARY.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    with (out/'QA31Y_J_WITNESSES.csv').open('w',encoding='utf-8',newline='') as f:
        w=csv.writer(f);w.writerow(['label','tick','j_x','j_y','operand','flag','next_x','next_y','g_events_in_384','stdin_events_prior','input_owner'])
        for x in witnesses:
            w.writerow([x['label'],x['j_tick'],*x['j_ip'],x['operand'],x['flag_before_multiply'],*x['next_ip'],len(x['upstream_g']),len(x['prior_physical_stdin_reads']),'unknown'])
    print(json.dumps(report,sort_keys=True))
    return report

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--zip-dir',required=True)
    p.add_argument('--qa31w-csv',required=True)
    p.add_argument('--out',required=True)
    a=p.parse_args()
    run(Path(a.zip_dir),Path(a.qa31w_csv),Path(a.out))
