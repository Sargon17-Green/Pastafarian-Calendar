#!/usr/bin/env python3
"""QA18: source-byte role partition from 49 original *real* Native BF98 traces.
No novel Native executions, no calendar oracle, no dead-code certification.
"""
import argparse,copy,gzip,hashlib,json,zipfile
from pathlib import Path
import stage1_qa17_native_frontier as frozen

KINDS=('original_executed','only_overwritten_execution','g_read_not_executed',
       'p_target_not_executed_or_read','never_touched')
CONTROL=set(map(ord,'><^v[]rwx_|jk{}ut()?#@pg;'))

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def partition(glyphs,original,dynamic,gets,puts):
    static=set(glyphs)
    first=static & original
    second=(static & dynamic)-first
    remaining=static-first-second
    third=remaining & gets
    fourth=(remaining-third) & puts
    fifth=remaining-third-fourth
    result=dict(zip(KINDS,(first,second,third,fourth,fifth)))
    need(set().union(*result.values())==static,'nonblank source was not partitioned')
    need(sum(map(len,result.values()))==len(static),'source coordinate counted twice')
    return result

def verify(d):
    need(d.get('schema')=='qa18-source-glyph-contact-v1' and
         d.get('source_git_blob')==frozen.SOURCE_BLOB and
         d.get('native_original_trace_count')==49 and
         d.get('native_executions_new_in_qa18')==0 and
         d.get('stage1_complete') is False and
         d.get('dead_code_certified') is False,'forged provenance/Stage1 closure')
    roles=d.get('roles',{})
    need(set(roles)==set(KINDS),'missing source role')
    arr=[]
    for key in KINDS:
        coords=roles[key]
        need(type(coords) is list and len(coords)==d['counts'][key], 'source role count forged')
        need(all(type(c) is list and len(c)==2 and
                 all(type(i) is int and i>=0 for i in c) for c in coords),
             'invalid source coordinates')
        arr+=list(map(tuple,coords))
    need(len(arr)==len(set(arr))==d['source_nonblank_total'], 'source coordinate overlap/hole')
    need(d['native_STEP_nonblank_visited']==
         d['counts'][KINDS[0]]+d['counts'][KINDS[1]], 'source STEP count forged')
    need(d['native_STEP_nonblank_unvisited']==sum(d['counts'][x] for x in KINDS[2:]),
         'source unexecuted count forged')

def selftest():
    g={(0,0):ord('p'),(1,0):ord('g'),(2,0):ord('x'),
       (3,0):ord('4'),(4,0):ord('>')}
    p=partition(g,{(0,0)},{(1,0)},{(2,0)},{(3,0)})
    d={'schema':'qa18-source-glyph-contact-v1','source_git_blob':frozen.SOURCE_BLOB,
       'native_original_trace_count':49,'native_executions_new_in_qa18':0,
       'stage1_complete':False,'dead_code_certified':False,
       'roles':{k:[list(x) for x in sorted(v)] for k,v in p.items()},
       'counts':{k:len(v) for k,v in p.items()},'source_nonblank_total':5,
       'native_STEP_nonblank_visited':2,'native_STEP_nonblank_unvisited':3}
    verify(d)
    changes=[
       lambda a:a.__setitem__('stage1_complete',True),
       lambda a:a.__setitem__('dead_code_certified',True),
       lambda a:a.__setitem__('source_git_blob','0'*40),
       lambda a:a.__setitem__('native_original_trace_count',48),
       lambda a:a.__setitem__('native_executions_new_in_qa18',49),
       lambda a:a['roles']['never_touched'].pop(),
       lambda a:a['roles']['never_touched'].__setitem__(0,[0,0]),
       lambda a:a['counts'].__setitem__('original_executed',2),
       lambda a:a.__setitem__('native_STEP_nonblank_unvisited',2)]
    for i,fn in enumerate(changes):
        x=copy.deepcopy(d);fn(x)
        try:verify(x)
        except (AssertionError,IndexError):pass
        else:raise AssertionError('forged synthetic provenance accepted '+str(i))
    print('QA18_NINE_SYNTHETIC_PROVENANCE_FORGERIES_REJECTED')
    print('QA18_SYNTHETICS_NOT_NATIVE_EXECUTIONS')

