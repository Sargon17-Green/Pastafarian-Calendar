#!/usr/bin/env python3
"""Stage56 source-bound sauce trace, QA only, no production wiring.

The raw comparison stops at the first divergent day-number input. The
translated comparison follows all 46 real successive drops, not the kernel's
isolated stirAt(i), which initializes bowls anew. PHP calls the same component
classes as LegacyOverwrittenOrder11 and checks the drop-46 latch against the
actual kernel. Python observes the pinned, unmodified sauce via line tracing.
No fixture from another branch; no change to either locked checkout.

Run from an independent QA checkout:
  python3 tools/stage56_gmp_qa/sauce_first_divergence.py \
    --php-root /path/to/production --canonical-root /path/to/canonical \
    --output /path/outside/both/trace.json
Exit 0 = diagnostic contract satisfied, 1 = discrepancy, 2 = invalid input.
This is NOT Stage56 acceptance, GMP integration, or raw parity PASS.
"""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import linecache

PROJECT = "PC-BRANCH-PHP-MALAY"
PHP_SHA = "fcaf1674d2c4125b6794fd37312f68d11aa2a8dd"
PY_SHA = "cc2cf0b422757a5e7c33218ce30cffa8f99c6786"
C = -13334246
TARGETS = {4999: -13340403, 5000: -13336277, 5001: -13332033}
SHIFT = -1721425

PHP = r"""
require $argv[1].'/tests/bootstrap.php';
require_once $argv[1].'/src/Patches/CanonicalJdnBoundary56.php';
$k=new \Pastafari\Stage01\BootstrapKernel();
$c=(int)$argv[2]; $t=(int)$argv[3]; $translated=$argv[4]==='translated';
if ($translated) {
    $pair=\Pastafari\Stage01\Patches\CanonicalJdnBoundary56::translatedPair(
        $c,$t,'cc2cf0b422757a5e7c33218ce30cffa8f99c6786');
    $c=$pair['calculation']; $t=$pair['target'];
}
$a=$k->dayCount($c); $b=$k->dayCount($t); $d=$k->distance($c,$t);
$counts=['action'=>$a,'target'=>$b,'distance'=>$d,'connection'=>$a->add($b),
         'direction'=>$t<$c?1:($t===$c?2:3)];
$out=['counts'=>[$a->toString(),$b->toString(),$d->toString(),
                 $counts['connection']->toString(),$counts['direction']]];
if ($translated) {
    $save=new \Pastafari\Stage01\Patches\SavePatch01(new \Pastafari\Stage01\Legacy\LegacyRemainder());
    $factory=new \Pastafari\Stage01\Legacy\LegacyBowlFactory($save);
    $pours=new \Pastafari\Stage01\Patches\PoursAliasPatch09(new \Pastafari\Stage01\Legacy\LegacyFixedPositionPours($save));
    $shadow=new \Pastafari\Stage01\Patches\BowlShadowPatch10(new \Pastafari\Stage01\Legacy\LegacyInPlaceBowlStir($save),$save);
    $values=static function(array $v):array {
        $out=[]; foreach(range(1,6) as $id){$out[]=$v[$id]->toString();} return $out;
    };
    $stones=$k->stones(); $drops=$k->visibleDrops($c,$t); $bowls=$factory->initialBowls($counts);
    $out['drops']=[];
    for($i=1;$i<=46;$i++){
        $drop=$drops[$i]; $order=$k->bowlOrder($drop); $before=$values($bowls);
        $pour=$pours->patchedPours($i,$drop,$stones[$i],$bowls,$order);
        $shadow->stirOneDropViaShadow($bowls,$i,$drop,$stones[$i],$order,$pour);
        $out['drops'][]=['i'=>$i,'drop'=>$drop->toString(),'order'=>$order,
                          'before'=>$before,'after'=>$values($bowls)];
    }
    $s=$k->sauceOrder($c,$t); $r=$k->askBowl($c,$t,3,30);
    $out['final']=['bowls'=>$values($s['bowls']),'order'=>$s['orderAtDrop46'],
                   'first'=>$r['first']->toString(),'step'=>$r['step'],
                   'next'=>$r['nextBowlId']];
    if($out['drops'][45]['order']!==$s['orderAtDrop46'])throw new RuntimeException('LATCH');
}
echo json_encode($out,JSON_THROW_ON_ERROR);
"""

def cmd(args, timeout=120):
    p = subprocess.run(args, capture_output=True, timeout=timeout, check=True)
    return p.stdout

def git(root, *args):
    return cmd(["git", "-C", str(root), *args], 20)

def verify(root, sha, paths):
    if git(root, "rev-parse", "HEAD").decode().strip() != sha:
        raise ValueError("HEAD mismatch: " + str(root))
    if git(root, "status", "--porcelain", "--untracked-files=all").strip():
        raise ValueError("dirty checkout: " + str(root))
    hashes = {}
    for path in paths:
        disk = (root / path).read_bytes()
        if disk != git(root, "show", f"{sha}:{path}"):
            raise ValueError("source bytes mismatch: " + path)
        hashes[path] = hashlib.sha256(disk).hexdigest()
    return hashes

