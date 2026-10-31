#!/usr/bin/env python3
"""QA17: executable trace coverage frontier over the original 17+32 native PyFunge captures.

Finite observational measurements, *never* a global dead-code or Stage-1 proof.
Checks immutable original trace SHA-256, record shape, chronological physical p/g
and memory-to-execution consistency; reports additive route/byte/edge coverage.
No Python implementation of Pastafarian arithmetic.
"""
import argparse
import copy
import gzip
import hashlib
import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
ORIGINAL_RUN = 39108506703
QA14_RUN = 39374913267
QA14_ARTIFACTS = (12242831803,12243500881,12243575160,12243082239)
FROZEN_QA13_DIGEST_BOOK_SHA256 = '0808ee2cf28febee50aaf672d382bc7ef814997841ee23aabc6109844ad43667'
FROZEN_QA14_DIGEST_BOOK_SHA256 = 'c4f6144e3d6a485d8b6ca5304e86c8e6b7b4c4f8a8501b541f013234e6a04c88'
VALID_HEX = re.compile(r'[0-9a-f]{64}\Z', re.ASCII)
WATCH = '><^v[]rwx_|jk{}ut()'


def need(ok, text):
    if not ok:
        raise AssertionError(text)


def pin_source(file):
    if file is None:
        return None  # Allowed for local analytics; CI always passes --source.
    data = Path(file).read_bytes()
    gitblob = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    need(gitblob == SOURCE_BLOB, 'Production source blob changed')
    return [line.rstrip(b'\r') for line in data.split(b'\n')]


def source_byte(source, xy):
    if source is None:
        return None
    x,y = xy
    return source[y][x] if 0 <= y < len(source) and 0 <= x < len(source[y]) else 32


def scan(raw, name, source=None):
    """Validate temporal lineage, with no shadow program or fake arithmetic oracle."""
    need(type(raw) is bytes and len(raw) > 10000, name+' trace absent/truncated')
    last_tick = 0
    step = None
    pending = None
    memory = {}
    coords = set(); edges = set(); initial_chars = set(); codes = Counter()
    writes = reads = read_written = executed_written = 0
    mutated_executable = set()
    gates = []; earlier = None
    arithmetic = False
    arith_coords = set(); arith_edges = set()
    for line in raw.splitlines():
        fields = line.split(b'\t')
        op = fields[0]
        if op == b'STEP':
            need(pending is None and len(fields)==9, name+' dangling p/g event')
            try:
                tick,ip,x,y,dx,dy,ch,depth = map(int,fields[1:])
            except Exception as ex:
                raise AssertionError(name+' malformed STEP') from ex
            need(tick==last_tick+1 and ip==1 and depth>=0 and 0<=ch<=255,
                 name+' step sequence, depth or opcode forged')
            last_tick=tick;xy=(x,y); coords.add(xy); codes[ch]+=1
            if earlier is not None:
                edges.add((earlier,xy))
            if (x,y,dx,dy)==(5,0,1,0):
                arithmetic = True
            if arithmetic:
                arith_coords.add(xy)
                if earlier is not None:
                    arith_edges.add((earlier,xy))
            if xy in memory:
                need(ch==memory[xy], name+' stale written instruction executed')
                executed_written += 1
                mutated_executable.add(xy)
            elif source is not None:
                need(ch==source_byte(source,xy),name+' static source-to-STEP mismatch')
            if source is not None and source_byte(source,xy)!=32:
                initial_chars.add(xy)
            if xy==(1500,1860): gates.append((tick,ch))
            step=(tick,xy,ch)
            earlier=xy
        elif op in (b'WRITE_BEFORE',b'READ_BEFORE'):
            kind=b'WRITE' if op.startswith(b'WRITE') else b'READ'
            need(step is not None and pending is None, name+' orphan p/g before')
            need(step[2]==ord('p' if kind==b'WRITE' else 'g'),
                 name+' event not bound to executed p/g')
            need(len(fields)==(6 if kind==b'WRITE' else 5), name+' malformed p/g before')
            try:
                tick,x,y,old=map(int,fields[1:5]);xy=(x,y)
                value=int(fields[5]) if kind==b'WRITE' else None
            except ValueError as ex:
                raise AssertionError(name+' malformed p/g operands') from ex
            need(tick==last_tick, name+' p/g before tick forged')
            expected=memory.get(xy,source_byte(source,xy))
            if expected is not None:
                need(old==expected,name+' read/write ignores current memory version')
            pending=(kind,tick,xy,old,value)
        elif op in (b'WRITE_AFTER',b'READ_AFTER'):
            kind=b'WRITE' if op.startswith(b'WRITE') else b'READ'
            need(pending is not None and pending[0]==kind and len(fields)==5,
                 name+' orphan or crossed after event')
            try:
                tick,x,y,value=map(int,fields[1:]);xy=(x,y)
            except ValueError as ex:
                raise AssertionError(name+' malformed after') from ex
            need((tick,xy)==(pending[1],pending[2]),name+' changed p/g target')
            if kind==b'WRITE':
                need(value==pending[4],name+' p did not store expected byte')
                memory[xy]=value;writes+=1
            else:
                need(value==pending[3],name+' g changed between before and after')
                reads+=1
                if xy in memory:read_written+=1
            pending=None
        else:
            raise AssertionError(name+' unrecognized Native event '+repr(op))
    need(pending is None and last_tick>1000 and arithmetic,
         name+' incomplete native execution or missing arithmetic handoff')
    need(writes>0 and reads>0 and read_written>0 and executed_written>0,
         name+' no genuine mutated-memory involvement')
    need(len(gates)==1,name+' gate execution frequency changed')
    return {'name':name,'steps':last_tick,'p':writes,'g':reads,
            'read_after_write':read_written,'executed_written':executed_written,
            'gate_byte':gates[0][1],
            'coordinates':coords,'edges':edges,'arith_coords':arith_coords,
            'arith_edges':arith_edges,'mutated_executable':mutated_executable,
            'static_nonblank_executed':initial_chars,'opcodes':codes}


