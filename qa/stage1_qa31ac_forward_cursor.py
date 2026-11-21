#!/usr/bin/env python3
"""QA31AC: original-Native finite byte cursor and EOF audit (forward oracle).

Source: original QA31V SHA-pinned signed STEP traces inside frozen QA31Y ZIP.
No new interpreter execution. This does not establish universal byte ownership.
Python >=3.9, standard library.
"""
import argparse
import collections
import copy
import csv
import hashlib
import json
from pathlib import Path

from stage1_qa31x_pairwise_first_divergence import CaseReader, load_w_csv, selected_pairs, check
from stage1_qa31y_source_pinned_last_writer_reader import SOURCE_BLOB, source_sites_check, p_address

PROJECT='PC-BRANCH-BEFUNGE98-KYRGYZ'
BRANCH='qa-befunge98-stage1-order-isolation-20261008'
ORIGINAL_RUN=41689861481
SITE=(13,5)


def audit_cursor(events,receipt,label):
    """Rebuild a FIFO buffer only from logged readline payloads, independently of input label."""
    raw=bytes.fromhex(receipt['raw_hex'])
    check(hashlib.sha256(raw).hexdigest()==receipt['raw_sha256'], 'receipt raw SHA mismatch: '+label)
    buffered=bytearray();offset=0;rows=[];reads=0; eof=0; read_bytes=0
    for e in events:
        tick=e['t']; op=e['op']; site=tuple(e['ip']); chunks=e.get('reads',[])
        check(not chunks or (op==126 and site==SITE),'unexpected I/O read site')
        if op==ord('s'):
            raise AssertionError('unmodeled s modification of original source')
        if op==ord('p') and p_address(e)==SITE:
            raise AssertionError('original stdin opcode overwritten by p')
        if op!=126:
            continue
        check(site==SITE,'unexpected ~ instruction site')
        check(e['pre']==[], 'stdin stack shape not supported')
        check(e['delta']==[1,0], 'stdin entry direction unexpected')
        check(len(chunks)<=1,'multiple read records for same physical STEP')
        chunk=None
        if chunks:
            chunk=chunks[0]
            check(offset==len(buffered),'readline invoked while prior bytes unconsumed')
            check(chunk['method']=='readline', 'read method mismatch')
            check(chunk['t']==tick and chunk['ip']==e['ip'] and chunk['stack']==e['pre'],'read record location/stack mismatch')
            check(type(chunk['start']) is int and type(chunk['end']) is int,'invalid read offsets')
            check(chunk['start']==len(buffered) and chunk['end']>=chunk['start'],'read offsets nonconsecutive')
            b=bytes.fromhex(chunk['hex'])
            check(chunk['end']-chunk['start']==len(b),'read payload offset/length mismatch')
            buffered.extend(b); reads+=1;read_bytes+=len(b)
        before=offset
        if offset<len(buffered):
            value=buffered[offset]
            check(not (len(e['post'])!=1 or e['post'][0]!=value),'~ return differs from buffered byte')
            check(e['next_delta']==[1,0] and e['next']==[14,5], 'successful ~ changed flow')
            offset+=1
            kind='byte'; eof_observed=False
        else:
            check(chunk is not None and chunk['hex']=='' and
                  chunk['start']==chunk['end']==len(raw),'EOF without explicit empty read at input boundary')
            check(e['post']==[] and e['next_delta']==[-1,0] and e['next']==[12,5],
                  'EOF must reflect with unchanged stack')
            check(offset==len(raw), 'EOF before declared raw input exhausted')
            value=None;kind='eof_reflect';eof_observed=True;eof+=1
        rows.append({'label':label,'tick':tick,'kind':kind,'returned_integer':value,
                     'raw_byte_offset':before if kind=='byte' else None,
                     'byte_hex':('%02x'%value) if kind=='byte' else None,
                     'readline_at_tick':chunk is not None,
                     'refill_start':None if chunk is None else chunk['start'],
                     'refill_end':None if chunk is None else chunk['end'],
                     'cursor_after':offset,'read_record_method':None if chunk is None else chunk['method'],
                     'eof_reflected':eof_observed})
    check(bytes(buffered)==raw and offset==len(raw),'incomplete/mismatched raw input consumption')
    check(reads==receipt['reads'],'read record receipt total disagreement')
    return rows,{'bytes':offset,'reads':reads,'eof':eof,'buffered_bytes':read_bytes,
                 'source_site_reads':len(rows),'raw_sha256':receipt['raw_sha256']}


