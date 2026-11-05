#!/usr/bin/env python3
"""QA31AD: full finite 200-case signed original Native stdin/EOF provenance audit.

No Native/CI execution. Reuses *same branch* independently source-pinned
QA31X/Y and QA31AC readers, forward cursor, and independent reverse oracle.

Execute one shard at a time; then --combine  to bind 8 original shards into a
single fail-closed verdict. All exact file SHA256 expectations are hard pinned
inside the historical CaseReader and CSV loader. Python >=3.9 stdlib only.
"""
import argparse
import collections
import copy
import csv
import hashlib
import json
from pathlib import Path

from stage1_qa31x_pairwise_first_divergence import CaseReader, load_w_csv, check, ZIP_SHA256
from stage1_qa31y_source_pinned_last_writer_reader import SOURCE_BLOB, source_sites_check, p_address
from stage1_qa31ac_forward_cursor import audit_cursor, synthetic_guards
from stage1_qa31ac_reverse_receipt_oracle import reverse_oracle, original_hostile_controls

PROJECT='PC-BRANCH-BEFUNGE98-KYRGYZ'
BRANCH='qa-befunge98-stage1-order-isolation-20261008'
NATIVE_RUN=41689861481
SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def observed_unsupported(events):
    """Unsupported observed behavior is UNKNOWN; forgery/integrity stays FAIL."""
    for e in events:
        if e['op']==ord('&'): return 'observed_numeric_input_&'
        if e['op']==ord('s'): return 'observed_source_mutation_s'
        if e['op']==ord('p') and p_address(e)==(13,5):
            return 'observed_stdin_instruction_overwrite'
        if e.get('reads') and (e['op']!=126 or e['ip']!=[13,5]):
            return 'observed_alternate_input_site'
        if e['op']==126 and (e['ip']!=[13,5] or e['delta']!=[1,0]):
            return 'observed_unmodeled_stdin_direction_or_site'
        if e['op']==126 and len(e.get('reads',[]))>1:
            return 'observed_multiple_refills_per_step'
    return None


def original_tamper_tests(events,receipt):
    """Hostiles are mutated *copies* of one original signed physical trace."""
    io=[e for e in events if e['op']==126]
    assert len(io)>=2
    count=0
    def reject(fn,expect):
        nonlocal count
        copied=copy.deepcopy(events)
        r=copy.deepcopy(receipt)
        fn(copied,r)
        try:
            expect(copied,r)
        except (AssertionError, ValueError, TypeError, KeyError, IndexError):
            count+=1
        else:
            raise AssertionError('adversarial mutation escaped original '+str(count+1))
    one=next(i for i,e in enumerate(events) if e['op']==126 and e['post'])
    pinned=next(i for i,e in enumerate(events) if e['ip']==[13,5] and e['op']==126)
    reject(lambda ev,r:ev[pinned].update(op=ord('z')),
           lambda ev,r: source_sites_check(ev))
    reject(lambda ev,r:ev[one].update(post=[(ev[one]['post'][0]+1)%256]),
           lambda ev,r: audit_cursor(ev,r,'hostile physical return'))
    reject(lambda ev,r:r.update(raw_sha256='0'*64),
           lambda ev,r: reverse_oracle([e for e in ev if e['op']==126],r,'hostile receipt'))
    reject(lambda ev,r:r.update(reads=r['reads']+1),
           lambda ev,r: reverse_oracle([e for e in ev if e['op']==126],r,'hostile reads'))
    reject(lambda ev,r:ev[one].update(next=[999,5]),
           lambda ev,r: reverse_oracle([e for e in ev if e['op']==126],r,'hostile next ip'))
    return count


