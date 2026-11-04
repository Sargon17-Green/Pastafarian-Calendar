#!/usr/bin/env python3
"""QA31AC independent reverse-receipt byte index and EOF verifier.

Algorithm is not a forward buffer simulation: it starts from receipt raw bytes,
assigns ~ returns in reverse, then checks refill partition by offset membership.
No import from QA31AC forward. Fails closed on ambiguous/unlogged I/O.
"""
import argparse
import collections
import copy
import hashlib
import json
from pathlib import Path

from stage1_qa31x_pairwise_first_divergence import CaseReader,load_w_csv,selected_pairs,check
from stage1_qa31y_source_pinned_last_writer_reader import p_address,source_sites_check

PROJECT='PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'


def reverse_oracle(io,receipt,label):
    """io is chronologically ordered observed ~ steps, not forward conclusions."""
    raw=bytes.fromhex(receipt['raw_hex'])
    check(hashlib.sha256(raw).hexdigest()==receipt['raw_sha256'],'receipt SHA forgery')
    check(io and all(e['op']==126 and e['ip']==[13,5] for e in io),'wrong source opcode or site')
    entries=[]
    for e in io:
        check(e['delta']==[1,0] and e['pre']==[], 'unmodeled pre-~ or direction')
        for r in e.get('reads',[]):
            check(r['t']==e['t'] and r['ip']==e['ip'] and r['stack']==e['pre'], 'reader location/stack forgery')
            check(r['method']=='readline','readline method forgery')
            check(type(r['start']) is int and type(r['end']) is int and r['start']<=r['end'], 'reader range invalid')
            bytes_read=bytes.fromhex(r['hex'])
            check(len(bytes_read)==r['end']-r['start'],'reader payload length forged')
            entries.append((e['t'],r['start'],r['end'],bytes_read))
    check(len(entries)==receipt['reads'],'original receipt read count mismatch')
    # Physical readline intervals must tile the complete raw-byte interval;
    # empty read has zero-width EOF interval. This does not model a buffer queue.
    ordered=[];end=0; eof_intervals=0
    for tick,start,stop,chunk in entries:
        check(start==end,'reader ranges overlap, gap or reorder')
        check(chunk==raw[start:stop],'reader chunk mismatches original receipt input')
        check(tick>ordered[-1][0] if ordered else True,'read events not time ordered')
        if start==stop:
            check(start==len(raw),'empty-read before end of original raw input')
            eof_intervals+=1
        else:
            check(eof_intervals==0,'non-empty read after EOF')
        ordered.append((tick,start,stop,chunk))
        end=stop
    check(end==len(raw),'readline stream not fully covered')
    ret_index=len(raw); reverse_bytes=0; eofs=0; matching=[]
    for e in reversed(io):
        if e['post']==[]:
            check(ret_index==len(raw),'EOF before all byte returns (reverse chronology)')
            check(e['next']==[12,5] and e['next_delta']==[-1,0], 'EOF must reflect')
            check(len(e['reads'])==1 and e['reads'][0]['hex']=='' and
                  e['reads'][0]['start']==e['reads'][0]['end']==len(raw),'unwitnessed EOF')
            check(eofs==0,'multiple EOF events unsupported in finite traces')
            eofs+=1
        else:
            check(len(e['post'])==1 and type(e['post'][0]) is int,'malformed stdin byte push')
            check(e['next']==[14,5] and e['next_delta']==[1,0], 'byte-return direction forged')
            check(ret_index>0,'extra stdin character with no raw input owner')
            ret_index-=1;value=raw[ret_index]
            check(e['post'][0]==value,'reverse raw receipt byte mismatch')
            owners=[(t,a,b) for t,a,b,_ in ordered if a<=ret_index<b]
            check(len(owners)==1,'no unique chunk containing reverse byte index')
            t,a,b=owners[0]
            if ret_index==a:
                check(len(e['reads'])==1 and e['t']==t,'first byte was not observed at refill STEP')
            else:
                check(len(e['reads'])==0,'later byte claims an impossible new refill')
                check(e['t']>t,'consumed byte predates its original observed read')
            reverse_bytes+=1;matching.append((e['t'],ret_index,value,t))
    check(ret_index==0,'some original bytes lack physical ~ return')
    check(eofs==eof_intervals,'EOF event count != empty-read count')
    check(len(io)==reverse_bytes+eofs,'unexpected number of input operations')
    return {'label':label,'bytes':reverse_bytes,'eof':eofs,'reads':len(entries),
           'signed_stdin_events':len(io),'reverse_byte_matches':len(matching),
           'unique_refill_owner_offsets':len(matching)},matching


