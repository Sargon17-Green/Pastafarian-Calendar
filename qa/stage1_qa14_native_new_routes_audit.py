#!/usr/bin/env python3
"""Independent fail-closed per-shard and cross-shard 32 NEW native trace audit.

Numerical oracle is only executable Befunge references (Native producer).
Python 3 validates actual trace-time mutable Funge-space, opcode execution,
source signatures, output equality, memory ownership and complete case set.
"""
import copy,hashlib,json,sys
from pathlib import Path
import stage1_native_route_graph as graph
import stage1_qa13_native_memory_audit as memory

PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
REF={'reference/work_counts.b98':'f941efc793c9eee4accf5d03873f8ed029b16725',
     'reference/save.b98':'7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44'}
M=(1<<127)-1
# Independent frozen roster: deliberately do NOT import the Native producer.
PAIRS=(
 (-15055673,-15055672),(-15055672,-15055671),
 (-15055671,-15055670),(-15055670,-15055669),
 (-15055672,-15055670),(-15055672,0),
 (-15055670,1),(-1,0),(-2,2),(1,2),
 (2,3),(15055670,15055672),(-M,M),
 (M,M+1),(-(M+1),-M),(10**80+17,-(10**80+19)),
)

def expected_rows():
    out=[]
    for i,(c,t) in enumerate(PAIRS):
        out.extend([('pair%02d_A'%i,c,t),('pair%02d_B'%i,t,c)])
    return out

def enc(n):
    return ('1' if n<0 else '0')+' '+str(abs(n))

def need(ok,msg):
    if not ok: raise AssertionError(msg)

def blob(path):
    data=Path(path).read_bytes()
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()

def check_row(row,label,c,t,shard):
    need(type(row)==dict and row.get('label')==label,'QA14 label mismatch')
    need(row.get('signed_days')==[str(c),str(t)] and
         row.get('transport')==enc(c)+' '+enc(t),
         'QA14 signed day transport changed '+label)
    need(row.get('valid') is True and row.get('trace_file')==label+'.tsv' and
         row.get('native_interpreter_calls')==5,
         'QA14 Native identity/trace provenance malformed '+label)
    output=row.get('stdout')
    need(type(output)==list and len(output)==7 and
         all(type(z)==str and z.lstrip('-').isdigit() for z in output),
         'QA14 seven-field native output malformed '+label)
    digest=row.get('trace_sha256')
    need(type(digest)==str and len(digest)==64 and
         all(c in '0123456789abcdef' for c in digest),
         'QA14 trace digest malformed '+label)
    need(type(row.get('trace_bytes'))==int and row['trace_bytes']>50000,
         'QA14 trace length implausible '+label)
    return True

def verify_manifest(doc,shard):
    need(type(doc)==dict and doc.get('schema')=='qa14-expanded-new-native-2d-routes-v1',
         'QA14 manifest schema invalid')
    need(doc.get('source_git_blob')==PIN and doc.get('reference_pins')==REF,
         'QA14 source provenance changed')
    need(doc.get('shard')==shard and doc.get('shards')==4 and
         doc.get('reference_invocations')==24 and
         doc.get('native_production_invocations')==16 and
         doc.get('native_traced_invocations')==8 and
         doc.get('stage1_final_acceptance') is False,
         'QA14 native invocation or stage claim forged')
    pairs=[(n,c,t) for k,(n,c,t) in enumerate(expected_rows()) if k%4==shard]
    records=doc.get('records')
    need(type(records)==list and len(records)==8,'QA14 missing/extra cases')
    for row,(name,c,t) in zip(records,pairs):
        check_row(row,name,c,t,shard)
    return True

def selftest():
    fake=[]
    for shard in range(4):
        rows=[]
        for i,(n,c,t) in enumerate(expected_rows()):
            if i%4!=shard:continue
            rows.append({'label':n,'signed_days':[str(c),str(t)],
                         'transport':enc(c)+' '+enc(t),'valid':True,
                         'stdout':['0']*7,'trace_file':n+'.tsv',
                         'trace_sha256':'a'*64,'trace_bytes':60000,
                         'native_interpreter_calls':5})
        fake.append(dict(schema='qa14-expanded-new-native-2d-routes-v1',
                         source_git_blob=PIN,reference_pins=REF,shard=shard,
                         shards=4,reference_invocations=24,
                         native_production_invocations=16,native_traced_invocations=8,
                         stage1_final_acceptance=False,records=rows))
        verify_manifest(fake[-1],shard)
    cases=[
        lambda d: d.update(stage1_final_acceptance=True),
        lambda d: d.update(source_git_blob='0'*40),
        lambda d: d['records'].pop(),
        lambda d: d['records'][0]['signed_days'].__setitem__(0,'1234'),
        lambda d: d['records'][0].update(transport='1 0 0 0'),
        lambda d: d['records'][0].update(trace_file='../escape.tsv'),
        lambda d: d['records'][0].update(trace_sha256='fake'),
        lambda d: d.update(native_traced_invocations=9),
        lambda d: d['records'][0]['stdout'].pop(),
        lambda d: d['records'].reverse(),
    ]
    for i,mut in enumerate(cases):
        z=copy.deepcopy(fake[0]);mut(z)
        try:verify_manifest(z,0)
        except AssertionError:continue
        raise AssertionError('QA14 accepted forged manifest '+str(i))
    print('QA14_FAIL_CLOSED_10_MANIFEST_FORGERIES_REJECTED')

