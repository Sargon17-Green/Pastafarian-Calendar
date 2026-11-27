#!/usr/bin/env python3
"""Disposable small-domain memo semantics/trace probe. Not a timing or heap gate."""
import argparse
from collections import OrderedDict
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from dart_hebrew_representative_small_oracle import fixtures, DRIVER
from dart_hebrew_representative_lru_audit import verify_source

COUNTER = Path("lib/src/monster_month_weave_counter.dart")
MARK = "  static BigInt countCompletions(\n"
WRAPPER = r'''
  static final _qaCache = <String, BigInt>{};
  static final _qaCosts = <String, int>{};
  static final qaEvents = <Map<String, Object?>>[];
  static bool qaEnabled = false;
  static int _qaBytes = 0;
  static List<int> qaState() => [_qaCache.length, _qaBytes];
  static void qaReset() {
    _qaCache.clear();
    _qaCosts.clear();
    _qaBytes = 0;
  }

  static BigInt countCompletions(
    List<int> remaining, {
    required int openedUpTo,
    required int closedUpTo,
  }) {
    if (qaEvents.length >= 20000) {
      throw StateError('QA event cap');
    }
    final vector = List<int>.of(remaining);
    final key = openedUpTo.toString() + '/' + closedUpTo.toString() +
        '/' + vector.join(',');
    final pre = qaState();
    final victims = <List<Object>>[];
    var cost = 0;
    var status = 'bypass';
    BigInt? result;
    String? errorType;
    try {
      if (qaEnabled && _qaCache.containsKey(key)) {
        result = _qaCache.remove(key)!;
        _qaCache[key] = result;
        status = 'hit';
      } else {
        result = _qaUncached(remaining,
            openedUpTo: openedUpTo, closedUpTo: closedUpTo);
        if (qaEnabled) {
          cost = 128 + 2 * key.length + (result.bitLength + 7) ~/ 8;
          if (cost > 262144) {
            status = 'oversize';
          } else {
            status = 'miss';
            while (_qaCache.length >= 64 || _qaBytes + cost > 262144) {
              final victim = _qaCache.keys.first;
              final victimCost = _qaCosts.remove(victim)!;
              _qaCache.remove(victim);
              _qaBytes -= victimCost;
              victims.add([victim, victimCost]);
            }
            _qaCache[key] = result;
            _qaCosts[key] = cost;
            _qaBytes += cost;
          }
        }
      }
      return result;
    } catch (error) {
      status = 'error';
      errorType = error.runtimeType.toString();
      rethrow;
    } finally {
      qaEvents.add({
        'seq': qaEvents.length, 'remaining': vector,
        'opened': openedUpTo, 'closed': closedUpTo, 'key': key,
        'status': status, 'decimal': result?.toString(),
        'bits': result?.bitLength, 'error': errorType,
        'cost': cost, 'victims': victims, 'pre': pre, 'post': qaState(),
      });
    }
  }
'''

def need(ok, why):
    if not ok:
        raise RuntimeError(why)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def save(path, obj):
    data = (json.dumps(obj, ensure_ascii=True, separators=(",", ":")) + "\n").encode()
    path.write_bytes(data)
    return sha(data)


def driver():
    start = "  for (final row in rows) {"
    end = "  File(args[1]).writeAsStringSync(jsonEncode(results));"
    need(DRIVER.count(start) == DRIVER.count(end) == 1, "driver anchors")
    return DRIVER.replace(start, """
  MonsterMonthWeaveCounter.qaEnabled = args[2] == 'on';
  final start = MonsterMonthWeaveCounter.qaState();
  late List<int> beforeReset;
  try {
  for (final row in rows) {""", 1).replace(end, """
  } finally {
    beforeReset = MonsterMonthWeaveCounter.qaState();
    MonsterMonthWeaveCounter.qaReset();
  }
  File(args[1]).writeAsStringSync(jsonEncode({
    'results': results, 'events': MonsterMonthWeaveCounter.qaEvents,
    'start': start, 'before_reset': beforeReset,
    'after_reset': MonsterMonthWeaveCounter.qaState(),
  }));""", 1)