def load_corpus(original_zip, shard_zips, source=None):
    first=[];new=[]
    with zipfile.ZipFile(original_zip) as archive:
        m=json.loads(archive.read('diverse_manifest.json'))
        need(m.get('schema')=='befunge-stage1-diverse-native-v1' and
             type(m.get('cases')) is list and len(m['cases'])==17,
             'QA13 manifest identity or length changed')
        names=[]; digest_set=set();book=[]
        for case in m['cases']:
            name=case['case'];names.append(name)
            need(case['trace_file']==name+'.tsv' and
                 VALID_HEX.fullmatch(case['trace_sha256']),
                 'QA13 trace name/digest forged '+name)
            raw=archive.read(case['trace_file'])
            need(hashlib.sha256(raw).hexdigest()==case['trace_sha256'],
                 'QA13 raw trace SHA mismatch '+name)
            digest_set.add(case['trace_sha256']);book.append((name,case['trace_sha256']))
            x=scan(raw,name,source)
            need(x['gate_byte']==(118 if case['valid'] else 62),
                 'QA13 gate type mismatch '+name)
            x['valid']=case['valid']; first.append(x)
        need(len(set(names))==17 and len(digest_set)==17,
             'QA13 duplicate label or trace')
        need(hashlib.sha256(json.dumps(sorted(book),separators=(',',':')).encode()).hexdigest()==FROZEN_QA13_DIGEST_BOOK_SHA256,
             'QA13 archive evidence book differs from the originally verified 17 traces')
    names=set(); hashes=set();book=[]
    need(len(shard_zips)==4,'QA14 must have four original shards')
    for i,path in enumerate(shard_zips):
        with zipfile.ZipFile(path) as archive:
            m=json.loads(archive.read('native_manifest.json'))
            need(m.get('shard')==i and m.get('shards')==4 and
                 m.get('source_git_blob')==SOURCE_BLOB and
                 m.get('stage1_final_acceptance') is False and
                 type(m.get('records')) is list and len(m['records'])==8,
                 'QA14 shard identity/source/shape forged '+str(i))
            for case in m['records']:
                label=case['label']
                need(label.startswith('pair') and label.endswith(('_A','_B')) and
                     label not in names and
                     case['trace_file']==label+'.tsv' and
                     case['native_interpreter_calls']==5 and
                     VALID_HEX.fullmatch(case['trace_sha256']),
                     'QA14 case identity forged '+label)
                names.add(label)
                raw=gzip.decompress(archive.read(label+'.tsv.gz'))
                digest=hashlib.sha256(raw).hexdigest()
                need(digest==case['trace_sha256'] and
                     len(raw)==case['trace_bytes'] and digest not in hashes,
                     'QA14 raw bytes/SHA or distinctness forged '+label)
                hashes.add(digest);book.append((label,digest))
                x=scan(raw,label,source)
                need(x['gate_byte']==118 and case['valid'] is True,
                     'QA14 executed input gate malformed '+label)
                x['valid']=True;new.append(x)
    need(len(new)==32 and len(names)==32 and
         {f'pair{i:02d}_{x}' for i in range(16) for x in 'AB'}==names,
         'QA14 missing/reordered pair directions')
    need(hashlib.sha256(json.dumps(sorted(book),separators=(',',':')).encode()).hexdigest()==FROZEN_QA14_DIGEST_BOOK_SHA256,
         'QA14 archive evidence book differs from the originally verified 32 traces')
    return first,new