def one_shard(directory,shard):
    folder=Path(directory)
    doc=json.loads((folder/'native_manifest.json').read_text())
    verify_manifest(doc,shard)
    need(blob('src/interleaved_work_counts.b98')==PIN,
         'QA14 production source hash changed')
    source=graph.load_source('src/interleaved_work_counts.b98')
    found=[]
    for r in doc['records']:
        label=r['label']
        tsv=folder/(label+'.tsv')
        b=tsv.read_bytes()
        need(len(b)==r['trace_bytes'] and
             hashlib.sha256(b).hexdigest()==r['trace_sha256'],
             'QA14 real trace SHA mismatch '+label)
        need((folder/(label+'.out')).read_bytes()==
             (' '.join(r['stdout'])+'\n').encode('ascii'),
             'QA14 saved stdout different '+label)
        details=memory.scan(b,label)
        actual=graph.analyze(source,str(tsv))
        stats=actual['statistics']; executed=actual['arithmetic_executed_opcodes']
        need(stats['native_ip_ids']==1 and stats['arithmetic_steps']>1000 and
             details['put']>=30 and details['get']>=40 and
             details['executed_written']>=2 and details['read_after_write']>0,
             'QA14 missing real native instruction p/g or modified execution '+label)
        need(details['gate_executed_byte']==118 and
             executed.get('p',0)>1 and executed.get('g',0)>1 and
             executed.get('x',0)>30 and
             stats['executed_content_changing_gate_writes']>=2,
             'QA14 signed valid source no longer exercises real mutable code '+label)
        found.append({'label':label,'signed_days':r['signed_days'],
                      'trace_sha256':r['trace_sha256'],
                      'output_sha256':hashlib.sha256((folder/(label+'.out')).read_bytes()).hexdigest(),
                      'steps':details['ticks'],'put':details['put'],'get':details['get'],
                      'read_after_write':details['read_after_write'],
                      'executed_written':details['executed_written'],
                      'history_sha256':details['history_sha256'],
                      'route_steps':stats['arithmetic_steps'],
                      'dual_nodes':stats['graph_merge_and_fork_nodes'],
                      'control_opcodes':{s:executed.get(s,0) for s in 'w_u{}[]|rj'} })
        print('QA14_NEW_NATIVE_PHYSICAL_MEMORY_PASS',shard,label,
              details['put'],details['get'],details['executed_written'],flush=True)
    result={'schema':'qa14-native-expanded-shard-proof-v1','source_git_blob':PIN,
            'shard':shard,'test_scope':'32_new_directed_2d_native_routes',
            'native_interpreter_invocations':40,'source_modified':False,
            'stage1_final_acceptance':False,'records':found}
    (folder/'qa14_shard_proof.json').write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('QA14_NEW_NATIVE_SHARD_VERIFIED',shard,'cases',len(found),flush=True)

def aggregate(dirs):
    need(len(dirs)==4,'QA14 four receipt directories required')
    docs=[]
    for i,dir in enumerate(dirs):
        doc=json.loads((Path(dir)/'qa14_shard_proof.json').read_text())
        need(doc.get('schema')=='qa14-native-expanded-shard-proof-v1' and
             doc.get('source_git_blob')==PIN and doc.get('shard')==i and
             doc.get('native_interpreter_invocations')==40 and
             doc.get('source_modified') is False and
             doc.get('stage1_final_acceptance') is False,
             'QA14 post-native shard proof invalid')
        rows=doc.get('records')
        need(type(rows)==list and len(rows)==8,'QA14 shard proof incomplete')
        expected=[n for k,(n,c,t) in enumerate(expected_rows()) if k%4==i]
        need([x['label'] for x in rows]==expected,
             'QA14 shard output records not covering frozen roster')
        for z in rows:
            need(type(z.get('steps'))==int and z['steps']>1000 and
                 type(z.get('put'))==int and z['put']>=30 and
                 type(z.get('get'))==int and z['get']>=40 and
                 type(z.get('executed_written'))==int and
                 z['executed_written']>=2 and
                 len(z.get('history_sha256',''))==64,
                 'QA14 shard proof counters missing')
        docs.append(doc)
    unique={r['history_sha256'] for doc in docs for r in doc['records']}
    # Numeric rows can share some paths; record the empirical count rather
    # than inventing a threshold or claiming universal route coverage.
    output={'schema':'qa14-expanded-native-geometry-conclusion-v1',
            'source_git_blob':PIN,'number_of_new_native_directed_cases':32,
            'number_of_independent_native_interpreter_invocations':160,
            'number_of_unique_observed_write_histories':len(unique),
            'source_modified':False,'stage1_final_acceptance':False,
            'native_receipts_all_four_shards':True,
            'physical_put':sum(z['put'] for x in docs for z in x['records']),
            'physical_get':sum(z['get'] for x in docs for z in x['records']),
            'executed_previously_written':sum(z['executed_written'] for x in docs for z in x['records'])}
    print('QA14_EXPANDED_NATIVE_ALL_SHARDS_PASS',json.dumps(output,sort_keys=True))
    print('STAGE1_OPEN_NOT_FULL_GEOMETRY_OR_OWNERSHIP_ACCEPTANCE')
    return output

if __name__=='__main__':
    selftest()
    if len(sys.argv)==4 and sys.argv[1]=='shard':one_shard(sys.argv[2],int(sys.argv[3]))
    elif len(sys.argv)==6 and sys.argv[1]=='aggregate':aggregate(sys.argv[2:6])
    elif len(sys.argv)!=1:raise SystemExit('usage: SCRIPT shard DIR IDX | aggregate DIR0 DIR1 DIR2 DIR3')
