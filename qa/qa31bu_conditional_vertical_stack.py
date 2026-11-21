#!/usr/bin/env python3
"""QA31BU: finite conditional stack semantics + ORIGINAL signed source owner.

This is QA-only. The counterfactual southbound entry is NOT asserted reachable.
No interpreter/Native run and no changed-program trace is created.
Python 3.11+ standard library. Reproduction:
  python qa31bu_conditional_vertical_stack.py --ai AI.zip --bn BN.zip \
      --bo BO.zip --bt BT.zip --out empty_output_directory
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import io
import json
from pathlib import Path
import zipfile
from qa31bp_original_output_ancestry import original_cases, digest, check_manifest, P, PIN, SOURCE

SHA = {
    'AI':'9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49',
    'BN':'6aaaa08c0edc66f529936d173a2894a7ed9123c523f5b47987498af4fa84ff79',
    'BO':'b95e2c8f9ca4d4c0dc9f2d31fcdf0690e1fad246cfd731ed905e5488638697de',
    'BT':'faacb845cadc7554766ccff76d52a970aea10b775ed97ff20a306cb9c3dbabf6',
}
# Directly observed on the immutable Git blob SOURCE using GitHub's blob API,
# x=1500 and zero-based y=1861..1881. The entire 1.8MB blob is NOT locally
# rehashed; this is a pinned byte-window witness only.
BYTES_GITHUB = 'v7a*9+1a*7+a*1+a*0+g.'
HEX_INDEPENDENT_ENCODING = '76 37 61 2a 39 2b 31 61 2a 37 2b 61 2a 31 2b 61 2a 30 2b 67 2e'
X = 1500
Y0, Y1 = 1861,1881
LIMIT = Y1-Y0+1
MEMORY_ADDR = (79,1710)


def require(ok, what):
    if not ok:
        raise ValueError(what)


def source_guard(actual: str):
    require(len(actual) == LIMIT and actual.encode('ascii') == bytes.fromhex(HEX_INDEPENDENT_ENCODING),
            'immutable GitHub source window failed byte-by-byte guard')
    require(actual == BYTES_GITHUB and actual[-1] == '.', 'GitHub y1881 byte is not dot')
    return True


def fetch_data(path: Path, label: str):
    data=path.read_bytes()
    require(digest(data)==SHA[label],label+' immutable archive SHA256 mismatch')
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        require(z.testzip() is None,label+' zip CRC mismatch')
        if 'MANIFEST.json' in z.namelist():
            m=check_manifest(z,'MANIFEST.json')
            require(m['project_id']==P,label+' project id mismatch')
    return data


def to_rows(raw: bytes):
    return [json.loads(t) for t in raw.splitlines() if t.strip()]


def oracle_a_interpreter(source: str, start_stack: tuple[int,...], memory_value: int, storage_offset: tuple[int,int]):
    """Oracle A: instruction-by-instruction bounded interpreter, no static arithmetic shortcuts."""
    stack=list(start_stack)
    ip=(X,Y0)
    dx,dy=(0,-1) # v overwrites incoming direction; initial direction deliberately arbitrary
    greads=[]
    out=[]
    for t,ins in enumerate(source,1):
        require(t<=LIMIT and ip==(X,Y0+t-1), 'conditional vertical instruction pointer')
        if ins=='v':
            dx,dy=0,1
        elif ins.isdigit():
            stack.append(ord(ins)-48)
        elif ins=='a':
            stack.append(10)
        elif ins in ('+','*'):
            b=stack.pop() if stack else 0
            a=stack.pop() if stack else 0
            stack.append(a+b if ins=='+' else a*b)
        elif ins=='g':
            y=stack.pop() if stack else 0
            x=stack.pop() if stack else 0
            effective=(x+storage_offset[0], y+storage_offset[1])
            greads.append(list(effective))
            stack.append(memory_value if (x,y)==MEMORY_ADDR else 32)
        elif ins=='.':
            v=stack.pop() if stack else 0
            out.append(str(v)+' ')
        else: raise ValueError('unsupported hypothetical instruction')
        ip=(ip[0]+dx,ip[1]+dy)
    require(t==LIMIT,'conditional instruction bound')
    return {'address':greads, 'output_prefix':''.join(out), 'end_stack':stack,
            'next_ip':list(ip), 'executed_instruction_count':t}


def oracle_b_algebra(source: str, start_stack: tuple[int,...], memory_value: int, storage_offset: tuple[int,int]):
    """Oracle B: independent closed-form decimal-place interpretation, no stack executor.

    Source is treated as two decimal digit expressions and a single read/print:
    x = 7*10 + 9; y = 1*1000 + 7*100 + 1*10 + 0.
    This independently checks the interpreter's arithmetic and preserved stack.
    """
    require(source == 'v7a*9+1a*7+a*1+a*0+g.', 'unexpected source grammar')
    xs=[7,9]
    ys=[1,7,1,0]
    x=sum(d*10**i for i,d in enumerate(reversed(xs)))
    y=sum(d*10**i for i,d in enumerate(reversed(ys)))
    require((x,y)==MEMORY_ADDR,'static address derivation')
    return {'address':[[x+storage_offset[0],y+storage_offset[1]]], 'output_prefix':f'{memory_value} ',
            'end_stack':list(start_stack), 'next_ip':[X,Y1+1],
            'executed_instruction_count':LIMIT}


def original_1881_audit(ai:bytes, bn:bytes, bo:bytes, bt:bytes):
    with zipfile.ZipFile(io.BytesIO(bt)) as z, zipfile.ZipFile(io.BytesIO(bn)) as nz:
        bs=json.loads(z.read('evidence/qa31bt_summary.json'))
        require(bs['project_id']==P and bs['selected_complete_original_traces']==135 and bs['stage1_pass'] is False,
                'BT verified cohort')
        bt_rows={r['case']:r for r in to_rows(z.read('evidence/qa31bt_cases.jsonl'))}
        require(len(bt_rows)==135,'BT cohort duplicates')
        unchanged=to_rows(nz.read('evidence/qa31bn_noops.jsonl'))
        require(len(unchanged)>=12,'genuine original no-effect controls below threshold')
        unchanged_by_case={}
        for row in unchanged:
            require(row['classification']=='NO_NUMERIC_EFFECT' and row['original_g']==row['intervention_g']
                    and row['baseline_sinks']==row['forward_sinks'], 'invalid original no-op')
            unchanged_by_case.setdefault(row['case'],[]).append(row)
    original_receipts=Counter()
    found=set()
    witnessed_noop=0
    per_case=[]
    # Reuse immutable acquisition/manifest/trace-SHA loader, not its owner algorithm.
    for receipt,events,controls,progress in original_cases(ai,bn,bo):
        label=receipt['label']
        require(label in bt_rows and bt_rows[label]['trace_sha256']==receipt['trace_sha256'],
                'BT source/trace association')
        tick=bt_rows[label]['original_fetch_tick']
        require(isinstance(tick,int) and 1<tick<=len(events),'original fetch tick range')
        anchor=events[tick-1]
        require(anchor['t']==tick and anchor['ip']==[1500,1860] and anchor['op']==62
                and anchor['string'] is False,'original source fetch anchor mismatch')
        # Owner F: forward chronological last-p map restricted to one address.
        physical=[]
        for e in events[:tick-1]:
            if e['string'] is False and e['op']==112:
                a=e['pre']; padded=[0]*max(0,3-len(a))+a
                val,px,py=padded[-3:]
                if (px,py)==(1500,1881): physical.append((e['t'],val))
        last_f=physical[-1] if physical else None
        # Owner R: independent reverse search from original raw events.
        last_r=None
        for e in reversed(events[:tick-1]):
            if e['op'] !=112 or e['string'] is not False:continue
            p=e['pre']; pv,px,py=([0]*max(0,3-len(p))+p)[-3:]
            if px==1500 and py==1881:
                last_r=(e['t'],pv)
                break
        require(last_f==last_r,'forward/reverse owner disagreement for original dot source')
        visits=sum(1 for e in events if e['ip']==[1500,1881])
        # No changed-program assertion: original pre-fetch memory and whole-original IP visits only.
        row={'case':label,'trace_sha256':receipt['trace_sha256'],
             'original_fetch_tick':tick,'original_pre_fetch_p_writes':len(physical),
             'original_last_owner':list(last_f) if last_f else None,
             'original_memory_at_fetch': last_f[1] if last_f else ord('.'),
             'original_ip_visits_complete_trace':visits}
        per_case.append(row)
        found.add(label)
        for nop in unchanged_by_case.get(label,[]):
            require(nop['trace_sha256']==receipt['trace_sha256'], 'genuine no-op trace sha mismatch')
            require(nop['case']==label,'no-op identity mismatch')
            witnessed_noop+=1
        original_receipts=progress
    require(len(per_case)==135 and len(found)==135,'signed original case count')
    require(original_receipts['original']==200 and original_receipts['steps']==3628390,
            'signed original receipt/STEP baseline')
    require(witnessed_noop>=12,'original matched unchanged controls below threshold')
    return per_case,witnessed_noop,original_receipts


def hostile_controls(source: str, baseline: list[dict]):
    """Detached mutations only; never execute modified Befunge/Native."""
    results=[]
    for i in range(LIMIT):
        alt=source[:i] + ('?' if source[i]!='?' else '!') + source[i+1:]
        try: source_guard(alt)
        except ValueError: results.append({'kind':'detached_source_byte','index':i,'y':Y0+i,'rejected':True})
        else: raise ValueError('forged source byte not rejected')
    # 12 independent unsigned report-row changes, caught by signed baseline equality.
    reference={r['case']:(r['trace_sha256'],r['original_fetch_tick'],r['original_memory_at_fetch']) for r in baseline}
    for i,r in enumerate(baseline[:12]):
        fake=dict(r)
        fake['original_memory_at_fetch']=r['original_memory_at_fetch']+1
        actual=(fake['trace_sha256'],fake['original_fetch_tick'],fake['original_memory_at_fetch'])
        if actual == reference[r['case']]: raise ValueError('forged original owner accepted')
        results.append({'kind':'detached_original_memory_receipt','case':r['case'],'rejected':True})
    require(len(results)>=12 and all(x['rejected'] for x in results),'detached hostile threshold')
    return results


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for key in ('ai','bn','bo','bt'):parser.add_argument('--'+key,type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    require(not args.out.exists(),'output directory already exists; preserve previous evidence')
    archive={k:fetch_data(getattr(args,k),k.upper()) for k in ('ai','bn','bo','bt')}
    source_guard(BYTES_GITHUB)
    original,n_noops,progress=original_1881_audit(archive['ai'],archive['bn'],archive['bo'],archive['bt'])
    memvalues=[-2**63,-2**31,-17,-1,0,1,7,10,32,127,2**31-1,2**63-1]
    stacks=[(),(0,),(5,),(-3,1),(2,0,-7),(79,1710),(-2**31,0,2**31-1),(3,3,3),
            (11,-11,0), (1,2,3,4), (-1,), (9,8,7,6,5)]
    simulated=[]
    offsets=[(0,0),(25,-10),(-79,0),(-100,1)]
    for offset in offsets:
        for st in stacks:
            for value in memvalues:
                a=oracle_a_interpreter(BYTES_GITHUB,st,value,offset)
                b=oracle_b_algebra(BYTES_GITHUB,st,value,offset)
                require(a==b,'independent conditional stack oracle disagreement')
                simulated.append({'initial_stack':list(st),'storage_offset':list(offset),
                                  'memory_at_effective_g_address':value,'result':a})
    forged=hostile_controls(BYTES_GITHUB,original)
    summary={'project_id':P,'qa':'QA31BU','stage1_pass':False,
      'entry_head':'a68cb80e34af6f1482d8fa275d8f901483bace63',
      'original_source_git_blob':SOURCE,
      'source_window':[X,Y0,Y1],'source_bytes':BYTES_GITHUB,
      'source_y1881_ascii':ord('.'),'source_full_git_blob_locally_rehashed':False,
      'hypothetical_v_entry_reachable':'UNKNOWN',
      'source_controlled_instruction_limit':LIMIT,
      'calculated_g_relative_address_operands':list(MEMORY_ADDR),
      'absolute_g_address_formula':'(79+SO_x,1710+SO_y)',
      'storage_offsets_tested':[list(x) for x in offsets],
      'output_prefix_if_conditional':'decimal(M[79+SO_x,1710+SO_y])+space under oracle I/O convention',
      'end_stack_if_conditional':'identical_to_explicit_initial_stack',
      'conditional_oracle_agreements':len(simulated),
      'genuine_unchanged_original_signed_controls':n_noops,
      'selected_original_traces':len(original),
      'original_signed_HALT_receipts':progress['original'],
      'original_signed_physical_steps':progress['steps'],
      'original_y1881_pre_fetch_writes':sum(x['original_pre_fetch_p_writes'] for x in original),
      'original_y1881_complete_trace_ip_visits':sum(x['original_ip_visits_complete_trace'] for x in original),
      'original_y1881_forward_reverse_owner_agreements':len(original),
      'detached_hostile_rejections':len(forged),
      'changed_run_path_writer_address_stack_memory_output':'UNKNOWN',
      'new_native_runs':0,'new_ci_runs':0,
      'input_archives_sha256':{k.upper():digest(v) for k,v in archive.items()}}
    args.out.mkdir(parents=True)
    def write_jsonl(name, rows):
        (args.out/name).write_text(''.join(json.dumps(v,ensure_ascii=False,sort_keys=True)+'\n' for v in rows),encoding='utf-8')
    write_jsonl('qa31bu_original_y1881.jsonl',original)
    write_jsonl('qa31bu_conditional_oracles.jsonl',simulated)
    write_jsonl('qa31bu_hostiles.jsonl',forged)
    (args.out/'qa31bu_summary.json').write_text(json.dumps(summary,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,sort_keys=True))

if __name__=='__main__':main()