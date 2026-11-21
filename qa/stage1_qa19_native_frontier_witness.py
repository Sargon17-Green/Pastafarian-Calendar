#!/usr/bin/env python3
"""QA19. Select *previously executed* source-adjacent IP locations.
These witnesses do NOT establish natural reachability of the target glyphs.
They are preconditions for explicit single-cell counterfactual redirection.
"""
import argparse,hashlib,json,zipfile
from pathlib import Path
import stage1_qa17_native_frontier as frozen
TARGETS=((150,20),(175,38),(396,17))
PIN=frozen.SOURCE_BLOB
def need(v,msg):
    if not v: raise AssertionError(msg)
def discover(archive, source):
    with zipfile.ZipFile(archive) as z:
        manifest=json.loads(z.read('diverse_manifest.json'))
        need(manifest['schema']=='befunge-stage1-diverse-native-v1' and len(manifest['cases'])==17,
             'original QA13 source trace manifest changed')
        result=[]
        for row in manifest['cases']:
            name=row['case'];raw=z.read(row['trace_file'])
            need(hashlib.sha256(raw).hexdigest()==row['trace_sha256'],
                 'QA13 immutable trace hash changed '+name)
            frozen.scan(raw,name,source)
            if not row['valid']: continue
            for item in raw.splitlines():
                f=item.split(b'\t')
                if f[0]!=b'STEP': continue
                tick,ipid,x,y,dx,dy,op,depth=map(int,f[1:])
                if ipid!=1 or tick>70000: continue
                if op in (ord('"'),ord('#'),ord('@'),ord(';')):continue
                for target in TARGETS:
                    if abs(x-target[0])+abs(y-target[1])!=1:continue
                    result.append(dict(target=list(target),case=name,fields=row['fields'],
                         tick=tick,neighbor=[x,y],source_byte=op,
                         depth=depth,delta=[dx,dy],trace_sha256=row['trace_sha256']))
        return manifest,result
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--original',required=True)
    ap.add_argument('--source',required=True)
    ap.add_argument('--output',required=True)
    a=ap.parse_args()
    source=frozen.pin_source(a.source)
    manifest,all_rows=discover(a.original,source)
    selected=[]
    for target in TARGETS:
        need(frozen.source_byte(source,target)==ord('x'),
             'candidate x source byte changed at '+repr(target))
        matches=[x for x in all_rows if tuple(x['target'])==target]
        need(matches, 'no real one-cell Native neighbor for '+repr(target))
        # One native input/case per target: candidate positions from this same
        # immutable trace, to avoid switching source histories mid-experiment.
        bycase={}
        for row in matches:bycase.setdefault(row['case'],[]).append(row)
        # Earliest repeatable witness, ties resolved by case string.
        name=min(bycase, key=lambda n:(min(v['tick'] for v in bycase[n]),n))
        candidates=sorted(bycase[name],key=lambda r:(r['tick'],r['neighbor']))
        selected.append(dict(target=list(target),case=name,fields=candidates[0]['fields'],
             trace_sha256=candidates[0]['trace_sha256'], candidates=candidates[:48]))
    output=dict(schema='qa19-one-cell-native-execution-witness-v1',
         source_git_blob=PIN,archive_original_run=39108506703,
         original_native_case_count=17,
         selection='nearest-executed-cardinal-neighbor-not-reachability',
         control_source_unmodified=True, stage1_complete=False, entries=selected)
    Path(a.output).write_text(json.dumps(output,indent=2,sort_keys=True)+'\n')
    print('QA19_REAL_NATIVE_THREE_ADJACENT_WITNESS_SETS_PASS',
          [(v['target'],v['case'],len(v['candidates']),v['candidates'][0]['tick'])
           for v in selected])
    print('QA19_OBSERVATION_NOT_NATURAL_REACHABILITY_PROOF')
if __name__=='__main__': main()
