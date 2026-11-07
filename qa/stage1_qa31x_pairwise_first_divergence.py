#!/usr/bin/env python3
"""QA31X: bounded offline first-divergence audit of pre-existing QA31V Native STEPs.

No Native rerun. Uses 8 exact-SHA-pinned QA31V shard ZIPs and 200-case QA31W
classification. Cross-route pairs, shard edges, and within-route controls.
The tool reports observed comparisons, never universal reachability or causality.
Python 3 standard library, runs as:
  python stage1_qa31x_pairwise_first_divergence.py --zip-dir DIR --qa31w-csv FILE --out DIR
"""
import argparse
import collections
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import zipfile

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_SHA = '560d6aa5807a7f766213a33835cce85eab0fa40c'
NATIVE_SHA = 'e3700d9bd600f215b0cdc47d29d45e74f3b7667e'
ZIP_SHA256 = [
 '5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553',
 '375cdf0e4fd88edbadd096fc7876d5fecde3e08364903222b2f85924d0803c2f',
 '9e71ecd677e9a16f748836ebf567413f27802554ed86d80c9c11376ab3ab396a',
 '19196d6b0a0e37e6ce0703baff330e1d4a004669862d48be3adb6a19a1828458',
 '83de475f9fc295d16c353e92e8c3a565686f53ecb936bc3666af59a7752f7f45',
 '180d394a9aacf11d1b9a381f7997e252ee6dc1e6c772823d2f1698f9085186d0',
 '1eda4ea3bfcb6f305499444752b4c269318ac40cf17f09fce979d3e7e8b30f14',
 'b54d244fcd45d38a4c7f8c99a490d32bfe55ff17de43b33a8239ec5fbf1dfa38',
]
QA31W_CSV_SHA = '0c45aea30f021671084bb4ccaa67436a00edcf1aaa41a6b23e3afbfdf9b89800'
CAP = 25000
PATH_FIELDS = ('ip','delta','op','next','next_delta','string')
STATE_FIELDS = ('pre','post')

def check(cond, reason):
    if not cond: raise AssertionError(reason)

def sha(b): return hashlib.sha256(b).hexdigest()

def event(e):
    return {'t':e['t'],'ip':e['ip'],'delta':e['delta'],'op':e['op'],
            'next':e['next'],'next_delta':e['next_delta'], 'string':e['string'],
            'reads':e.get('reads',[]),'pre':e['pre'],'post':e['post']}

def brief(e):
    if e is None: return None
    return {k:e[k] for k in ('t','ip','delta','op','next','next_delta','reads')}

def first_diff(a,b,keys):
    for i in range(min(len(a),len(b))):
        if any(a[i].get(k)!=b[i].get(k) for k in keys): return i
    if len(a)!=len(b): return min(len(a),len(b))
    return None

def context(a,b,idx):
    if idx is None:return None
    return {'tick':idx+1, 'left':brief(a[idx]) if idx<len(a) else None,
            'right':brief(b[idx]) if idx<len(b) else None}

def read_events(xs):
    return [dict(tick=i+1, ip=e['ip'], reads=e['reads']) for i,e in enumerate(xs) if e.get('reads')]

def branch_witness(a,b):
    # A transition difference at the same executed instruction, same tick.
    # This is an observed transition split, not a universal input cause.
    for i,(x,y) in enumerate(zip(a,b)):
        if all(x.get(k)==y.get(k) for k in ('ip','delta','op','string')) and (
               x['next']!=y['next'] or x['next_delta']!=y['next_delta']):
            return context(a,b,i)
    return None

def compare(a,b):
    idx={
      'first_full_record_difference':first_diff(a,b,PATH_FIELDS+STATE_FIELDS+('reads',)),
      'first_path_difference':first_diff(a,b,PATH_FIELDS),
      'first_ip_delta_difference':first_diff(a,b,('ip','delta')),
      'first_opcode_difference':first_diff(a,b,('op','string')),
      'first_stack_difference':first_diff(a,b,STATE_FIELDS),
      'first_raw_read_record_difference':first_diff(a,b,('reads',)),
    }
    rd_a,rd_b=read_events(a),read_events(b)
    first_read=next((i for i in range(min(len(rd_a),len(rd_b)))
                     if rd_a[i]!=rd_b[i]),None)
    if first_read is None and len(rd_a)!=len(rd_b):first_read=min(len(rd_a),len(rd_b))
    result={k:context(a,b,v) for k,v in idx.items()}
    result['first_read_event_difference'] = None if first_read is None else {
      'event_number':first_read+1,
      'left':rd_a[first_read] if first_read<len(rd_a) else None,
      'right':rd_b[first_read] if first_read<len(rd_b) else None}
    result['first_same_instruction_transition_split']=branch_witness(a,b)
    result['same_path_entire_execution']=(idx['first_path_difference'] is None)
    result['same_ip_opcode_path_entire_execution']=(first_diff(a,b,('ip','delta','op','string')) is None)
    result['left_steps'],result['right_steps']=len(a),len(b)
    result['left_reads'],result['right_reads']=len(rd_a),len(rd_b)
    return result

