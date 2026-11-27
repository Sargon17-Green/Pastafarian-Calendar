#!/usr/bin/env python3
"""Separate untraced RSS/VM heap diagnostic; not a timing or production gate."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import statistics
import subprocess
import tempfile

from dart_hebrew_representative_timing import WRAPPER
from dart_hebrew_representative_memo_small import COUNTER, MARK, execute, save
from dart_hebrew_representative_lru_audit import verify_source, need
from dart_hebrew_representative_public_trace import EXPECTED, FROZEN_SHA

DART = r"""
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_weave_counter.dart';

Future<void> main(List<String> args) async {
  final manifest = jsonDecode(File(args[0]).readAsStringSync()) as Map<String,dynamic>;
  final workload = args[1];
  final scope = args[2];
  final life = workload == 'LIFECYCLE';
  final independent = workload == 'INDEPENDENT' || life;
  final rows = life ? List<dynamic>.generate(20, (_) => [[2,2],0,0])
      : manifest['requests'][workload] as List<dynamic>;
  final f = BigInt.parse(manifest['foundation'] as String);
  final calendar = MonsterFiveFieldCalendar();
  final samples = <Map<String,Object?>>[];
  final results = <Object?>[];
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  client.findProxy = (_) => 'DIRECT';
  Uri? server;
  String? isolateId;
  String? serviceError;
  try {
    server = (await Service.getInfo()).serverUri;
    isolateId = Service.getIsolateId(Isolate.current);
    if (server == null || isolateId == null) serviceError = 'ServiceUnavailable';
  } catch (e) {
    serviceError = e.runtimeType.toString();
  }
  Future<void> sample(String checkpoint, int index) async {
    final row = <String,Object?>{
      'checkpoint':checkpoint, 'index':index,
      'current_rss_bytes':ProcessInfo.currentRss,
      'peak_rss_bytes':ProcessInfo.maxRss,
      'vm_response':null, 'vm_error':serviceError,
    };
    final endpoint = server;
    final id = isolateId;
    if (endpoint != null && id != null) {
      try {
        final uri = endpoint.resolve('getMemoryUsage')
            .replace(queryParameters:{'isolateId':id});
        final req = await client.getUrl(uri).timeout(const Duration(seconds:10));
        final resp = await req.close().timeout(const Duration(seconds:10));
        if (resp.statusCode != 200) throw StateError('VM service HTTP status');
        final body = await resp.transform(utf8.decoder).join().timeout(const Duration(seconds:10));
        final doc = jsonDecode(body);
        row['vm_response'] = doc;
        final result = doc['result'];
        if (result is! Map || result['heapUsage'] is! int ||
            result['heapCapacity'] is! int || result['externalUsage'] is! int) {
          row['vm_error'] = 'MemoryUsageUnavailable';
        }
      } catch (e) {
        row['vm_error'] = e.runtimeType.toString();
      }
    }
    samples.add(row);
  }
  MonsterMonthWeaveCounter.qaEnabled = scope != 'off';
  if (!MonsterMonthWeaveCounter.qaEmpty()) throw StateError('initial cache');
  try {
    await sample('baseline',-1);
    for (var i=0;i<rows.length;i++) {
      final row = rows[i] as List<dynamic>;
      try {
        if (independent) {
          final count = MonsterMonthWeaveCounter.countCompletions(
              (row[0] as List<dynamic>).cast<int>(),
              openedUpTo:row[1] as int,closedUpTo:row[2] as int);
          results.add(count.toString());
        } else {
          final date = calendar.calculate(f,BigInt.parse(row[0] as String),
              maxTransitions:row[1] as int);
          final tuple = date.canonicalComponents;
          results.add([tuple.first.toString(),...tuple.skip(1),date.cutletName,date.monthName]);
        }
        await sample('after_call',i);
      } finally {
        if (life || scope == 'call') {
          MonsterMonthWeaveCounter.qaReset();
          if (!MonsterMonthWeaveCounter.qaEmpty()) throw StateError('call reset');
          await sample('after_reset',i);
        }
      }
    }
  } finally {
    MonsterMonthWeaveCounter.qaReset();
    if (!MonsterMonthWeaveCounter.qaEmpty()) throw StateError('session reset');
    await sample('after_session_reset',rows.length);
    client.close(force:true);
  }
  File(args[3]).writeAsStringSync(jsonEncode({
    'scope':scope,'workload':workload,'samples':samples,'results':results,
    'heap_method':'Dart VM service getMemoryUsage; same isolate; no forced GC',
    'rss_method':'ProcessInfo currentRss/maxRss bytes',
  }),flush:true);
}
"""

def setup(root,work,out):
    shutil.copytree(root/'lib',work/'lib')
    shutil.copy2(root/'pubspec.yaml',work/'pubspec.yaml')
    # VM-service/RSS QA uses SDK APIs introduced in Dart 3.2.
    # Raise only the disposable harness constraint, not the production package.
    pubspec = work/'pubspec.yaml'
    spec = pubspec.read_text(encoding='utf-8')
    sdk = "sdk: '>=3.0.0 <4.0.0'"
    need(spec.count(sdk)==1,'QA SDK constraint anchor')
    pubspec.write_text(spec.replace(sdk,"sdk: '>=3.2.0 <4.0.0'",1),encoding='utf-8')
    save(out/'qa-sdk-constraint.json',dict(original=sdk,temporary="sdk: '>=3.2.0 <4.0.0'"))
    counter=work/COUNTER
    original=counter.read_text(encoding='utf-8')
    need(original.count(MARK)==1,'injection anchor')
    replacement=WRAPPER+'\n  static BigInt _qaUncached(\n'
    changed=original.replace(MARK,replacement,1)
    need(changed.replace(replacement,MARK,1)==original,'reversible injection')
    counter.write_text(changed,encoding='utf-8')
    (work/'tool').mkdir()
    (work/'tool/qa_memory.dart').write_text(DART,encoding='utf-8')
    execute(work,out,'version',['dart','--version'],30)
    execute(work,out,'pub-get',['dart','pub','get'],90)
    execute(work,out,'format',['dart','format',str(COUNTER),'tool/qa_memory.dart'],30)
    execute(work,out,'analyze',['dart','analyze'],90)

def check(d,workload,scope,requests):
    need(d['workload']==workload and d['scope']==scope,'arm identity')
    n=len(requests)
    checkpoints=[('baseline',-1)]
    for i in range(n):
        checkpoints.append(('after_call',i))
        if workload=='LIFECYCLE' or scope=='call':
            checkpoints.append(('after_reset',i))
    checkpoints.append(('after_session_reset',n))
    samples=d['samples']
    need([(x['checkpoint'],x['index']) for x in samples]==checkpoints,'checkpoint coverage')
    need(len(d['results'])==n,'result cardinality')
    if workload=='LIFECYCLE':
        need(d['results']==['2']*20,'small-domain oracle')
    elif workload=='INDEPENDENT':
        need(all(isinstance(x,str) and x.isdigit() for x in d['results']),'decimal control')
    else:
        need(d['results']==[EXPECTED[x[0]] for x in requests],'public anchors')
    peaks=[x['peak_rss_bytes'] for x in samples]
    rss=[x['current_rss_bytes'] for x in samples]
    need(all(isinstance(x,int) and x>0 for x in peaks+rss),'RSS units/values')
    need(peaks==sorted(peaks),'peak RSS monotonic')
    heap=[]
    for s in samples:
        if s['vm_error'] is not None:
            continue
        r=s['vm_response']['result']
        vals=[r[k] for k in ('heapUsage','heapCapacity','externalUsage')]
        need(all(isinstance(x,int) and x>=0 for x in vals) and vals[0]<=vals[1],'heap fields')
        heap.append(vals)
    m=dict(peak_rss_bytes=max(peaks),baseline_rss_bytes=rss[0],
        max_current_rss_delta=max(rss)-rss[0],final_current_rss_delta=rss[-1]-rss[0],
        heap_status='MEASURED' if len(heap)==len(samples) else 'NOT_MEASURED',
        heap_samples=len(heap),sample_count=len(samples))
    if m['heap_status']=='MEASURED':
        usage=[x[0] for x in heap]
        m.update(max_heap_usage_delta=max(usage)-usage[0],
            final_heap_usage_delta=usage[-1]-usage[0],
            max_heap_capacity=max(x[1] for x in heap),
            max_external_usage=max(x[2] for x in heap))
        if workload=='LIFECYCLE':
            post=[v[0] for v,s in zip(heap,samples) if s['checkpoint']=='after_reset']
            need(len(post)==20,'post-reset series')
            m['post_reset_usage_bytes']=post
            m['post_reset_trend_bytes']=statistics.median(post[-5:])-statistics.median(post[:5])
    return m

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--root',type=Path,default=Path.cwd())
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--workload',choices=('COLD','SAME','MIXED','INDEPENDENT','LIFECYCLE'),required=True)
    p.add_argument('--comparison',choices=('call','session'),required=True)
    a=p.parse_args()
    need(a.workload not in ('INDEPENDENT','LIFECYCLE') or a.comparison=='session','invalid scope')
    root,out=a.root.resolve(),a.out.resolve()
    out.mkdir(parents=True,exist_ok=False)
    lock=json.loads((root/'tool/dart_hebrew_representative_source_lock.json').read_text())
    need(verify_source(root,lock)==24,'source lock')
    frozen=root/'tool/dart_hebrew_representative_frozen_manifest.json'
    need(hashlib.sha256(frozen.read_bytes()).hexdigest()==FROZEN_SHA,'manifest digest')
    requests=[[[2,2],0,0]]*20 if a.workload=='LIFECYCLE' else json.loads(frozen.read_text())['requests'][a.workload]
    summary=dict(source_sha=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),
        manifest_sha256=FROZEN_SHA,locked_blobs=24,workload=a.workload,comparison=a.comparison,
        status='NOT_ACCEPTED',timing='NOT_MEASURED',pairs=[])
    save(out/'summary.json',summary)
    reference=None
    with tempfile.TemporaryDirectory(prefix='dart-representative-memory-') as temp:
        work=Path(temp)
        setup(root,work,out)
        arms=('off',a.comparison)
        for i in range(5):
            order=arms if i%2==0 else arms[::-1]
            pair=dict(index=i+1,order=list(order),arms={})
            for scope in order:
                name=f'pair-{i+1}-{scope}'
                raw=out/(name+'.json')
                exit_code=None
                try:
                    with (out/(name+'.log')).open('wb') as log:
                        proc=subprocess.run(['dart','run','--enable-vm-service=0','tool/qa_memory.dart',
                            str(frozen),a.workload,scope,str(raw)],cwd=work,stdout=log,stderr=subprocess.STDOUT,timeout=180)
                    exit_code=proc.returncode
                finally:
                    save(out/(name+'-process.json'),dict(exit_code=exit_code))
                need(exit_code==0,'process exit')
                d=json.loads(raw.read_text())
                m=check(d,a.workload,scope,requests)
                if reference is None:
                    reference=d['results']
                need(d['results']==reference,'exact differential')
                m['raw_sha256']=hashlib.sha256(raw.read_bytes()).hexdigest()
                pair['arms'][scope]=m
                save(out/'progress.json',dict(pair=pair,completed_pairs=summary['pairs']))
            off,on=(pair['arms'][s] for s in arms)
            pair['incremental_peak_rss_bytes']=on['peak_rss_bytes']-off['peak_rss_bytes']
            if off['heap_status']==on['heap_status']=='MEASURED':
                pair['incremental_max_heap_usage_delta']=on['max_heap_usage_delta']-off['max_heap_usage_delta']
                if a.workload=='LIFECYCLE':
                    pair['incremental_post_reset_trend']=on['post_reset_trend_bytes']-off['post_reset_trend_bytes']
            summary['pairs'].append(pair)
            save(out/'summary.json',summary)
    need(verify_source(root,lock)==24,'post source lock')
    heap_complete=all('incremental_max_heap_usage_delta' in p for p in summary['pairs'])
    median_rss=statistics.median(p['incremental_peak_rss_bytes'] for p in summary['pairs'])
    summary.update(status='MEMORY_MEASURED' if heap_complete else 'RSS_MEASURED_HEAP_NOT_MEASURED',
        median_incremental_peak_rss_bytes=median_rss,rss_guard_met=median_rss<=16*1024**2,
        heap_status='MEASURED' if heap_complete else 'NOT_MEASURED',
        recommendation='KEEP_A_DEFAULT')
    if heap_complete:
        summary['median_incremental_max_heap_usage_delta']=statistics.median(p['incremental_max_heap_usage_delta'] for p in summary['pairs'])
        if a.workload=='LIFECYCLE':
            trend=statistics.median(p['incremental_post_reset_trend'] for p in summary['pairs'])
            summary.update(median_incremental_post_reset_trend_bytes=trend,heap_trend_guard_met=trend<=4*1024**2)
    save(out/'summary.json',summary)
    print('REPRESENTATIVE_MEMORY_MEASURED',json.dumps(summary,ensure_ascii=True),flush=True)

if __name__=='__main__':
    main()