def tally(items):
    sets={k:set().union(*(x[k] for x in items)) for k in
          ('coordinates','edges','arith_coords','arith_edges',
           'mutated_executable','static_nonblank_executed')}
    totals={k:sum(x[k] for x in items) for k in ('steps','p','g','read_after_write','executed_written')}
    codes=Counter()
    for x in items:codes.update(x['opcodes'])
    return sets,totals,codes


def report(first,second,source=None):
    old,oa,oc=tally(first); new,na,nc=tally(second); full,fa,fc=tally(first+second)
    need(len(first)==17 and len(second)==32 and na['p']==11490 and
         na['g']==22210 and na['executed_written']==596 and
         oa['p']==2919 and oa['g']==5585 and oa['executed_written']==136,
         'Existing signed native metrics do not match original QA13/QA14')
    graph={key:{'qa13':len(old[key]),'qa14':len(new[key]),'union':len(full[key]),
                'new_in_qa14':len(new[key]-old[key]),
                'not_seen_in_qa14':len(old[key]-new[key])} for key in old}
    statics=None
    if source is not None:
        active={(x,y) for y,line in enumerate(source) for x,c in enumerate(line) if c!=32}
        observed=full['static_nonblank_executed']
        statics={'source_nonspace_glyphs':len(active),
                 'source_nonspace_glyphs_visited':len(observed),
                 'unobserved_source_glyphs':len(active-observed),
                 'unobserved_coordinates_sha256':hashlib.sha256(json.dumps(sorted(active-observed)).encode()).hexdigest(),
                 'warning':'Unobserved static glyphs include literals/data; not proof of dead code.'}
    modes={ch:{'qa13':oc[ord(ch)],'qa14':nc[ord(ch)],'total':fc[ord(ch)]}
           for ch in WATCH}
    return {'schema':'qa17-native-49-executed-path-coverage-frontier-v1',
            'provenance':{'qa13_original_run':ORIGINAL_RUN,'qa14_original_run':QA14_RUN,
                          'qa14_original_artifacts':list(QA14_ARTIFACTS),
                          'source_git_blob':SOURCE_BLOB},
            'scope':'FINITE_OBSERVED_NATIVE_STEP_P_G_NOT_GLOBAL_DEAD_CODE_PROOF',
            'case_counts':{'qa13':17,'qa14':32,'all':49},
            'physical_totals':{'qa13':oa,'qa14':na,'union':fa},
            'native_witness_sets':graph,
            'qa13_only_arithmetic_coordinates': [list(x) for x in sorted(old['arith_coords']-new['arith_coords'])],
            'qa13_only_arithmetic_edges': [[list(a),list(b)] for a,b in sorted(old['arith_edges']-new['arith_edges'])],
            'qa13_only_coordinate_witnesses': {
               f'{xy[0]},{xy[1]}': [r['name'] for r in first if xy in r['arith_coords']]
               for xy in sorted(old['arith_coords']-new['arith_coords'])},
            'observed_step_opcode_totals':modes,
            'static_glyph_coverage':statics,
            'gate_byte_classes':{'qa13_valid':14,'qa13_invalid':3,'qa14_valid':32},
            'stage1_final_accepted':False,
            'open':['Unobserved literal/code classification','Mutant causal tests on uncovered code',
                    'Unbounded input and full geometry/ownership certification']}