def guards():
    # Synthetic negative/positive controls are NOT claimed to be Native evidence.
    e=lambda t,ip,op,reads=None: {'t':t,'ip':[ip,0],'delta':[1,0], 'op':op,
           'next':[ip+1,0], 'next_delta':[1,0], 'string':False,
           'reads':reads or [],'pre':[0],'post':[0]}
    a=[e(1,0,48),e(2,1,49),e(3,2,50)]
    b=[dict(x) for x in a]
    tests=0
    def assert_test(flag):
        nonlocal tests
        check(flag,'self-test '+str(tests+1));tests+=1
    r=compare(a,b);assert_test(r['same_path_entire_execution']);assert_test(r['first_full_record_difference'] is None)
    b[1]=dict(b[1], post=[1]);r=compare(a,b)
    assert_test(r['first_stack_difference']['tick']==2);assert_test(r['same_path_entire_execution'])
    b=[dict(x) for x in a];b[2]=dict(b[2], reads=[{'value':9}]);r=compare(a,b)
    assert_test(r['first_raw_read_record_difference']['tick']==3);assert_test(r['first_read_event_difference']['event_number']==1)
    b=[dict(x) for x in a];b[1]=dict(b[1],next=[9,0]);r=compare(a,b)
    assert_test(r['first_same_instruction_transition_split']['tick']==2);assert_test(r['first_path_difference']['tick']==2)
    b=[dict(x) for x in a];b[1]=dict(b[1],ip=[10,0]);r=compare(a,b)
    assert_test(r['first_same_instruction_transition_split'] is None);assert_test(r['first_ip_delta_difference']['tick']==2)
    b=a[:-1];r=compare(a,b)
    assert_test(r['first_path_difference']['tick']==3);assert_test(r['first_raw_read_record_difference']['tick']==3)
    return tests

