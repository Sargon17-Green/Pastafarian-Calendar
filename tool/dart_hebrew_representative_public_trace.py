#!/usr/bin/env python3
"""Disposable public-call trace QA; no timing or physical-memory claim."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from dart_hebrew_representative_memo_small import COUNTER, MARK, WRAPPER, execute, save
from dart_hebrew_representative_lru_audit import audit, verify_source, need, digest

FROZEN_SHA = "e931141175945f3ef0c7273f5d5fdf2acc9bd81cecee6af361e6453ef40b08a4"
# Exact outputs from pristine artifact 15178533072, independently audited.
# Adjacent-year outputs are differential references, not independent calendar mathematics.
EXPECTED = {
    "-15057703": ["4999",15,433,32,121,"אכד","הדלת הסגורה"],
    "-15055672": ["5000",10,502,32,21,"עקרב","הדלת הסגורה"],
    "-15055671": ["5000",10,503,20,56,"עקרב","באר"],
    "-15055670": ["5000",14,1,29,38,"צחוק","צפרדע"],
    "-15053458": ["5001",9,1,41,1,"אשכול","בבל"],
}
DART = r"""
import 'dart:convert';
import 'dart:io';
import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_weave_counter.dart';
void require(bool condition, String name) {
  if (!condition) throw StateError(name);
}
void main(List<String> args) {
  final manifest = jsonDecode(File(args[0]).readAsStringSync()) as Map<String,dynamic>;
  final workload = args[1];
  final scope = args[2];
  final rows = manifest['requests'][workload] as List<dynamic>;
  final f = BigInt.parse(manifest['foundation'] as String);
  final calendar = MonsterFiveFieldCalendar();
  MonsterMonthWeaveCounter.qaEnabled = scope != 'off';
  final start = MonsterMonthWeaveCounter.qaState();
  final calls = <Map<String,Object?>>[];
  late List<int> beforeSessionReset;
  try {
    for (final dynamic raw in rows) {
      final row = raw as List<dynamic>;
      final first = MonsterMonthWeaveCounter.qaEvents.length;
      final pre = MonsterMonthWeaveCounter.qaState();
      Object? result;
      late List<int> beforeCallReset;
      try {
        if (workload == 'INDEPENDENT') {
          result = MonsterMonthWeaveCounter.countCompletions(
            (row[0] as List<dynamic>).cast<int>(),
            openedUpTo: row[1] as int, closedUpTo: row[2] as int).toString();
        } else {
          final date = calendar.calculate(f, BigInt.parse(row[0] as String),
              maxTransitions: row[1] as int);
          final tuple = date.canonicalComponents;
          require(tuple.length == 5 && tuple.first is BigInt &&
              tuple.skip(1).every((v) => v is int), 'tuple types');
          var immutable = false;
          try {
            tuple.add(0);
          } on UnsupportedError {
            immutable = true;
          }
          require(immutable, 'immutable tuple');
          require(date.cutletName == SourceLanguageCatalog.cutletText(date.cutletCanonicalIndex),
              'cutlet catalog');
          require(date.monthName == SourceLanguageCatalog.monthText(date.monthCanonicalIndex),
              'month catalog');
          result = [tuple.first.toString(), ...tuple.skip(1), date.cutletName, date.monthName];
        }
      } finally {
        beforeCallReset = MonsterMonthWeaveCounter.qaState();
        if (scope == 'call') MonsterMonthWeaveCounter.qaReset();
      }
      calls.add({
        'request': row, 'result': result, 'first': first,
        'end': MonsterMonthWeaveCounter.qaEvents.length,
        'pre': pre, 'before_reset': beforeCallReset,
        'post': MonsterMonthWeaveCounter.qaState(),
      });
    }
  } finally {
    beforeSessionReset = MonsterMonthWeaveCounter.qaState();
    MonsterMonthWeaveCounter.qaReset();
  }
  File(args[3]).writeAsStringSync(jsonEncode({
    'start': start, 'calls': calls, 'counts': MonsterMonthWeaveCounter.qaEvents,
    'before_session_reset': beforeSessionReset,
    'after_session_reset': MonsterMonthWeaveCounter.qaState(),
  }), flush: true);
}
"""

def trace(raw, workload, scope, requests):
    need(raw["start"] == [0,0] and len(raw["calls"]) == len(requests), "start/cardinality")
    events = []
    stats = dict(bypass=0,hit=0,miss=0,oversize=0,error=0,evictions=0,resets=0,
                 peak_entries=0,peak_bytes=0)
    state = [0,0]
    def emit(kind, call, pre, post, **extra):
        nonlocal state
        need(pre == state and len(events) < 20000, "boundary/cap")
        events.append(dict(seq=len(events),workload=workload,session=0,call=call,
                           kind=kind,pre=pre,post=post,**extra))
        state = post
        stats["peak_entries"] = max(stats["peak_entries"],post[0])
        stats["peak_bytes"] = max(stats["peak_bytes"],post[1])
        if kind == "reset":
            stats["resets"] += 1
    emit("session_start",None,state,state)
    cursor = 0
    results = []
    for cid,(call,request) in enumerate(zip(raw["calls"],requests)):
        need(call["request"] == request and call["first"] == cursor and
             cursor < call["end"] <= len(raw["counts"]), "request/coverage")
        need(call["pre"] == state,"call pre")
        emit("call_start",cid,state,state)
        for op,e in enumerate(raw["counts"][cursor:call["end"]]):
            need(e["seq"] == cursor+op and e["error"] is None,"count sequence/error")
            fields = {k:e[k] for k in ("remaining","opened","closed","key",
                       "status","bits","decimal","cost","victims")}
            fields["digest"] = digest(e["decimal"])
            emit("count",cid,e["pre"],e["post"],op=op,**fields)
            stats[e["status"]] += 1
            stats["evictions"] += len(e["victims"])
        cursor = call["end"]
        need(call["before_reset"] == state,"call end state")
        if scope == "call":
            need(call["post"] == [0,0],"call reset")
            emit("reset",cid,state,call["post"],reason="call")
        else:
            need(call["post"] == state,"unexpected reset")
        emit("call_end",cid,state,state)
        if workload == "INDEPENDENT":
            need(call["end"]-call["first"] == 1,"control count")
            e = raw["counts"][call["first"]]
            need([e["remaining"],e["opened"],e["closed"]] == request and
                 call["result"] == e["decimal"],"control key/result")
        else:
            need(call["result"] == EXPECTED[request[0]],"frozen public output")
        results.append(call["result"])
    need(cursor == len(raw["counts"]),"unassigned events")
    need(raw["before_session_reset"] == state and raw["after_session_reset"] == [0,0],"session reset")
    emit("reset",None,state,raw["after_session_reset"],reason="session")
    emit("session_end",None,state,state)
    doc = dict(workload=workload,scope=scope,events=events,summary=stats)
    need(audit(doc) == stats,"independent audit")
    return doc,results

def main():
    if hasattr(sys,"set_int_max_str_digits"):
        sys.set_int_max_str_digits(0)
    p = argparse.ArgumentParser()
    p.add_argument("--root",type=Path,default=Path.cwd())
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--workload",choices=("COLD","SAME","MIXED","INDEPENDENT"),required=True)
    a = p.parse_args()
    root,out = a.root.resolve(),a.out.resolve()
    out.mkdir(parents=True,exist_ok=False)
    lock = json.loads((root/"tool/dart_hebrew_representative_source_lock.json").read_text())
    need(verify_source(root,lock)==24,"source lock")
    frozen = root/"tool/dart_hebrew_representative_frozen_manifest.json"
    need(hashlib.sha256(frozen.read_bytes()).hexdigest()==FROZEN_SHA,"frozen manifest digest")
    requests = json.loads(frozen.read_text())["requests"][a.workload]
    scopes = ("off","session") if a.workload=="INDEPENDENT" else ("off","call","session")
    summary = dict(source_sha=subprocess.check_output(["git","-C",str(root),"rev-parse","HEAD"],text=True).strip(),
                   manifest_sha256=FROZEN_SHA,locked_blobs=24,workload=a.workload,
                   status="NOT_ACCEPTED",arms={},timing="NOT_MEASURED",memory="NOT_MEASURED")
    save(out/"summary.json",summary)
    with tempfile.TemporaryDirectory(prefix="dart-public-trace-") as tmp:
        work = Path(tmp)
        shutil.copytree(root/"lib",work/"lib")
        shutil.copy2(root/"pubspec.yaml",work/"pubspec.yaml")
        original = (work/COUNTER).read_text(encoding="utf-8")
        need(original.count(MARK)==1,"injection anchor")
        replacement = WRAPPER+"\n  static BigInt _qaUncached(\n"
        candidate = original.replace(MARK,replacement,1)
        need(candidate.replace(replacement,MARK,1)==original,"reversible injection")
        (work/COUNTER).write_text(candidate,encoding="utf-8")
        (work/"tool").mkdir()
        driver = work/"tool/qa_public_trace.dart"
        driver.write_text(DART,encoding="utf-8")
        execute(work,out,"version",["dart","--version"],30)
        execute(work,out,"pub-get",["dart","pub","get"],90)
        execute(work,out,"format",["dart","format",str(work/COUNTER),str(driver)],30)
        execute(work,out,"analyze",["dart","analyze"],90)
        baseline = None
        baseline_counts = None
        for scope in scopes:
            rawfile = out/(scope+"-raw.json")
            execute(work,out,scope,["dart","run",str(driver),str(frozen),a.workload,scope,str(rawfile)],180)
            doc,results = trace(json.loads(rawfile.read_text()),a.workload,scope,requests)
            counts = [(e["key"],e["decimal"]) for e in doc["events"] if e["kind"]=="count"]
            if baseline is None:
                baseline = results
                baseline_counts = counts
            need(results==baseline,"off/on mismatch")
            need(counts==baseline_counts,"ordered exact counter differential")
            owners = {}
            cross_call = cross_year = 0
            per_call = []
            for e in doc["events"]:
                kind = e["kind"]
                if kind == "call_start":
                    per_call.append(dict(call=e["call"],hit=0,miss=0,bypass=0,oversize=0))
                elif kind == "reset":
                    owners.clear()
                elif kind == "count":
                    status,key,cid = e["status"],e["key"],e["call"]
                    per_call[-1][status] += 1
                    for victim,_ in e["victims"]:
                        owners.pop(victim)
                    if status=="hit":
                        old = owners[key]
                        cross_call += int(old!=cid)
                        if a.workload!="INDEPENDENT":
                            cross_year += int(EXPECTED[requests[old][0]][0]!=EXPECTED[requests[cid][0]][0])
                    if status in ("miss","hit"):
                        owners[key]=cid
            trace_sha = save(out/(scope+"-trace.json"),doc)
            summary["arms"][scope] = dict(doc["summary"],trace_sha256=trace_sha,
                raw_sha256=hashlib.sha256(rawfile.read_bytes()).hexdigest(),results=results,
                per_call=per_call,cross_call_hits=cross_call,cross_year_hits=cross_year)
            save(out/"summary.json",summary)
    need(verify_source(root,lock)==24,"tracked source changed")
    summary["status"]="TRACE_PASS"
    save(out/"summary.json",summary)
    print("REPRESENTATIVE_PUBLIC_TRACE_PASS",json.dumps(summary,ensure_ascii=True),flush=True)

if __name__=="__main__":
    main()
