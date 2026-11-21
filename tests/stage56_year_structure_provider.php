<?php
declare(strict_types=1);
require_once __DIR__.'/bootstrap.php';
foreach (['YearStructureSlices56','MonthWeavingFrontier56','MonthWeavingAdjoint56',
    'MonthWeavingRanker56','UnboundedUniformChoice56',
    'ContextualYear5000Anchor56','YearStructureProvider56'] as $name) {
    require_once dirname(__DIR__).'/src/Patches/'.$name.'.php';
}
use Pastafari\Stage01\BootstrapKernel;
use Pastafari\Stage01\Patches\YearStructureProvider56;

$assertions=0;
function ok56(bool $ok,string $msg):void {
    global $assertions; ++$assertions;
    if (!$ok) throw new RuntimeException('STAGE56_PROVIDER_QA_'.$msg);
}
function rejected56(callable $cb,string $msg):void {
    try {$cb();} catch (InvalidArgumentException|RuntimeException|LogicException $e) {
        ok56($e->getMessage()===$msg,'REJECT_'.$msg);return;
    }
    throw new RuntimeException('STAGE56_NO_REJECTION_'.$msg);
}
$c=126;$source=str_repeat('a',40); // synthetic, NOT independently authenticated
$y=['number'=>5000,'openGateIndex'=>0,'closeGateIndex'=>6,
    'openGateDay'=>0,'closeGateDay'=>252];
$anchor=['calculation_jdn'=>$c,'source_commit'=>$source,'year'=>$y];
$trustedAnchor=static fn(int $day):array=>$anchor;
$trustedYear=static fn(int $day,int $number):array=>[
    'calculation_jdn'=>$day,'source_commit'=>$source,'year'=>$y];
$gate=static fn(int $index):int=>42*$index;
$builder=new YearStructureProvider56(new BootstrapKernel());
$s=$builder->buildVerified($c,$anchor,$trustedAnchor,$y,$trustedYear,$gate);
ok56($s['cutletCount']===6&&count($s['cutlets'])===6,'CUTLETS');
ok56(array_sum($s['cutletPartition'])===6&&
    count(array_unique($s['cutletNameIndices']))===6,'CUTLET_NAME_COUNT');
ok56($s['monthCount']>=3&&$s['monthCount']<=47&&
    $s['monthCount']===count($s['monthLengths'])&&
    $s['monthCount']===count($s['monthNameIndices']),'MONTHS');
ok56(array_sum($s['monthLengths'])===252&&count($s['monthWeaving'])===252&&
    count(array_unique($s['monthNameIndices']))===$s['monthCount'],'MONTH_COVERAGE');
$cursor=1;$forced=false;
foreach ($s['cutlets'] as $r) {
    ok56($r['firstDay']===$cursor&&$r['lastDay']>=$cursor,'CUTLET_INTERVAL');
    if ($r['lastDay']===126) $forced=true;
    $cursor=$r['lastDay']+1;
}
ok56($cursor===253&&$forced,'MANDATORY_CALCULATION_GATE');
$counts=array_fill(1,$s['monthCount'],0);$first=[];$last=[];
foreach ($s['monthWeaving'] as $i=>$id) {
    ok56(is_int($id)&&isset($counts[$id]),'MONTH_ID');
    ++$counts[$id];
    if (!isset($first[$id])) $first[$id]=$i;
    $last[$id]=$i;
}
foreach ($s['monthLengths'] as $i=>$n) {
    $id=$i+1;
    ok56($n>=4&&$n<=123&&$counts[$id]===$n,'MONTH_OCCURRENCES');
    if ($id>1) ok56($first[$id-1]<$first[$id]&&
        $last[$id-1]<$last[$id],'WEAVE_FIRST_LAST');
}
$bad=$anchor;$bad['calculation_jdn']=$c+1;
rejected56(static fn()=>$builder->buildVerified($c,$bad,$trustedAnchor,$y,
    $trustedYear,$gate),'STAGE56_ANCHOR_CANDIDATE_CONTEXT');
$badYear=$y;$badYear['closeGateDay']=253;
rejected56(static fn()=>$builder->buildVerified($c,$anchor,$trustedAnchor,
    $badYear,$trustedYear,$gate),'STAGE56_YEAR_WITNESS_MISMATCH_closeGateDay');
$badGate=static fn(int $i):int=>$i===3?127:42*$i;
rejected56(static fn()=>$builder->buildVerified($c,$anchor,$trustedAnchor,
    $y,$trustedYear,$badGate),'STAGE56_GATE_DISTANCE');
echo "STAGE56_PROVIDER_MICROGATE assertions={$assertions} synthetic=YES source_attested=NO profiles=0 PASS\n";
