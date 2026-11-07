#!/usr/bin/env python3
"""QA21: pin 6 real input-driven QA20 Native source-opcode executions.
No arithmetic oracle and no synthetic reachability.
"""
import argparse,gzip,hashlib,json,zipfile
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
SPECS=[(10,44,'>', 'invalid18',1503), (150,20,'x','invalid18',1185),
       (175,38,'x','invalid18',1502), (179,44,'@','invalid18',1672),
       (235,11,'x','invalid14',9891),(396,17,'x','invalid07',1065)]
ORIGINAL={'invalid18':(1,'21afa80d2e33e0331c185d0fb3816ec11b8d782f3879d79b541414d04b14a6e4'),
          'invalid14':(1,'7706e5c4883f0030e289208ccf4256485373356ff94b4687297110587107f902'),
          'invalid07':(2,'0ab05fc40ec783c412d552985ecc749349a297f5e06faa7df55c92590cba4e53')}
def need(v,why):
    if not v: raise AssertionError(why)
def git_blob(blob):return hashlib.sha1(b'blob '+str(len(blob)).encode()+b'\0'+blob).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--shard',action='append',required=True)
    p.add_argument('--source',required=True);p.add_argument('--output',required=True)
    a=p.parse_args();need(len(a.shard)==4,'expected four QA20 original shards')
    source=Path(a.source).read_bytes();need(git_blob(source)==PIN,'source Git blob pin mismatch')
    source_lines=source.splitlines(); rec={}
    for i,path in enumerate(a.shard):
        with zipfile.ZipFile(path) as z:
            m=json.loads(z.read('qa20_manifest.json'))
            need(m['schema']=='qa20-native-natural-route-21-controls-v1' and
                 m['source_git_blob']==PIN and m['shard']==i and
                 m['source_modified'] is False and m['ip_relocated'] is False,
                 'QA20 original shard identity changed')
            for row in m['records']:
                lab=row['label']
                if lab not in ORIGINAL:continue
                expected_shard,expected_hash=ORIGINAL[lab]
                need(i==expected_shard and row['compressed_trace_sha256']==expected_hash,
                     'original QA20 compressed trace provenance mismatch: '+lab)
                blob=z.read(row['path'])
                need(hashlib.sha256(blob).hexdigest()==expected_hash and
                     len(blob)==row['compressed_bytes'],'original SHA/byte length not reproducible')
                raw=gzip.decompress(blob)
                need(len(raw.splitlines())==row['steps'] and row['output']==['-1']*7 and
                     row['valid'] is False and row['natural_ip_no_intervention'] is True,
                     'QA20 original rejection/trace integrity mismatch')
                rec[lab]=(row,raw)
    need(set(rec)==set(ORIGINAL),'missing QA20 original immutable invalid Native traces')
    entries=[]
    for x,y,glyph,lab,tick in SPECS:
        need(chr(source_lines[y][x])==glyph,'source opcode at pinned target changed')
        row,trace=rec[lab];lines=trace.splitlines(keepends=True)
        fields=list(map(int,lines[tick-1].split()))
        need(len(fields)==7 and fields[0]==tick and fields[1:3]==[x,y] and
             fields[5]==ord(glyph) and fields[6]==0,
             'previously Native-executed source opcode witness not exact')
        entries.append({'target':[x,y],'opcode':glyph,'original_case':lab,
                        'input':row['raw_input'],'first_tick':tick,
                        'recorded_step':fields,
                        'prefix_sha256':hashlib.sha256(b''.join(lines[:tick-1])).hexdigest(),
                        'original_gzip_sha256':ORIGINAL[lab][1],
                        'qa20_shard':ORIGINAL[lab][0], 'original_full_steps':row['steps']})
    result={'schema':'qa21-native-six-original-natural-execution-witnesses-v1',
        'source_git_blob':PIN,'original_native_run':39761821210,
        'qa20_tested_commit':'d0a1c686c4f9244121246aa5b70266c072c3ddce',
        'normal_case_count':6,'scope':'finite_native_input_origin_unmodified_prefix',
        'natural_reachability_already_proven_from_qa20':True,
        'stage1_complete':False,'entries':entries}
    Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('QA21_SIX_FROZEN_INPUT_REACHED_ORIGINAL_NATIVE_OPCODES_PASS')
    print('QA21_WITNESS_SELECTION_ONLY_NOT_NEW_NATIVE_CAUSALITY')
if __name__=='__main__':main()