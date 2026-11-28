#!/usr/bin/env python3
"""Isolated GMP small rank/unrank gate, no production wiring or real-year qualification.
One-based lexicographic ranks over zero-based IDs with ordered first and last
occurrences. Small shapes only (<=4 IDs, <=10 positions, <=3 per ID).
Candidate uses exact suffix DP plus ordered-ending binomial factors;
oracle enumerates multiset permutations and filters first/last order.
"""
import itertools, json, os, pathlib, signal, subprocess, sys, tempfile
import row_microgate as row

PHP = r'''
function chooseExact(int $n, int $k): GMP {
    if ($k<0 || $n<$k) throw new LogicException('binomial bounds');
    $v=gmp_init(1);
    for ($j=1;$j<=$k;++$j) {
        [$v,$r]=gmp_div_qr(gmp_mul($v,$n-$j+1),$j);
        if (gmp_cmp($r,0)!==0) throw new LogicException('binomial exactness');
    }
    return $v;
}
final class SmallGmpRanker {
    private array $rows=[];
    private int $n;
    private int $size;
    public function __construct(private array $lengths) {
        $this->n=count($lengths); $this->size=array_sum($lengths);
        if (!array_is_list($lengths)||$this->n<1||$this->n>4||$this->size>10)
            throw new InvalidArgumentException('lengths');
        foreach ($lengths as $m) if (!is_int($m)||$m<1||$m>3)
            throw new InvalidArgumentException('lengths');
        $q=[$lengths[0]];
        for ($i=1;$i<$this->n;++$i) $q[]=$q[$i-1]+$lengths[$i]-1;
        for ($i=$this->n-1;$i>=0;--$i) {
            if ($i===$this->n-1) {
                $this->rows[$i]=array_fill(0,$q[$i]+1,gmp_init(1));
                continue;
            }
            $m=$lengths[$i+1]; $sum=gmp_init(0); $w=gmp_init(1);
            $this->rows[$i]=[$sum];
            for ($r=0;$r<$q[$i];++$r) {
                $sum=gmp_add($sum,gmp_mul($w,$this->rows[$i+1][$m+$r]));
                $this->rows[$i][]=$sum;
                [$w,$rem]=gmp_div_qr(gmp_mul($w,$m+$r-1),$r+1);
                if (gmp_cmp($rem,0)!==0) throw new LogicException('row exactness');
            }
        }
    }
    public function count(): GMP { return $this->rows[0][$this->lengths[0]]; }
    public function completions(array $prefix): GMP {
        $rem=$this->lengths; $high=-1;
        foreach ($prefix as $x) {
            if (!is_int($x)||$x<0||$x>=$this->n||$x>$high+1||$rem[$x]===0)
                return gmp_init(0);
            if ($x===$high+1) $high=$x;
            if ($rem[$x]===1) {
                for ($j=0;$j<$x;++$j) if ($rem[$j]>0) return gmp_init(0);
            }
            --$rem[$x];
        }
        if ($high===-1) return $this->count();
        $base=gmp_init(1); $total=0;
        for ($j=0;$j<=$high;++$j) {
            $r=$rem[$j];
            if ($r===0) continue;
            $base=gmp_mul($base,chooseExact($total+$r-1,$r-1));
            $total+=$r;
        }
        return $high===$this->n-1 ? $base : gmp_mul($base,$this->rows[$high][$total+1]);
    }
    public function rank(array $word): string {
        if (!array_is_list($word)||count($word)!==$this->size||
            gmp_cmp($this->completions($word),1)!==0) throw new InvalidArgumentException('word');
        $p=[]; $rank=gmp_init(1);
        foreach ($word as $x) {
            for ($j=0;$j<$x;++$j) $rank=gmp_add($rank,$this->completions([...$p,$j]));
            $p[]=$x;
        }
        return gmp_strval($rank);
    }
    public function unrank(string $rank): array {
        if (!preg_match('/^[1-9][0-9]*$/D',$rank)) throw new InvalidArgumentException('rank');
        $r=gmp_init($rank,10);
        if (gmp_cmp($r,$this->count())>0) throw new InvalidArgumentException('rank');
        $p=[];
        while (count($p)<$this->size) {
            $chosen=false;
            for ($j=0;$j<$this->n;++$j) {
                $b=$this->completions([...$p,$j]);
                if (gmp_cmp($r,$b)<=0) { $p[]=$j; $chosen=true; break; }
                $r=gmp_sub($r,$b);
            }
            if (!$chosen) throw new LogicException('no branch');
        }
        if (gmp_cmp($r,1)!==0) throw new LogicException('residual');
        return $p;
    }
}
if (!extension_loaded('gmp')) { echo '{"status":"NOT_RUN","reason":"GMP missing"}'; exit(77); }
$input=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR);
$engine=new SmallGmpRanker($input['lengths']);
$rank=[]; $unrank=[]; $prefix=[];
foreach ($input['words'] as $word) $rank[]=$engine->rank($word);
foreach ($input['ranks'] as $r) $unrank[]=$engine->unrank($r);
foreach ($input['prefixes'] as $p) $prefix[]=gmp_strval($engine->completions($p));
$negative=0;
foreach (['0','-1','01','x',gmp_strval(gmp_add($engine->count(),1))] as $r) {
    try { $engine->unrank($r); } catch (InvalidArgumentException $e) { ++$negative; }
}
foreach ([[],array_fill(0,array_sum($input['lengths']),-1),array_fill(0,array_sum($input['lengths']),true)] as $w) {
    try { $engine->rank($w); } catch (InvalidArgumentException $e) { ++$negative; }
}
echo json_encode(['status'=>'SMALL_RANK_RESULT','count'=>gmp_strval($engine->count()),
    'rank'=>$rank,'unrank'=>$unrank,'prefix'=>$prefix,'negative'=>$negative],JSON_THROW_ON_ERROR);
'''