def audit(rows, doc, enabled):
    need(doc["start"] == doc["after_reset"] == [0, 0], "cleanup")
    need(len(rows) == len(doc["results"]) == len(doc["events"]), "coverage")
    cache = OrderedDict()
    total = peak = peak_entries = 0
    stats = dict(bypass=0, hit=0, miss=0, oversize=0, error=0, evictions=0)
    hashes = []
    for i, (row, actual, e) in enumerate(zip(rows, doc["results"], doc["events"])):
        key = f'{row["opened"]}/{row["closed"]}/' + ",".join(map(str, row["vector"]))
        need(actual == row["expected"], f"oracle {i}")
        need(e["seq"] == i and e["remaining"] == row["vector"] and
             e["opened"] == row["opened"] and e["closed"] == row["closed"]
             and e["key"] == key, f"key {i}")
        need(e["pre"] == [len(cache), total], f"pre {i}")
        cost = 0
        victims = []
        if "error" in actual:
            status = "error"
            need(key not in cache and e["decimal"] is None and e["bits"] is None
                 and e["error"] == actual["error"], f"error {i}")
            hashes.append(None)
        else:
            decimal = actual["count"]
            bits = int(decimal).bit_length()
            need(e["decimal"] == decimal and e["bits"] == bits and e["error"] is None, f"value {i}")
            hashes.append(sha(decimal.encode("ascii")))
            if not enabled:
                status = "bypass"
            elif key in cache:
                status = "hit"
                need(cache[key][1] == decimal, f"hit {i}")
                cache.move_to_end(key)
            else:
                cost = 128 + 2 * len(key) + (bits + 7) // 8
                if cost > 262144:
                    status = "oversize"
                else:
                    status = "miss"
                    while len(cache) >= 64 or total + cost > 262144:
                        victim, (victim_cost, _) = cache.popitem(last=False)
                        victims.append([victim, victim_cost])
                        total -= victim_cost
                    cache[key] = (cost, decimal)
                    total += cost
        need(e["status"] == status and e["cost"] == cost and e["victims"] == victims, f"LRU {i}")
        need(e["post"] == [len(cache), total] and len(cache) <= 64 and 0 <= total <= 262144, f"post {i}")
        stats[status] += 1
        stats["evictions"] += len(victims)
        peak = max(peak, total)
        peak_entries = max(peak_entries, len(cache))
    need(doc["before_reset"] == [len(cache), total], "before reset")
    need(stats["error"] == 20, "invalid repeats")
    if enabled:
        need(stats["hit"] > 0 and stats["evictions"] > 0, "cache exercised")
    else:
        need(stats["bypass"] == 1134 and stats["hit"] == stats["miss"] == 0, "off mode")
    return dict(stats, peak_bytes=peak, peak_entries=peak_entries,
                digest_list_sha256=sha(json.dumps(hashes,separators=(",",":")).encode()))


def execute(work, out, name, command, timeout):
    with (out / (name + ".log")).open("wb") as log:
        result = subprocess.run(command, cwd=work, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
    need(result.returncode == 0, f"{name}: exit {result.returncode}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, default=Path.cwd())
    p.add_argument("--out", type=Path, required=True)
    args = p.parse_args()
    root, out = args.root.resolve(), args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((root / "tool/dart_hebrew_representative_source_lock.json").read_text())
    need(verify_source(root, manifest) == 24, "source lock")
    rows, census = fixtures()
    fixture = out / "fixtures.json"
    fixture_sha = save(fixture, rows)
    need(len(rows) == 1154 and fixture_sha == "10b1a5f61acc08eadfe5eb9f385a94f3b6a01d0afbd991b9c721a619b398db8c", "fixture lock")
    summary = dict(census, fixture_sha256=fixture_sha, locked_blobs=24, native="NOT_ACCEPTED",
                   source_sha=subprocess.check_output(["git","-C",str(root),"rev-parse","HEAD"],text=True).strip())
    save(out / "summary.json", summary)
    with tempfile.TemporaryDirectory(prefix="dart-memo-small-") as tmp:
        work = Path(tmp)
        shutil.copytree(root / "lib", work / "lib")
        shutil.copy2(root / "pubspec.yaml", work / "pubspec.yaml")
        original = (work / COUNTER).read_text(encoding="utf-8")
        need(original.count(MARK) == 1, "injection anchor")
        replacement = WRAPPER + "\n  static BigInt _qaUncached(\n"
        candidate = original.replace(MARK,replacement,1)
        need(candidate.replace(replacement,MARK,1) == original,"reversible injection")
        (work / COUNTER).write_text(candidate,encoding="utf-8")
        (work / "tool").mkdir()
        drv = work / "tool/qa_memo_small.dart"
        drv.write_text(driver(), encoding="utf-8")
        execute(work,out,"version",["dart","--version"],30)
        execute(work,out,"pub-get",["dart","pub","get"],90)
        execute(work,out,"format",["dart","format",str(work / COUNTER),str(drv)],30)
        execute(work,out,"analyze",["dart","analyze"],90)
        docs = {}
        for arm in ("off","on"):
            target = out / (arm + ".json")
            execute(work,out,arm,["dart","run",str(drv),str(fixture),str(target),arm],180)
            docs[arm] = json.loads(target.read_text())
            summary[arm] = dict(audit(rows,docs[arm],arm=="on"),raw_sha256=sha(target.read_bytes()))
        need(docs["off"]["results"] == docs["on"]["results"],"off/on mismatch")
        need(summary["off"]["digest_list_sha256"] == summary["on"]["digest_list_sha256"],"result digests")
    need(verify_source(root, manifest)==24,"tracked source changed")
    summary["native"]="PASS"
    save(out / "summary.json",summary)
    print("REPRESENTATIVE_MEMO_SMALL_PASS",json.dumps(summary),flush=True)


if __name__ == "__main__":
    main()
