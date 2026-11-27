#!/usr/bin/env python3
"""Disposable memo lifecycle gate; no performance or physical-memory claims."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from dart_hebrew_representative_memo_small import COUNTER, MARK, WRAPPER, execute, save
from dart_hebrew_representative_lru_audit import verify_source, need

DART = r"""
import 'dart:convert';
import 'dart:io';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_weave_counter.dart';
void require(bool value, String message) {
  if (!value) throw StateError(message);
}
BigInt count(List<int> v) => MonsterMonthWeaveCounter.countCompletions(
  v, openedUpTo: 0, closedUpTo: 0);
bool zero(List<int> s) => s[0] == 0 && s[1] == 0;
void main(List<String> args) {
  final enabled = args[0] == 'on';
  MonsterMonthWeaveCounter.qaEnabled = enabled;
  final cycles = <Map<String,Object?>>[];
  for (var i = 0; i < 20; i++) {
    final first = MonsterMonthWeaveCounter.qaEvents.length;
    require(zero(MonsterMonthWeaveCounter.qaState()), 'initial state');
    final errors = <String>[];
    late List<int> beforeReset;
    final invalid = i.isEven ? <int>[0,2] : <int>[];
    try {
      require(count([2,2]) == BigInt.from(2), 'independent two-word oracle');
      require(count([2,2]) == BigInt.from(2), 'repeat oracle');
      final warm = MonsterMonthWeaveCounter.qaState();
      try {
        count(invalid);
        throw StateError('invalid request returned');
      } on ArgumentError catch (e) {
        errors.add(e.runtimeType.toString());
      }
      require(errors.length == 1, 'first invalid request');
      final afterInvalid = MonsterMonthWeaveCounter.qaState();
      require(warm[0] == afterInvalid[0] && warm[1] == afterInvalid[1], 'invalid request changed cache');
      require(count([2,2]) == BigInt.from(2), 'post-error recovery');
      // Let the second real invalid request escape the inner scope.
      count(invalid);
      throw StateError('invalid request returned');
    } on ArgumentError catch (e) {
      errors.add(e.runtimeType.toString());
    } finally {
      beforeReset = MonsterMonthWeaveCounter.qaState();
      MonsterMonthWeaveCounter.qaReset();
    }
    require(errors.length == 2, 'two invalid requests');
    require(zero(MonsterMonthWeaveCounter.qaState()), 'finally cleanup');
    cycles.add({'cycle':i,'first':first,'end':MonsterMonthWeaveCounter.qaEvents.length,
      'errors':errors,'before_reset':beforeReset,'after_reset':MonsterMonthWeaveCounter.qaState()});
  }
  File(args[1]).writeAsStringSync(jsonEncode({'cycles':cycles,'events':MonsterMonthWeaveCounter.qaEvents}),flush:true);
}
"""

def audit(doc, enabled):
    need(len(doc["cycles"]) == 20 and len(doc["events"]) == 100, "cardinality")
    counts = {"hit":0,"miss":0,"bypass":0,"error":0}
    valid_key = "0/0/2,2"
    valid_cost = 128 + 2 * len(valid_key) + 1
    for i, cycle in enumerate(doc["cycles"]):
        first = 5*i
        err = "ArgumentError" if i%2==0 else "RangeError"
        invalid = [0,2] if i%2==0 else []
        warm = [1,valid_cost] if enabled else [0,0]
        statuses = ["miss","hit","error","hit","error"] if enabled else ["bypass","bypass","error","bypass","error"]
        need(cycle == dict(cycle=i,first=first,end=first+5,errors=[err,err],
             before_reset=warm,after_reset=[0,0]), "cycle boundary/error")
        for j,e in enumerate(doc["events"][first:first+5]):
            status = statuses[j]
            vector = invalid if status=="error" else [2,2]
            key = "0/0/" + ",".join(map(str,vector))
            need(e["seq"]==first+j and e["remaining"]==vector and e["opened"]==e["closed"]==0 and e["key"]==key,"event key")
            need(e["status"]==status and e["pre"]==([0,0] if j==0 else warm) and e["post"]==warm and e["victims"]==[],"event state")
            need(e["decimal"]==(None if status=="error" else "2") and e["bits"]==(None if status=="error" else 2) and e["error"]==(err if status=="error" else None),"event value")
            need(e["cost"]==(valid_cost if status=="miss" else 0),"event cost")
            counts[status]+=1
    need(counts==({"hit":40,"miss":20,"bypass":0,"error":40} if enabled else {"hit":0,"miss":0,"bypass":60,"error":40}),"counts")
    return dict(counts,cycles=20,resets=20,events=100)

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--root",type=Path,default=Path.cwd())
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    root,out=a.root.resolve(),a.out.resolve()
    out.mkdir(parents=True,exist_ok=False)
    lock=json.loads((root/"tool/dart_hebrew_representative_source_lock.json").read_text())
    need(verify_source(root,lock)==24,"source locks")
    summary=dict(source_sha=subprocess.check_output(["git","-C",str(root),"rev-parse","HEAD"],text=True).strip(),locked_blobs=24,status="NOT_ACCEPTED",arms={})
    save(out/"summary.json",summary)
    with tempfile.TemporaryDirectory(prefix="dart-memo-lifecycle-") as tmp:
        work=Path(tmp)
        shutil.copytree(root/"lib",work/"lib")
        shutil.copy2(root/"pubspec.yaml",work/"pubspec.yaml")
        original=(work/COUNTER).read_text(encoding="utf-8")
        need(original.count(MARK)==1,"injection anchor")
        replacement=WRAPPER+"\n  static BigInt _qaUncached(\n"
        candidate=original.replace(MARK,replacement,1)
        need(candidate.replace(replacement,MARK,1)==original,"reversible injection")
        (work/COUNTER).write_text(candidate,encoding="utf-8")
        (work/"tool").mkdir()
        driver=work/"tool/qa_lifecycle.dart"
        driver.write_text(DART,encoding="utf-8")
        execute(work,out,"version",["dart","--version"],30)
        execute(work,out,"pub-get",["dart","pub","get"],90)
        execute(work,out,"format",["dart","format",str(work/COUNTER),str(driver)],30)
        execute(work,out,"analyze",["dart","analyze"],90)
        for arm in ("off","on"):
            raw=out/(arm+"-raw.json")
            execute(work,out,arm,["dart","run",str(driver),arm,str(raw)],180)
            summary["arms"][arm]=dict(audit(json.loads(raw.read_text()),arm=="on"),raw_sha256=hashlib.sha256(raw.read_bytes()).hexdigest())
            save(out/"summary.json",summary)
    need(verify_source(root,lock)==24,"post source locks")
    summary["status"]="LIFECYCLE_PASS"
    save(out/"summary.json",summary)
    print("REPRESENTATIVE_LIFECYCLE_PASS",json.dumps(summary),flush=True)

if __name__=="__main__":
    main()
