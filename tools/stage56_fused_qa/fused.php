<?php
declare(strict_types=1);
// Standalone QA prototype; no production wiring. Canonical unsigned LE base 10^9.
const B = 1000000000;
function fused(array $a, array $b, array $c): array {
    $na=count($a); $nb=count($b); $nc=count($c); $n=max($na+$nb-1,$nc); $out=[]; $carry=0;
    for ($k=0; $k<$n; ++$k) {
        $sum=$carry+($c[$k]??0); $carry=0;
        $i=max(0,$k-$nb+1); $last=min($na-1,$k);
        while ($i<=$last) {
            $end=min($last+1,$i+8);
            for (;$i<$end;++$i) $sum+=$a[$i]*$b[$k-$i];
            $carry+=intdiv($sum,B); $sum=$sum%B;
        }
        $carry+=intdiv($sum,B); $out[]=$sum%B;
    }
    while ($carry>0) { $out[]=$carry%B; $carry=intdiv($carry,B); }
    while (count($out)>1 && end($out)===0) array_pop($out);
    return $out;
}
function scale(array $a,int $m,int $d): array {
    $carry=0; $out=[];
    foreach ($a as $x) { $v=$x*$m+$carry; $out[]=$v%B; $carry=intdiv($v,B); }
    if ($carry) $out[]=$carry;
    $rem=0; for ($i=count($out)-1;$i>=0;--$i) { $v=$rem*B+$out[$i]; $out[$i]=intdiv($v,$d); $rem=$v%$d; }
    if ($rem!==0) throw new RuntimeException('NONEXACT');
    while (count($out)>1&&end($out)===0) array_pop($out);
    return $out;
}
function countWeaves(array $l): array {
    $n=count($l); $width=[$l[0]];
    for ($i=1;$i<$n;++$i) $width[]=$width[$i-1]+$l[$i]-1;
    $following=array_fill(0,$width[$n-1]+1,[1]);
    for ($i=$n-2;$i>=0;--$i) {
        $current=[[0]]; $sum=[0]; $weight=[1]; $m=$l[$i+1];
        for ($q=1;$q<=$width[$i];++$q) {
            $sum=fused($weight,$following[$m+$q-1],$sum); $current[]=$sum;
            $weight=scale($weight,$m+$q-2,$q);
        }
        $following=$current;
    }
    return $following[$l[0]];
}
if (PHP_INT_SIZE!==8) throw new RuntimeException('64_BIT_REQUIRED');
$input=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR);
foreach ($input as $case) {
    $result=isset($case['lengths']) ? countWeaves($case['lengths']) : fused(...$case['operands']);
    echo json_encode($result,JSON_THROW_ON_ERROR),"\n";
}