def selftest():
    """True passing synthetic event sequence; each adversarial edit must fail early.

    Never a substitute for the 49 independently archived native traces.
    """
    lines=[
      b'STEP\t1\t1\t0\t0\t1\t0\t112\t0',
      b'WRITE_BEFORE\t1\t1500\t1860\t32\t118',
      b'WRITE_AFTER\t1\t1500\t1860\t118',
      b'STEP\t2\t1\t1\t0\t1\t0\t103\t0',
      b'READ_BEFORE\t2\t1500\t1860\t118',
      b'READ_AFTER\t2\t1500\t1860\t118',
      b'STEP\t3\t1\t5\t0\t1\t0\t32\t0',
      b'STEP\t4\t1\t1500\t1860\t1\t0\t118\t0',
    ]
    for tick in range(5,1005):
        lines.append((f'STEP\t{tick}\t1\t{tick+100}\t1\t1\t0\t32\t0').encode('ascii'))
    sample=b'\n'.join(lines)+b'\n'
    parsed=scan(sample,'passing-synthetic-fixture')
    need(parsed['p']==parsed['g']==parsed['executed_written']==1,
         'QA17 synthetic test fixture did not prove successful event lineage')
    attacks=[
      ('stale executed byte',b'1500\t1860\t1\t0\t118\t0',b'1500\t1860\t1\t0\t119\t0', 'stale written instruction'),
      ('missing before event',b'WRITE_BEFORE\t1\t1500\t1860\t32\t118\n',b'', 'orphan or crossed after'),
      ('wrong after write value',b'WRITE_AFTER\t1\t1500\t1860\t118',b'WRITE_AFTER\t1\t1500\t1860\t119','p did not store'),
      ('wrong write coordinate',b'WRITE_AFTER\t1\t1500\t1860\t118',b'WRITE_AFTER\t1\t1500\t1861\t118','changed p/g target'),
      ('duplicated step tick',b'STEP\t2\t1',b'STEP\t1\t1','step sequence'),
      ('get event attached to put',b'WRITE_BEFORE\t1',b'READ_BEFORE\t1','event not bound'),
      ('wrong IP',b'STEP\t1\t1',b'STEP\t1\t2','step sequence'),
    ]
    for name,old,new,reason in attacks:
        need(old in sample,'negative fixture byte absent: '+name)
        forged=sample.replace(old,new,1)
        try:scan(forged,name)
        except AssertionError as err:
            need(reason in str(err),'QA17 forged event rejected for an unrelated reason: '+name+' / '+str(err))
        else:raise AssertionError('QA17 accepted forged Native event: '+name)
    print('QA17_POSITIVE_SYNTHETIC_CAUSAL_LINEAGE_FIXTURE_PASS')
    print('QA17_SEVEN_SYNTHETIC_TRACE_FORGERIES_REJECTED')


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--qa13',required=False)
    p.add_argument('--shard',action='append',default=[])
    p.add_argument('--source')
    p.add_argument('--output')
    p.add_argument('--selftest',action='store_true')
    a=p.parse_args()
    selftest()
    if a.selftest:return
    need(a.qa13 and len(a.shard)==4 and a.output,'Need QA13+four original QA14 artifacts')
    source=pin_source(a.source)
    first,new=load_corpus(a.qa13,a.shard,source)
    doc=report(first,new,source)
    Path(a.output).write_text(json.dumps(doc,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print('QA17_NATIVE_49_CROSS_CORPUS_EXECUTED_FRONTIER_PASS',
          json.dumps({'cases':49,'new_steps':doc['physical_totals']['qa14']['steps'],
                      'new_visited_coordinates':doc['native_witness_sets']['arith_coords']['new_in_qa14'],
                      'new_executed_edges':doc['native_witness_sets']['arith_edges']['new_in_qa14'],
                      'new_dynamic_cells':doc['native_witness_sets']['mutated_executable']['new_in_qa14']},sort_keys=True))
    print('QA17_UNOBSERVED_STATIC_GLYPHS_ARE_NOT_PROVEN_DEAD_CODE')
    print('QA17_STAGE1_OPEN_NO_GENERAL_GEOMETRY_ACCEPTANCE')

if __name__=='__main__':main()
