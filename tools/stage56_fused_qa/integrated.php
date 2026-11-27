<?php
declare(strict_types=1);
require_once dirname(__DIR__, 2) . '/src/BigInt.php';
require_once dirname(__DIR__, 2) . '/src/Patches/MonthWeavingInterleaving56.php';
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\MonthWeavingInterleaving56;
if (PHP_INT_SIZE !== 8) throw new RuntimeException('64_BIT_REQUIRED');
$cases = json_decode(stream_get_contents(STDIN), true, 512, JSON_THROW_ON_ERROR);
foreach ($cases as $case) {
    if (isset($case['operands'])) {
        [$a,$b,$c] = array_map([BigInt::class,'fromString'],$case['operands']);
        $old = $c->add($a->mul($b))->toString();
        $new = $c->addProduct56($a,$b,true)->toString();
        $result = [$old,$new,$c->addProduct56($a,$b,false)->toString()];
    } elseif (isset($case['bench'])) {
        [$a,$b,$c] = array_map([BigInt::class,'fromString'],$case['bench']);
        $old = $c->add($a->mul($b))->toString();
        $samples = [[],[]];
        for ($pair=0;$pair<3;++$pair) {
            foreach ($pair%2 ? [1,0] : [0,1] as $mode) {
                $start=hrtime(true);
                for ($i=0;$i<12;++$i) {
                    $v=$mode ? $c->addProduct56($a,$b,true) : $c->add($a->mul($b));
                }
                $samples[$mode][]=(hrtime(true)-$start)/1e9;
                if ($v->toString()!==$old) throw new RuntimeException('BENCH_VALUE');
            }
        }
        $result=$samples;
    } else {
        $result=[];
        foreach ([false,true] as $mode) {
            $engine = new MonthWeavingInterleaving56($case['lengths'],false,$mode);
            $count=$engine->count()->toString();
            $probes=[];
            foreach ($case['probes'] as [$rank,$word]) {
                $probes[]=[$engine->rank($word)->toString(),$engine->unrank(BigInt::fromString($rank))];
            }
            $result[]=[$count,$probes];
            unset($engine);
        }
    }
    echo json_encode($result,JSON_THROW_ON_ERROR),"\n";
}
