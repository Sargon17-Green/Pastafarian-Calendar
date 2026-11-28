#!/usr/bin/env python3
"""QA31R: independently audit signed Native p/g last-writer and row ingress."""
import argparse
import copy
import gzip
import hashlib
import json
import zipfile
from pathlib import Path

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
QA31G_ZIP_SHA = 'e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161'
QA31D_ZIP_SHA = 'b8df61e31a3f28bfcc21bbccb4d2ee26b5ccfeca534969e87d95a211fbb40eeb'
QA31G_TRACE_SHA = {
    'digit': '018091d998f546a918575f3f3f93e07cad68bd88d5adcdf8a36663cfafdcc4aa',
    'digit_space': '69f868bd3969b77e7640cb355c6429e73822c6845e8968d82ef2b45ecbf04ad7',
}
QA20_UNSEEN = {
    (286,5), (235,23), (211,29), (10,32), (57,32), (113,32), (174,32),
    (235,32), (10,35), (57,35), (127,35), (152,35), (199,35), (248,35), (309,35),
}

class AuditError(AssertionError):
    pass

def need(ok, why):
    if not ok:
        raise AuditError(why)

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def git_blob_sha(raw):
    return hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()

def load_source(path):
    raw = Path(path).read_bytes()
    need(git_blob_sha(raw) == SOURCE_BLOB, 'original source Git blob mismatch')
    rows = raw.splitlines()
    need(len(rows) == 2015, 'pinned source splitlines height mismatch')
    need(rows[49] == b'', 'memory target row 49 is no longer empty in original source')
    return rows

def source_cell(rows, x, y):
    if rows is None:
        return 32
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return rows[y][x]
    return 32

def event_at(events, x, y, opcode):
    hits = [e for e in events if e['ip'] == [x,y] and e['op'] == ord(opcode)]
    need(len(hits) == 1, f'expected one {opcode} at ({x},{y}), got {len(hits)}')
    return hits[0]

def verify_source_opcodes(events, rows):
    if rows is None:
        return
    for e in events:
        if e['op'] in (ord('p'), ord('g'), ord('x'), ord('j')):
            x,y=e['ip']
            need(source_cell(rows,x,y) == e['op'], f'source opcode mismatch at ({x},{y})')
            need(e['string'] is False, f'control opcode executed in string mode at ({x},{y})')

def replay_memory(events, rows):
    memory = {}
    last_writer = {}
    reads = {}
    write_events = 0
    for e in events:
        op=e['op']; pre=e['pre']; post=e['post']; tick=e['t']; ip=e['ip']
        if op == ord('p'):
            write_events += 1
            need(len(pre) >= 3, f'p stack underflow at tick {tick}')
            value,x,y=pre[-3],pre[-2],pre[-1]
            need(y == 49, f'p target outside pinned row 49 at tick {tick}')
            need(post == pre[:-3], f'p stack transition mismatch at tick {tick}')
            memory[(x,y)] = value
            last_writer[(x,y)] = {'tick':tick,'ip':ip,'value':value,'opcode':'p'}
        elif op == ord('g'):
            need(len(pre) >= 2, f'g stack underflow at tick {tick}')
            x,y=pre[-2],pre[-1]
            need(y == 49, f'g target outside pinned row 49 at tick {tick}')
            value=memory.get((x,y), source_cell(rows,x,y))
            need(post == pre[:-2] + [value], f'g read/stack mismatch at tick {tick} target ({x},{y})')
            reads[tick] = {'tick':tick,'ip':ip,'target':[x,y],'value':value,
                           'last_writer':copy.deepcopy(last_writer.get((x,y)))}
    return reads,last_writer,write_events

def verify_motion(e, expected_next, expected_delta, label):
    need(e['next'] == expected_next, label+' next coordinate mismatch')
    need(e['next_delta'] == expected_delta, label+' next direction mismatch')
    x,y=e['ip']; dx,dy=expected_delta
    need(expected_next == [x+dx,y+dy], label+' transition arithmetic mismatch')

