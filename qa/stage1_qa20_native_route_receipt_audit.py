#!/usr/bin/env python3
"""QA20 independent physical STEP-trace validator; no calendar computation."""
import argparse, copy, gzip, hashlib, json
from pathlib import Path
from collections import Counter

PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def verify_manifest(folder, sh, reference):
    data=json.loads((folder/'qa20_manifest.json').read_text())
    # Reify QA18 dictionary-shaped target rows without trusting custom receipt list.
    targets=[(int(r['x']),int(r['y']),r['source_char']) for r in reference['never_touched_potential_control_glyphs']]
    need(data.get('schema')=='qa20-native-natural-route-21-controls-v1' and
         data.get('source_git_blob')==PIN and data.get('qa18_original_run')==39423789058 and
         data.get('shard')==sh and data.get('source_modified') is False and
         data.get('ip_relocated') is False and
         data.get('stage1_final_acceptance') is False and
         data.get('all_natural_reachability_proved') is False and
         data.get('native_case_count')==12,
         'receipt source pin/scope forged')
    need(data.get('targets')==[list(x) for x in targets], 'not exactly original QA18 21 targets')
    rec=data.get('records');need(type(rec) is list and len(rec)==12,'missing Native cases')
    labels=[];minima=Counter();hit_targets=set();step_total=0
    for row in rec:
        lab=row['label'];labels.append(lab)
        p=folder/row['path']
        need(row['path']==lab+'.steps.gz' and p.is_file(),'missing raw Native source route')
        blob=p.read_bytes()
        need(hashlib.sha256(blob).hexdigest()==row['compressed_trace_sha256'] and
             len(blob)==row['compressed_bytes'],'Native trace hash not bound')
        raw=gzip.decompress(blob)
        actual={f'{x},{y}':[] for x,y,ch in targets}
        nearest={f'{x},{y}':[10**10,None] for x,y,ch in targets}
        tick=0
        for line in raw.splitlines():
            f=line.split(b'\t');need(len(f)==7,'unexpected physical STEP schema')
            seq,x,y,dx,dy,op,string=map(int,f)
            tick+=1
            need(seq==tick and 0<=op<=255 and string in (0,1), 'Native monotonic STEP broken')
            for tx,ty,ch in targets:
                k=f'{tx},{ty}';dist=abs(x-tx)+abs(y-ty)
                if dist<nearest[k][0]: nearest[k]=[dist,[tick,x,y,dx,dy,op,string]]
                if dist==0:
                    actual[k].append([tick,op,string])
                    if not string and op==ord(ch):hit_targets.add(k)
        need(row['steps']==tick and tick>50 and row['nearest']==nearest and
             row['target_step_hits']==actual,'physical route summary not reproducible from saved STEPs')
        need(row['natural_ip_no_intervention'] is True and
             len(row['output'])==7 and row['output']==row['expected'],
             'wrong actual Native results or spoofed natural route')
        if row['valid'] is False:
            need(row['output']==['-1']*7, 'malformed input unexpectedly accepted')
        else:
            need(len(row['raw_input'].split())==4, 'valid input lexical shape changed')
        step_total+=tick
        for k in nearest:minima[k]=min(minima.get(k,10**10),nearest[k][0])
    need(len(set(labels))==12 and all(lab.startswith(('valid','invalid')) for lab in labels),
         'duplicate or mislabeled input')
    return {'cases':len(rec),'steps':step_total,'min_distances':dict(minima),
            'natural_source_opcode_hits':sorted(hit_targets),'labels':labels}

def selftest():
    d={'schema':'qa20-native-natural-route-21-controls-v1','source_git_blob':PIN,
       'qa18_original_run':39423789058,'shard':0,'source_modified':False,
       'ip_relocated':False,'stage1_final_acceptance':False,
       'all_natural_reachability_proved':False,'native_case_count':12}
    alters=[('wrong_sha','source_git_blob','0'*40),('fake_natural','ip_relocated',True),
       ('fake_stage1','stage1_final_acceptance',True),('fake_all','all_natural_reachability_proved',True),
       ('wrong_run','qa18_original_run',1),('missed_case','native_case_count',11)]
    for _,key,val in alters:
        tmp=copy.deepcopy(d);tmp[key]=val
        good=(tmp['schema']=='qa20-native-natural-route-21-controls-v1' and
             tmp['source_git_blob']==PIN and tmp['qa18_original_run']==39423789058 and
             tmp['shard']==0 and tmp['source_modified'] is False and
             tmp['ip_relocated'] is False and tmp['stage1_final_acceptance'] is False and
             tmp['all_natural_reachability_proved'] is False and tmp['native_case_count']==12)
        need(not good,'synthetic forged header accepted')
    print('QA20_SIX_HEADER_FORGERIES_REJECTED_SYNTHETIC_ONLY')

def main():
    pa=argparse.ArgumentParser();pa.add_argument('--shard',type=int)
    pa.add_argument('--directory');pa.add_argument('--qa18');pa.add_argument('--aggregate',nargs='*')
    pa.add_argument('--output');pa.add_argument('--selftest',action='store_true')
    p=pa.parse_args();selftest()
    if p.selftest:return
    qa18=json.loads(Path(p.qa18).read_text())
    need(qa18['schema']=='qa18-source-glyph-contact-v1' and
         qa18['source_git_blob']==PIN and
         len(qa18['never_touched_potential_control_glyphs'])==21 and
         qa18['dead_code_certified'] is False,'original QA18 baseline changed')
    if p.aggregate:
        need(len(p.aggregate)==4, 'need exact four original shards')
        proof=[verify_manifest(Path(folder),i,qa18) for i,folder in enumerate(p.aggregate)]
        expected={f'valid{i:02d}' for i in range(27)}|{f'invalid{i:02d}' for i in range(21)}
        labels=[lab for d in proof for lab in d['labels']]
        need(len(labels)==48 and set(labels)==expected,'missing/duplicate/shuffled Native test input')
        all_dist={}
        all_hits=set()
        for d in proof:
            all_hits.update(d['natural_source_opcode_hits'])
            for k,v in d['min_distances'].items():all_dist[k]=min(all_dist.get(k,10**10),v)
        result={'schema':'qa20-final-finite-native-physical-route-audit-v1',
                'native_cases':48,'native_valid':27,'native_invalid':21,
                'step_total':sum(d['steps'] for d in proof),
                'all_original_qa18_targets':21,
                'natural_source_opcode_hits':sorted(all_hits),
                'min_l1_by_candidate':all_dist,
                'not_hit_source_opcode_count':21-len(all_hits),
                'no_dead_code_certification':True,'stage1_complete':False}
        need(len(all_dist)==21 and result['step_total']>100000, 'geometry receipts incomplete')
        Path(p.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA20_FORTY_EIGHT_REAL_NATIVE_NATURAL_ROUTE_RECEIPTS_PASS',result)
        print('QA20_NO_DEAD_CODE_INFERENCE_STAGE1_OPEN')
    else:
        need(p.shard in range(4) and p.directory and p.output, 'missing shard args')
        result=verify_manifest(Path(p.directory),p.shard,qa18)
        Path(p.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA20_TWELVE_RAW_NATIVE_ROUTE_RECEIPTS_PASS',p.shard,result['steps'])

if __name__=='__main__':main()