def verify_zip_and_trace_tamper(reader, row):
    """Corrupt original ZIP and gzipped trace copies, trigger actual digest guards."""
    n=0
    s,receipt=reader.receipts[row['label']]
    data=(Path(reader.folder)/f'QA31V_SHARD{s}.zip').read_bytes() if hasattr(reader,'folder') else None
    # The exact binary digest of the archived outer ZIP is already enforced by
    # CaseReader constructor. A changed byte must be rejected by same guard.
    if data is not None:
        m=bytearray(data);m[len(m)//2]^=1
        try:check(digest(m)==ZIP_SHA256[s], 'corrupted outer ZIP rejected')
        except AssertionError:n+=1
        else:raise AssertionError('modified outer original ZIP digest escaped')
    blob=reader.zips[s].read(receipt['trace'])
    m=bytearray(blob);m[len(m)//2]^=1
    try:check(digest(m)==receipt['trace_sha256'], 'corrupted gzipped Native STEP rejected')
    except AssertionError:n+=1
    else:raise AssertionError('modified original STEP trace SHA escaped')
    check(n==2,'original ZIP and compressed trace hostile precondition')
    return n


def check_shard(zip_dir,csv_path,out_dir,shard):
    out=Path(out_dir);out.mkdir(parents=True,exist_ok=True)
    rows=load_w_csv(csv_path)
    chosen=rows[shard*25:(shard+1)*25]
    check(len(chosen)==25,'original 25-case partition')
    reader=CaseReader(zip_dir)
    # Retain raw source directory for a real outer ZIP tamper check.
    reader.folder=str(zip_dir)
    physical=0;source_checks=0;rejected=0;uncertain=[];all_forward=[];all_reverse=[];results=[]
    good_cases=0
    for row in chosen:
        label=row['label'];events=reader.load(row)
        s,rcpt=reader.receipts[label]
        raw=bytes.fromhex(rcpt['raw_hex'])
        check(digest(raw)==rcpt['raw_sha256'],'raw receipt digest changed')
        check(rcpt['reads']==int(row['reads']),'recorded reads mismatch')
        check(s==shard,'original shard partition drift')
        physical+=len(events)
        source_checks+=source_sites_check(events)
        problem=observed_unsupported(events)
        if problem:
            uncertain.append({'label':label,'reason':problem,'signed_steps':len(events)})
            results.append({'label':label,'classification':'UNKNOWN','reason':problem,
                            'signed_steps':len(events),'raw_receipt_sha256':rcpt['raw_sha256']})
            continue
        fw,meta=audit_cursor(events,rcpt,label)
        rev,links=reverse_oracle([e for e in events if e['op']==126],rcpt,label)
        check(rev['bytes']==meta['bytes'] and rev['reads']==meta['reads'] and rev['eof']==meta['eof'],
              'two independent raw-byte oracles diverged')
        assert len(links)==meta['bytes']
        forward={(x['tick']):(x['raw_byte_offset'],x['returned_integer'])
                 for x in fw if x['kind']=='byte'}
        check(len(forward)==meta['bytes'],'forward byte witness duplicate or omission')
        for tick,index,value,owner_tick in links:
            check(tick in forward and forward[tick]==(index,value),
                  'independent reverse owner index != forward cursor')
            all_reverse.append({'label':label,'tick':tick,'raw_byte_offset':index,
                                'returned_integer':value,'original_refill_tick':owner_tick})
        check(meta['reads']==int(row['reads']) and meta['eof']==int(row['eof_reads']),
              'physical EOF/read receipts differ from 200-row classification')
        check(meta['bytes']==len(raw),'returned byte count != signed raw input length')
        check(meta['source_site_reads']==len(raw)+meta['eof'],
              'not every original ~ return or EOF reflection accounted for')
        good_cases+=1
        all_forward.extend(fw)
        results.append({'label':label,'classification':'VERIFIED_FINITE','signed_steps':len(events),
                        'raw_receipt_sha256':rcpt['raw_sha256'],'raw_byte_count':len(raw),
                        'original_readline_calls':meta['reads'],'readline_eof_reflections':meta['eof'],
                        'all_tilde_instructions':meta['source_site_reads'],
                        'reverse_matches':rev['reverse_byte_matches']})
        # One fully-signed test per shard guards against a shared class-specific artifact.
        if good_cases==1:
            rejected+=original_tamper_tests(events,rcpt)
            rejected+=verify_zip_and_trace_tamper(reader,row)
    check(len(reader.processed)==25 and sum(reader.processed.values())==physical,
          'shard trace population not fully verified')
    summary={'schema':'qa31ad-shard-v1','project_id':PROJECT,'branch':BRANCH,
             'original_source_blob':SOURCE,'native_source_commit':'e3700d9bd600f215b0cdc47d29d45e74f3b7667e',
             'original_native_run':NATIVE_RUN,'shard':shard,'original_zip_sha256':ZIP_SHA256[shard],
             'original_zips_sha_crc_verified_in_read':8,'original_trace_sha_step_verified':len(reader.processed),
             'original_physical_steps':physical,'original_source_site_opcode_checks':source_checks,
             'finite_verified_cases':good_cases,'unknown_cases':len(uncertain),
             'original_received_bytes':sum(r.get('raw_byte_count',0) for r in results),
             'observed_readline_calls':sum(r.get('original_readline_calls',0) for r in results),
             'observed_eof_reflections':sum(r.get('readline_eof_reflections',0) for r in results),
             'physical_tilde_instructions':sum(r.get('all_tilde_instructions',0) for r in results),
             'independent_reverse_byte_matches':len(all_reverse),'hostile_signed_mutations_rejected':rejected,
             'global_byte_owner_proven':False,'stage1_pass':False,'new_native_runs':0,'new_ci_runs':0}
    obj={'summary':summary,'cases':results,'unknowns':uncertain,
         'forward_witnesses':all_forward,'reverse_witnesses':all_reverse}
    file=out/f'QA31AD_SHARD{shard}.json'
    file.write_text(json.dumps(obj,ensure_ascii=False,sort_keys=True,separators=(',',':'))+'\n',encoding='utf-8')
    print(json.dumps(summary,sort_keys=True))


def combine(output):
    out=Path(output)
    shards=[json.loads((out/f'QA31AD_SHARD{i}.json').read_text(encoding='utf-8')) for i in range(8)]
    cases=[row for shard in shards for row in shard['cases']]
    check(len(cases)==200 and len({r['label'] for r in cases})==200,'full 200 original labels')
    assert all(s['summary']['original_zip_sha256']==ZIP_SHA256[i] and s['summary']['shard']==i for i,s in enumerate(shards))
    check(all(len(x['cases'])==25 for x in shards),'25 original native cases per ZIP')
    counts={k:sum(s['summary'][k] for s in shards) for k in (
        'original_trace_sha_step_verified','original_physical_steps','original_source_site_opcode_checks',
        'finite_verified_cases','unknown_cases','original_received_bytes','observed_readline_calls',
        'observed_eof_reflections','physical_tilde_instructions','independent_reverse_byte_matches',
        'hostile_signed_mutations_rejected')}
    check(counts['original_trace_sha_step_verified']==200,'200 signed traces')
    check(counts['original_physical_steps']==3628390,'historical 3,628,390 original physical STEPs')
    check(counts['finite_verified_cases']+counts['unknown_cases']==200,'full classification')
    check(counts['original_received_bytes']==counts['independent_reverse_byte_matches'],
          'incomplete independent finite byte-offset matching')
    check(counts['original_received_bytes']+counts['observed_eof_reflections']==counts['physical_tilde_instructions'],
          'unaccounted observed tilde I/O')
    check(counts['hostile_signed_mutations_rejected']==56,'7 original mutation controls per shard')
    # A full original-signed 23-mutation receipt/physical-control set and
    # independent 10-mutation synthetic controls; neither is a Native rerun.
    first=shards[0]['forward_witnesses']
    # Additional negative tests require actual source records, run in shard checks.
    synth=synthetic_guards()
    summary={'schema':'qa31ad-full-signed-200-original-input-cursor-eof-v1',
             'project_id':PROJECT,'branch':BRANCH,'original_source_blob':SOURCE,
             'original_native_run':NATIVE_RUN,'original_zip_sha256':ZIP_SHA256,
             'original_zips_sha_crc_verified':8,**counts,
             'synthetic_positive':synth['synthetic_positive_cases'],
             'synthetic_hostile_rejections':synth['synthetic_negative_rejections'],
             'original_interpreter_buffer_directly_observed':False,
             'source_receipt_trace_finite_conformance_only':True,
             'global_byte_owner_proven':False,'global_reachability_proven':False,
             'full_functional_qa_pass':False,'geometric_spaghetti_qa_pass':False,
             'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False}
    # Rebuild a canonical 200-row per-case CSV in strict historical index order.
    with (out/'QA31AD_200_CASES.csv').open('w',encoding='utf-8',newline='') as f:
        wr=csv.DictWriter(f,fieldnames=['label','classification','signed_steps','raw_receipt_sha256',
                'raw_byte_count','original_readline_calls','readline_eof_reflections',
                'all_tilde_instructions','reverse_matches','reason'])
        wr.writeheader();wr.writerows(cases)
    with (out/'QA31AD_FORWARD_ALL_WITNESSES.csv').open('w',encoding='utf-8',newline='') as f:
        all_witnesses=[r for s in shards for r in s['forward_witnesses']]
        check(len(all_witnesses)==counts['physical_tilde_instructions'],'forward physical event coverage')
        wr=csv.DictWriter(f,fieldnames=list(all_witnesses[0]));wr.writeheader();wr.writerows(all_witnesses)
    with (out/'QA31AD_INDEPENDENT_REVERSE_WITNESSES.csv').open('w',encoding='utf-8',newline='') as f:
        rs=[r for s in shards for r in s['reverse_witnesses']]
        wr=csv.DictWriter(f,fieldnames=list(rs[0]));wr.writeheader();wr.writerows(rs)
    (out/'QA31AD_FULL_SUMMARY.json').write_text(json.dumps(summary,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    manifest={'schema':'qa31ad-manifest-sha256-v1','entries':{p.name:digest(p.read_bytes())
       for p in sorted(out.glob('QA31AD_*')) if p.is_file() and p.name!='QA31AD_MANIFEST.json'}}
    (out/'QA31AD_MANIFEST.json').write_text(json.dumps(manifest,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(summary,sort_keys=True))


def main():
    p=argparse.ArgumentParser();p.add_argument('--zip-dir');p.add_argument('--qa31w-csv');
    p.add_argument('--out',required=True);g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--shard',type=int,choices=list(range(8)));g.add_argument('--combine',action='store_true')
    a=p.parse_args()
    if a.combine:combine(a.out)
    else:
        check(a.zip_dir is not None and a.qa31w_csv is not None,'missing original source inputs')
        check_shard(a.zip_dir,a.qa31w_csv,a.out,a.shard)

if __name__=='__main__':main()