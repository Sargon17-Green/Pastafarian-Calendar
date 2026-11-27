#!/usr/bin/env python3
"""Untraced representative timing: fresh process per arm, paired comparisons.
This is QA only, not a physical-memory or promotion gate.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import statistics
import subprocess
import tempfile
import time

from dart_hebrew_representative_memo_small import COUNTER, MARK, execute, save
from dart_hebrew_representative_lru_audit import verify_source, need
from dart_hebrew_representative_public_trace import EXPECTED, FROZEN_SHA

# Same ordered string identity and LRU policy as accepted trace; no trace
# lists, victim objects, per-counter decimal conversion or trace serialization.
WRAPPER = r"""
  static final _qaCache = <String, BigInt>{};
  static final _qaCosts = <String, int>{};
  static bool qaEnabled = false;
  static int _qaBytes = 0;
  static bool qaEmpty() => _qaCache.isEmpty && _qaCosts.isEmpty && _qaBytes == 0;
  static void qaReset() {
    _qaCache.clear();
    _qaCosts.clear();
    _qaBytes = 0;
  }

  static BigInt countCompletions(List<int> remaining, {
    required int openedUpTo, required int closedUpTo,
  }) {
    if (!qaEnabled) {
      return _qaUncached(remaining, openedUpTo: openedUpTo, closedUpTo: closedUpTo);
    }
    final key = openedUpTo.toString() + '/' + closedUpTo.toString() +
        '/' + remaining.join(',');
    final cached = _qaCache.remove(key);
    if (cached != null) {
      _qaCache[key] = cached;
      return cached;
    }
    final result = _qaUncached(remaining, openedUpTo: openedUpTo, closedUpTo: closedUpTo);
    final cost = 128 + 2 * key.length + (result.bitLength + 7) ~/ 8;
    if (cost <= 262144) {
      while (_qaCache.length >= 64 || _qaBytes + cost > 262144) {
        final victim = _qaCache.keys.first;
        _qaCache.remove(victim);
        _qaBytes -= _qaCosts.remove(victim)!;
      }
      _qaCache[key] = result;
      _qaCosts[key] = cost;
      _qaBytes += cost;
    }
    return result;
  }
