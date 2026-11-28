#!/usr/bin/env python3
"""Stage56 isolated QA row kernel; Linux only. No production wiring.
Source trace: run 46078094949 artifact 15237855899, verified SHA256
e745c64c41fc77f85e00a19e96d0b07a106e4529b9bea883c2b37b12223489e4.
Initial DP widths derive L[0]=q[0], L[i]=q[i]-q[i-1]+1.
This is a row-only microgate: rank/unrank qualification is still required.
"""
import hashlib, itertools, json, math, os, pathlib, resource, signal, subprocess, sys, tempfile, time

# The source bounds the maximum word length to 5778; exact decimal digests
# may exceed Python's default 4300-digit conversion ceiling.
if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(0)

ROOT = pathlib.Path(__file__).resolve().parents[2]
LOCKS = {
    "src/BigInt.php": "3ec9a816ed2c704998018abab36efa5a8e98d20c",
    "src/Patches/MonthWeavingInterleaving56.php": "05a348188f1752c8f10699ea7b76ecd24ad44238",
}
LARGE = [
    [123,123,122,120,123,120,120,123,121,123,123,122,122,122,123,123,123,118,120,121,122,122,123,117,121,120,123,123,118,120,119,123,119,121],
    [115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,97,50,122,110,81,54,101,83,88,40,25,77,98,122,105],
    [123,120,121,121,119,123,123,122,118,123,120,123,123,118,120,117,123,118,120,121,121,123,123,123,123,116,122,120,120,122,122,120,123,122,123,114,123,123,122,123,122,114,118,123,123,123],
]
SMALL = [list(x) for n in (1,2,3) for x in itertools.product((1,2,3), repeat=n)]
PHP = r'''
require $argv[1] . '/src/BigInt.php';
$mode = $argv[2];
$L = json_decode($argv[3], true, 512, JSON_THROW_ON_ERROR);
if (!is_array($L) || !array_is_list($L) || !$L || count($L)>47) throw new InvalidArgumentException('lengths');
foreach ($L as $x) if (!is_int($x) || $x<1 || $x>123) throw new InvalidArgumentException('length');
if (array_sum($L)>5778 || !in_array($mode,['gmp','baseline'],true)) throw new InvalidArgumentException('input');
$g = $mode === 'gmp';
if ($g && !extension_loaded('gmp')) { echo json_encode(['status'=>'NOT_RUN','reason'=>'GMP missing']); exit(77); }
$zero = static fn()=> $g ? gmp_init(0) : \Pastafari\Stage01\BigInt::zero();
$one = static fn()=> $g ? gmp_init(1) : \Pastafari\Stage01\BigInt::one();
$width = [$L[0]];
for ($i=1;$i<count($L);++$i) $width[]=$width[$i-1]+$L[$i]-1;
$hash=hash_init('sha256'); $following=null; $cells=0; $arithmetic=0; $conversion=0; $start=hrtime(true);
for ($i=count($L)-1;$i>=0;--$i) {
    $t=hrtime(true);
    $qmax=$width[$i];
    if ($i===count($L)-1) $current=array_fill(0,$qmax+1,$one());
    else {
        $current=[$zero()]; $sum=$zero(); $w=$one(); $m=$L[$i+1];
        for ($q=1;$q<=$qmax;++$q) {
            $r=$q-1; $target=$m+$r;
            if (!isset($following[$target])) throw new LogicException('index');
            if ($g) {
                $sum=gmp_add($sum,gmp_mul($w,$following[$target]));
                [$w,$rem]=gmp_div_qr(gmp_mul($w,$m+$r-1),$r+1);
                if (gmp_cmp($rem,0)!==0) throw new LogicException('nonexact');
            } else {
                $sum=$sum->add($w->mul($following[$target]));
                $w=$w->mulSmall($m+$r-1)->divSmallExact($r+1);
            }
            $current[]=$sum; ++$cells;
        }
    }
    $arithmetic+=hrtime(true)-$t;
    $t=hrtime(true);
    foreach ($current as $q=>$v) {
        $s=$g ? gmp_strval($v,10) : $v->toString();
        if (!preg_match('/^(0|[1-9][0-9]*)$/D',$s)) throw new LogicException('noncanonical');
        if ($g && \Pastafari\Stage01\BigInt::fromString($s)->toString()!==$s) throw new LogicException('conversion');
        hash_update($hash,$i.':'.$q.':'.$s."\n");
    }
    $conversion+=hrtime(true)-$t;
    $following=$current; unset($current);
}
$count=$g ? gmp_strval($following[$width[0]]) : $following[$width[0]]->toString();
echo json_encode(['status'=>'ROW_RESULT','mode'=>$mode,'cells'=>$cells,'hash'=>hash_final($hash),
'count'=>$count,'arithmetic_ns'=>$arithmetic,'conversion_hash_ns'=>$conversion,
'total_ns'=>hrtime(true)-$start,'php_peak'=>memory_get_peak_usage(true),
'php'=>PHP_VERSION,'gmp'=>$g?phpversion('gmp'):null,'gmp_library'=>$g?GMP_VERSION:null],JSON_THROW_ON_ERROR);
'''

def widths(L):
    if not L or len(L)>47 or any(type(x) is not int or not 1<=x<=123 for x in L) or sum(L)>5778:
        raise ValueError("lengths")
    q=[L[0]]
    for m in L[1:]:
        q.append(q[-1]+m-1)
    return q