def enumerate_words(lengths):
    # Independent multiset permutation enumeration, no DP or rank formula.
    n=len(lengths)
    def visit(p,rem):
        if not any(rem):
            if (sorted(range(n),key=p.index)==list(range(n)) and
                sorted(range(n),key=lambda x:len(p)-1-p[::-1].index(x))==list(range(n))):
                yield p
            return
        for x in range(n):
            if rem[x]:
                r=rem.copy(); r[x]-=1
                yield from visit(p+[x],r)
    return list(visit([],list(lengths)))

def worker(payload):
    with tempfile.TemporaryDirectory(prefix="stage56-gmp-rank-") as d:
        rss=pathlib.Path(d)/"rss"
        p=subprocess.Popen(["/usr/bin/time","-f","%M","-o",str(rss),"php",
            "-d","memory_limit=512M","-r",PHP],stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,
            preexec_fn=row.cap,start_new_session=True)
        try:
            stdout,stderr=p.communicate(json.dumps(payload),timeout=180)
        except BaseException:
            try: os.killpg(p.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            p.communicate()
            raise
        if p.returncode or stderr:
            raise RuntimeError(f"rank worker exit={p.returncode} stderr={stderr[:1000]} stdout={stdout[:1000]}")
        if int(rss.read_text().strip())*1024>512*1024**2: raise RuntimeError("RSS limit")
        return json.loads(stdout)

def main():
    row.source_lock()
    if not sys.platform.startswith("linux"): raise RuntimeError("Linux required")
    shapes=row.SMALL+[[1,1,1,1],[2,2,2,2],[3,2,1,2],[2,3,2,3]]
    words_checked=prefix_checked=negative_checked=0
    for L in shapes:
        words=enumerate_words(L)
        if not words or words!=sorted(words) or len({tuple(w) for w in words})!=len(words):
            raise RuntimeError("oracle enumeration order")
        prefixes={}
        for w in words:
            for k in range(len(w)+1):
                p=tuple(w[:k]); prefixes[p]=prefixes.get(p,0)+1
        # Test zero-completion siblings as well as every legal prefix.
        for p in list(prefixes):
            if len(p)<sum(L):
                for x in range(len(L)): prefixes.setdefault(p+(x,),0)
        keys=sorted(prefixes)
        ranks=[str(i) for i in range(1,len(words)+1)]
        result=worker(dict(lengths=L,words=words,ranks=ranks,prefixes=keys))
        expected=dict(status="SMALL_RANK_RESULT",count=str(len(words)),rank=ranks,
            unrank=words,prefix=[str(prefixes[p]) for p in keys],negative=8)
        if result!=expected: raise RuntimeError(f"rank oracle mismatch {L}")
        words_checked+=len(words); prefix_checked+=len(keys); negative_checked+=8
        row.emit(dict(type="small_rank",lengths=L,words=len(words),prefixes=len(keys),negative=8))
    row.emit(dict(status="SMALL_RANK_GATE_PASS",shapes=len(shapes),rank=words_checked,
        unrank=words_checked,prefixes=prefix_checked,negative=negative_checked,
        qualification="SMALL_ONLY"))
    return 0

if __name__=="__main__":
    try: sys.exit(main())
    except (RuntimeError,ValueError,OSError,subprocess.TimeoutExpired) as exc:
        row.emit(dict(status="FAIL",error=str(exc))); sys.exit(1)
