#!/usr/bin/env python3
"""QA31Z finite signed-original-trace stack lineage. Python 3 stdlib only.

No Native execution. Dependencies are syntactic dataflow in witnessed Funge
stack transitions, not proof of byte causality or global source ownership.
Fail closed on trace inconsistencies; quarantine unsupported opcodes as unknown.
"""
import argparse
import collections
import csv
import json
from dataclasses import dataclass
from pathlib import Path
from stage1_qa31x_pairwise_first_divergence import CaseReader, load_w_csv, selected_pairs, check
from stage1_qa31y_source_pinned_last_writer_reader import OPCODES, SITES, local_j_check, source_sites_check

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
LOOKBACK=384
G_SITES={(151,8),(57,17),(129,17),(202,17),(275,17)}

@dataclass(frozen=True)
class Tag:
    sources: frozenset= frozenset()  # (x,y,tick) of physically witnessed g
    opaque: bool=False              # untracked provenance before window / unsupported opcode

UNKNOWN=Tag(opaque=True)
KNOWN=Tag()

def union(*xs):
    return Tag(frozenset().union(*(x.sources for x in xs)), any(x.opaque for x in xs))

def num(e): return chr(e['op']) if 32<=e['op']<=126 else '?'

def op_transfer(e, tags):
    """Execute structural stack effect. Return (tags, support, push-origin).
    Every supported effect MUST reproduce full physical 'post' values.
    Literal/dynamic behavior is not inferred from matching numeric values.
    """
    a=list(e['pre']); t=list(tags)
    check(len(a)==len(t),'tag/pre-stack mismatch at '+str(e['t']))
    def pop():
        return (a.pop(),t.pop()) if a else (0,KNOWN) # Funge underflow -> zero
    def push(value,tag): a.append(value);t.append(tag)
    op=num(e); supported=True; origin=None
    if op in '0123456789abcdef':
        push(int(op,16),KNOWN)
    elif op in ('+','-','*','/','%','`'):
        b,btag=pop(); av,atag=pop()
        if op=='+':v=av+b
        elif op=='-':v=av-b
        elif op=='*':v=av*b
        elif op=='`':v=int(av>b)
        elif op=='/':v=0 if b==0 else int(av/b)
        else:v=0 if b==0 else av % b  # cannot always match PyFunge modulo; fail closed
        push(v,union(atag,btag))
    elif op=='!':
        v,tag=pop();push(int(not v),tag)
    elif op==':':
        v,tag=pop();push(v,tag);push(v,tag)
    elif op=='\\':
        a1,t1=pop();a2,t2=pop();push(a1,t1);push(a2,t2)
    elif op=='$':pop()
    elif op=='g':
        y,y_tag=pop(); x,x_tag=pop()
        check(bool(e['post']),'physical g missing value at '+str(e['t']))
        value=e['post'][-1]
        site=tuple(e['ip'])
        if site in G_SITES:
            origin=(site[0],site[1],e['t'])
            push(value,Tag(frozenset({origin}),False))
        else:
            push(value,UNKNOWN)
    elif op=='p':
        for _ in range(3):pop()
    elif op in ('~','&'):
        check(len(e['post'])>=len(e['pre'])+1,'read expected to push')
        push(e['post'][-1],UNKNOWN)
    elif op in (' ','>','<','^','v','#','[',']','w','r','q','z'):
        # Conservative: only accept if the physical post is unchanged.
        # No lineage assertions for stack-mutating extensions.
        if e['post']!=e['pre']: supported=False
    elif op in ('_','|'):
        pop()
    elif op=='j':
        pop()
    else:
        supported=False
    if not supported:
        # Preserve the physical state but erase all unsound provenance.
        return [UNKNOWN for _ in e['post']],False,None
    check(a==e['post'],f'physical stack mismatch tick={e["t"]} ip={e["ip"]} op={op} '
         f'expected={a[-5:]} actual={e["post"][-5:]}')
    return t, True, origin