def audit_digit(events, raw_hex, rows):
    need(raw_hex == '31', 'natural digit input receipt changed')
    need(len(events) == 2046, 'digit Native step count mismatch')
    need([e['t'] for e in events] == list(range(1,2047)), 'digit STEP ticks are not contiguous')
    verify_source_opcodes(events, rows)
    reads,last,write_events = replay_memory(events, rows)

    # Natural stdin evidence: one byte 0x31 was read, not an invented -1/EOF value.
    input_events=[e for e in events if e['ip']==[13,5] and e['op']==ord('~')]
    need(len(input_events)==2, 'expected two original ~ calls')
    first=input_events[0]
    need(first['t']==292 and first['reads']==[{'end':1,'hex':'31','ip':[13,5],
         'method':'readline','stack':[],'start':0,'t':292}] and first['post']==[49],
         'first stdin byte is not original ASCII 1')
    second=input_events[1]
    need(second['t']==1132 and second['reads'][0]['hex']=='' and second['post']==[],
         'second read is not the recorded EOF event')

    g29=event_at(events,57,29,'g')
    need(g29['pre'][-2:]==[3,49] and g29['post'][-1]==1,'row29 m gate is not 1')
    need(reads[g29['t']]['last_writer']=={'tick':1082,'ip':[248,14],'value':1,'opcode':'p'},
         'row29 m=1 does not have the expected signed last writer')
    j29=event_at(events,89,29,'j')
    need(j29['pre'][-1]==61 and j29['next']==[151,29],'row29 j operand/transition mismatch')
    x29=event_at(events,211,29,'x')
    need(x29['pre'][-2:]==[-201,3],'row29 outgoing vector mismatch')
    verify_motion(x29,[10,32],[-201,3],'row29-to-row32')

    g32=event_at(events,57,32,'g')
    need(g32['pre'][-2:]==[1,49] and g32['post'][-1]==0,'row32 q gate is not 0')
    need(reads[g32['t']]['last_writer']=={'tick':146,'ip':[106,2],'value':0,'opcode':'p'},
         'row32 q=0 does not have the expected signed last writer')
    j32=event_at(events,113,32,'j')
    need(j32['pre'][-1]==0 and j32['next']==[114,32],'row32 j operand/transition mismatch')
    x32=event_at(events,174,32,'x')
    need(x32['pre'][-2:]==[-164,3],'row32 outgoing vector mismatch')
    verify_motion(x32,[10,35],[-164,3],'row32-to-row35')

    g35r=event_at(events,57,35,'g')
    need(g35r['pre'][-2:]==[2,49] and g35r['post'][-1]==1,'row35 source-value read mismatch')
    need(reads[g35r['t']]['last_writer']=={'tick':1034,'ip':[200,14],'value':1,'opcode':'p'},
         'row35 (2,49) value lacks expected last writer')
    g35q1=event_at(events,127,35,'g')
    need(g35q1['pre'][-2:]==[1,49] and g35q1['post'][-1]==0,'row35 q-before-increment is not 0')
    need(reads[g35q1['t']]['last_writer']=={'tick':146,'ip':[106,2],'value':0,'opcode':'p'},
         'row35 q-before-increment last writer mismatch')
    p35a=event_at(events,152,35,'p')
    need(p35a['pre'][-3:]==[1,10,49] and p35a['post']==p35a['pre'][:-3],
         'row35 first p does not write value 1 to (10,49)')
    g35q2=event_at(events,199,35,'g')
    need(g35q2['pre'][-2:]==[1,49] and g35q2['post'][-1]==0,'row35 q changed before second p')
    need(reads[g35q2['t']]['last_writer']=={'tick':146,'ip':[106,2],'value':0,'opcode':'p'},
         'row35 q second read last writer mismatch')
    p35b=event_at(events,248,35,'p')
    need(p35b['pre'][-3:]==[1,1,49] and p35b['post']==p35b['pre'][:-3],
         'row35 second p does not write q+1=1 to (1,49)')
    x35=event_at(events,309,35,'x')
    need(x35['pre'][-2:]==[-299,3],'row35 outgoing vector mismatch')
    verify_motion(x35,[10,38],[-299,3],'row35-to-row38')

    g38=event_at(events,57,38,'g')
    need(g38['pre'][-2:]==[1,49] and g38['post'][-1]==1,'row38 q read is not 1')
    need(reads[g38['t']]['last_writer']=={'tick':1684,'ip':[248,35],'value':1,'opcode':'p'},
         'row38 q=1 does not have row35 p as last writer')

    # The route is real: the exact source-control cells are physically visited in this Native trace.
    visited={(e['ip'][0],e['ip'][1]) for e in events}
    hit=sorted(QA20_UNSEEN & visited, key=lambda p:(p[1],p[0]))
    remaining=sorted(QA20_UNSEEN - visited, key=lambda p:(p[1],p[0]))
    need(len(hit)==12 and remaining==[(286,5),(235,23),(235,32)],
         'QA20-unseen native frontier coverage mismatch')

    return {
      'native_input_hex':'31','first_read_tick':first['t'],'first_read_ascii':49,
      'second_read_tick':second['t'],'second_read_eof':True,
      'row29_m':1,'row29_m_last_writer':reads[g29['t']]['last_writer'],
      'row29_j_operand':61,'row29_to_row32_next':x29['next'],
      'row32_q':0,'row32_q_last_writer':reads[g32['t']]['last_writer'],
      'row32_j_operand':0,'row32_to_row35_next':x32['next'],
      'row35_source_value':1,'row35_q_before_increment':0,
      'row35_first_p':{'tick':p35a['t'],'target':[10,49],'value':1},
      'row35_second_p':{'tick':p35b['t'],'target':[1,49],'value':1},
      'row35_to_row38_next':x35['next'],
      'row38_q':1,'row38_q_last_writer':reads[g38['t']]['last_writer'],
      'qa20_unseen_controls_hit':[[x,y] for x,y in hit],
      'qa20_unseen_controls_still_unwitnessed':[[x,y] for x,y in remaining],
      'memory_read_events_checked':len(reads),'memory_write_events_checked':write_events,
    }