def py_reference(core, target):
    rows = []
    def tracer(frame, event, arg):
        if frame.f_code is not core.sauce.__code__:
            return None
        if event == "line":
            line = linecache.getline(frame.f_code.co_filename, frame.f_lineno).strip()
            v = frame.f_locals
            if line == "drop_number = drop_index + 1" and rows:
                rows[-1]["after"] = list(map(str, v["bowls"]))
            elif line == "direct = [0] * 6":
                rows.append({"i": v["drop_number"], "drop": str(v["value"]),
                             "order": [i+1 for i in v["order"]],
                             "before": list(map(str, v["bowls"]))})
            elif line == "if last_drop_permutation is None:  # pragma: no cover - loop invariant":
                rows[-1]["after"] = list(map(str, v["bowls"]))
        return tracer
    sys.settrace(tracer)
    try:
        state = core.sauce(C, target)
    finally:
        sys.settrace(None)
    if len(rows) != 46 or any("after" not in row for row in rows):
        raise ValueError("canonical source tracing shape mismatch")
    a,b = core.day_number(C),core.day_number(target)
    r = core.response_descriptor(state,2,30)
    order = [i+1 for i in state.last_drop_permutation]
    return {"counts":[str(a),str(b),str(abs(target-C)+1),str(a+b),1 if target<C else 3],
            "drops":rows,"final":{"bowls":list(map(str,state.bowls)), "order":order,
            "first":str(r.first),"step":r.step,"next":order[(order.index(3)+1)%6]}}

def php(root, target, translated):
    return json.loads(cmd(["php","-d","memory_limit=512M","-r",PHP,str(root),
                           str(C),str(target),"translated" if translated else "raw"]))

def first_difference(actual, expected, path=""):
    if type(actual) is not type(expected):
        return {"path":path,"php":actual,"python":expected}
    if isinstance(expected, dict):
        if actual.keys() != expected.keys():
            return {"path":path,"php_keys":list(actual),"python_keys":list(expected)}
        for k in expected:
            diff=first_difference(actual[k],expected[k],path+"/"+k)
            if diff is not None: return diff
    elif isinstance(expected, list):
        if len(actual)!=len(expected):
            return {"path":path,"php_length":len(actual),"python_length":len(expected)}
        for i,(a,b) in enumerate(zip(actual,expected)):
            diff=first_difference(a,b,path+"/"+str(i))
            if diff is not None: return diff
    elif actual!=expected:
        return {"path":path,"php":actual,"python":expected}
    return None

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--php-root",type=Path,required=True)
    p.add_argument("--canonical-root",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    a=p.parse_args()
    ph=a.php_root.resolve(strict=True); py=a.canonical_root.resolve(strict=True); out=a.output.resolve()
    if ph==out or ph in out.parents or py==out or py in out.parents:
        raise ValueError("output must be outside locked checkouts")
    core_path="implementations/python/pastafari_calendar/core.py"
    php_paths=["tests/bootstrap.php","src/BootstrapKernel.php","src/BigInt.php",
        "src/Legacy/LegacyDayTag.php","src/Patches/FoundationScarPatch02.php",
        "src/Patches/CanonicalJdnBoundary56.php","src/Legacy/LegacyOverwrittenOrder11.php",
        "src/Legacy/LegacyBowlFactory.php","src/Patches/PoursAliasPatch09.php",
        "src/Patches/BowlShadowPatch10.php"]
    hashes={"php":verify(ph,PHP_SHA,php_paths),"canonical":verify(py,PY_SHA,[core_path])}
    sys.dont_write_bytecode=True
    spec=importlib.util.spec_from_file_location("locked_core",py/core_path)
    core=importlib.util.module_from_spec(spec);sys.modules[spec.name]=core;spec.loader.exec_module(core)
    if core.FOUNDATION_JDN != C: raise ValueError("foundation mismatch")
    results=[]
    for year,target in TARGETS.items():
        expected=py_reference(core,target)
        raw=php(ph,target,False)
        raw_diff=first_difference(raw["counts"],expected["counts"],"/counts")
        translated=php(ph,target,True)
        diff=first_difference(translated,expected)
        good=(raw_diff=={"path":"/counts/0","php":"3442851","python":"1"} and diff is None)
        results.append({"year":year,"target":target,"raw":raw,"raw_first_difference":raw_diff,
            "translated":translated,"canonical":expected,"translated_first_difference":diff,
            "status":"PASS" if good else "MISMATCH"})
    verify(ph,PHP_SHA,php_paths);verify(py,PY_SHA,[core_path])
    ok=all(r["status"]=="PASS" for r in results)
    report={"project_id":PROJECT,"php_sha":PHP_SHA,"canonical_sha":PY_SHA,"source_hashes":hashes,
            "status":"DIAGNOSTIC_PASS" if ok else "DIAGNOSTIC_MISMATCH",
            "raw_parity":False,"stage56_accepted":False,"years":results}
    out.parent.mkdir(parents=True,exist_ok=True)
    data=(json.dumps(report,sort_keys=True,separators=(",",":"))+"\n").encode()
    tmp=out.with_name(out.name+".tmp");tmp.write_bytes(data);os.replace(tmp,out)
    print(report["status"],hashlib.sha256(data).hexdigest())
    return 0 if ok else 1

if __name__=="__main__":
    try:
        sys.exit(main())
    except (ValueError,OSError,RuntimeError,KeyError,TypeError,subprocess.SubprocessError) as exc:
        print("DIAGNOSTIC_INPUT_ERROR:",exc,file=sys.stderr)
        sys.exit(2)