"""

DRIVER = r"""
import 'dart:convert';
import 'dart:io';
import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_weave_counter.dart';
void main(List<String> args) {
  final driverEntryEpochUs = DateTime.now().microsecondsSinceEpoch;
  final manifest = jsonDecode(File(args[0]).readAsStringSync()) as Map<String,dynamic>;
  final workload = args[1];
  final scope = args[2];
  final rows = manifest['requests'][workload] as List<dynamic>;
  final f = BigInt.parse(manifest['foundation'] as String);
  final calendar = MonsterFiveFieldCalendar();
  // QA_INIT
  final results = <Object?>[];
  final callsUs = <int>[];
  final resetsUs = <int>[];
  final sw = Stopwatch();
  try {
    for (final dynamic raw in rows) {
      final row = raw as List<dynamic>;
      try {
        if (workload == 'INDEPENDENT') {
          final vector = (row[0] as List<dynamic>).cast<int>();
          final opened = row[1] as int;
          final closed = row[2] as int;
          sw..reset()..start();
          final value = MonsterMonthWeaveCounter.countCompletions(vector,
              openedUpTo: opened, closedUpTo: closed);
          sw.stop();
          callsUs.add(sw.elapsedMicroseconds);
          results.add(value.toString());
        } else {
          final day = BigInt.parse(row[0] as String);
          final limit = row[1] as int;
          sw..reset()..start();
          final date = calendar.calculate(f, day, maxTransitions: limit);
          sw.stop();
          callsUs.add(sw.elapsedMicroseconds);
          final tuple = date.canonicalComponents;
          results.add([tuple.first.toString(), ...tuple.skip(1),
            date.cutletName, date.monthName]);
        }
      } finally {
        // QA_CALL_RESET
      }
    }
  } finally {
    // QA_SESSION_RESET
  }
  File(args[3]).writeAsStringSync(jsonEncode({
    'workload': workload, 'scope': scope, 'driver_entry_epoch_us': driverEntryEpochUs,
    'calls_us': callsUs, 'resets_us': resetsUs, 'results': results,
  }), flush: true);
}
"""

def driver(pristine):
    if pristine:
        return DRIVER
    return DRIVER.replace('// QA_INIT', '''
  MonsterMonthWeaveCounter.qaEnabled = scope != 'off';
  if (!MonsterMonthWeaveCounter.qaEmpty()) throw StateError('initial cache');
''').replace('// QA_CALL_RESET', '''
        if (scope == 'call') {
          sw..reset()..start();
          MonsterMonthWeaveCounter.qaReset();
          sw.stop();
          resetsUs.add(sw.elapsedMicroseconds);
          if (!MonsterMonthWeaveCounter.qaEmpty()) throw StateError('call reset');
        }
''').replace('// QA_SESSION_RESET', '''
    if (scope != 'off') {
      sw..reset()..start();
      MonsterMonthWeaveCounter.qaReset();
      sw.stop();
      resetsUs.add(sw.elapsedMicroseconds);
    }
    if (!MonsterMonthWeaveCounter.qaEmpty()) throw StateError('session reset');
''')

def setup(root, work, out, pristine):
    work.mkdir()
    shutil.copytree(root / 'lib', work / 'lib')
    shutil.copy2(root / 'pubspec.yaml', work / 'pubspec.yaml')
    if not pristine:
        counter = work / COUNTER
        original = counter.read_text(encoding='utf-8')
        need(original.count(MARK) == 1, 'counter injection anchor')
        replacement = WRAPPER + '\n  static BigInt _qaUncached(\n'
        changed = original.replace(MARK, replacement, 1)
        need(changed.replace(replacement, MARK, 1) == original, 'reversible wrapper')
        counter.write_text(changed, encoding='utf-8')
    (work / 'tool').mkdir()
    (work / 'tool/qa_timing.dart').write_text(driver(pristine), encoding='utf-8')
    prefix = 'pristine-' if pristine else 'wrapped-'
    execute(work, out, prefix+'version', ['dart','--version'],30)
    execute(work, out, prefix+'pub-get', ['dart','pub','get'],90)
    files = ['tool/qa_timing.dart'] if pristine else ['tool/qa_timing.dart', str(COUNTER)]
    execute(work, out, prefix+'format', ['dart','format',*files],30)
    execute(work, out, prefix+'analyze', ['dart','analyze'],90)

def run_arm(work, out, frozen, workload, scope, name):
    raw = out / (name+'.json')
    launch_epoch_us = time.time_ns()//1000
    start = time.monotonic_ns()
    exit_code = None
    try:
        with (out/(name+'.log')).open('wb') as log:
            proc = subprocess.run(['dart','run','tool/qa_timing.dart',str(frozen),
                workload,scope,str(raw)],cwd=work,stdout=log,stderr=subprocess.STDOUT,timeout=180)
        exit_code=proc.returncode
    except subprocess.TimeoutExpired:
        save(out/(name+'-process.json'),dict(exit_code=None,timeout=True,wall_us=(time.monotonic_ns()-start)//1000))
        raise
    wall_us = (time.monotonic_ns()-start)//1000
    save(out/(name+'-process.json'),dict(exit_code=exit_code,timeout=False,wall_us=wall_us,
        launch_epoch_us=launch_epoch_us))
    need(exit_code==0,'process exit '+name)
    d=json.loads(raw.read_text())
    need(d['scope']==scope and d['workload']==workload,'arm identity')
    return d, dict(raw_sha256=hashlib.sha256(raw.read_bytes()).hexdigest(),
        wall_us=wall_us, launch_to_driver_us=d['driver_entry_epoch_us']-launch_epoch_us,
        calculate_us=sum(d['calls_us']), reset_us=sum(d['resets_us']), calls_us=d['calls_us'],
        resets_us=d['resets_us'],exit_code=exit_code)

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--root',type=Path,default=Path.cwd())
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--workload',choices=('COLD','SAME','MIXED','INDEPENDENT'),required=True)
    p.add_argument('--comparison',choices=('pristine','call','session'),required=True)
    a=p.parse_args()
    need(a.workload!='INDEPENDENT' or a.comparison!='call','independent control must not reset per call')
    root,out=a.root.resolve(),a.out.resolve()
    out.mkdir(parents=True,exist_ok=False)
    lock=json.loads((root/'tool/dart_hebrew_representative_source_lock.json').read_text())
    need(verify_source(root,lock)==24,'source locks')
    frozen=root/'tool/dart_hebrew_representative_frozen_manifest.json'
    need(hashlib.sha256(frozen.read_bytes()).hexdigest()==FROZEN_SHA,'manifest digest')
    requests=json.loads(frozen.read_text())['requests'][a.workload]
    summary=dict(source_sha=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),
        locked_blobs=24,manifest_sha256=FROZEN_SHA,workload=a.workload,comparison=a.comparison,
        status='NOT_ACCEPTED',memory='NOT_MEASURED',pairs=[],jit='dart run, fresh process per arm')
    save(out/'summary.json',summary)
    reference=None
    with tempfile.TemporaryDirectory(prefix='dart-representative-timing-') as temp:
        base=Path(temp)
        wrapped=base/'wrapped'
        setup(root,wrapped,out,False)
        pristine=base/'pristine'
        if a.comparison=='pristine':
            setup(root,pristine,out,True)
        arms=('pristine','off') if a.comparison=='pristine' else ('off',a.comparison)
        for i in range(5):
            order=arms if i%2==0 else arms[::-1]
            pair=dict(index=i+1,order=list(order),arms={})
            for arm in order:
                d,metrics=run_arm(pristine if arm=='pristine' else wrapped,out,frozen,a.workload,arm,f'pair-{i+1}-{arm}')
                need(len(d['results'])==len(d['calls_us'])==len(requests),'result cardinality')
                need(all(isinstance(x,int) and x>=0 for x in d['calls_us']+d['resets_us']),'timing types')
                need(metrics['calculate_us']>0,'zero total')
                need(len(d['resets_us'])==(len(requests)+1 if arm=='call' else 1 if arm=='session' else 0),'reset coverage')
                if a.workload!='INDEPENDENT':
                    need(d['results']==[EXPECTED[row[0]] for row in requests],'frozen public anchors')
                else:
                    need(all(isinstance(x,str) and x.isdigit() for x in d['results']),'control decimal')
                if reference is None:
                    reference=d['results']
                need(d['results']==reference,'exact differential')
                metrics['result_sha256']=hashlib.sha256(json.dumps(d['results'],ensure_ascii=True,separators=(',',':')).encode()).hexdigest()
                pair['arms'][arm]=metrics
                save(out/'progress.json',dict(pair=pair,completed_pairs=summary['pairs']))
            left,right=(pair['arms'][arm] for arm in arms)
            # Include explicitly measured reset overhead, not unrelated serialization.
            l=left['calculate_us']+left['reset_us']
            r=right['calculate_us']+right['reset_us']
            pair['paired_ratio']=r/l
            summary['pairs'].append(pair)
            save(out/'summary.json',summary)
    need(verify_source(root,lock)==24,'post source locks')
    ratios=[p['paired_ratio'] for p in summary['pairs']]
    summary.update(status='TIMING_MEASURED',paired_ratios=ratios,
        median_paired_gain=statistics.median(1-r for r in ratios),
        median_paired_overhead=statistics.median(r-1 for r in ratios),
        positive_pairs=sum(r<1 for r in ratios),
        recommendation='KEEP_A_DEFAULT',physical_memory='NOT_MEASURED')
    save(out/'summary.json',summary)
    print('REPRESENTATIVE_TIMING_MEASURED',json.dumps(summary,ensure_ascii=True),flush=True)

if __name__=='__main__':
    main()