def audit_one(events,idx,label):
    j=events[idx]; coord=tuple(j['ip'])
    flag=local_j_check(events,idx)
    lo=max(0,idx-LOOKBACK)
    gs=[n for n in range(lo,idx) if tuple(events[n]['ip']) in G_SITES and events[n]['op']==103]
    result={'label':label,'tick':j['t'],'j_site':list(coord),'operand':j['pre'][-1],
            'flag':flag,'g_in_384':len(gs),'lineage':'unknown',
            'observed_g_sites':[],'dependent_g_sites':[],
            'unresolved_input_byte_owner':True,'global_source_ownership':False,
            'unsupported_opcodes':[],'opaque_pre_window':True}
    if not gs:return result
    start=gs[0]
    tags=[UNKNOWN for _ in events[start]['pre']]
    physically_seen=set()
    for n in range(start,idx):
        e=events[n]
        if n>start:check(events[n-1]['post']==e['pre'],f'physical pre/post discontinuity {label}:{e["t"]}')
        tags,supported,origin=op_transfer(e,tags)
        if origin is not None:physically_seen.add(origin)
        if not supported:result['unsupported_opcodes'].append({'tick':e['t'],'ip':e['ip'],'op':e['op']})
    check(len(tags)==len(j['pre']),'j tag stack length mismatch')
    check(j['pre'],'empty j pre physical')
    tag=tags[-1]
    result['observed_g_sites']=[list(x) for x in sorted(physically_seen)]
    result['dependent_g_sites']=[list(x) for x in sorted(tag.sources)]
    result['opaque_pre_window']=tag.opaque
    if result['unsupported_opcodes'] or tag.opaque:
        result['lineage']='unknown'
    elif tag.sources:
        result['lineage']='observed_g_structural_dependency'
    else:
        result['lineage']='no_target_g_in_observed_operand_stack'
    # This result is deliberately NEVER a proof of input-byte provenance.
    return result


def selftests():
    def e(t,op,pre,post,ip=(1,1)):
        return {'t':t,'op':ord(op),'ip':list(ip),'pre':pre,'post':post}
    count=0
    # Positive transfer: observed g -> (>) -> (*) -> j, matching physical stacks.
    seq=[e(1,'g',[0,49],[32],(151,8)),e(2,'0',[32],[32,0]),
         e(3,'`',[32,0],[1]),e(4,'1',[1],[1,1]),e(5,'*',[1,1],[1])]
    tags=[UNKNOWN,UNKNOWN]
    for x in seq:
        tags,ok,_=op_transfer(x,tags);check(ok,'synthetic supported');count+=1
    check(tags[-1].sources==frozenset({(151,8,1)}) and not tags[-1].opaque,'positive lineage');count+=1
    # Distinct input tags must not be invented from identical numeric values.
    tags,_,_=op_transfer(e(1,'g',[0,49],[32],(151,8)),[UNKNOWN,UNKNOWN])
    check(tags[0].sources==frozenset({(151,8,1)}),'observed origin');count+=1
    tags,_,_=op_transfer(e(2,'0',[32],[32,0]),tags)
    tags,_,_=op_transfer(e(3,'*',[32,0],[0]),tags)
    check(bool(tags[0].sources),'structural dependency survives multiply-by-zero, not numeric causality');count+=1
    # Unsupported mutation erases all lineage; benign control leaves it intact.
    tags,ok,_=op_transfer(e(4,'s',[0],[0]),tags)
    check(not ok and tags[0].opaque and not tags[0].sources,'poison unknown');count+=1
    tags,ok,_=op_transfer(e(5,'>',[0],[0]),tags)
    check(ok and tags[0].opaque,'control cannot resolve unknown');count+=1
    # Known numeric expression unrelated to target g is correctly classified as no g lineage.
    a,ok,_=op_transfer(e(1,'5',[],[5]),[])
    b,ok,_=op_transfer(e(2,'3',[5],[5,3]),a)
    c,ok,_=op_transfer(e(3,'+',[5,3],[8]),b)
    check(c==[KNOWN],'constant expression');count+=1
    # Fail closed if a forged 'post' contradicts opcode physical arithmetic.
    for bad in [e(4,'+',[5,3],[9]),e(4,'g',[0,49],[]),e(4,'!',[0],[0]),e(4,'*',[4,5],[19])]:
        try:op_transfer(bad,[UNKNOWN for _ in bad['pre']])
        except AssertionError:count+=1
        else:raise AssertionError('hostile forged stack accepted '+str(bad))
    check(count==15,f'self-test count {count}')
    return count