def synthetic_guards():
    """Synthetic contract checks; never counted as Native runs."""
    def step(t,b,r=[],eof=False):
        return {'t':t,'ip':[13,5],'op':126,'pre':[],
                'post':[] if eof else [b], 'delta':[1,0],
                'next_delta':[-1,0] if eof else [1,0],
                'next':[12,5] if eof else [14,5],'reads':r}
    raw=b'Ab';rec={'raw_hex':raw.hex(),'raw_sha256':hashlib.sha256(raw).hexdigest(),'reads':2}
    read=lambda t,h,s,e:{'method':'readline','t':t,'ip':[13,5],'stack':[],
                         'hex':h,'start':s,'end':e}
    good=[step(1,65,[read(1,'4162',0,2)]),step(2,98),step(3,0,[read(3,'',2,2)],True)]
    rows,st=audit_cursor(good,rec,'synthetic')
    check(len(rows)==3 and st['bytes']==2 and st['eof']==1,'positive synthetic cursor')
    attacks=[
       (0,'post',[66]), (0,'op',ord('z')),(1,'post',[65]),
       (1,'reads',[read(2,'',2,2)]),(0,'delta',[-1,0]),
       (2,'post',[0]),(2,'next_delta',[1,0]),(2,'next',[14,5]),
       (2,'reads',[]), (0,'ip',[13,6]),
    ]
    bad=0
    for index,key,value in attacks:
        v=copy.deepcopy(good);v[index][key]=value
        try:audit_cursor(v,rec,'hostile')
        except (AssertionError,IndexError,ValueError,KeyError):bad+=1
        else:raise AssertionError('synthetic hostile escaped '+str((index,key)))
    check(bad==10,'synthetic attack count drift')
    return {'synthetic_positive_cases':1,'synthetic_negative_rejections':bad}


def run(zip_dir,csv_path,qa31ab_witnesses,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    table=load_w_csv(csv_path); pairs,_=selected_pairs(table)
    labels=sorted({x['label'] for _,a,b in pairs for x in (a,b)})
    check(len(labels)==29,'changed original Native trace population')
    lookup={r['label']:r for r in table}
    prior=json.loads(Path(qa31ab_witnesses).read_text(encoding='utf-8'))
    check(len(prior)==261,'QA31AB witness count drift')
    prior_lookup={(w['label'],w['stdin_tick']):w for w in prior}
    check(len(prior_lookup)==261,'duplicate QA31AB stdin origins')
    reader=CaseReader(zip_dir)
    all_rows=[];cases=[]; pinned=0; matching_prior=0
    for label in labels:
        events=reader.load(lookup[label]); pinned+=source_sites_check(events)
        _,receipt=reader.receipts[label]
        details,meta=audit_cursor(events,receipt,label)
        check(meta['reads']==int(lookup[label]['reads']),'CSV reads discrepancy')
        check(meta['eof']==int(lookup[label]['eof_reads']),'CSV EOF discrepancy')
        for w in details:
            key=(label,w['tick'])
            if w['kind']=='byte':
                check(key in prior_lookup,'missing prior QA31AB lineage witness')
                p=prior_lookup[key]
                check(p['stdin_value']==w['returned_integer'] and p['p_value']==w['returned_integer'],
                      'QA31AB byte→p transfer mismatch')
                matching_prior+=1
            else:check(key not in prior_lookup,'EOF cannot be a QA31AB successful byte witness')
        all_rows.extend(details);cases.append({'label':label,**meta})
    check(len(reader.zips)==8 and len(reader.processed)==29 and sum(reader.processed.values())==510835,
          'original signed Native verification coverage drift')
    check(pinned==3557,'original source pinned site checks drift')
    check(matching_prior==261 and len(all_rows)==281,'stdin events/witnesses count drift')
    check(sum(x['reads'] for x in cases)==53 and sum(x['eof'] for x in cases)==20,'read/EOF aggregate drift')
    check(sum(x['bytes'] for x in cases)==261,'raw input total drift')
    stats=synthetic_guards()
    with (out/'QA31AC_FORWARD_CURSOR_WITNESSES.csv').open('w',newline='',encoding='utf-8') as f:
        wr=csv.DictWriter(f,fieldnames=list(all_rows[0]));wr.writeheader();wr.writerows(all_rows)
    summary={'schema':'qa31ac-finite-signed-original-cursor-v1','project_id':PROJECT,
      'branch':BRANCH,'source_blob':SOURCE_BLOB,'original_native_run':ORIGINAL_RUN,
      'original_zip_sha256_crc_verified':8,'original_signed_traces_verified':29,'physical_steps_verified':510835,
      'source_pinned_opcode_site_checks':pinned,'observed_stdin_opcodes':len(all_rows),
      'receipt_sha256_pinned_cases':len(cases), 'exact_raw_byte_to_tilde_return_matches':matching_prior,
      'previous_qa31ab_x_to_p_matches':matching_prior,'physical_readline_events':53,
      'physical_returned_bytes':261,'empty_readline_eof_reflections':20,
      'all_selected_case_raw_receipt_lengths_exact':True,**stats,
      'interpreter_internal_buffer_directly_instrumented':False,
      'finite_signed_byte_offsets_reconstructed':True,'universal_byte_ownership_proven':False,
      'new_native_runs':0,'new_ci_runs':0,'full_functional_qa_pass':False,
      'geometric_spaghetti_qa_pass':False,'stage1_pass':False}
    (out/'QA31AC_FORWARD_SUMMARY.json').write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    (out/'QA31AC_CASES.json').write_text(json.dumps(cases,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,sort_keys=True))
    return summary


if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--zip-dir',required=True)
    ap.add_argument('--qa31w-csv',required=True);ap.add_argument('--qa31ab-witnesses',required=True)
    ap.add_argument('--out',required=True);a=ap.parse_args()
    run(a.zip_dir,a.qa31w_csv,a.qa31ab_witnesses,a.out)