def original_hostile_controls(io,receipt):
    # Mutable copies of *original signed Native I/O events*, not fabricated positives.
    def clone():return copy.deepcopy(io),copy.deepcopy(receipt)
    baseline,_=reverse_oracle(io,receipt,'original-control')
    check(baseline['eof']==1 and baseline['reads']==2,'hostile source must contain real EOF')
    count=0
    def attack(changer):
        nonlocal count
        events,rcpt=clone();changer(events,rcpt)
        try:reverse_oracle(events,rcpt,'mutant')
        except (AssertionError,ValueError,IndexError,KeyError,TypeError):count+=1
        else:raise AssertionError('hostile original mutation survived #'+str(count+1))
    attack(lambda es,r: es[0].update(op=ord('z')))
    attack(lambda es,r: es[0].update(ip=[13,6]))
    attack(lambda es,r: es[0].update(post=[es[0]['post'][0]+1]))
    attack(lambda es,r: es[1].update(post=[es[1]['post'][0]+1]))
    attack(lambda es,r: es[0].update(delta=[-1,0]))
    attack(lambda es,r: es[0].update(next=[12,5]))
    attack(lambda es,r: es[-1].update(next_delta=[1,0]))
    attack(lambda es,r: es[-1].update(next=[14,5]))
    attack(lambda es,r: es[-1].update(post=[0]))
    attack(lambda es,r: es[-1].update(reads=[]))
    attack(lambda es,r: es[0]['reads'][0].update(hex='31'+'00'+es[0]['reads'][0]['hex'][4:]))
    attack(lambda es,r: es[0]['reads'][0].update(start=1))
    attack(lambda es,r: es[0]['reads'][0].update(end=1))
    attack(lambda es,r: es[0]['reads'][0].update(method='readbyte'))
    attack(lambda es,r: es[0]['reads'][0].update(t=999))
    attack(lambda es,r: es[0]['reads'][0].update(ip=[1,1]))
    attack(lambda es,r: es[0]['reads'][0].update(stack=[1]))
    attack(lambda es,r: es[1].update(reads=[copy.deepcopy(es[0]['reads'][0])]))
    attack(lambda es,r: r.update(raw_hex=r['raw_hex'][:-2]+'00'))
    attack(lambda es,r: r.update(raw_sha256='0'*64))
    attack(lambda es,r: r.update(reads=1))
    attack(lambda es,r: es[-1]['reads'][0].update(start=8))
    attack(lambda es,r: es[-1]['reads'][0].update(hex='30'))
    check(count==23,'hostile count drift')
    return count


def run(zip_dir,csv_file,forward_csv,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    records=load_w_csv(csv_file);pairs,_=selected_pairs(records)
    selected=sorted({x['label'] for _,a,b in pairs for x in (a,b)})
    check(len(selected)==29,'population changed')
    by_label={r['label']:r for r in records};reader=CaseReader(zip_dir)
    results=[];refs=[];readtotal=0;eof_total=0;bytes_total=0;source_count=0;hostile_base=None
    for label in selected:
        events=reader.load(by_label[label]);source_count+=source_sites_check(events)
        check(not any(e['op']==ord('s') or e['op']==ord('p') and p_address(e)==(13,5)
                      for e in events),'possible stdin instruction patch')
        check(not any(e['reads'] and (e['op']!=126 or e['ip']!=[13,5]) for e in events),
              'unmodeled competing stdin read site')
        check(not any(e['op']==38 for e in events),'unmodeled numeric stdin read (&)')
        io=[e for e in events if e['op']==126]
        r,matched=reverse_oracle(io,reader.receipts[label][1],label)
        check(r['reads']==int(by_label[label]['reads']) and r['eof']==int(by_label[label]['eof_reads']),
              'receipt/classification divergence')
        results.append(r);refs.extend((label,*x) for x in matched)
        bytes_total+=r['bytes'];readtotal+=r['reads'];eof_total+=r['eof']
        if hostile_base is None and r['eof']==1:hostile_base=(io,reader.receipts[label][1])
    check(source_count==3557,'source-pinned site checks')
    check(len(reader.zips)==8 and len(reader.processed)==29 and sum(reader.processed.values())==510835,
          'original signed trace count')
    check(bytes_total==261 and readtotal==53 and eof_total==20,'population drift')
    attacks=original_hostile_controls(*hostile_base)
    # Compare separately generated forward witness CSV, not its summary claims.
    with Path(forward_csv).open(encoding='utf-8',newline='') as f:
        import csv
        forward=list(csv.DictReader(f))
    check(len(forward)==281,'forward witness count mismatch')
    mapping={(r['label'],int(r['tick'])):r for r in forward if r['kind']=='byte'}
    check(len(mapping)==261,'forward byte witness keys not unique')
    for label,tick,offset,value,read_tick in refs:
        fw=mapping[(label,tick)]
        check(int(fw['raw_byte_offset'])==offset and int(fw['returned_integer'])==value,
              'independent reverse/forward byte owner mismatch')
    result={'schema':'qa31ac-independent-reverse-receipt-v1',
      'project_id':PROJECT,'source_blob':SOURCE,
      'original_signed_traces_verified':29,'original_zip_sha256_crc_verified':8,
      'physical_steps_verified':510835,'source_pinned_opcode_checks':source_count,
      'physical_stdin_events_checked':sum(r['signed_stdin_events'] for r in results),
      'receipt_raw_bytes_signed_sha_verified':bytes_total,'backward_receipt_to_tilde_matches':bytes_total,
      'reverse_to_forward_exact_cursor_matches':bytes_total,
      'raw_receipt_refills_verified':readtotal,'independent_eof_reflections_verified':eof_total,
      'hostile_original_trace_receipt_controls_rejected':attacks,
      'no_other_observed_input_method_in_selected_traces':True,
      'direct_interpreter_buffer_instrumentation':False,
      'universal_reachability_or_byte_owner_proven':False,'stage1_pass':False,
      'new_native_runs':0,'new_ci_runs':0}
    (out/'QA31AC_REVERSE_SUMMARY.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    (out/'QA31AC_REVERSE_CASES.json').write_text(json.dumps(results,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps(result,sort_keys=True))
    return result


if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--zip-dir',required=True)
    ap.add_argument('--qa31w-csv',required=True);ap.add_argument('--forward-csv',required=True)
    ap.add_argument('--out',required=True);a=ap.parse_args()
    run(a.zip_dir,a.qa31w_csv,a.forward_csv,a.out)