def read_trace(zf, receipt, label):
    case=next((c for c in receipt['cases'] if c['label']==label),None)
    need(case is not None, 'missing QA31G case '+label)
    need(case['status']=='HALT' and case['error'] is None and
         case['raw_sha256']==sha256(bytes.fromhex(case['raw_hex'])),
         label+' original input/status receipt mismatch')
    name=case['trace']; compressed=zf.read(name)
    need(sha256(compressed)==case['trace_sha256'],label+' compressed trace SHA mismatch')
    need(case['trace_sha256']==QA31G_TRACE_SHA[label],label+' pinned trace SHA mismatch')
    raw=gzip.decompress(compressed)
    events=[json.loads(line) for line in raw.splitlines()]
    need(len(events)==case['steps'],label+' trace event count mismatch')
    return case,events

def verify_qa31d(zf):
    native=json.loads(zf.read('qa31d_native.json'))
    independent=json.loads(zf.read('qa31d_independent.json'))
    need(native['schema']=='qa31d-finite-valid-pair-original-native-pre-j-v1', 'QA31D schema mismatch')
    need(native['source_git_blob']==SOURCE_BLOB and native['stage1_complete'] is False,
         'QA31D source/stage scope mismatch')
    need(len(native['records'])==2 and independent['steps']==37100 and
         independent['hostile_receipts_rejected']==10, 'QA31D paired evidence summary mismatch')
    summary=[]
    for label in ('valid00','valid01'):
        record=next(r for r in native['records'] if r['label']==label)
        obs=record['j_observations']
        need(len(obs)==1 and obs[0]['tick']==9607 and obs[0]['operand']==61 and
             obs[0]['pre_step'][1:3]==[114,38] and obs[0]['pre_toss']==[61],
             'QA31D row38 j observation mismatch '+label)
        step_name='qa31d_'+label+'.steps.gz'
        raw=gzip.decompress(zf.read(step_name)).decode('utf-8')
        steps=[]
        for line in raw.splitlines():
            a=line.split('\t')
            if len(a)>=7:
                tick,x,y,dx,dy,op,depth=map(int,a[:7]);steps.append((tick,x,y,dx,dy,op,depth))
        need(len(steps)==(17387 if label=='valid00' else 19713),'QA31D STEP count mismatch '+label)
        need(not any(s[2] in (32,35) for s in steps),'QA31D pair unexpectedly visits row32/35')
        need(any(s[1:3]==(150,29) and s[5]==ord('x') for s in steps),
             'QA31D alternative row29 exit missing '+label)
        need(any(s[1:3]==(114,38) and s[5]==ord('j') for s in steps),
             'QA31D row38 j missing '+label)
        summary.append({'label':label,'steps':len(steps),'row29_x150':True,
                        'row32_or_row35_visited':False,'row38_j_operand':61})
    return summary

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('qa31g_zip')
    ap.add_argument('qa31d_zip')
    ap.add_argument('--source',default=None)
    ap.add_argument('--out',default='qa31r_signed_route_owner.json')
    a=ap.parse_args()
    rows=load_source(a.source) if a.source else None

    graw=Path(a.qa31g_zip).read_bytes()
    need(sha256(graw)==QA31G_ZIP_SHA,'QA31G artifact ZIP SHA mismatch')
    with zipfile.ZipFile(a.qa31g_zip) as zf:
        need(zf.testzip() is None,'QA31G ZIP CRC failure')
        receipt=json.loads(zf.read('qa31g_receipt.json'))
        need(receipt['schema']=='qa31g-original-native-eof-v1' and
             receipt['source_blob']==SOURCE_BLOB and receipt['source_modified'] is False and
             receipt['stage1_pass'] is False,'QA31G receipt identity/scope mismatch')
        independent=json.loads(zf.read('qa31g_independent.json'))
        need(independent['schema']=='qa31g-independent-v1' and
             independent['cases_verified']==3 and independent['forgeries_rejected']==5 and
             independent['stage1_pass'] is False,'QA31G independent audit receipt mismatch')
        digit_case,digit_events=read_trace(zf,receipt,'digit')
        route=audit_digit(digit_events,digit_case['raw_hex'],rows)
        space_case,space_events=read_trace(zf,receipt,'digit_space')
        need(space_case['raw_hex']=='3120' and space_case['steps']==3038 and
             space_case['reads']==2,'digit-space raw input/step receipt mismatch')
        verify_source_opcodes(space_events,rows)
        space_reads,_,_=replay_memory(space_events,rows)
        space_g29=event_at(space_events,57,29,'g')
        need(space_g29['pre'][-2:]==[3,49] and space_g29['post'][-1]==0 and
             space_reads[space_g29['t']]['value']==0,
             'digit-space control does not read m=0 at row29')
        need(not any(e['ip'][1] in (32,35) for e in space_events),
             'digit-space control unexpectedly enters row32/35')
        # Fourteen event/receipt mutations must be rejected by the independent route audit.
        mutations=[]
        def mut(name, fn): mutations.append((name,fn))
        mut('row29_m_read',lambda es: event_at(es,57,29,'g')['post'].__setitem__(-1,0))
        mut('row29_jump_operand',lambda es: event_at(es,89,29,'j')['pre'].__setitem__(-1,60))
        mut('row29_edge',lambda es: event_at(es,211,29,'x')['next'].__setitem__(0,11))
        mut('row32_q_read',lambda es: event_at(es,57,32,'g')['post'].__setitem__(-1,1))
        mut('row32_jump_operand',lambda es: event_at(es,113,32,'j')['pre'].__setitem__(-1,1))
        mut('row32_edge',lambda es: event_at(es,174,32,'x')['next'].__setitem__(1,34))
        mut('row35_source_read',lambda es: event_at(es,57,35,'g')['post'].__setitem__(-1,0))
        mut('row35_q_read_first',lambda es: event_at(es,127,35,'g')['post'].__setitem__(-1,1))
        mut('row35_first_p',lambda es: event_at(es,152,35,'p')['pre'].__setitem__(-3,0))
        mut('row35_q_read_second',lambda es: event_at(es,199,35,'g')['post'].__setitem__(-1,1))
        mut('row35_second_p',lambda es: event_at(es,248,35,'p')['pre'].__setitem__(-3,0))
        mut('row35_edge',lambda es: event_at(es,309,35,'x')['next'].__setitem__(0,11))
        mut('row38_q_read',lambda es: event_at(es,57,38,'g')['post'].__setitem__(-1,0))
        mut('stdin_byte',lambda es: next(e for e in es if e['ip']==[13,5] and e['op']==ord('~'))['reads'][0].__setitem__('hex','30'))
        rejected=[]
        for name,fn in mutations:
            altered=copy.deepcopy(digit_events);fn(altered)
            try:audit_digit(altered,digit_case['raw_hex'],rows)
            except (AuditError,KeyError,IndexError,TypeError):rejected.append(name)
            else:raise AuditError('hostile mutation accepted: '+name)
        # With exact source bytes available, reject four additional source-opcode substitutions.
        source_mutations=0
        if rows is not None:
            for x,y in ((57,29),(211,29),(174,32),(248,35)):
                altered=copy.deepcopy(rows); altered[y]=bytearray(altered[y]); altered[y][x]=ord(' '); altered[y]=bytes(altered[y])
                try:audit_digit(digit_events,digit_case['raw_hex'],altered)
                except AuditError:source_mutations+=1
                else:raise AuditError(f'hostile source mutation accepted at ({x},{y})')
        qa31d_raw=Path(a.qa31d_zip).read_bytes()
        need(sha256(qa31d_raw)==QA31D_ZIP_SHA,'QA31D artifact ZIP SHA mismatch')
        with zipfile.ZipFile(a.qa31d_zip) as dz:
            need(dz.testzip() is None,'QA31D ZIP CRC failure')
            qa31d=verify_qa31d(dz)
        report={
          'schema':'qa31r-signed-native-last-writer-route-v1',
          'project_id':'PC-BRANCH-BEFUNGE98-KYRGYZ',
          'source_git_blob':SOURCE_BLOB,'source_bytes_verified':rows is not None,
          'source_splitlines_height':len(rows) if rows is not None else None,
          'qa31g_artifact_sha256':sha256(graw),'qa31d_artifact_sha256':sha256(qa31d_raw),
          'qa31g_digit_steps':len(digit_events),'qa31g_digit_space_steps':len(space_events),
          'natural_digit_route':route,
          'digit_space_contrast':{'raw_input_hex':'3120','row29_m':0,
                                  'row32_or_row35_visited':False},
          'qa31d_pair_separate_route':qa31d,
          'event_mutations_rejected':len(rejected),'event_mutation_names':rejected,
          'source_opcode_mutations_rejected':source_mutations if rows is not None else None,
          'fresh_native':0,'global_reachability_proven':False,
          'global_input_ownership_proven':False,'stage1_pass':False
        }
    Path(a.out).write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('QA31R_NATURAL_DIGIT_ROUTE_ROW29_32_35_38_VERIFIED')
    print('QA31R_PG_LAST_WRITER_AND_INCOMING_EDGES_VERIFIED')
    print('QA31R_QA20_UNSEEN_CONTROLS_HIT',len(route['qa20_unseen_controls_hit']),'/15')
    print('QA31R_EVENT_FORGERIES_REJECTED',len(rejected),'/14')
    if rows is None:
        print('QA31R_SOURCE_OPCODE_FORGERIES_REJECTED SKIPPED_NO_SOURCE')
    else:
        print('QA31R_SOURCE_OPCODE_FORGERIES_REJECTED',source_mutations,'/4')
    print('QA31R_NO_NEW_NATIVE_NO_STAGE1_PASS')

if __name__=='__main__':
    main()