def run(zip_dir,csv_path,out):
    out=Path(out);out.mkdir(parents=True,exist_ok=True)
    cases=load_w_csv(csv_path)
    pairs,_=selected_pairs(cases)
    labels=sorted({x['label'] for _,a,b in pairs for x in (a,b)})
    check(len(labels)==29,'expected 29 physical traces')
    lookup={x['label']:x for x in cases}
    reader=CaseReader(zip_dir)
    items=[]; source_checks=0
    for label in labels:
        events=reader.load(lookup[label])
        source_checks+=source_sites_check(events)
        for i,e in enumerate(events):
            if tuple(e['ip']) in SITES and e['op']==106:
                items.append(audit_one(events,i,label))
    test_count=selftests()
    check(len(items)==364,'expected 364 QA31Y original signed j witnesses')
    check(source_checks==3557,'expected source-pinned event checks')
    counts=collections.Counter(e['lineage'] for e in items)
    per_site=collections.Counter((tuple(e['j_site']),e['lineage']) for e in items)
    origin_sites=collections.Counter(tuple(o[:2]) for e in items for o in e['dependent_g_sites'])
    report={'schema':'qa31z-source-pinned-finite-stack-dependency-v1',
       'project_id':PROJECT,'branch_head_input':'709aae98b2777060e15f1d33d988f8fe767334e1',
       'source_blob':SOURCE_BLOB,'original_native_run':41689861481,
       'source_opcode_checks':source_checks,
       'original_zip_sha256_crc_verified':len(reader.zips),
       'signed_traces_verified':len(reader.processed),
       'signed_physical_steps_verified':sum(reader.processed.values()),
       'j_events':len(items),
       'lineage_counts':dict(counts),
       'lineage_per_j_site':{f'{s[0]},{s[1]}:{k}':v for (s,k),v in sorted(per_site.items())},
       'dependent_site_occurrences':{f'{x},{y}':c for (x,y),c in sorted(origin_sites.items())},
       'synthetic_positive_and_hostile_checks':test_count,
       'window_steps':LOOKBACK,
       'global_byte_owner':'unknown',
       'global_reachability_proven':False,'full_functional_qa_pass':False,
       'geometric_spaghetti_qa_pass':False,'stage1_pass':False,'new_native_runs':0}
    (out/'QA31Z_SUMMARY.json').write_text(json.dumps(report,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    (out/'QA31Z_WITNESSES.json').write_text(json.dumps(items,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    with (out/'QA31Z_WITNESSES.csv').open('w',encoding='utf-8',newline='') as f:
        w=csv.writer(f);w.writerow(['label','j_tick','j_x','j_y','operand','lineage','dependent_g_sites','g_observed','unsupported_ops','opaque_operand','byte_owner'])
        for x in items:
            w.writerow([x['label'],x['tick'],*x['j_site'],x['operand'],x['lineage'],
                        '|'.join('%d:%d@%d'%tuple(s) for s in x['dependent_g_sites']),
                        x['g_in_384'],len(x['unsupported_opcodes']),x['opaque_pre_window'],'unknown'])
    print(json.dumps(report,ensure_ascii=False,sort_keys=True))
    return report

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--zip-dir',required=True);ap.add_argument('--qa31w-csv',required=True);ap.add_argument('--out',required=True);a=ap.parse_args()
    run(a.zip_dir,a.qa31w_csv,a.out)