def oracle(L):
    q=widths(L)
    h=hashlib.sha256()
    following=None
    for i in reversed(range(len(L))):
        if i==len(L)-1:
            row=[1]*(q[i]+1)
        else:
            m=L[i+1]
            row=[0]
            for r in range(q[i]):
                # m=1 gives 1 for r=0 and zero thereafter (source recurrence).
                w=(int(r==0) if m==1 else math.comb(m+r-2,r))
                row.append(row[-1]+w*following[m+r])
        for j,v in enumerate(row):
            h.update(f"{i}:{j}:{v}\n".encode("ascii"))
        following=row
    return {"cells":sum(q[:-1]),"hash":h.hexdigest(),"count":str(following[q[0]])}

def exhaustive(L):
    # Independently enumerate legal words: first and last occurrences in ID order.
    n=sum(L)
    return sorted(w for w in itertools.product(range(len(L)),repeat=n)
        if all(w.count(i)==L[i] for i in range(len(L)))
        and sorted(range(len(L)),key=w.index)==list(range(len(L)))
        and sorted(range(len(L)),key=lambda i:n-1-w[::-1].index(i))==list(range(len(L))))

def source_lock():
    for path,expected in LOCKS.items():
        b=(ROOT/path).read_bytes()
        got=hashlib.sha1(f"blob {len(b)}\0".encode()+b).hexdigest()
        if got!=expected: raise RuntimeError(f"source mismatch: {path} {got}")

def cap():
    resource.setrlimit(resource.RLIMIT_AS,(512*1024**2,512*1024**2))
    resource.setrlimit(resource.RLIMIT_CORE,(0,0))

def run(mode,L):
    with tempfile.TemporaryDirectory(prefix="stage56-gmp-") as d:
        rss=pathlib.Path(d)/"rss"
        t=time.monotonic_ns()
        p=subprocess.Popen(["/usr/bin/time","-f","%M","-o",str(rss),"php","-d","memory_limit=512M",
                          "-r",PHP,str(ROOT),mode,json.dumps(L)],stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,text=True,preexec_fn=cap,start_new_session=True)
        try:
            stdout,stderr=p.communicate(timeout=180)
        except BaseException:
            try: os.killpg(p.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            p.communicate()
            raise
        elapsed=time.monotonic_ns()-t
        if p.returncode or stderr: raise RuntimeError(f"{mode} exit={p.returncode} stderr={stderr[:1000]} stdout={stdout[:1000]}")
        result=json.loads(stdout)
        if result.get("status")!="ROW_RESULT" or result.get("mode")!=mode:
            raise RuntimeError("invalid worker identity")
        result["rss_bytes"]=int(rss.read_text().strip())*1024
        result["elapsed_ns"]=elapsed
        if result["rss_bytes"]>512*1024**2: raise RuntimeError("RSS limit")
        return result

def emit(record):
    print(json.dumps(record,sort_keys=True),flush=True)

def main():
    source_lock()
    if not sys.platform.startswith("linux"): raise RuntimeError("Linux RSS/RLIMIT_AS required")
    p=subprocess.run(["php","-r","echo extension_loaded('gmp') ? 'yes' : 'no';"],capture_output=True,text=True,timeout=5)
    if p.returncode or p.stderr: raise RuntimeError("PHP probe failed")
    if p.stdout!="yes":
        emit({"status":"NOT_RUN","reason":"GMP extension missing","php_probe":p.stdout})
        return 77
    for L in SMALL:
        o=oracle(L)
        words=exhaustive(L)
        if int(o["count"])!=len(words): raise RuntimeError(f"independent enumeration mismatch {L}")
        for mode in ("baseline","gmp"):
            r=run(mode,L)
            if any(r[k]!=o[k] for k in o): raise RuntimeError(f"small oracle mismatch {L} {mode}")
        emit({"type":"small","lengths":L,"oracle":o,"exhaustive_count":len(words)})
    for L in ([123],[123,1],[1,123],[123,123]):
        o=oracle(L)
        for mode in ("baseline","gmp"):
            r=run(mode,L)
            if any(r[k]!=o[k] for k in o): raise RuntimeError(f"boundary mismatch {L} {mode}")
        emit({"type":"boundary","lengths":L,"oracle":o})
    for L in ([],[0],[124],[-1],[True],[1]*48):
        for mode in ("baseline","gmp"):
            try: run(mode,L)
            except RuntimeError as e:
                if "InvalidArgumentException" not in str(e): raise
            else: raise RuntimeError("invalid accepted")
    passed=True
    for year,L in zip((4999,5000,5001),LARGE):
        o=oracle(L)
        pairs=[]
        for rep in range(3):
            pair={}
            for mode in (("baseline","gmp") if rep%2==0 else ("gmp","baseline")):
                r=run(mode,L)
                if any(r[k]!=o[k] for k in o): raise RuntimeError(f"large mismatch {year} {mode}")
                pair[mode]=r
            pairs.append(pair)
            emit({"type":"paired_row","year":year,"repeat":rep,"oracle":o,"result":pair})
        # Require each pair to satisfy the threshold, not only a median.
        ok=all(5*x["gmp"]["elapsed_ns"]<=4*x["baseline"]["elapsed_ns"]
               and x["gmp"]["rss_bytes"]<=x["baseline"]["rss_bytes"] for x in pairs)
        emit({"type":"row_performance","year":year,"pass":ok})
        passed &= ok
    emit({"status":"ROW_MICROGATE_PASS" if passed else "ROW_MICROGATE_REJECT",
          "qualification":"INCOMPLETE","missing":"candidate rank/unrank comparison; no real-year authorization"})
    return 0 if passed else 1

if __name__=="__main__":
    try:
        sys.exit(main())
    except (RuntimeError,ValueError,subprocess.TimeoutExpired,OSError) as exc:
        emit({"status":"FAIL","error":str(exc)})
        sys.exit(1)