def load_w_csv(path):
    raw=Path(path).read_bytes()
    check(sha(raw)==QA31W_CSV_SHA,'QA31W CSV SHA mismatch')
    rows=list(csv.DictReader(io.StringIO(raw.decode('utf-8'))))
    check(len(rows)==200,'200 entries required')
    check([int(r['global_index']) for r in rows]==list(range(200)),'row ordering')
    for i,r in enumerate(rows):
        check(int(r['shard'])==i//25 and int(r['within_shard'])==i%25,'shard consistency')
    c=collections.Counter(r['route_id'] for r in rows)
    check(c=={'R1':20,'R2':30,'R3':10,'R4':1,'R5':4,'R6':9,'R7':36,'R8':90},'route totals')
    return rows

def selected_pairs(rows):
    by_route=collections.defaultdict(list)
    for r in rows:by_route[r['route_id']].append(r)
    representatives=[by_route['R'+str(i)][0] for i in range(1,9)]
    pairs=[]; unique=set()
    def add(tag,x,y):
        ids=tuple(sorted((x['label'],y['label'])))
        check(ids[0]!=ids[1],'self-pair')
        if (tag,ids) not in unique:
            unique.add((tag,ids));pairs.append((tag,x,y))
    for i in range(8):
        for j in range(i+1,8):add('cross_route_representatives',representatives[i],representatives[j])
    for i in range(1,8):add('inter_shard_edge',rows[i*25-1],rows[i*25])
    for route in ('R1','R2','R3','R5','R6','R7','R8'):
        group=by_route[route]
        add('same_route_negative_control',group[0],group[-1])
    check(len(pairs)==42,'expected 28+7+7 comparisons')
    return pairs,representatives

class CaseReader:
    def __init__(self,folder):
        self.zips=[]; self.receipts={};self.bytes_scanned=0
        for s in range(8):
            p=Path(folder)/f'QA31V_SHARD{s}.zip'
            check(p.is_file(),f'missing {p}')
            raw=p.read_bytes()
            check(sha(raw)==ZIP_SHA256[s],f'outer artifact SHA mismatch shard{s}')
            self.bytes_scanned+=len(raw)
            z=zipfile.ZipFile(io.BytesIO(raw))
            check(z.testzip() is None,f'bad CRC shard{s}')
            r=json.loads(z.read('qa31v_receipt.json'))
            check(len(r['cases'])==25,f'25 cases shard{s}')
            for item in r['cases']:
                check(item['label'] not in self.receipts,'duplicate label')
                self.receipts[item['label']]=(s,item)
            self.zips.append(z)
        check(len(self.receipts)==200,'200 independent receipt cases')
        self.cache={}; self.processed={}
    def load(self,row):
        label=row['label']
        if label in self.cache:return self.cache[label]
        s,item=self.receipts[label]
        check(s==int(row['shard']),'receipt shard mismatch')
        check(item['trace_sha256']==row['trace_sha256'],'receipt/CSV trace hash mismatch')
        check(item['steps']==int(row['steps']),'receipt/CSV steps mismatch')
        check(item['reads']==int(row['reads']),'receipt/CSV reads mismatch')
        check(item['status']=='HALT','not Native HALT')
        gz=self.zips[s].read(item['trace'])
        check(sha(gz)==item['trace_sha256'],'physical trace gzip SHA mismatch '+label)
        events=[event(json.loads(ln)) for ln in gzip.decompress(gz).splitlines()]
        check(len(events)==item['steps'] and 0<len(events)<=CAP,'trace step count')
        check(events[0]['t']==1 and events[0]['ip']==[0,0],'initial IP')
        check(all(x['t']==j+1 for j,x in enumerate(events)),'STEP ordinals')
        check(all(events[j]['next']==events[j+1]['ip'] and events[j]['next_delta']==events[j+1]['delta'] for j in range(len(events)-1)), 'physical continuity')
        reads=sum(bool(e['reads']) for e in events)
        check(reads==int(row['reads']),'physical reads/summary mismatch')
        self.cache[label]=events;self.processed[label]=len(events)
        return events

def run(zip_dir,csv_path,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    cases=load_w_csv(csv_path);pairs,reps=selected_pairs(cases)
    reader=CaseReader(zip_dir)
    results=[]
    for tag,a,b in pairs:
        x=reader.load(a);y=reader.load(b)
        z=compare(x,y)
        results.append(dict(category=tag,left=a['label'],right=b['label'],
                            left_route=a['route_id'],right_route=b['route_id'],
                            same_route=a['route_id']==b['route_id'],**z))
    check(len(results)==42,'pair count')
    check(all(r['same_route'] for r in results if r['category']=='same_route_negative_control'),'negative-control route identity')
    check(sum(r['category']=='inter_shard_edge' for r in results)==7,'boundary coverage')
    check(all(c in reader.processed for r in results for c in (r['left'],r['right'])),'all witnesses read')
    tests=guards()
    count=collections.Counter(r['category'] for r in results)
    same_path=collections.Counter(r['category'] for r in results if r['same_path_entire_execution'])
    splits=collections.Counter(r['category'] for r in results if r['first_same_instruction_transition_split'] is not None)
    coverage={'project':PROJECT,'native_source_commit':NATIVE_SHA,'source_blob':SOURCE_SHA,
       'qa31v_action_run':41689861481, 'old_original_native_cases_not_rerun':200,
       'qa31w_csv_sha256':QA31W_CSV_SHA,'artifact_zip_sha256':ZIP_SHA256,
       'pairs':len(results), 'categories':dict(count),
       'different_traces_loaded':len(reader.processed),
       'physical_steps_parsed_for_selected_cases':sum(reader.processed.values()),
       'self_tests':tests, 'same_path_by_category':dict(same_path),
       'same_instruction_transition_splits_by_category':dict(splits),
       'no_new_native':True,'global_stage1_pass':False,
       'scope':'Finite same-tick comparison. First read and control discrepancies are observations, not source-byte ownership proofs.'}
    (out/'QA31X_PAIRWISE_WITNESSES.json').write_text(json.dumps(results,indent=2,ensure_ascii=False)+'\n')
    (out/'QA31X_COVERAGE.json').write_text(json.dumps(coverage,indent=2,ensure_ascii=False)+'\n')
    columns=['category','left','right','left_route','right_route','left_steps','right_steps',
      'first_full_record_difference','first_raw_read_record_difference','first_path_difference',
      'first_ip_delta_difference','first_opcode_difference','first_stack_difference',
      'first_same_instruction_transition_split','same_path_entire_execution']
    with (out/'QA31X_PAIRWISE_SUMMARY.csv').open('w',newline='',encoding='utf-8') as f:
        w=csv.writer(f);w.writerow(columns)
        for r in results:w.writerow([r[k]['tick'] if isinstance(r.get(k),dict) and 'tick' in r[k] else r.get(k) for k in columns])
    lines=[f'# QA31X — bounded first-divergence on {len(results)} original physical-trace pairs',
      '',f'Project `{PROJECT}`; immutable source blob `{SOURCE_SHA}`.',
      f'Original Native run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41689861481',
      '',f'- Original artifact ZIP SHA256+CRC validated: 8/8; selected physical trace SHA256 checked: {len(reader.processed)}/{len(reader.processed)}.',
      f'- Selected cases: {len(reader.processed)}; physical STEP records parsed: {sum(reader.processed.values()):,}.',
      f'- Comparisons: {len(results)} = 28 pairwise route representatives + 7 shard edges + 7 within-class controls.',
      f'- Synthetic analyzer self-tests: {tests}/{tests}. New Native: **none**. Stage1: **OPEN**.',
      '', '| Group | Pairs | Whole identical physical control-flow path | Same-instruction transition splits |',
      '|---|---:|---:|---:|']
    for group in ('cross_route_representatives','inter_shard_edge','same_route_negative_control'):
        lines.append(f'| {group} | {count[group]} | {same_path[group]} | {splits[group]} |')
    lines.extend(['','## Seven inter-shard edges',
      '| Pair | Observed routes | First read event difference | First path difference STEP | First same-instruction transition split STEP |',
      '|---|---|---|---:|---:|'])
    for r in results:
        if r['category']!='inter_shard_edge':continue
        fmt=lambda k: str(r[k]['tick']) if r[k] is not None else 'none'
        read=r['first_read_event_difference']
        lines.append(f"| {r['left']} ↔ {r['right']} | {r['left_route']} / {r['right_route']} | "+
          (str(read['event_number']) if read else 'none')+f" | {fmt('first_path_difference')} | {fmt('first_same_instruction_transition_split')} |")
    lines.extend(['','## Route-representative pairwise minimum witnesses',
      '| Routes | Original input pair | First physical path split | First same-instruction transition |',
      '|---|---|---:|---|'])
    for r in results:
        if r['category']!='cross_route_representatives':continue
        split=r['first_same_instruction_transition_split']
        transition=(f"STEP {split['tick']} at {split['left']['ip']}, op={split['left']['op']}: "+
                    f"{split['left']['next']} vs {split['right']['next']}") if split else 'none observed'
        first=r['first_path_difference']
        lines.append(f"| {r['left_route']}/{r['right_route']} | {r['left']} ↔ {r['right']} | "+
                     (str(first['tick']) if first else 'none')+f" | {transition} |")
    lines.extend(['','## Interpretation / limits',
      '- A full-record mismatch may occur before IP divergence because stdin bytes or stack state differ even under identical control flow.',
      '- A same-tick path divergence is **not** automatically the causative branch: different loop iteration counts may shift the event alignment.',
      '- The same-instruction transition witness is a stricter event-local observation (equal IP/delta/op/string, distinct next IP or direction). It does not alone establish which input byte controls that instruction.',
      '- When no direct transition split is observed, the pair supplies no local branch witness; do not invent one.',
      '- The comparison is not a new interpreter, proof of global reachability, proof of source ownership, full functional QA, or Stage1 acceptance.',
      '', '## Reproduction',
      '`python stage1_qa31x_pairwise_first_divergence.py --zip-dir PATH --qa31w-csv QA31W_200_PHYSICAL_TRACE_CLASSIFICATION.csv --out OUT`',
      'Expects `QA31V_SHARD0.zip`…`QA31V_SHARD7.zip` with pinned SHA256 as above.',
      ''])
    (out/'QA31X_REVIEW.md').write_text('\n'.join(lines),encoding='utf-8')
    print(json.dumps(coverage,indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--zip-dir',required=True)
    p.add_argument('--qa31w-csv',required=True)
    p.add_argument('--out',required=True)
    a=p.parse_args();run(a.zip_dir,a.qa31w_csv,a.out)