def raw_cases(old,shards):
    with zipfile.ZipFile(old) as z:
        m=json.loads(z.read('diverse_manifest.json'))
        for row in m['cases']:
            yield row['case'],z.read(row['trace_file'])
    for i,path in enumerate(shards):
        with zipfile.ZipFile(path) as z:
            m=json.loads(z.read('native_manifest.json'))
            need(m['shard']==i,'QA14 shard reordered')
            for row in m['records']:
                yield row['label'],gzip.decompress(z.read(row['label']+'.tsv.gz'))

def native_role_events(old,shards):
    original=set();dynamic=set();gets=set();puts=set()
    witnesses={};steps=reads=writes=0
    names=[]
    for name,raw in raw_cases(old,shards):
        names.append(name);written=set()
        for ln in raw.splitlines():
            f=ln.split(b'\t')
            if f[0]==b'STEP':
                xy=tuple(map(int,f[3:5]))
                (dynamic if xy in written else original).add(xy);steps+=1
            elif f[0]==b'READ_AFTER':
                xy=tuple(map(int,f[2:4]))
                gets.add(xy);reads+=1
                witnesses.setdefault(xy,set()).add(name)
            elif f[0]==b'WRITE_AFTER':
                xy=tuple(map(int,f[2:4]))
                puts.add(xy);written.add(xy);writes+=1
        need(steps>=1000,'trace too short')
    need(len(names)==len(set(names))==49,'Native labels duplicate')
    need((steps,writes,reads)==(3288759,14409,27795),'Native physical event totals drifted')
    return original,dynamic,gets,puts,witnesses

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--qa13');p.add_argument('--shard',action='append',default=[])
    p.add_argument('--source');p.add_argument('--output');p.add_argument('--selftest',action='store_true')
    a=p.parse_args();selftest()
    if a.selftest:return
    need(a.qa13 and len(a.shard)==4 and a.source and a.output,'missing original Native artifacts')
    source=frozen.pin_source(a.source)
    old,new=frozen.load_corpus(a.qa13,a.shard,source)
    old_report=frozen.report(old,new,source)
    glyphs={(x,y):ch for y,line in enumerate(source) for x,ch in enumerate(line) if ch!=32}
    original,dynamic,gets,puts,witnesses=native_role_events(a.qa13,a.shard)
    parts=partition(glyphs,original,dynamic,gets,puts)
    d={'schema':'qa18-source-glyph-contact-v1',
       'source_git_blob':frozen.SOURCE_BLOB,
       'source_nonblank_total':len(glyphs),'native_original_trace_count':49,
       'native_executions_new_in_qa18':0,'stage1_complete':False,'dead_code_certified':False,
       'counts':{k:len(v) for k,v in parts.items()},
       'roles':{k:[list(x) for x in sorted(v)] for k,v in parts.items()},
       'native_STEP_nonblank_visited':len((original|dynamic)&set(glyphs)),
       'native_STEP_nonblank_unvisited':len(set(glyphs)-(original|dynamic)),
       'unvisited_g_read_native_witnesses':{
           str(x)+','+str(y):sorted(witnesses.get((x,y),[]))[:5]
           for x,y in sorted(parts['g_read_not_executed'])},
       'never_touched_potential_control_glyphs':[
           {'x':x,'y':y,'source_char':chr(glyphs[(x,y)])}
           for x,y in sorted(parts['never_touched']) if glyphs[(x,y)] in CONTROL],
       'qa17_source_glyph_sha256':old_report['static_glyph_coverage']['unobserved_coordinates_sha256'],
       'limitation':'No Native execution or g read in 49 traces cannot establish dead code; stringmode/literals not semantic operators.'}
    need(len(glyphs)==13442 and d['native_STEP_nonblank_visited']==12460
         and d['native_STEP_nonblank_unvisited']==982,
         'QA17 static-source observation baseline changed')
    verify(d)
    Path(a.output).write_text(json.dumps(d,sort_keys=True,indent=2)+'\n',encoding='utf8')
    print('QA18_NATIVE_49_SOURCE_GLYPH_ROLE_PARTITION_PASS',json.dumps(d['counts'],sort_keys=True))
    print('QA18_NO_STATIC_GLYPH_MARKED_DEAD_AND_STAGE1_OPEN')

if __name__=='__main__':main()
