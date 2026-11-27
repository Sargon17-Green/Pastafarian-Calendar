#!/usr/bin/env python3
"""Pristine-source baseline preflight only; no memo or performance claims."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from dart_hebrew_representative_lru_audit import verify_source, need

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "out/dart-hebrew-representative-preflight"
F = -15055671
DART = r"""
import 'dart:convert';
import 'dart:io';
import 'package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_year_traversal.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_meatball_partition.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_lengths.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_weave_planner.dart';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_names.dart';

void require(bool condition, String name) {
  if (!condition) throw StateError(name);
}

void main(List<String> args) {
  final f = BigInt.from(-15055671);
  final traversal = MonsterYearTraversal();
  final y0 = traversal.resolve(f, f, maxTransitions: 0);
  final prevDay = y0.candidate.openGate;
  final nextDay = y0.candidate.closeGate + BigInt.one;
  final which = int.parse(args[0]);
  final day = which == -1 ? prevDay : (which == 1 ? nextDay : f);
  final year = traversal.resolve(f, day, maxTransitions: which.abs());
  require(year.yearNumber == BigInt.from(5000 + which), 'year identity');
  final cutlets = MonsterMeatballPartitioner().partition(f, year);
  final lengths = const MonsterMonthLengthPlanner().plan(f, year);
  final weave = const MonsterMonthWeavePlanner().plan(f, year, lengths);
  final names = const MonsterMonthNamePlanner().plan(f, year, lengths, weave);
  final calendar = MonsterFiveFieldCalendar();
  final requests = which == 0 ? [f - BigInt.one, f, f + BigInt.one] : [day];
  final results = <Object>[];
  for (final request in requests) {
    final date = calendar.calculate(f, request, maxTransitions: which.abs());
    final tuple = date.canonicalComponents;
    require(tuple.length == 5 && tuple.first is BigInt &&
        tuple.skip(1).every((value) => value is int), 'tuple types');
    var immutable = false;
    try {
      tuple.add(0);
    } on UnsupportedError {
      immutable = true;
    }
    require(immutable, 'tuple immutability');
    require(date.cutletName == SourceLanguageCatalog.cutletText(date.cutletCanonicalIndex), 'cutlet catalog');
    require(date.monthName == SourceLanguageCatalog.monthText(date.monthCanonicalIndex), 'month catalog');
    results.add([request.toString(), [tuple.first.toString(), ...tuple.skip(1)],
        date.cutletName, date.monthName]);
  }
  final errors = <String>[];
  if (which == 0) {
    for (final limit in [-1, 65]) {
      try {
        calendar.calculate(f, f, maxTransitions: limit);
        throw StateError('invalid limit accepted');
      } on RangeError {
        errors.add('RangeError');
      }
    }
    try {
      calendar.calculate(f, nextDay, maxTransitions: 0);
      throw StateError('insufficient limit accepted');
    } on IncompleteMonsterYearTraversal {
      errors.add('IncompleteMonsterYearTraversal');
    }
  }
  File(args[1]).writeAsStringSync(jsonEncode([
    year.yearNumber.toString(),
    year.candidate.openGate.toString(),
    year.candidate.closeGate.toString(),
    cutlets.meatballs.map((c) => [
      c.openGate.toString(), c.closeGate.toString(), c.nameIndex, c.name
    ]).toList(),
    lengths.lengths, weave.monthIds, names.nameIndices, names.names,
    weave.weaveCount.toString(), weave.weaveChoice.result.toString(),
    results, errors
  ]) + '\n', flush: true);
}
"""

def canonical(obj):
    return (json.dumps(obj, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")

def write(name, obj):
    data = canonical(obj)
    (OUT / name).write_bytes(data)
    return hashlib.sha256(data).hexdigest()

def run(args, cwd, limit):
    print("RUN", *map(str,args), flush=True)
    subprocess.run(args, cwd=cwd, check=True, timeout=limit)

def validate(row, expected_year):
    year, opening, closing, cutlets, lengths, word, indices, names, count, rank, results, errors = row
    o, c = int(opening), int(closing)
    need(int(year) == expected_year and 252 <= c-o <= 5778, "year span")
    need(len(word) == c-o and sum(lengths) == len(word), "word span")
    need(3 <= len(lengths) <= 47 and all(4 <= n <= 123 for n in lengths), "lengths")
    need(len(indices) == len(names) == len(lengths) and len(set(indices)) == len(indices)
         and all(1 <= i <= 47 for i in indices), "month catalog indices")
    need(set(word) == set(range(1,len(lengths)+1)), "word alphabet")
    positions = [[j for j,x in enumerate(word) if x == i] for i in range(1,len(lengths)+1)]
    need([len(p) for p in positions] == lengths, "multiplicities")
    first, last = [p[0] for p in positions], [p[-1] for p in positions]
    need(first == sorted(set(first)) and last == sorted(set(last)), "first/last order")
    need(1 <= int(rank) <= int(count), "rank range")
    edge = o
    for lo,hi,i,name in cutlets:
        need(int(lo) == edge and int(hi)>edge and 1<=i<=17 and isinstance(name,str), "cutlet partition")
        edge = int(hi)
    need(edge == c, "cutlet endpoint")
    need(len(results) == (3 if expected_year == 5000 else 1), "request count")
    for req, actual, cutlet_name, month_name in results:
        day = int(req)
        need(o < day <= c, "request inclusivity")
        off = day-o-1
        m = word[off]-1
        hits = [x for x in cutlets if int(x[0]) < day <= int(x[1])]
        need(len(hits) == 1, "unique cutlet")
        lo, _, cutlet_index, expected_name = hits[0]
        expect = [year,cutlet_index,day-int(lo),indices[m],sum(j<=off for j in positions[m])]
        need(actual == expect and cutlet_name == expected_name and month_name == names[m], "independent prefix projection")
    if expected_year == 5000:
        need([int(x[0]) for x in results] == [F-1,F,F+1], "AC.1 request sequence")
        need([x[1] for x in results] == [["5000",10,502,32,21],["5000",10,503,20,56],["5000",14,1,29,38]], "AC.1")
        need(errors == ["RangeError","RangeError","IncompleteMonsterYearTraversal"], "exception classes")
    else:
        need(not errors, "unexpected exception records")

def main():
    if hasattr(sys,"set_int_max_str_digits"):
        sys.set_int_max_str_digits(0)
    OUT.mkdir(parents=True,exist_ok=False)
    source_lock = json.loads((ROOT/"tool/dart_hebrew_representative_source_lock.json").read_text())
    locked = verify_source(ROOT,source_lock)
    write("source-lock.json",source_lock)
    print("SOURCE_LOCK_PASS",locked,flush=True)
    with tempfile.TemporaryDirectory(prefix="dart-representative-pristine-") as temp:
        work = Path(temp)
        shutil.copytree(ROOT/"lib",work/"lib")
        shutil.copy2(ROOT/"pubspec.yaml",work/"pubspec.yaml")
        for path,sha in source_lock["blobs"].items():
            if path.startswith("lib/") or path=="pubspec.yaml":
                data=(work/path).read_bytes()
                actual=hashlib.sha1(f"blob {len(data)}\0".encode()+data).hexdigest()
                need(actual==sha,"disposable copy blob mismatch: "+path)
        (work/"bin").mkdir()
        driver=work/"bin"/"baseline.dart"
        driver.write_text(DART,encoding="utf-8")
        run(["dart","--version"],work,30)
        run(["dart","pub","get"],work,120)
        run(["dart","analyze"],work,120)
        rows={}
        hashes={}
        for delta in (0,-1,1):
            raw=OUT/f"raw-{5000+delta}.json"
            run(["dart","run",str(driver),str(delta),str(raw)],work,180)
            row=json.loads(raw.read_text(encoding="utf-8"))
            validate(row,5000+delta)
            rows[delta]=row
            hashes[str(5000+delta)]=write(f"baseline-{5000+delta}.json",row)
            print("BASELINE_PROJECTION_PASS",5000+delta,flush=True)
        need(rows[-1][2]==rows[0][1] and rows[0][2]==rows[1][1],"adjacent continuity")
        prev=int(rows[0][1])
        nxt=int(rows[0][2])+1
        need(int(rows[-1][10][0][0])==prev and int(rows[1][10][0][0])==nxt,"adjacent requested boundaries")
        manifest=dict(project_id="PC-BRANCH-DART-HEBREW",source_commit=source_lock["source_commit"],
            foundation=str(F), years=[[rows[d][0],rows[d][1],rows[d][2]] for d in (-1,0,1)],
            baseline_sha256=hashes, requests={
                "COLD":[[str(F),0]],
                "SAME":[[str(x),0] for x in (F-1,F,F+1,F)],
                "MIXED":[[str(x),t] for x,t in ((F-1,0),(nxt,1),(prev,1),(F,0),(nxt,1),(F+1,0))],
                "INDEPENDENT":[[[100+i,100,100],0,0] for i in range(8)]})
        sha=write("manifest.json",manifest)
        (OUT/"manifest.sha256").write_text(sha+"  manifest.json\n",encoding="ascii")
        print("PRISTINE_BASELINE_MANIFEST_PASS",sha,flush=True)

if __name__=="__main__":
    try:
        main()
    except Exception as exc:
        OUT.mkdir(parents=True,exist_ok=True)
        (OUT/"failure.txt").write_text(repr(exc)+"\n",encoding="utf-8")
        raise
